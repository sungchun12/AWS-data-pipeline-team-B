set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.dynamic.partition=true;

INSERT OVERWRITE TABLE allstarfull PARTITION (yearID)
SELECT      playerID, gameNum, gameID, teamID, lgID, 
            GP, startingpos, t.yearID
FROM allstarfull_stg t;

