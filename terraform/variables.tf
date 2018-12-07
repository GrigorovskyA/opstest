variable "environment" {
  default = "staging"
}

// See main.tf for how many instances would be created in every AZ
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
