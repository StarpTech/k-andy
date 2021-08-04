resource "hcloud_server" "agent" {
  for_each = { for i in range(0, var.server_count) : "#${i}" => i }
  name     = "${var.cluster_name}-${var.group_name}-${each.value}-${local.agent_pet_names[each.value]}"

  image       = data.hcloud_image.ubuntu.name
  server_type = var.server_type
  location    = element(var.server_locations, each.value)

  ssh_keys = [var.provisioning_ssh_key_id]
  labels = merge({
    node_type = "worker"
  }, var.common_labels)

  # Join cluster as agent after first boot
  # Adding the random pet name as comment is a trick to recreate the server on pet-name change
  user_data = format("%s\n#%s\n%s", "#cloud-config", local.agent_pet_names[each.value], yamlencode(
    {
      runcmd = [
        "curl -sfL https://get.k3s.io | K3S_URL='https://${var.control_plane_ip}:6443' INSTALL_K3S_VERSION='${var.k3s_version}' K3S_TOKEN='${var.k3s_cluster_secret}' sh -s - agent --kubelet-arg='cloud-provider=external'"
      ]
      packages = var.additional_packages
    }
  ))

  network {
    network_id = var.network_id
    ip         = cidrhost(var.subnet_ip_range, var.ip_offset + each.value)
  }

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s-agent.service; do sleep 1; done"
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = var.ssh_private_key
    }
  }
}

resource "hcloud_server_network" "agent" {
  for_each  = { for i in range(0, var.server_count) : "#${i}" => i }
  subnet_id = var.subnet_id
  server_id = hcloud_server.agent[each.key].id
  ip        = cidrhost(var.subnet_ip_range, var.ip_offset + each.value) // start at x.y.z.OFFSET
}
