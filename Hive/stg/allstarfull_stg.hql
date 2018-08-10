DROP TABLE IF EXISTS allstarfull_stg;

CREATE EXTERNAL TABLE IF NOT EXISTS allstarfull_stg (

   playerID STRING,
   yearID STRING,
   gameNum INT,
   gameID STRING,
   teamID STRING,
   lgID  STRING,
   GP INT,
   startingPos SMALLINT
)

ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
LOCATION 's3a://ima-flexb-sor/data/AllstarFull'
TBLPROPERTIES ("skip.header.line.count"="1")
;
