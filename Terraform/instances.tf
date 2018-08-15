resource "aws_eip" "analytics-eip" {
  instance = "${aws_instance.analytics-bastion.id}"
  vpc      = true
}

resource "aws_instance" "analytics-bastion" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.public-az1-sn.id}"
  vpc_security_group_ids      = ["${aws_security_group.ima-flexb-analytics.id}"]
  key_name                    = "${var.key_name}"

  tags {
    Name     = "analytics-bastion"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  # Runs shell script upon startup:
  user_data = <<HEREDOC
  #!/bin/bash
  yum update -y
  yum install postgresql -y && yum install haproxy -y
  service haproxy start

HEREDOC
}

/*
Below for MySQL setup:
resource "aws_instance" "database" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "false"
  subnet_id                   = "${aws_subnet.private-az1-sn.id}"
  vpc_security_group_ids      = ["${aws_security_group.ima-flexb-database.id}"]
  key_name                    = "${var.key_name}"

  tags {
    Name     = "database"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  user_data = <<HEREDOC
  #!/bin/bash
  yum update -y
  yum install -y mysql55-server
  service mysqld start
HEREDOC
}*/


# The comment lines below were previously in the set of SQL commands above. 
# There is a problem with the syntax used to create the database and insert records.
# Steps to get this to work (done as root user):


# 1) Log into MySQL instance manually via SSH
# 2) Stop the server: `service mysqld stop`
# 3) Restart in safe mode: `sudo mysqld_safe --skip-grant-tables --skip-networking &`
# 4) Reconnect: `mysql -u root`
# 5) Clear existing privileges: `FLUSH PRIVILEGES;`
# 6) Update root user's password (5.7.15 and older): 
# `SET PASSWORD FOR 'root'@'localhost' = PASSWORD('new_password');`  
# 7) Stop as in 2), then restart normally: `service mysql start`
# 8) Start a MySQL session as root: `mysql -u root -p`
# 9) Add the test database: `CREATE DATABASE test;`
# 10) Add data as shown in the CREATE TABLE / INSERT steps below.
# 11) Check in a browser at: 
# <Public IP of front-end instance>/calldb.php to 
# confirm data exists and there is connectivity between machines


#/usr/bin/mysqladmin -u root -password 'secret'
#mysql -u root -p secret -e "create user 'root'@'%' identified by 'secret';" mysql
#mysql -u root -p secret -e 'CREATE TABLE mytable (mycol varchar(255));' test
#mysql -u root -p secret -e "INSERT INTO mytable (mycol) values ('linuxacademythebest') ;" test

