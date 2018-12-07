variable "vpc_id" {
  default = ""
}

variable "region" {
  default = ""
}

variable "security_group_ids" {
  type = "list"
}

variable "subnet_ids" {
  type = "list"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_lb" "lb" {
  internal = false
  load_balancer_type = "application"
  security_groups = ["${var.security_group_ids}"]
  subnets = ["${var.subnet_ids}"]
}
