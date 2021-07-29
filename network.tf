resource "hcloud_network" "k3s" {
  name     = "${var.name}-k3s-network"
  ip_range = var.network_cidr
  labels   = local.common_labels
}

resource "hcloud_network_subnet" "k3s_nodes" {
  type         = "cloud"
  network_id   = hcloud_network.k3s.id
  network_zone = "eu-central"
  ip_range     = var.subnet_cidr
}

locals {
  first_control_plane_ip = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 1)
}