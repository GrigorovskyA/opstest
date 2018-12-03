provider "aws" {
  region = "${var.lb_region}"
  access_key = "${var.lb_access_key}"
  secret_key = "${var.lb_secret_key}"
}

data "aws_security_group" "default" {
  name = "default"
}

data "aws_vpcs" "aws_vpcs" {}

//FIXME: What if we have several VPC?
data "aws_subnet_ids" "subnets" {
  vpc_id = "${data.aws_vpcs.aws_vpcs.ids[0]}"
}

resource "aws_security_group" "allow_http" {
  name = "allow_http"
  description = "Allow HTTP traffic"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "lb" {
  internal = false
  load_balancer_type = "application"
  security_groups = [
    "${data.aws_security_group.default.id}",
    "${aws_security_group.allow_http.id}"
  ]
  subnets = ["${data.aws_subnet_ids.subnets.ids}"]

  tags {
    Environment = "${var.lb_environment}"
  }
}

//FIXME: What if we have several VPC?
resource "aws_lb_target_group" "lb-target-group" {
  port = "${var.lb_target_port}"
  protocol = "HTTP"
  vpc_id = "${data.aws_vpcs.aws_vpcs.ids[0]}"

  health_check {
    path = "/ping"
    port = "${var.lb_target_port}"
    timeout = 5
    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "lb-target-group-attachment" {
  count = "${var.lb_instance_ids_count}"
  port = "${var.lb_target_port}"
  target_group_arn = "${aws_lb_target_group.lb-target-group.arn}"
  target_id = "${element(var.lb_instance_ids, count.index)}"
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.lb-target-group.arn}"
  }
}
