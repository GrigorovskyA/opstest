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

locals {
  region_by_zone = "${transpose(var.aws_zones)}"
  az_symbol = "${replace(var.aws_zone, element(local.region_by_zone[var.aws_zone], 0), "")}"
  az_number = "${local.az_letters[local.az_symbol]}"
}

resource "aws_subnet" "subnet" {
  availability_zone = "${var.aws_zone}"
  cidr_block = "10.${lookup(var.environment_index, var.environment, 0)}.${local.az_number}.0/24"
  map_public_ip_on_launch = true
  vpc_id = "${var.vpc_id}"
}

resource "aws_instance" "instance" {
  count = "${var.instance_count}"
  ami = "${data.aws_ami.image.id}"
  associate_public_ip_address = true
  availability_zone = "${var.aws_zone}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_pair_id}"
  subnet_id = "${aws_subnet.subnet.id}"
  vpc_security_group_ids = ["${var.security_group_ids}"]

  root_block_device = {
    volume_size = "${var.volume_size}"
  }

  tags {
    environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["private_ip", "vpc_security_group_ids", "root_block_device"]
  }
}
