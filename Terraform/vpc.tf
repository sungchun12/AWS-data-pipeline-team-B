provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "ima-flexb-vpc" {
  cidr_block = "${var.vpc-fullcidr}"

  #### this 2 true values are for use the internal vpc dns resolution
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name     = "ima-flexb-vpc"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}
