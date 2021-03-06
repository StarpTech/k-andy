locals {
  server_location = "nbg1"
  control_plane_server_type = "cpx11"
  agent_server_type = "cx31"
}

resource "hcloud_server" "control_plane" {
  name = "k3s-control-plane-1"

  image       = data.hcloud_image.ubuntu.name
  server_type = local.control_plane_server_type
  location    = local.server_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "control-plane"
  }

  user_data = <<-EOT
  #cloud-config
  # fetch packages
  package_update: true
  # Install additional packages
  packages:
    - open-iscsi
  # Only run after first boot
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_key} INSTALL_K3S_EXEC="--cluster-init" sh -
  EOT
}

resource "hcloud_server_network" "control_plane" {
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.control_plane.id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2)
}

resource "hcloud_server" "agent" {
  name = "k3s-agent-1"

  image       = data.hcloud_image.ubuntu.name
  server_type = local.agent_server_type
  location    = local.server_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "worker"
  }

  depends_on = [hcloud_server.control_plane]

  user_data = <<-EOT
  #cloud-config
  # fetch packages
  package_update: true
  # Install additional packages
  packages:
    - open-iscsi
  # Only run after first boot
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_URL="https://${hcloud_server_network.control_plane.ip}:6443" K3S_TOKEN=${var.k3s_key} sh -
  EOT
}

resource "hcloud_server_network" "agent" {
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.agent.id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3)
}