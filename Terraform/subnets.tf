resource "aws_subnet" "public-az1-sn" {
  vpc_id     = "${aws_vpc.ima-flexb-vpc.id}"
  cidr_block = "${var.subnet-public-az1-cidr}"

  tags {
    Name     = "public-az1-sn"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_route_table_association" "public-az1" {
  subnet_id      = "${aws_subnet.public-az1-sn.id}"
  route_table_id = "${aws_route_table.ima-flexb-rt-pub.id}"
}

resource "aws_subnet" "private-az1-sn" {
  vpc_id     = "${aws_vpc.ima-flexb-vpc.id}"
  cidr_block = "${var.subnet-private-az1-cidr}"

  tags {
    Name     = "private-az1-sn"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_route_table_association" "private-az1" {
  subnet_id      = "${aws_subnet.private-az1-sn.id}"
  route_table_id = "${aws_route_table.ima-flexb-rt-pri.id}"
}
