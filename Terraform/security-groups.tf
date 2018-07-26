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
    cidr_blocks = ["12.106.136.114/32"]
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
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    security_groups = ["${aws_security_group.ima-flexb-analytics.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EMR Master
resource "aws_security_group" "ima-flexb-emr-master-sg" {
  name        = "ima-flexb-emr-master-sg"
  description = "EMR master security group"

  tags {
    Name     = "ima-flexb-emr-master-sg"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  vpc_id = "${aws_vpc.ima-flexb-vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["12.106.136.114/32"]
  }

  ingress {
    from_port   = 8433
    to_port     = 8433
    protocol    = "TCP"
    cidr_blocks = ["52.94.86.0/23"]
  }

  # outbound:
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EMR Core security group:
resource "aws_security_group" "ima-flexb-emr-worker-sg" {
  name        = "ima-flexb-emr-worker-sg"
  description = "emr workers"

  tags {
    Name     = "ima-flexb-emr-worker-sg"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  vpc_id = "${aws_vpc.ima-flexb-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "emr-workers-tcp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ima-flexb-emr-worker-sg.id}"
  source_security_group_id = "${aws_security_group.ima-flexb-emr-master-sg.id}"
}

resource "aws_security_group_rule" "emr-master-tcp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ima-flexb-emr-master-sg.id}"
  source_security_group_id = "${aws_security_group.ima-flexb-emr-worker-sg.id}"
}

resource "aws_security_group_rule" "emr-workers-udp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.ima-flexb-emr-worker-sg.id}"
  source_security_group_id = "${aws_security_group.ima-flexb-emr-master-sg.id}"
}

resource "aws_security_group_rule" "emr-master-udp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  security_group_id        = "${aws_security_group.ima-flexb-emr-master-sg.id}"
  source_security_group_id = "${aws_security_group.ima-flexb-emr-worker-sg.id}"
}
