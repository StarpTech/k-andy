resource "random_password" "k3s_cluster_secret" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "provision_public" {
  name       = "${var.name} - provisioning SSH key"
  public_key = tls_private_key.provision.public_key_openssh
  labels     = local.common_labels
}

data "hcloud_image" "ubuntu" {
  name = "ubuntu-20.04"
}