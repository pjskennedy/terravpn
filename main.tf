locals {
  public_key_filename  = "${path.root}/keys/id_rsa.pub"
  private_key_filename = "${path.root}/keys/id_rsa"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "ca_vars" {
  template = "${file("${path.root}/files/vars.tpl")}"
  vars {
    cert_key_country = "${var.cert_key_country}"
    cert_key_province = "${var.cert_key_province}"
    cert_key_city = "${var.cert_key_city}"
    cert_key_org = "${var.cert_key_org}"
    cert_key_email = "${var.cert_key_email}"
    cert_key_ou = "${var.cert_key_ou}"
  }
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated" {
  key_name   = "pjsk-vpn-${uuid()}"
  public_key = "${tls_private_key.generated.public_key_openssh}"

  lifecycle {
    ignore_changes = ["key_name"]
  }
}

resource "aws_security_group" "vpn_security_group" {
  name = "vpn-security-group"

  # Inbound VPN
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "local_file" "public_key_openssh" {
  content  = "${tls_private_key.generated.public_key_openssh}"
  filename = "${local.public_key_filename}"
}

resource "local_file" "private_key_pem" {
  content  = "${tls_private_key.generated.private_key_pem}"
  filename = "${local.private_key_filename}"
}

resource "null_resource" "chmod" {
  depends_on = ["local_file.private_key_pem"]

  triggers {
    key = "${tls_private_key.generated.private_key_pem}"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_filename}"
  }
}

resource "aws_instance" "vpn" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_size}"
  vpc_security_group_ids = ["${aws_security_group.vpn_security_group.id}"]

  key_name = "${aws_key_pair.generated.key_name}"

  tags {
    Name = "vpn"
  }

  connection {
    user        = "ubuntu"
    private_key = "${tls_private_key.generated.private_key_pem}"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y openvpn easy-rsa",
      "mkdir -p ~/terraform/files"
    ]
  }

  provisioner "file" {
    content = "${data.template_file.ca_vars.rendered}"
    destination = "~/terraform/files/vars"
  }

  provisioner "file" {
    source = "files/before.rules"
    destination = "~/terraform/files/before.rules"
  }

  provisioner "file" {
    source = "files/make_config.sh"
    destination = "~/terraform/files/make_config.sh"
  }

  provisioner "file" {
    source = "files/server.conf"
    destination = "~/terraform/files/server.conf"
  }

  provisioner "file" {
    source = "files/sysctl.conf"
    destination = "~/terraform/files/sysctl.conf"
  }

  provisioner "file" {
    source = "files/ufw"
    destination = "~/terraform/files/ufw"
  }

  provisioner "file" {
    source = "files/client.conf.tpl"
    destination = "~/terraform/files/client.conf.tpl"
  }

  provisioner "remote-exec" {
    inline = [
      "make-cadir ~/openvpn-ca",
      "cp ~/terraform/files/vars ~/openvpn-ca/vars",
      "cd ~/openvpn-ca",
      ". ./vars",
      "./clean-all",
      "./pkitool --initca server",
      "./pkitool --server server",
      "./pkitool client1",
      "./build-dh",
      "openvpn --genkey --secret keys/ta.key",
      "cd ~/openvpn-ca/keys",
      "sudo cp ca.crt server.crt server.key ta.key dh2048.pem /etc/openvpn",
      "sudo cp ~/terraform/files/server.conf /etc/openvpn/server.conf",
      "sudo cp ~/terraform/files/sysctl.conf /etc/sysctl.conf",
      "sudo cp ~/terraform/files/before.rules /etc/ufw/before.rules",
      "sudo cp ~/terraform/files/ufw /etc/default/ufw",
      "sudo sysctl -p /etc/sysctl.conf",
      "sudo ufw allow 1194/udp",
      "sudo ufw allow OpenSSH",
      "sudo ufw disable",
      "sudo ufw --force enable",
      "sudo systemctl enable openvpn@server",
      "mkdir -p ~/client-configs/files",
      "chmod 700 ~/client-configs/files",
      "sudo cp ~/terraform/files/client.conf.tpl ~/client-configs/base.conf",
      "sed -i -e 's/SELF_PUBLIC_IP/${self.public_ip}/g' ~/client-configs/base.conf",
      "sudo cp ~/terraform/files/make_config.sh ~/client-configs/make_config.sh",
      "sudo chmod 700 ~/client-configs/make_config.sh",
      "cd ~/client-configs",
      "sudo ./make_config.sh client1",
      "sudo reboot"
    ]
  }
}
