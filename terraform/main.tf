module "us-east-1a" {
  source = "./modules/instance"
  region = "${var.region}"

  aws_zone = "us-east-1a"
  instance_count = 1

  aws_ssh_private_key = "${var.aws_ssh_private_key}"
  aws_zones = "${local.aws_zones}"
  environment = "${var.environment}"
  environment_index = "${local.environment_index}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
}

module "us-east-1c" {
  source = "./modules/instance"
  region = "${var.region}"

  aws_zone = "us-east-1c"
  instance_count = 2

  aws_ssh_private_key = "${var.aws_ssh_private_key}"
  aws_zones = "${local.aws_zones}"
  environment = "${var.environment}"
  environment_index = "${local.environment_index}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
}

module "us-east-1e" {
  source = "./modules/instance"
  region = "${var.region}"

  aws_zone = "us-east-1e"
  instance_count = 1

  aws_ssh_private_key = "${var.aws_ssh_private_key}"
  aws_zones = "${local.aws_zones}"
  environment = "${var.environment}"
  environment_index = "${local.environment_index}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
}

module "lb" {
  source = "./modules/lb"
  region = "${var.region}"

  lb_port = "${var.lb_port}"
  proxy_port = "${var.proxy_port}"
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
