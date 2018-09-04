
import argparse
import sys
import logging
from pyspark.sql import SparkSession #import spark functionality for spark sql
from pyspark.sql.types import DoubleType, IntegerType, StringType, BooleanType, ArrayType #import data types
from pyspark.sql import DataFrame #used for sql functionality on dataframes
from pyspark.sql.functions import monotonically_increasing_id, col, row_number, max #used to create incremental ids
import pyspark.sql.functions as F #import all functions
from pyspark.sql.window import Window
logger = logging.getLogger(__name__) #import script logging information

# For interactive debugging:
#fielding_post_data_path = 's3://ima-flexb-sor/data/FieldingPost/'
#batting_post_data_path = 's3://ima-flexb-sor/data/BattingPost/'
#pitching_post_data_path = 's3://ima-flexb-sor/data/PitchingPost/'
#output_path = 's3://ima-flexb-agg/data/Players_dim/'
#error_path = 's3://ima-flexb-agg/error/Players_dim/'

# Parse runtime variables:
parser = argparse.ArgumentParser()

parser.add_argument("--fielding-post-data-path", 
                    help="S3 path to FieldingPost data file.")
parser.add_argument("--batting-post-data-path", 
                    help="S3 path to BattingPost data file.")
parser.add_argument("--pitching-post-data-path", 
                    help="S3 path to PitchingPost data file.")
parser.add_argument("--output-path",
                    help="S3 path for results from this script")
parser.add_argument("--error-path",
                    help="S3 path for problem records")

args = parser.parse_args()

if args.fielding_post_data_path:
    fielding_post_data_path = args.fielding_post_data_path
if args.batting_post_data_path:
    batting_post_data_path = args.batting_post_data_path
if args.pitching_post_data_path:
    pitching_post_data_path = args.pitching_post_data_path
if args.output_path:
    output_path = args.output_path
if args.error_path:
    error_path = args.error_path

# start Spark session:
spark = SparkSession.builder.appName("SimpleApp").getOrCreate()

# read input files:
fielding = spark.read.format("csv").option("header", "true")\
  .load(fielding_post_data_path)
fielding.cache() # for faster operations

batting = spark.read.format("csv").option("header", "true")\
  .load(batting_post_data_path)
batting.cache() # for faster operations

pitching = spark.read.format("csv").option("header", "true")\
  .load(pitching_post_data_path)
pitching.cache()

#convert column names to replace periods with underscores if they exist
for df in [fielding, batting, pitching]:
	new_names = [nm.replace('.', '_') for nm in df.schema.names]
	df = df.toDF(*new_names)

#function created to create row-wise union amongst relevant columns from each dataframe
def unionAll(*dfs):
    return reduce(DataFrame.unionAll, dfs)

#implement union all function
players=unionAll(fielding['playerID','yearID','teamID','lgID'],
	             batting['playerID','yearID','teamID','lgID'],
                 pitching['playerID','yearID','teamID','lgID'])

#filter for distinct rows
players=players.distinct()

# Add primary key column to players:
players = players.withColumn("player_key", monotonically_increasing_id()) #create an index of increasing rows
windowSpec = Window.orderBy("player_key") #create ordering for index
players.withColumn("player_key", row_number().over(windowSpec)).sort(col("player_key").desc()) #create column where the index goes in incremental order

players = players.withColumn("playerID", players["playerID"].cast('varchar(30)'))
players = players.withColumn("yearID", players["yearID"].cast(IntegerType()))
players = players.withColumn("teamID", players["teamID"].cast('char(3)'))
players = players.withColumn("lgID", players["lgID"].cast('char(2)'))

#put null values into a separate table for later analysis
# "|" is logical disjunction(OR) syntax
players_null=players.where(players['playerID'].isNull() | \
	                       players['yearID'].isNull() | \
	                       players['teamID'].isNull() | \
	                       players['lgID'].isNull() )

#filter for non_null values in final dataframe
players=players.where(players['playerID'].isNotNull() & \
                      players['yearID'].isNotNull() & \
                      players['teamID'].isNotNull() & \
                      players['lgID'].isNotNull() )

try:
	players.repartition(1).write.csv(output_path, mode = 'overwrite', header = 'true')
	print('resulting file written successfully to {}'.format(output_path))
except:
	print('There was a problem writing results to {}'.format(output_path))

try:
	players_null.repartition(1).write.csv(error_path, mode = 'overwrite', header = 'true')
	print('resulting file written successfully to {}'.format(error_path))
except:
	print('There was a problem writing results to {}'.format(error_path))