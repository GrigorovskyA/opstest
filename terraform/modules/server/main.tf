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
  public_key = "${file(var.server_key_path_pub)}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH traffic"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_security_group" "default" {
  name = "default"
}

resource "aws_instance" "server" {
  count = "${var.server_count}"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.key_pair.id}"
  vpc_security_group_ids = [
    "${data.aws_security_group.default.id}",
    "${aws_security_group.allow_ssh.id}"
  ]
  root_block_device = {
    volume_size = 8
  }

  tags {
    Environment = "${var.server_environment}"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["private_ip", "vpc_security_group_ids", "root_block_device"]
  }
}

resource "null_resource" "server-provision" {
  count = "${var.server_count}"

  connection {
    timeout = "10m"
    user = "ubuntu"
    host = "${aws_instance.server.*.public_dns[count.index]}"
    private_key = "${file(var.server_key_path_priv)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -u root bash -c 'echo \"${aws_instance.server.*.availability_zone[count.index]}\" > /etc/aws_availability_zone'",
      "sudo -u root bash -c 'echo \"${aws_instance.server.*.public_dns[count.index]}\" > /etc/aws_public_dns'",
      "sudo -u root bash -c 'echo \"${aws_instance.server.*.private_dns[count.index]}\" > /etc/aws_private_dns'"
    ]
  }

  provisioner "local-exec" {
    working_dir = "../ansible"
    command = <<EOT
      ansible-playbook \
      -u ubuntu \
      --become \
      -i '${aws_instance.server.*.public_ip[count.index]},' \
      --private-key ${var.server_key_path_priv} \
      --ssh-common-args="-o StrictHostKeyChecking=no -o IdentitiesOnly=yes" \
      tasks/provision.yml
    EOT
  }
}
