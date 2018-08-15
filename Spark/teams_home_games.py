
import sys
import logging
from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType

logger = logging.getLogger(__name__)

# Parse runtime variables:
try:
	teams_s3_path = sys.argv[1]
	home_games_s3_path = sys.argv[2]
	result_s3_path = sys.argv[3]
except IndexError as err:
	logger.error(err)
	raise

# start Spark session:
spark = SparkSession.builder.appName("SimpleApp").getOrCreate()

# read / format Teams.csv file:
teams = spark.read.format("csv").option("header", "true").load(teams_s3_path)
teams.cache() # for faster operations
new_names = [nm.replace('.', '_') for nm in teams.schema.names]
teams = teams.toDF(*new_names)

# read / format HomeGames.csv file:
home_games = spark.read.format("csv").option("header", "true").load(home_games_s3_path)
home_games.cache()
new_names = [nm.replace('.', '_') for nm in home_games.schema.names]
home_games = home_games.toDF(*new_names)

# sorted count of home_games records by team, year, and park to check for dupes:
#home_games.groupby(['team_key', 'year_key', 'park_key']).count().orderBy('count', ascending=False).show()

# sort count of teams records by team and year to check for dupes:
#teams.groupby(['teamID', 'yearID']).count().orderBy('count', ascending=False).show()

# change games and attendance to numerics:
home_games = home_games.withColumn("games", home_games["games"].cast(DoubleType()))
home_games = home_games.withColumn("attendance", home_games["attendance"].cast(DoubleType()))

# aggregate home_games by team and year before joining to teams:
home_games_grp = home_games.groupby(['team_key', 'year_key']).sum('games', 'attendance')
home_games_grp = home_games_grp.toDF(*['team_key', 'year_key', 'games', 'home_attendance'])

# join home_games_grp to teams:
result = teams.join(home_games_grp, (teams.teamID == home_games_grp.team_key) 
	& (teams.yearID == home_games_grp.year_key), 'left_outer')\
.select(*[col for col in teams.columns] \
	+ [home_games_grp.games, home_games_grp.home_attendance])

# write result to csv:
try:
	result.write.csv(result_s3_path, header=True)
	print('resulting file written successfully to {}'.format(result_s3_path))
except:
	print('There was a problem writing results to {}'.format(result_s3_path))

spark.stop()

#result.toPandas().to_csv('/data/aggregates/teams_agg.csv', index=False)
