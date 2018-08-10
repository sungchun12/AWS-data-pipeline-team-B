variable "region" {
  default = "ca-central-1"
}

variable "AmiLinux" {
  type = "map"

  default = {
    us-east-1    = "ami-cfe4b2b0"
    us-west-1    = "ami-0e86606d"
    us-west-2    = "ami-0ad99772"
    ca-central-1 = "ami-03e86a67"
  }

  description = "AMI to enable PowerBI connection to Redshift"
}

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

variable data_directory {
  default = "../data/core"
}

variable file_format {
  default = ".csv"
}

variable "inputfiles" {
  type = "map"

  default = {
    allstarfull         = "AllstarFull"
    appearances         = "Appearances"
    awardsmanagers      = "AwardsManagers"
    awardsplayers       = "AwardsPlayers"
    awardssharemanagers = "AwardsShareManagers"
    awardsshareplayers  = "AwardsSharePlayers"
    batting             = "Batting"
    battingpost         = "BattingPost"
    collegeplaying      = "CollegePlaying"
    fielding            = "Fielding"
    fieldingof          = "FieldingOF"
    fieldingofsplit     = "FieldingOFsplit"
    fieldingpost        = "FieldingPost"
    halloffame          = "HallOfFame"
    homegames           = "HomeGames"
    managers            = "Managers"
    managershalf        = "ManagersHalf"
    parks               = "Parks"
    people              = "People"
    pitching            = "Pitching"
    pitchingpost        = "PitchingPost"
    salaries            = "Salaries"
    schools             = "Schools"
    seriespost          = "SeriesPost"
    teams               = "Teams"
    teamsfranchises     = "TeamsFranchises"
    teamshalf           = "TeamsHalf"
  }
}
