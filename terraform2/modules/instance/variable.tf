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

variable "image_id" {
  default = ""
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

variable "instance_type" {
  default = "t2.micro"
}

locals {
  az_letters = {
    "a" = 1
    "b" = 2
    "c" = 3
    "d" = 4
    "e" = 5
    "f" = 6
  }
}
