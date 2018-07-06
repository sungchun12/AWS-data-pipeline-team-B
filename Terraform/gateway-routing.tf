# Declare the data source
data "aws_availability_zones" "available" {}

/* EXTERNAL NETWORG , IG, ROUTE TABLE */
resource "aws_internet_gateway" "ima-flexb-gw" {
  vpc_id = "${aws_vpc.ima-flexb-vpc.id}"

  tags {
    Name     = "ima-flexb-gw"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}

resource "aws_network_acl" "ima-flexb-acl" {
  vpc_id = "${aws_vpc.ima-flexb-vpc.id}"

  egress {
    protocol   = "-1"
    rule_no    = 2
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 1
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name     = "ima-flexb-acl"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}

resource "aws_route_table" "ima-flexb-rt-pub" {
  vpc_id = "${aws_vpc.ima-flexb-vpc.id}"

  tags {
    Name     = "ima-flexb-rt-pub"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ima-flexb-gw.id}"
  }
}

resource "aws_route_table" "ima-flexb-rt-pri" {
  vpc_id = "${aws_vpc.ima-flexb-vpc.id}"

  tags {
    Name     = "ima-flexb-rt-pri"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  route {
    cidr_block = "0.0.0.0/0"

    # connects the private subnet to the public one:
    nat_gateway_id = "${aws_nat_gateway.public-az1-ngw.id}"
  }
}

resource "aws_eip" "forNat" {
  vpc = true
}

resource "aws_nat_gateway" "public-az1-ngw" {
  allocation_id = "${aws_eip.forNat.id}"
  subnet_id     = "${aws_subnet.public-az1-sn.id}"
  depends_on    = ["aws_internet_gateway.ima-flexb-gw"]

  tags {
    Name     = "public-az1-ngw"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }
}
