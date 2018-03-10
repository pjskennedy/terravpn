
output "public_ip" {
  value = "${aws_instance.vpn.public_ip}"
}

output "ssh_command" {
  description = "Command to use to immediately SSH into the instance. This is pre-configured with the temporary SSH key created."
  value = "ssh -i ${local.private_key_filename} ubuntu@${aws_instance.vpn.public_ip}"
}

output "config_download_command" {
  description = "Command to Download VPN client config."
  value = "scp -i ${local.private_key_filename} ubuntu@${aws_instance.vpn.public_ip}:~/client-configs/files/client1.ovpn client1.ovpn"
}