variable "environment" {
  default = "staging"
}

variable "region" {
  default = "us-east-1"
}

variable "proxy_port" {
  default = 8080
}

variable "lb_port" {
  default = 80
}

variable "aws_ssh_public_key" {
  default = ""
}

variable "aws_ssh_private_key" {
  default = ""
}

variable "aws_zones" {
  type = "map"
  default = {
    us-east-1 = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
    us-east-2 = ["us-east-2a", "us-east-2b", "us-east-2c"]
    us-west-1 = ["us-west-1b", "us-west-1c"]
    us-west-2 = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
}

variable "environment_index" {
  type = "map"
  default = {
    dev = 1,
    development = 1
    staging = 2
    stage = 2
    test = 3
    prod = 4
    production = 4
  }
}
