resource "hcloud_server" "control_plane" {
  count = var.control_plane_server_count - 1
  name  = "${var.name}-control-plane-${count.index + 1}"

  image       = data.hcloud_image.ubuntu.name
  server_type = var.control_plane_server_type
  location    = element(var.server_locations, count.index + 1)

  ssh_keys = [hcloud_ssh_key.provision_public.id]
  labels = merge({
    node_type = "control-plane"
  }, local.common_labels)

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
      # Disable workloads on master node
      "kubectl taint node ${self.name} node-role.kubernetes.io/master=true:NoSchedule",
      "kubectl taint node ${self.name} CriticalAddonsOnly=true:NoExecute",
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.provision.private_key_pem
    }
  }

  depends_on = [
    hcloud_server.first_control_plane
  ]
}

resource "hcloud_server_network" "control_planes" {
  for_each  = { for server in hcloud_server.control_plane : server.name => server }
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = each.value.id
}