
CREATE TABLE all_star_full (

  playerID VARCHAR(50),
  yearID SMALLINT,
  gameNum SMALLINT,
  gameID VARCHAR(20),
  teamID VARCHAR(3),
  lgID CHAR(2),
  GP SMALLINT,
  startingPos SMALLINT
);


COPY all_star_full
FROM 's3://ima-flexb-sor/data/AllstarFull/AllstarFull.csv'
iam_role 'arn:aws:iam::<account number>:role/ima-flexb-dw' -- look this up in the AWS Console
DELIMITER ','
IGNOREHEADER 1
;

SELECT COUNT(*) FROM all_star_full;

--SELECT * FROM stl_load_errors;