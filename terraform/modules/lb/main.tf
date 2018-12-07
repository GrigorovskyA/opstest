provider "aws" {
  region = "${var.region}"
}

resource "aws_lb" "lb" {
  internal = false
  load_balancer_type = "application"
  security_groups = ["${var.security_group_ids}"]
  subnets = ["${var.subnet_ids}"]
}

resource "aws_lb_target_group" "target" {
  port = "${var.proxy_port}"
  protocol = "HTTP"
  vpc_id = "${var.vpc_id}"
  target_type = "instance"

  health_check {
    path = "/ping"
    port = "${var.proxy_port}"
    timeout = 5
    interval = 10
  }
}

resource "aws_lb_target_group_attachment" "attachment" {
  // Known bug here
  // count = "${length(var.instance_ids)}"
  count = "${var.instance_count}"
  port = "${var.proxy_port}"
  target_group_arn = "${aws_lb_target_group.target.arn}"
  target_id = "${var.instance_ids[count.index]}"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port = "${var.lb_port}"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.target.arn}"
  }
}
