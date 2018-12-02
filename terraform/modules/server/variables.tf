variable "server_region" {
  default = ""
}

variable "server_access_key" {
  default = ""
}

variable "server_secret_key" {
  default = ""
}

variable "server_count" {
  default = 0
}

variable "server_key_path_pub" {
  default = "~/.ssh/id_rsa.pub"
}

variable "server_key_path_priv" {
  default = "~/.ssh/id_rsa"
}

variable "server_environment" {
  default = ""
}
