resource "null_resource" "provision" {
  count = "${var.instance_count}"

  connection {
    timeout = "10m"
    user = "ubuntu"
    host = "${aws_instance.instance.*.public_ip[count.index]}"
    private_key = "${file(var.aws_ssh_private_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -u root bash -c 'echo \"${aws_instance.instance.*.availability_zone[count.index]}\" > /etc/aws_availability_zone'",
      "sudo -u root bash -c 'echo \"${aws_instance.instance.*.public_dns[count.index]}\" > /etc/aws_public_dns'",
      "sudo -u root bash -c 'echo \"${aws_instance.instance.*.private_dns[count.index]}\" > /etc/aws_private_dns'"
    ]
  }

  provisioner "local-exec" {
    working_dir = "../ansible"
    command = <<EOT
      ansible-playbook \
      -u ubuntu \
      --become \
      -i '${aws_instance.instance.*.public_ip[count.index]},' \
      --private-key ${var.aws_ssh_private_key} \
      --ssh-common-args="-o StrictHostKeyChecking=no -o IdentitiesOnly=yes" \
      tasks/provision.yml
    EOT
  }
}
