resource "hcloud_server" "agents" {
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
    - curl -sfL https://get.k3s.io | K3S_URL="https://${local.first_control_plane_ip}:6443" K3S_TOKEN=${random_password.k3s_cluster_secret.result} sh -
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
      private_key = file(var.private_key)
    }
  }
}

resource "hcloud_server_network" "agents_network" {
  count     = length(hcloud_server.agents)
  server_id = hcloud_server.agents[count.index].id
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2 + var.servers_num + count.index)
}
