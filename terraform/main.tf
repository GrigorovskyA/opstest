module "server-eu-central-1" {
  source = "./modules/server"
  server_count = 2
  server_region = "eu-central-1"
  server_access_key = "${var.aws_access_key}"
  server_secret_key = "${var.aws_secret_key}"
  server_key_path_pub = "${var.aws_key_path_pub}"
  server_key_path_priv = "${var.aws_key_path_priv}"
  server_environment = "staging"
}

module "lb-eu-central-1" {
  source = "./modules/lb"
  lb_region = "eu-central-1"
  lb_access_key = "${var.aws_access_key}"
  lb_secret_key = "${var.aws_secret_key}"
  lb_environment = "staging"
  lb_target_port = 8080
  lb_instance_ids = "${module.server-eu-central-1.id}"
}
