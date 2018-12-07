module "image" {
  source = "./modules/image"
  region = "${var.region}"
}

module "network" {
  source = "./modules/network"
  region = "${var.region}"
  proxy_port = "${var.proxy_port}"
  lb_port = "${var.lb_port}"
  aws_ssh_public_key = "${var.aws_ssh_public_key}"
}

locals {
  instance_security_group_ids = [
    "${module.network.security_groups["default"]}",
    "${module.network.security_groups["ssh"]}",
    "${module.network.security_groups["http_proxy"]}",
    "${module.network.security_groups["outbound_traffic"]}"
  ]

  lb_security_group_ids = [
    "${module.network.security_groups["default"]}",
    "${module.network.security_groups["http"]}",
  ]
}

module "us-east-1a" {
  source = "./modules/instance"
  region = "${var.region}"

  aws_zone = "us-east-1a"
  instance_count = 1

  aws_zones = "${var.aws_zones}"
  environment = "${var.environment}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
  aws_ssh_private_key = "${var.aws_ssh_private_key}"
  environment_index = "${var.environment_index}"
}

module "us-east-1c" {
  source = "./modules/instance"
  region = "${var.region}"

  aws_zone = "us-east-1c"
  instance_count = 2

  aws_zones = "${var.aws_zones}"
  environment = "${var.environment}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
  aws_ssh_private_key = "${var.aws_ssh_private_key}"
  environment_index = "${var.environment_index}"
}

module "us-east-1e" {
  source = "./modules/instance"
  region = "${var.region}"

  aws_zone = "us-east-1e"
  instance_count = 1

  aws_zones = "${var.aws_zones}"
  environment = "${var.environment}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
  aws_ssh_private_key = "${var.aws_ssh_private_key}"
  environment_index = "${var.environment_index}"
}

module "lb" {
  source = "./modules/lb"
  region = "${var.region}"

  proxy_port = "${var.proxy_port}"
  lb_port = "${var.lb_port}"
  security_group_ids = "${local.lb_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
  subnet_ids = [
    "${module.us-east-1a.subnet_id}",
    "${module.us-east-1c.subnet_id}",
    "${module.us-east-1e.subnet_id}"
  ]
  instance_ids = "${concat(
    module.us-east-1a.ids,
    module.us-east-1c.ids,
    module.us-east-1e.ids
  )}"
  instance_count = "${
    module.us-east-1a.instance_count +
    module.us-east-1c.instance_count +
    module.us-east-1e.instance_count
  }"
}
