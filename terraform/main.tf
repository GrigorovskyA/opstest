module "server-eu-central-1" {
  source = "./modules/server"

  server_count = 2
  server_region = "eu-central-1"
  server_access_key = "${var.aws_access_key}"
  server_secret_key = "${var.aws_secret_key}"
  server_key_path = "${var.key_path}"
  server_environment = "staging"
}
