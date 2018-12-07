provider "aws" {
  region = "${var.region}"
}

data "aws_ami" "image" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "id" {
  value = "${data.aws_ami.image.id}"
}
