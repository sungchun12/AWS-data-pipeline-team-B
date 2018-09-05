
import argparse
import logging
from pyspark.sql import SparkSession #import spark functionality for spark sql
from pyspark.sql.types import DoubleType, IntegerType, StringType, BooleanType, ArrayType #import data types
from pyspark.sql import DataFrame #used for sql functionality on dataframes
from pyspark.sql.functions import monotonically_increasing_id, col, row_number, max #used to create incremental ids
import pyspark.sql.functions as F #import all functions
from pyspark.sql.window import Window
logger = logging.getLogger(__name__) #import script logging information

# for debugging:
#college_playing_data_path = 's3://ima-flexb-sor/data/CollegePlaying/' 
#output_path = 's3://ima-flexb-agg/data/CollegePlaying_dim/'
#error_path = 's3://ima-flexb-agg/error/CollegePlaying_dim/'

# Parse runtime variables:
parser = argparse.ArgumentParser()

parser.add_argument("--college-playing-data-path", 
                    help="S3 path to CollegePlaying data file.")
parser.add_argument("--output-path",
                    help="S3 path for results from this script")
parser.add_argument("--error-path",
                    help="S3 path for problem records")

args = parser.parse_args()

if args.college_playing_data_path:
    college_playing_data_path = args.college_playing_data_path
if args.college_playing_output_path:
    output_path = args.output_path
if args.college_playing_error_path:
    error_path = args.error_path

# start Spark session:
spark = SparkSession.builder.appName("CollegePlayingApp").getOrCreate()

#load college table:
college = spark.read.format("csv").option("header", "true")\
  .load(college_playing_data_path)
college.cache() # for faster operations

#convert column names to replace periods with underscores if they exist
new_names = [nm.replace('.', '_') for nm in college.schema.names]
college = college.toDF(*new_names)

#convert data types to match data model
college = college.withColumn("yearID", 
                             college["yearID"].cast(IntegerType()))
college = college.withColumn("playerID", 
                             college["playerID"].cast('varchar(30)'))
college = college.withColumn("schoolID", 
                            college["schoolID"].cast('varchar(30)'))

college_null=college.where(college['yearID'].isNull() | \
                           college['playerId'].isNull() | \
                           college['schoolID'].isNull() )

college=college.where(college['yearID'].isNotNull() & \
                      college['playerId'].isNotNull() & \
                      college['schoolID'].isNotNull() )

# Add primary key column to players:
college = college.withColumn("player_college_key", \
                              monotonically_increasing_id()) #create an index of increasing rows

#create ordering for index
windowSpec = Window.orderBy("player_college_key") 
#create column where the index goes in incremental order
college.withColumn("player_college_key", 
                  row_number().over(windowSpec))\
                  .sort(col("player_college_key").desc()) 

# write results file to data path:
try:
	college.repartition(1).write.csv(output_path, 
                                   mode = 'overwrite', 
                                   header = 'true')
	print('resulting file written successfully to {}'\
     .format(output_path))
except:
	print('There was a problem writing results to {}'\
    .format(output_path))

# write any errors to error path:
try:
  college_null.repartition(1).write.csv(error_path, 
                                   mode = 'overwrite', 
                                   header = 'true')
  print('Error records written to {}'\
    .format(error_path))
except:
  print('There was a problem writing error records to {}'\
    .format(error_path))

