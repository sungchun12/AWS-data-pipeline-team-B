resource "aws_instance" "analytics" {
  ami                         = "${lookup(var.AmiLinux, var.region)}"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = "${aws_subnet.public-az1-sn.id}"
  vpc_security_group_ids      = ["${aws_security_group.ima-flexb-analytics.id}"]
  key_name                    = "${var.key_name}"

  tags {
    Name     = "analytics"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  # Runs shell script upon startup:
  user_data = <<HEREDOC
  #!/bin/bash
  yum update -y
  yum install -y httpd24 php56 php56-mysqlnd
  service httpd start
  chkconfig httpd on
  echo "<?php" >> /var/www/html/calldb.php
  echo "\$conn = new mysqli('mydatabase.ima-chi-flexb', 'root', 'secret', 'test');" >> /var/www/html/calldb.php
  echo "\$sql = 'SELECT * FROM mytable'; " >> /var/www/html/calldb.php
  echo "\$result = \$conn->query(\$sql); " >>  /var/www/html/calldb.php
  echo "while(\$row = \$result->fetch_assoc()) { echo 'the value is: ' . \$row['mycol'] ;} " >> /var/www/html/calldb.php
  echo "\$conn->close(); " >> /var/www/html/calldb.php
  echo "?>" >> /var/www/html/calldb.php
HEREDOC
}

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
  /usr/bin/mysqladmin -u root password 'secret'
  mysql -u root -psecret -e "create user 'root'@'%' identified by 'secret';" mysql
  mysql -u root -psecret -e 'CREATE TABLE mytable (mycol varchar(255));' test
  mysql -u root -psecret -e "INSERT INTO mytable (mycol) values ('linuxacademythebest') ;" test
HEREDOC
}
