
import argparse
import logging
from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType, IntegerType
from pyspark.sql.functions import col, udf, monotonically_increasing_id, row_number, max
from pyspark.sql.window import Window

logger = logging.getLogger(__name__)

# Parse runtime variables:
parser = argparse.ArgumentParser()

parser.add_argument("--teams-dim-path",
	                help="Path to processed teams dim file.")
parser.add_argument("--teams-data-path",
                    help="S3 path to Teams data file.")
parser.add_argument("--home-games-data-path",
                    help="S3 path to HomeGames data file.")
parser.add_argument("--output-path",
                    help="S3 path for results from this script")
parser.add_argument("--error-path",
                    help="S3 path for problem records")

args = parser.parse_args()

if args.teams_dim_path:
	teams_dim_path = args.teams_dim_path
if args.teams_data_path:
    teams_data_path = args.teams_data_path
if args.home_games_data_path:
    home_games_data_path = args.home_games_data_path
if args.output_path:
    output_path = args.output_path
if args.error_path:
    error_path = args.error_path

# start Spark session:
spark = SparkSession.builder.appName("teams_fact_etl").getOrCreate()

# read teams dim data:
teams_dim = spark.read.format("csv").option("header", "true")\
  .load(teams_dim_path)
teams_dim.cache()

# read / format Teams.csv file:
teams = spark.read.format("csv").option("header", "true")\
  .load(teams_data_path)
teams.cache() # for faster operations
new_names = [nm.replace('.', '_') for nm in teams.schema.names]
teams = teams.toDF(*new_names)

# read / format HomeGames.csv file:
home_games = spark.read.format("csv").option("header", "true")\
  .load(home_games_data_path)
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
teams_fact = teams.join(home_games_grp, 
	(teams.teamID == home_games_grp.team_key) & \
	(teams.yearID == home_games_grp.year_key), 'left_outer')

teams_dim = teams_dim.select(*(col(x).alias(x + '_dim') for x in teams_dim.columns))
teams_fact = teams_fact.join(teams_dim,
	 (teams_fact.teamID == teams_dim.teamID_dim) & \
     (teams_fact.yearID == teams_dim.yearID_dim), \
     'left')\
     .select(*['team_key_dim', 'teamID', 'yearID', 'franchID', 'lgID', 
     	  'LgWin', 'W', 'L', 'ERA', 'home_games', 'home_attendance'])

#create field name remapping:
mapping = dict({'team_key_dim'  :'team_key'})

#iterate through all columns in player fact table with mapping above
teams_fact = teams_fact.select([col(c)\
    .alias(mapping.get(c, c)) for c in teams_fact.columns])

# convert W and L columns from str to ints:
str_to_int = ['W', 'L']
for s in str_to_int:
    teams_fact = teams_fact.withColumn(s, \
 	  teams_fact[s].cast(IntegerType()))

# convert ERA column from str to numeric:
str_to_numeric = ['ERA']
for s in str_to_numeric:
    teams_fact = teams_fact.withColumn(s, \
      teams_fact[s].cast(DoubleType()))

# Remove and log nulls in business key columns:
nulls_check = ['teamID', 'yearID', 'team_key']
for nc in nulls_check:
	null_issue = teams_fact.where(teams_fact[nc].isNull())
	if null_issue.count() > 0:
		null_issue.write.csv(error_path, header=True)
	teams_fact = teams_fact.where(teams_fact[nc].isNull() == False)

# write teams_fact to csv:
try:
	teams_fact.write.csv(output_path, mode = 'overwrite', header=True)
	print('resulting file written successfully to {}'.format(output_path))
except:
	print('There was a problem writing results to {}'.format(output_path))

spark.stop()