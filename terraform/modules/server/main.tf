variable "server_region" {}
variable "server_access_key" {}
variable "server_secret_key" {}
variable "server_count" {}
variable "server_key_path" {}

provider "aws" {
  region = "${var.server_region}"
  access_key = "${var.server_access_key}"
  secret_key = "${var.server_secret_key}"
}

data "aws_ami" "ubuntu" {
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

resource "aws_key_pair" "key_pair" {
  key_name = "server"
  public_key = "${file(var.server_key_path)}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH traffic"
  //  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "server" {
  count = "${var.server_count}"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.key_pair.id}"
  security_groups = ["default", "allow_ssh"]
  root_block_device = {
    volume_size = 8
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["private_ip", "vpc_security_group_ids", "root_block_device"]
  }

  depends_on = ["aws_key_pair.key_pair"]
}

resource "null_resource" "server-provision" {
  count = "${var.server_count}"

  connection {
    timeout = "10m"
    user = "ubuntu"
    host = "${aws_instance.server.*.public_dns[count.index]}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -u root bash -c 'echo \"${aws_instance.server.*.availability_zone[count.index]}\" > /run/aws_availability_zone'",
      "sudo -u root bash -c 'echo \"${aws_instance.server.*.public_dns[count.index]}\" > /run/aws_public_dns'",
      "sudo -u root bash -c 'echo \"${aws_instance.server.*.private_dns[count.index]}\" > /run/aws_private_dns'"
    ]
  }
}

output "id" {
  value = "${aws_instance.server.*.id}"
}

output "arn" {
  value = "${aws_instance.server.*.arn}"
}

output "availability_zone" {
  value = "${aws_instance.server.*.availability_zone}"
}

output "placement_group" {
  value = "${aws_instance.server.*.placement_group}"
}

output "key_name" {
  value = "${aws_instance.server.*.key_name}"
}

output "password_data" {
  value = "${aws_instance.server.*.password_data}"
}

output "public_dns" {
  value = "${aws_instance.server.*.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.server.*.public_ip}"
}

output "ipv6_addresses" {
  value = "${aws_instance.server.*.ipv6_addresses}"
}

output "network_interface_id" {
  value = "${aws_instance.server.*.network_interface_id}"
}

output "primary_network_interface_id" {
  value = "${aws_instance.server.*.primary_network_interface_id}"
}

output "private_dns" {
  value = "${aws_instance.server.*.private_dns}"
}

output "private_ip" {
  value = "${aws_instance.server.*.private_ip}"
}

output "security_groups" {
  value = "${aws_instance.server.*.security_groups}"
}

output "vpc_security_group_ids" {
  value = "${aws_instance.server.*.vpc_security_group_ids}"
}

output "subnet_id" {
  value = "${aws_instance.server.*.subnet_id}"
}
