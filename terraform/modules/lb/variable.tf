variable "instance_count" {
  default = 0
}
variable "instance_ids" {
  type = "list"
}

variable "lb_port" {
  default = 80
}

variable "proxy_port" {
  default = 8080
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

variable "vpc_id" {
  default = ""
}
