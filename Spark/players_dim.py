
import sys
import logging
from pyspark.sql import SparkSession #import spark functionality for spark sql
from pyspark.sql.types import DoubleType, IntegerType, StringType, BooleanType, ArrayType #import data types
#from IPython.display import display # display multiple outputs within the same cell
#from functools import reduce #for Python 3.x
from pyspark.sql import DataFrame #used for sql functionality on dataframes
from pyspark.sql.functions import monotonically_increasing_id, col, row_number, max #used to create incremental ids
import pyspark.sql.functions as F #import all functions
from pyspark.sql.window import Window
logger = logging.getLogger(__name__) #import script logging information

# these variables will be used for command line paths passed through for input/output files
# Parse runtime variables:
try:
    fielding_s3_path = sys.argv[1]
    batting_s3_path = sys.argv[2]
    pitching_s3_path = sys.argv[3]
    players_output_path= sys.argv[4]

except IndexError as err:
    logger.error(err)
    raise

# start Spark session:
spark = SparkSession.builder.appName("SimpleApp").getOrCreate()

# read input files:
fielding = spark.read.format("csv").option("header", "true")\
  .load(fielding_post_s3_path)
fielding.cache() # for faster operations

batting = spark.read.format("csv").option("header", "true")\
  .load(batting_post_s3_path)
batting.cache() # for faster operations

pitching = spark.read.format("csv").option("header", "true")\
  .load(pitching_post_s3_path)
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
players_null=players.where(players['playerID'].isNull() | players['yearID'].isNull() | players['teamID'].isNull() | players['lgID'].isNull() )


#filter for non_null values in final dataframe
players=players.where(players['playerID'].isNotNull() | players['yearID'].isNotNull() | players['teamID'].isNotNull() | players['lgID'].isNotNull() )

try:
	players.repartition(1).write.csv(players_output_path, mode = 'overwrite', header = 'true')
	print('resulting file written successfully to {}'.format(players_output_path))
except:
	print('There was a problem writing results to {}'.format(players_output_path))



