output "ids" {
  value = "${aws_instance.server.*.id}"
}

output "ids_count" {
  value = "${var.server_count}"
}

output "arn" {
  value = "${aws_instance.server.*.arn}"
}

output "availability_zone" {
  value = "${aws_instance.server.*.availability_zone}"
}

output "placement_group" {
  value = "${aws_instance.server.*.placement_group}"
}

output "key_name" {
  value = "${aws_instance.server.*.key_name}"
}

output "password_data" {
  value = "${aws_instance.server.*.password_data}"
}

output "public_dns" {
  value = "${aws_instance.server.*.public_dns}"
}

output "public_ip" {
  value = "${aws_instance.server.*.public_ip}"
}

output "ipv6_addresses" {
  value = "${aws_instance.server.*.ipv6_addresses}"
}

output "network_interface_id" {
  value = "${aws_instance.server.*.network_interface_id}"
}

output "primary_network_interface_id" {
  value = "${aws_instance.server.*.primary_network_interface_id}"
}

output "private_dns" {
  value = "${aws_instance.server.*.private_dns}"
}

output "private_ip" {
  value = "${aws_instance.server.*.private_ip}"
}

output "security_groups" {
  value = "${aws_instance.server.*.security_groups}"
}

output "vpc_security_group_ids" {
  value = "${aws_instance.server.*.vpc_security_group_ids}"
}

output "subnet_id" {
  value = "${aws_instance.server.*.subnet_id}"
}
