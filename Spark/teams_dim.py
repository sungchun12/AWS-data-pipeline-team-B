
from datetime import datetime
import logging
import sys
from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import col, udf

logger = logging.getLogger(__name__)

# Parse runtime variables:
try:
	teams_s3_path = sys.argv[1]
	home_games_s3_path = sys.argv[2]
	result_s3_path = sys.argv[3]
	error_s3_path = sys.argv[4]
except IndexError as err:
	logger.error(err)
	raise

# start Spark session:
spark = SparkSession.builder.appName("teams_dim_etl").getOrCreate()

# read / format Teams.csv file:
teams = spark.read.format("csv").option("header", "true")\
.load(teams_s3_path)
teams.cache() # for faster operations
new_names = [nm.replace('.', '_') for nm in teams.schema.names]
teams = teams.toDF(*new_names)

# read / format HomeGames.csv file:
home_games = spark.read.format("csv").option("header", "true")\
 .load(home_games_s3_path)

home_games.cache()
new_names = [nm.replace('.', '_') for nm in home_games.schema.names]
home_games = home_games.toDF(*new_names)

# Reformat date columns in home_games:
str_to_date = ['span_first', 'span_last']
strpfunc = udf(lambda x: datetime.strptime(x, "%Y-%m-%d"))
newfunc = udf(lambda x: '{0}/{1}/{2}'.format(x.month, x.day, x.year))
for s in str_to_date:
	home_games = home_games.withColumn(s, \
	  newfunc(strpfunc(col(s))))

# join home_games to teams:
result = teams.join(home_games, (teams.teamID == home_games.team_key) 
	& (teams.yearID == home_games.year_key), 'left_outer')\
.select(*['teamID', 'yearID', 'franchID', 'lgID', 'park_key',
          'name', 'park', 'span_first', 'span_last'])

# Remove and log nulls in business key columns:
nulls_check = ['teamID', 'yearID', 'park_key']
for nc in nulls_check:
	null_issue = result.where(result[nc].isNull())
	if null_issue.count() > 0:
		null_issue.write.csv(error_s3_path, header=True)
	result = result.where(result[nc].isNull() == False)

# write result to csv:
try:
	result.write.csv(result_s3_path, header=True)
	print('resulting file written successfully to {}'.format(result_s3_path))
except:
	print('There was a problem writing results to {}'.format(result_s3_path))

spark.stop()