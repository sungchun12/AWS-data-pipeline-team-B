
import sys
import logging
from pyspark.sql import SparkSession #import spark functionality for spark sql
from pyspark.sql.types import DoubleType, IntegerType, StringType, BooleanType, ArrayType #import data types
from pyspark.sql import DataFrame #used for sql functionality on dataframes
from pyspark.sql.functions import monotonically_increasing_id, col, row_number, max #used to create incremental ids
import pyspark.sql.functions as F #import all functions
from pyspark.sql.window import Window
logger = logging.getLogger(__name__) #import script logging information

# these variables will be used for command line paths passed through for input/output files
# Parse runtime variables:
try:
    college_playing_s3_path = sys.argv[1]
    college_playing_output_path= sys.argv[6]

except IndexError as err:
    logger.error(err)
    raise

# start Spark session:
spark = SparkSession.builder.appName("SimpleApp").getOrCreate()

#load all tables
college = spark.read.format("csv").option("header", "true")\
  .load(college_playing_s3_path)
college.cache() # for faster operations


#convert column names to replace periods with underscores if they exist
new_names = [nm.replace('.', '_') for nm in college.schema.names]
college = college.toDF(*new_names)

#convert data types to match data model
college = college.withColumn("yearID", college["yearID"].cast(IntegerType()))
college = college.withColumn("playerID", college["playerID"].cast('varchar(30)'))
college = college.withColumn("schoolID", college["schoolID"].cast('varchar(30)'))

college_null=college.where(college['yearID'].isNull() | college['playerId'].isNull() | college['schoolID'].isNull() )
college=college.where(college['yearID'].isNotNull() | college['playerId'].isNotNull() | college['schoolID'].isNotNull() )

try:
	college.repartition(1).write.csv(college_playing_output_path, mode = 'overwrite', header = 'true')
	print('resulting file written successfully to {}'.format(college_playing_output_path))
except:
	print('There was a problem writing results to {}'.format(college_playing_output_path))
