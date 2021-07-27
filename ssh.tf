resource "tls_private_key" "provision" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  filename        = "${var.name}_ssh_private"
  file_permission = "400"
  content         = tls_private_key.provision.private_key_pem
}