output "subnet_id" {
  value = "${aws_subnet.subnet.id}"
}

output "ids" {
  value = "${aws_instance.instance.*.id}"
}
