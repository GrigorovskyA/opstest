variable "region" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "proxy_port" {
  default = 8080
}

variable "lb_port" {
  default = 80
}

variable "security_group_ids" {
  type = "list"
}

variable "subnet_ids" {
  type = "list"
}

variable "instance_ids" {
  type = "list"
}

variable "instance_count" {
  default = 0
}
