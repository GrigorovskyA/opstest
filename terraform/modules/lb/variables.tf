variable "lb_region" {
  default = ""
}

variable "lb_access_key" {
  default = ""
}

variable "lb_secret_key" {
  default = ""
}

variable "lb_environment" {
  default = ""
}

variable "lb_target_port" {
  default = 0
}

variable "lb_instance_ids" {
  type = "list"
}

variable "lb_instance_ids_count" {
  default = 0
}
