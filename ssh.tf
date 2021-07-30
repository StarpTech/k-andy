resource "tls_private_key" "ssh" {
  count     = var.ssh_private_key_location == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "local_file" "custom_ssh_private_key" {
  count    = var.ssh_private_key_location == null ? 0 : 1
  filename = var.ssh_private_key_location
}

data "tls_public_key" "custom_ssh" {
  count           = var.ssh_private_key_location == null ? 0 : 1
  private_key_pem = data.local_file.custom_ssh_private_key[0].content
}

locals {
  ssh_private_key = var.ssh_private_key_location != null ? data.local_file.custom_ssh_private_key[0].content : tls_private_key.ssh[0].private_key_pem
  ssh_public_key  = var.ssh_private_key_location != null ? data.tls_public_key.custom_ssh[0].public_key_openssh : tls_private_key.ssh[0].public_key_openssh
}