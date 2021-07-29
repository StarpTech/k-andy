resource "random_pet" "agent_suffix" {
  count = var.agent_server_count
}

locals {
  agent_pet_names = [for pet in random_pet.agent_suffix : pet.id]
}

resource "hcloud_server" "agent" {
  for_each = { for i in range(0, var.agent_server_count) : i => local.agent_pet_names[i] }
  name     = "${var.name}-agent-${each.value}"

  image       = data.hcloud_image.ubuntu.name
  server_type = var.agent_server_type
  location    = element(var.server_locations, each.key)

  ssh_keys = [hcloud_ssh_key.provision_public.id]
  labels = merge({
    node_type = "worker"
  }, local.common_labels)

  # Join cluster as agent after first boot
  user_data = format("%s\n%s", "#cloud-config", yamlencode(
    {
      runcmd = [
        "curl -sfL https://get.k3s.io | K3S_URL='https://${local.first_control_plane_ip}:6443' INSTALL_K3S_VERSION='${var.k3s_version}' K3S_TOKEN='${random_password.k3s_cluster_secret.result}' sh -s - agent --kubelet-arg='cloud-provider=external'"
      ]
      packages = var.server_additional_packages
    }
  ))

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
      private_key = local.ssh_private_key
    }
  }
}

resource "hcloud_server_network" "agent" {
  for_each  = { for i in range(0, var.agent_server_count) : i => i }
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.agent[each.key].id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 33 + each.key) // start at x.y.z.33
}