resource "aws_s3_bucket" "ima-flexb-dw-logs" {
  bucket = "ima-flexb-dw-logs"
  region = "${var.region}"

  #acl = "public"

  tags = {
    Name     = "ima-flexb-dw-logs"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}
