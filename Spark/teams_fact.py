
import logging
import sys
from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType, IntegerType

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
spark = SparkSession.builder.appName("teams_fact_etl").getOrCreate()

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

str_to_int = ['games', 'attendance']
for s in str_to_int:
 	home_games = home_games.withColumn(s, \
 	  home_games[s].cast(IntegerType()))

# Group home games data (parkID can change):
home_games_grp = home_games.groupby(['team_key', 'year_key']).sum('games', 'attendance')
home_games_grp = home_games_grp.toDF(*['team_key', 'year_key', 'home_games', 'home_attendance'])

# join home_games_grp to teams:
result = teams.join(home_games_grp, (teams.teamID == home_games_grp.team_key) 
	& (teams.yearID == home_games_grp.year_key), 'left_outer')\
.select(*['teamID', 'yearID', 'franchID', 'lgID', 'LgWin', 'W',
          'L', 'ERA', 'home_games', 'home_attendance'])

# convert W and L columns from str to ints:
str_to_int = ['W', 'L']
for s in str_to_int:
    result = result.withColumn(s, \
 	  result[s].cast(IntegerType()))

# convert ERA column from str to numeric:
str_to_numeric = ['ERA']
for s in str_to_numeric:
    result = result.withColumn(s, \
      result[s].cast(DoubleType()))

# Remove and log nulls in business key columns:
nulls_check = ['teamID', 'yearID']
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