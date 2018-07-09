variable "region" {
  default = "ca-central-1"
}

variable "AmiLinux" {
  type = "map"

  default = {
    us-east-1    = "ami-b73b63a0"
    us-west-2    = "ami-5ec1673e"
    ca-central-1 = "ami-03e86a67"
    
  }

  description = "maps basic AMI with Python / Java etc. installed by region"
}

#variable "aws_access_key" {
#  default     = ""
#  description = "the user aws access key"
#}

#variable "aws_secret_key" {
#  default     = ""
#  description = "the user aws secret key"
#}

variable "vpc-fullcidr" {
  default     = "10.0.0.0/16"
  description = "CIDR address block for the VPC"
}

variable "subnet-public-az1-cidr" {
  default     = "10.0.1.0/24"
  description = "the cidr of the subnet"
}

variable "subnet-private-az1-cidr" {
  default     = "10.0.2.0/24"
  description = "the cidr of the subnet"
}

variable "key_name" {
  default     = "mw-vpc-test"
  description = "the ssh key to use in the EC2 machines"
}

variable "DnsZoneName" {
  default     = "ima-chi-flexb"
  description = "the internal dns name"
}

variable "tags" {
  type = "map"

  default = {
    Owner    = "Matt Winkler"
    Email    = "matt.winkler@slalom.com"
    Location = "Chicago"
  }
}

# declare redshift variables:
variable redshift_master_username {}

variable redshift_master_password {}

variable redshift_logs_prefix {
  default = "log/"
}
