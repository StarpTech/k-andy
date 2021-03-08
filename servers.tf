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
    - curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_cluster_secret.result} INSTALL_K3S_EXEC="--cluster-init" sh -
  EOT
}

resource "hcloud_server_network" "first_control_plane" {
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.first_control_plane.id
  ip        = local.first_control_plane_ip
}

resource "hcloud_server" "control_planes" {
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
    - curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_cluster_secret.result} INSTALL_K3S_EXEC="--server https://${local.first_control_plane_ip}:6443" sh -
  EOT

  network {
    ip         = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3 + count.index)
    network_id = hcloud_network.k3s.id
  }

  depends_on = [
    hcloud_server.first_control_plane
  ]
}

resource "hcloud_server_network" "control_planes" {
  count     = var.servers_num - 1
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.control_planes[count.index].id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3 + count.index)
}
