variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_key_path_pub" {
  default = "~/.ssh/id_rsa.pub"
}

variable "aws_key_path_priv" {
  default = "~/.ssh/id_rsa"
}
