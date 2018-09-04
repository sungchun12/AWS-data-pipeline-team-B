
from __future__ import print_function #import print function with ('') syntax
import sys #The list of command line arguments passed to a Python script.
import logging
from pyspark.sql import SparkSession #import spark functionality for spark sql
from pyspark.sql.types import DoubleType, IntegerType, StringType, BooleanType, ArrayType #import data types
from IPython.display import display # display multiple outputs within the same cell
from functools import reduce #for Python 3.x
from pyspark.sql import DataFrame #used for sql functionality on dataframes
from pyspark.sql.functions import monotonically_increasing_id, col, row_number, max #used to create incremental ids
import pyspark.sql.functions as F #import all functions
from pyspark.sql.window import Window
logger = logging.getLogger(__name__)

# these variables will be used for command line paths passed through for input/output files
# Parse runtime variables:
try:
    fielding_post_s3_path = sys.argv[1]
    batting_post_s3_path = sys.argv[2]
    pitching_post_s3_path = sys.argv[3]
    salaries_s3_path = sys.argv[4]
    players_s3_path = sys.argv[5] # get the players dim table as input
    players_fact_output_path= sys.argv[6]
except IndexError as err:
    logger.error(err)
    raise

# start Spark session:
spark = SparkSession.builder.appName("SimpleApp").getOrCreate()

# read input files:
players = spark.read.format("csv").option("header", "true")\
  .load(players_s3_path)
players.cache()

fielding = spark.read.format("csv").option("header", "true")\
  .load(fielding_post_s3_path)
fielding.cache()

batting = spark.read.format("csv").option("header", "true")\
  .load(batting_post_s3_path)
batting.cache()

pitching = spark.read.format("csv").option("header", "true")\
  .load(pitching_post_s3_path)
pitching.cache()

salaries = spark.read.format("csv").option("header", "true")\
  .load(salaries_s3_path)
salaries.cache()


#isolate the fields needed from each source table for fact data. Need to accumulate metrics as necessary
group_keys = ['playerID', 'yearID', 'teamID', 'lgID']
metrics = ['A','BB','IPouts','R','H','salary']
all_columns = group_keys + metrics

# Ensure metrics columns exist in all dataframes before union:
for df in [fielding, batting, pitching, salaries]:
	for mk in metrics:
		if mk in df.columns:
			df = df.withColumn(mk, df[mk].cast(IntegerType()))
		else:
			df = df.withColumn(mk, lit(0))

	df = df.groupby(group_keys).sum(metrics)
	df = df.toDF(*all_columns)

# union metrics dataframes together to create player_fact skeleton:
def unionAll(*dfs):
    return reduce(DataFrame.unionAll, dfs)

#implement union all function
players_fact=unionAll(fielding, batting, pitching, salaries)
players_fact = players_fact.groupby(group_keys).sum(metric_keys)

# Assign foreign key from players table:
players_fact = players_fact.join(players,\
	(players.playerID == batting_grp.playerID) & \
	(players.yearID == batting_grp.yearID.cast(IntegerType())) & \
	(players.teamID == batting_grp.teamID) & \
	(players.lgID == batting_grp.lgID), \
	'left')\
    .select(*('player_key', 'A', 'BB', 'IPouts', 'R', 'H', 'salary'))


#create field name remapping
mapping = dict({'A'         :'assists', 
	            'BB'        :'walks',
	            'IPouts'    :'outs_pitched',
	            'R'         :'runs',
	            'H'         :'hits'})

#iterate through all columns in player fact table with mapping above
player_fact=player_fact.select([col(c)\
	.alias(mapping.get(c, c)) for c in player_fact.columns])

#put null values into a separate table for later analysis
# "|" is logical disjunction(OR) syntax
player_fact_null=player_fact.where(player_fact['player_key'].isNull())

# get only the records with a valid player_key:
player_fact=player_fact.where(player_fact['player_key'].isNotNull())

# upload results to s3:
try:
	player_fact.repartition(1).write.csv(players_fact_output_path, mode = 'overwrite', header = 'true')
	print('resulting file written successfully to {}'.format(players_fact_output_path))
except:
	print('There was a problem writing results to {}'.format(players_fact_output_path))

