# IAM instance profile to give EMR instances access to S3
resource "aws_iam_instance_profile" "ima-flexb-instance-profile" {
  name = "ima-flexb-instance-profile"
  role = "${data.aws_iam_role.ima-flexb-emr-role.name}"
}

# Look up IAM role for Flexb-emr
data aws_iam_role "ima-flexb-emr-role" {
  name = "ima-flexb-emr-role"
}

data aws_iam_role "ima-flexb-emr-service-role" {
  name = "ima-flexb-emr-service-role"
}

resource "aws_emr_cluster" "ima-flexb-emr-cluster" {
  name          = "ima-flexb-emr-cluster"
  release_label = "emr-5.15.0"
  applications  = ["Spark", "Hive", "Hue", "JupyterHub"]
  log_uri       = "s3://ima-flexb-emr-logs/"

  additional_info = <<EOF
{
  "instanceAwsClientConfiguration": {
    "proxyPort": 8099,
    "proxyHost": "myproxy.example.com"
  }
}
EOF

  configurations                    = "emr-configurations.json"
  termination_protection            = false
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_id                         = "${aws_subnet.public-az1-sn.id}"
    emr_managed_master_security_group = "${aws_security_group.ima-flexb-emr-master-sg.id}"
    emr_managed_slave_security_group  = "${aws_security_group.ima-flexb-emr-worker-sg.id}"
    instance_profile                  = "${aws_iam_instance_profile.ima-flexb-instance-profile.arn}"

    key_name = "${var.key_name}"
  }

  master_instance_type = "m4.large"
  core_instance_type   = "m4.large"
  core_instance_count  = 1

  tags {
    role     = "rolename"
    env      = "env"
    Name     = "ima-flexb-emr-cluster"
    Owner    = "${var.tags["Owner"]}"
    Email    = "${var.tags["Email"]}"
    Location = "${var.tags["Location"]}"
  }

  #bootstrap_action {
  #  path = "s3://elasticmapreduce/bootstrap-actions/run-if"
  #  name = "runif"
  #  args = ["instance.isMaster=true", "echo running on master node"]
  #}

  service_role = "${data.aws_iam_role.ima-flexb-emr-service-role.arn}"
}

