module "server-eu-central-1" {
  source = "./modules/server"
  server_access_key = "${var.aws_access_key}"
  server_count = 2
  server_environment = "staging"
  server_key_path_priv = "${var.aws_ssh_private_key}"
  server_key_path_pub = "${var.aws_ssh_public_key}"
  server_region = "eu-central-1"
  server_secret_key = "${var.aws_secret_key}"
}

module "lb-eu-central-1" {
  source = "./modules/lb"
  lb_access_key = "${var.aws_access_key}"
  lb_environment = "staging"
  lb_instance_ids = "${module.server-eu-central-1.ids}"
  lb_instance_ids_count = "${module.server-eu-central-1.ids_count}"
  lb_region = "eu-central-1"
  lb_secret_key = "${var.aws_secret_key}"
  lb_target_port = 8080
}
