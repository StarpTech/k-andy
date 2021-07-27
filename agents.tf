resource "hcloud_server" "agent" {
  count = var.agent_server_count
  name  = "${var.name}-agent-${count.index}"

  image       = data.hcloud_image.ubuntu.name
  server_type = var.agent_server_type
  location    = element(var.server_locations, count.index)

  ssh_keys = [hcloud_ssh_key.provision_public.id]
  labels = merge({
    node_type = "worker"
  }, local.common_labels)

  user_data = <<-EOT
  #cloud-config
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_URL="https://${local.first_control_plane_ip}:6443" INSTALL_K3S_VERSION="${var.k3s_version}" K3S_TOKEN=${random_password.k3s_cluster_secret.result} sh -s - agent --kubelet-arg="cloud-provider=external"
  EOT

  depends_on = [
    # Control plane server must be created before the worker node can be attached
    hcloud_server.first_control_plane
  ]

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s-agent.service; do sleep 1; done"
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.provision.private_key_pem
    }
  }
}

resource "hcloud_server_network" "agents_network" {
  count     = length(hcloud_server.agent)
  server_id = hcloud_server.agent[count.index].id
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2 + var.control_plane_server_count + count.index)
}
