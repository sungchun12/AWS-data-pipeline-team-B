resource "aws_security_group" "ima-flexb-analytics" {
  name = "ima-flexb-analytics"

  tags {
    Name     = "ima-flexb-analytics"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  description = "INBOUND Connection settings"
  vpc_id      = "${aws_vpc.ima-flexb-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # For connecting to Redshift - set up instance to forward
  # connections here to the Redshift cluster
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "TCP"
    cidr_blocks = ["12.106.136.114/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ima-flexb-database" {
  name = "ima-flexb-database"

  tags {
    Name     = "ima-flexb-database"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  description = "Inbound Connection settings"
  vpc_id      = "${aws_vpc.ima-flexb-vpc.id}"

  ingress {
    from_port = 5439
    to_port   = 5439
    protocol  = "TCP"

    # allow tcp access from analytics security group:
    security_groups = ["${aws_security_group.ima-flexb-analytics.id}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
