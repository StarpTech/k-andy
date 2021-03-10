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
  # Initialize cluster after first boot
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_cluster_secret.result}" INSTALL_K3S_VERSION="${var.k3s_version}" sh -s - server --server https://${local.first_control_plane_ip}:6443 --disable local-storage --disable-cloud-controller --disable traefik --disable servicelb --kubelet-arg="cloud-provider=external"
  EOT

  network {
    ip         = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3 + count.index)
    network_id = hcloud_network.k3s.id
  }

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      "kubectl taint node ${self.name} node-role.kubernetes.io/master=true:NoSchedule",
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key)
    }
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
