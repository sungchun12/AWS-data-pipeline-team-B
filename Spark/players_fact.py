
import argparse
import logging
from pyspark.sql import SparkSession #import spark functionality for spark sql
from pyspark.sql.types import DoubleType, IntegerType, StringType, BooleanType, ArrayType #import data types
from pyspark.sql import DataFrame #used for sql functionality on dataframes
from pyspark.sql.functions import monotonically_increasing_id, col, row_number, max, lit #used to create incremental ids
from pyspark.sql.window import Window
logger = logging.getLogger(__name__)

# For interactive debugging:
# players_data_path = 's3://ima-flexb-agg/data/Players_dim/'
# fielding_post_data_path = 's3://ima-flexb-sor/data/FieldingPost/'
# batting_post_data_path = 's3://ima-flexb-sor/data/BattingPost/'
# pitching_post_data_path = 's3://ima-flexb-sor/data/PitchingPost/'
# salaries_data_path = 's3://ima-flexb-sor/data/Salaries/'
# output_path = 's3://ima-flexb-agg/data/Players_fact/'
# error_path = 's3://ima-flexb-agg/error/Players_fact/'

# Parse runtime variables:
parser = argparse.ArgumentParser()

parser.add_argument("--players-data-path", 
                    help="S3 path to Players data file.")
parser.add_argument("--fielding-post-data-path", 
                    help="S3 path to FieldingPost data file.")
parser.add_argument("--batting-post-data-path", 
                    help="S3 path to BattingPost data file.")
parser.add_argument("--pitching-post-data-path", 
                    help="S3 path to Pitching data file.")
parser.add_argument("--salaries-data-path", 
                    help="S3 path to Salaries data file.")
parser.add_argument("--output-path",
                    help="S3 path for results from this script")
parser.add_argument("--error-path",
                    help="S3 path for problem records")

args = parser.parse_args()

if args.players_data_path:
    players_data_path = args.players_data_path
if args.fielding_post_data_path:
    fielding_post_data_path = args.fielding_post_data_path
if args.batting_post_data_path:
    batting_post_data_path = args.batting_post_data_path
if args.pitching_post_data_path:
    pitching_post_data_path = args.pitching_post_data_path
if args.salaries_data_path:
    salaries_data_path = args.salaries_data_path
if args.output_path:
    output_path = args.output_path
if args.error_path:
    error_path = args.error_path

# start Spark session:
spark = SparkSession.builder.appName("SimpleApp").getOrCreate()

# read input files:
players = spark.read.format("csv").option("header", "true")\
  .load(players_data_path)
players.cache()
#filter for distinct rows
players=players.distinct()

fielding = spark.read.format("csv").option("header", "true")\
  .load(fielding_post_data_path)
fielding.cache()

batting = spark.read.format("csv").option("header", "true")\
  .load(batting_post_data_path)
batting.cache()

pitching = spark.read.format("csv").option("header", "true")\
  .load(pitching_post_data_path)
pitching.cache()

salaries = spark.read.format("csv").option("header", "true")\
  .load(salaries_data_path)
salaries.cache()

#isolate the fields needed from each source table for fact data. Need to accumulate metrics as necessary
group_keys = ['playerID', 'yearID', 'teamID', 'lgID']
metrics = ['A','BB','IPouts','R','H','salary']

# Ensure metrics columns exist in all dataframes before union:
def assign_metrics(df, group_keys, metrics):
    """Determines whether metric columns exist, adding them if not. 
    Groups results according to group_keys and sums metrics"""
    all_columns = group_keys + metrics
    for mt in metrics:
        if mt in df.columns:
            df = df.withColumn(mt, df[mt].cast(IntegerType()))
        else:
            df = df.withColumn(mt, lit(0))
            df = df.withColumn(mt, df[mt].cast(IntegerType()))
    df = df.groupby(*group_keys).sum(*metrics)
    df = df.toDF(*all_columns)
    return df

# apply function above to each data frame for analysis:
fielding = assign_metrics(fielding, group_keys, metrics)
batting  = assign_metrics(batting, group_keys, metrics)
pitching = assign_metrics(pitching, group_keys, metrics)
salaries = assign_metrics(salaries, group_keys, metrics)

# union metrics dataframes together to create player_fact skeleton:
def unionAll(*dfs):
    return reduce(DataFrame.unionAll, dfs)

#implement union all function
players_fact = unionAll(fielding, batting, pitching, salaries)
players_fact = players_fact.groupby(*group_keys).sum(*metrics)
all_columns = group_keys + metrics
players_fact = players_fact.toDF(*all_columns)

# Assign foreign key from players table:
players_fact = players_fact.join(players,\
    (players.playerID == players_fact.playerID) & \
    (players.yearID == players_fact.yearID.cast(IntegerType())) & \
    (players.teamID == players_fact.teamID) & \
    (players.lgID == players_fact.lgID), \
    'left')\
    .select(*['player_key', 'A', 'BB', 'IPouts', 'R', 'H', 'salary'])

#create field name remapping
mapping = dict({'A'         :'assists', 
                'BB'        :'walks',
                'IPouts'    :'outs_pitched',
                'R'         :'runs',
                'H'         :'hits'})

#iterate through all columns in player fact table with mapping above
players_fact=players_fact.select([col(c)\
    .alias(mapping.get(c, c)) for c in players_fact.columns])

#put null values into a separate table for later analysis
# "|" is logical disjunction(OR) syntax
players_fact_null=players_fact.where(players_fact['player_key'].isNull())

# get only the records with a valid player_key:
players_fact=players_fact.where(players_fact['player_key'].isNotNull())

players = players.withColumn("player_fact_key", \
                             monotonically_increasing_id())
windowSpec = Window.orderBy("player_fact_key")
players.withColumn("player_fact_key", \
                   row_number().over(windowSpec))\
                   .sort(col("player_fact_key").desc())

# upload results to s3:
try:
    players_fact.repartition(1).write.csv(output_path, mode = 'overwrite', header = 'true')
    print('resulting file written successfully to {}'.format(output_path))
except:
    print('There was a problem writing results to {}'.format(output_path))

try:
    players_fact_null.repartition(1).write.csv(error_path, mode = 'overwrite', header = 'true')
    print('resulting file written successfully to {}'.format(error_path))
except:
    print('There was a problem writing results to {}'.format(error_path))

