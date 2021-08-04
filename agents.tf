module "agents" {
  source = "./modules/agent_group"

  k3s_cluster_secret = random_password.k3s_cluster_secret.result
  k3s_version        = var.k3s_version

  name             = var.name
  server_locations = var.server_locations

  provisioning_ssh_key_id = hcloud_ssh_key.provision_public.id
  ssh_private_key         = local.ssh_private_key

  control_plane_ip = local.first_control_plane_ip
  network_id       = hcloud_network.k3s.id
  subnet_id        = hcloud_network_subnet.k3s_nodes.id
  subnet_ip_range  = hcloud_network_subnet.k3s_nodes.ip_range
  ip_offset        = 33

  server_count = var.agent_server_count
  server_type  = var.agent_server_type

  depends_on = [hcloud_server.first_control_plane]
}
