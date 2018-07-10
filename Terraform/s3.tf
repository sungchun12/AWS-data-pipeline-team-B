resource "aws_s3_bucket" "ima-flexb-dw-logs" {
  bucket = "ima-flexb-dw-logs"
  region = "${var.region}"
  acl    = "log-delivery-write"

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
}
