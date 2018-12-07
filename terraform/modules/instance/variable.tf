variable "region" {
  default = ""
}

variable "aws_zone" {
  default = ""
}

variable "instance_count" {
  default = 0
}

variable "vpc_id" {
  default = ""
}

variable "security_group_ids" {
  type = "list"
}

variable "aws_zones" {
  type = "map"
}

variable "environment" {
  default = ""
}

variable "volume_size" {
  default = 8
}

variable "key_pair_id" {
  default = ""
}

variable "aws_ssh_private_key" {
  default = ""
}

variable "instance_type" {
  default = "t2.micro"
}

variable "environment_index" {
  type = "map"
}
