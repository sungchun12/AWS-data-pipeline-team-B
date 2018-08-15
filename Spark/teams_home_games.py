
teams = spark.read.format("csv").option("header", "true").load("/data/Teams/Teams.csv")
teams.cache() # for faster operations
new_names = [nm.replace('.', '_') for nm in teams.schema.names]
teams = teams.toDF(*new_names)

home_games = spark.read.format("csv").option("header", "true").load("/data/HomeGames/HomeGames.csv")
home_games.cache()
new_names = [nm.replace('.', '_') for nm in home_games.schema.names]
home_games = home_games.toDF(*new_names)

# sorted count of home_games records by team, year, and park to check for dupes:
home_games.groupby(['team_key', 'year_key', 'park_key']).count().orderBy('count', ascending=False).show()

# soart count of teams records by team and year to check for dupes:
teams.groupby(['teamID', 'yearID']).count().orderBy('count', ascending=False).show()

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
result.write.csv('/data/aggregates/teams_agg.csv',header=True)
#result.toPandas().to_csv('/data/aggregates/teams_agg.csv', index=False)
