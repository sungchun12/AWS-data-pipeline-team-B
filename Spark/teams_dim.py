
import argparse
from datetime import datetime
import logging
from pyspark.sql import SparkSession
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import col, udf, monotonically_increasing_id, row_number, max
from pyspark.sql.window import Window

logger = logging.getLogger(__name__)

# Parse runtime variables:
parser = argparse.ArgumentParser()

parser.add_argument("--teams-data-path", 
                    help="S3 path to Players data file.")
parser.add_argument("--home-games-data-path", 
                    help="S3 path to FieldingPost data file.")
parser.add_argument("--output-path",
                    help="S3 path for results from this script")
parser.add_argument("--error-path",
                    help="S3 path for problem records")

args = parser.parse_args()

if args.teams_data_path:
    teams_data_path = args.teams_data_path
if args.home_games_data_path:
    home_games_data_path = args.home_games_data_path
if args.output_path:
    output_path = args.output_path
if args.error_path:
    error_path = args.error_path

# start Spark session:
spark = SparkSession.builder.appName("TeamsDimApp").getOrCreate()

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

# Reformat date columns in home_games:
str_to_date = ['span_first', 'span_last']
strpfunc = udf(lambda x: datetime.strptime(x, "%Y-%m-%d"))
newfunc = udf(lambda x: '{0}/{1}/{2}'.format(x.month, x.day, x.year))
for s in str_to_date:
    home_games = home_games.withColumn(s, \
      newfunc(strpfunc(col(s))))

# join home_games to teams:
teams_dim = teams.join(home_games,\
       (teams.teamID == home_games.team_key) & \
       (teams.yearID == home_games.year_key),\
       'left_outer')\
      .select(*['teamID', 'yearID', 'franchID', 'lgID', 'park_key',
          'name', 'park', 'span_first', 'span_last'])

# Remove and log nulls in business key columns:
nulls_check = ['teamID', 'yearID', 'park_key']
for nc in nulls_check:
    null_issue = teams_dim.where(teams_dim[nc].isNull())
    if null_issue.count() > 0:
        null_issue.write.csv(error_path, mode='overwrite', header=True)
    teams_dim = teams_dim.where(teams_dim[nc].isNull() == False)


teams_dim = teams_dim.withColumn("team_key", \
                             monotonically_increasing_id())
windowSpec = Window.orderBy("team_key")
teams_dim.withColumn("team_key", \
                   row_number().over(windowSpec))\
                   .sort(col("team_key").desc())

# write result to csv:
try:
    teams_dim.write.csv(output_path, mode = 'overwrite', header=True)
    print('resulting file written successfully to {}'.format(output_path))
except:
    print('There was a problem writing results to {}'.format(output_path))