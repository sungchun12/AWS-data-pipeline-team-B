# for landing data:
resource "aws_s3_bucket" "ima-flexb-sor" {
  bucket = "ima-flexb-sor"
  region = "${var.region}"
  acl    = "public-read"

  versioning {
    enabled = true
  }

  tags = {
    Name     = "ima-flexb-sor"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}

resource "aws_s3_bucket_object" "ima-flexb-sor-logs" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "logs/"
  source = "${var.data_directory}/null.csv"
}

resource "aws_s3_bucket_object" "ima-flexb-sor-output" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "output/"
  source = "${var.data_directory}/null.csv"
}

resource "aws_s3_bucket_object" "allstarfull" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["allstarfull"]}/${var.inputfiles["allstarfull"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["allstarfull"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "appearances" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["appearances"]}/${var.inputfiles["appearances"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["appearances"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "awardsmanagers" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["awardsmanagers"]}/${var.inputfiles["awardsmanagers"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["awardsmanagers"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "awardsplayers" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["awardsplayers"]}/${var.inputfiles["awardsplayers"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["awardsplayers"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "awardssharemanagers" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["awardssharemanagers"]}/${var.inputfiles["awardssharemanagers"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["awardssharemanagers"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "awardsshareplayers" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["awardsshareplayers"]}/${var.inputfiles["awardsshareplayers"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["awardsshareplayers"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "batting" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["batting"]}/${var.inputfiles["batting"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["batting"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "battingpost" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["battingpost"]}/${var.inputfiles["battingpost"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["battingpost"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "collegeplaying" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["collegeplaying"]}/${var.inputfiles["collegeplaying"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["collegeplaying"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "fielding" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["fielding"]}/${var.inputfiles["fielding"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["fielding"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "fieldingof" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["fieldingof"]}/${var.inputfiles["fieldingof"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["fieldingof"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "fieldingofsplit" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["fieldingofsplit"]}/${var.inputfiles["fieldingofsplit"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["fieldingofsplit"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "fieldingpost" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["fieldingpost"]}/${var.inputfiles["fieldingpost"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["fieldingpost"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "halloffame" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["halloffame"]}/${var.inputfiles["halloffame"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["halloffame"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "homegames" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["homegames"]}/${var.inputfiles["homegames"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["homegames"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "managers" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["managers"]}/${var.inputfiles["managers"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["managers"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "managershalf" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["managershalf"]}/${var.inputfiles["managershalf"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["managershalf"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "parks" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["parks"]}/${var.inputfiles["parks"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["parks"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "people" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["people"]}/${var.inputfiles["people"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["people"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "pitching" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["pitching"]}/${var.inputfiles["pitching"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["pitching"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "pitchingpost" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["pitchingpost"]}/${var.inputfiles["pitchingpost"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["pitchingpost"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "salaries" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["salaries"]}/${var.inputfiles["salaries"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["salaries"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "schools" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["schools"]}/${var.inputfiles["schools"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["schools"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "seriespost" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["seriespost"]}/${var.inputfiles["seriespost"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["seriespost"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "teams" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["teams"]}/${var.inputfiles["teams"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["teams"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "teamsfranchises" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["teamsfranchises"]}/${var.inputfiles["teamsfranchises"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["teamsfranchises"]}${var.file_format}"
}

resource "aws_s3_bucket_object" "teamshalf" {
  bucket = "${aws_s3_bucket.ima-flexb-sor.id}"
  acl    = "public-read"
  key    = "data/${var.inputfiles["teamshalf"]}/${var.inputfiles["teamshalf"]}${var.file_format}"
  source = "${var.data_directory}/${var.inputfiles["teamshalf"]}${var.file_format}"
}

# aggregated
resource "aws_s3_bucket" "ima-flexb-agg" {
  bucket = "ima-flexb-agg"
  region = "${var.region}"

  tags = {
    Name     = "ima-flexb-agg"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}

data "aws_redshift_service_account" "main" {}

# for redshift logs
resource "aws_s3_bucket" "ima-flexb-dw-logs" {
  bucket = "ima-flexb-dw-logs"
  region = "${var.region}"

  #acl    = "log-delivery-write"
  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"

    tags {
      "rule"      = "log"
      "autoclean" = "true"
    }

    expiration {
      days = 90
    }
  }

  tags = {
    Name     = "ima-flexb-dw-logs"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
                    "Sid": "Put bucket policy needed for audit logging",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "${data.aws_redshift_service_account.main.arn}"
                    },
                    "Action": "s3:PutObject",
                    "Resource": "arn:aws:s3:::ima-flexb-dw-logs/*"
                },
                {
                    "Sid": "Get bucket policy needed for audit logging ",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "${data.aws_redshift_service_account.main.arn}"
                    },
                    "Action": "s3:GetBucketAcl",
                    "Resource": "arn:aws:s3:::ima-flexb-dw-logs"
                }
    ]
}
EOF
}
