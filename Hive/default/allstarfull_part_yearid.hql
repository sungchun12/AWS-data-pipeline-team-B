CREATE EXTERNAL TABLE IF NOT EXISTS allstarfull (
   
   playerID STRING,
   gameNum INT,
   gameID STRING,
   teamID STRING,
   lgID  STRING,
   GP INT,
   startingPos SMALLINT

)
COMMENT 'All star game records'
PARTITIONED BY (yearID STRING)
STORED AS SEQUENCEFILE
;
