variable "aws_ssh_private_key" {
  default = ""
}

variable "aws_zone" {
  default = ""
}

variable "aws_zones" {
  type = "map"
}

variable "environment" {
  default = ""
}

variable "environment_index" {
  type = "map"
}

variable "instance_count" {
  default = 0
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_pair_id" {
  default = ""
}

variable "region" {
  default = ""
}

variable "security_group_ids" {
  type = "list"
}

variable "volume_size" {
  default = 8
}

variable "vpc_id" {
  default = ""
}
