locals {
  region = "us-east-1"
  proxy_port = 8080
  lb_port = 80
  environment = "staging"
}

module "image" {
  source = "./modules/image"
  region = "${local.region}"
}

module "network" {
  source = "./modules/network"
  region = "${local.region}"
  proxy_port = "${local.proxy_port}"
  lb_port = "${lb_port}"
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
  region = "${local.region}"

  aws_zone = "us-east-1a"
  instance_count = 1

  aws_zones = "${var.aws_zones}"
  environment = "${local.environment}"
  image_id = "${module.image.id}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.instance_security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
}

module "us-east-1c" {
  source = "./modules/instance"
  region = "${local.region}"

  aws_zone = "us-east-1c"
  instance_count = 2

  aws_zones = "${var.aws_zones}"
  environment = "${local.environment}"
  image_id = "${module.image.id}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
}

module "us-east-1e" {
  source = "./modules/instance"
  region = "${local.region}"

  aws_zone = "us-east-1e"
  instance_count = 1

  aws_zones = "${var.aws_zones}"
  environment = "${local.environment}"
  image_id = "${module.image.id}"
  key_pair_id = "${module.network.key_pair_id}"
  security_group_ids = "${local.security_group_ids}"
  vpc_id = "${module.network.vpc_id}"
}

module "lb" {
  source = "./modules/lb"
  region = "${local.region}"

  security_group_ids = "${local.lb_security_group_ids}"
  subnet_ids = [
    "${module.us-east-1a.subnet_id}",
    "${module.us-east-1c.subnet_id}",
    "${module.us-east-1e.subnet_id}"
  ]
}
