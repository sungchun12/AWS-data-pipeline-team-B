data "aws_caller_identity" "current" {}

resource "aws_redshift_cluster" "ima-flexb-dw" {
  # basic config:
  cluster_identifier = "ima-flexb-dw"
  database_name      = "dw"
  master_username    = "${var.redshift_master_username}"
  master_password    = "${var.redshift_master_password}"
  node_type          = "dc2.large"
  cluster_type       = "single-node"

  # role configs:
  iam_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ima-flexb-dw"]

  # cluster networking:
  vpc_security_group_ids    = ["${aws_security_group.ima-flexb-database.id}"]
  cluster_subnet_group_name = "${aws_redshift_subnet_group.dw-sng.name}"
  publicly_accessible       = true

  # data security:
  encrypted = true

  # snapshot settings:
  skip_final_snapshot = true # TODO: set to false for real launch

  #snapshot_copy {
  #  destination_region = "us-east-1"
  #}

  # logging:
  logging {
    enable        = true
    bucket_name   = "${aws_s3_bucket.ima-flexb-dw-logs.bucket}"
    s3_key_prefix = "${var.redshift_logs_prefix}"
  }
  tags {
    Name     = "ima-flexb-dw"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}

# for redshift logs
data "aws_redshift_service_account" "main" {}

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
