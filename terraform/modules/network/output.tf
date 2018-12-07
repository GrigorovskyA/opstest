output "vpc_id" {
  value = "${aws_vpc.network.id}"
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

output "key_pair_id" {
  value = "${aws_key_pair.key_pair.id}"
}
