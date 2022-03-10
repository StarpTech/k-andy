resource "hcloud_network" "k3s" {
  count    = var.network_id == null ? 1 : 0
  name     = "${var.name}-k3s-network"
  ip_range = var.network_cidr
  labels   = local.common_labels
}

data "hcloud_network" "k3s" {
  count = var.network_id == null ? 0 : 1
  id    = var.network_id
}

locals {
  network_id               = var.network_id == null ? hcloud_network.k3s[0].id : var.network_id
  network_name             = var.network_id == null ? hcloud_network.k3s[0].name : data.hcloud_network.k3s[0].name
  primary_control_plane_ip = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, var.control_plane_primary_index)
}

resource "hcloud_network_subnet" "k3s_nodes" {
  type         = "cloud"
  network_id   = local.network_id
  network_zone = "eu-central"
  ip_range     = var.subnet_cidr
}
