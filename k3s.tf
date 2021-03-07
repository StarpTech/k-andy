locals {
  server_location           = "nbg1"
  control_plane_server_type = "cx11"
  agent_server_type         = "cx21"
  first_control_plane_ip    = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2)
}

resource "hcloud_server" "first_control_plane" {
  name = "k3s-control-plane-0"

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
  # Update packages after first boot
  package_update: true
  # Install additional packages
  packages:
    - open-iscsi # required for longhorn storage provider
  # Initialize cluster after first boot
  # Manifest at this location will automatically be deployed to K3s in a manner similar to kubectl apply
  write_files:
  - content: ${filebase64("./hello-kubernetes.yaml")}
    path: /var/lib/rancher/k3s/server/manifests/hello-kubernetes.yaml
    encoding: b64
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_key} INSTALL_K3S_EXEC="--cluster-init" sh -
  EOT

  network {
    ip         = local.first_control_plane_ip
    network_id = hcloud_network.k3s.id
  }

  # **Note**: the depends_on is important when directly attaching the
  # server to a network. Otherwise Terraform will attempt to create
  # server and sub-network in parallel. This may result in the server
  # creation failing randomly.
  depends_on = [
    hcloud_network_subnet.k3s_nodes
  ]
}

resource "hcloud_server" "control_plane" {
  count = var.servers_num - 1
  name  = "k3s-control-plane-${count.index + 1}"

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
  # Update packages after first boot
  package_update: true
  # Install additional packages
  packages:
    - open-iscsi # required for longhorn storage provider
  # Initialize cluster after first boot
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN=${var.k3s_key} INSTALL_K3S_EXEC="--server https://${local.first_control_plane_ip}:6443" sh -
  EOT

  network {
    ip         = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3 + count.index)
    network_id = hcloud_network.k3s.id
  }

  depends_on = [
    hcloud_server.first_control_plane
  ]
}

resource "hcloud_server" "agent" {
  count = var.agents_num
  name  = "k3s-agent-${count.index}"

  image       = data.hcloud_image.ubuntu.name
  server_type = local.agent_server_type
  location    = local.server_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "worker"
  }

  user_data = <<-EOT
  #cloud-config
  # Update packages after first boot
  package_update: true
  # Install additional packages
  packages:
    - open-iscsi # required for longhorn storage provider
  # Add worker after first boot
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_URL="https://${local.first_control_plane_ip}:6443" K3S_TOKEN=${var.k3s_key} sh -
  EOT

  network {
    ip         = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2 + var.servers_num + count.index)
    network_id = hcloud_network.k3s.id
  }


  depends_on = [
    # Control plane server must be created before the worker node can be attached
    hcloud_server.first_control_plane
  ]
}
