provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "network" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

output "vpc_id" {
  value = "${aws_vpc.network.id}"
}

resource "aws_internet_gateway" "network" {
  vpc_id = "${aws_vpc.network.id}"
}

resource "aws_route" "network" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.network.id}"
  route_table_id = "${aws_vpc.network.main_route_table_id}"
}

resource "aws_security_group" "ssh" {
  name = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id = "${aws_vpc.network.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "http" {
  name = "allow_http"
  description = "Allow HTTP traffic"
  vpc_id = "${aws_vpc.network.id}"

  ingress {
    from_port = "${var.lb_port}"
    to_port = "${var.lb_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "http_proxy" {
  name = "allow_http_proxy"
  description = "Allow HTTP proxy traffic"
  vpc_id = "${aws_vpc.network.id}"

  ingress {
    from_port = "${var.proxy_port}"
    to_port = "${var.proxy_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "outbound_traffic" {
  name = "allow_internet_access"
  description = "Allow access to internet"
  vpc_id = "${aws_vpc.network.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_security_group" "default" {
  name = "default"
  vpc_id = "${aws_vpc.network.id}"
}

output "security_groups" {
  value = {
    default = "${data.aws_security_group.default.id}"
    ssh = "${aws_security_group.ssh.id}"
    http = "${aws_security_group.http.id}"
    http_proxy = "${aws_security_group.http_proxy.id}"
    outbound_traffic = "${aws_security_group.outbound_traffic.id}"
  }
}

resource "aws_key_pair" "key_pair" {
  public_key = "${file(var.aws_ssh_public_key)}"
}

output "key_pair_id" {
  value = "${aws_key_pair.key_pair.id}"
}
