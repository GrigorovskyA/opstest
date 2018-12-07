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
