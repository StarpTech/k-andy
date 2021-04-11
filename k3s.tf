locals {
  control_plane_server_type = "cx11"
  agent_server_type         = "cx21"
  first_control_plane_ip    = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2)
  locations                 = [var.server_location, "fsn1", "hel1"]
  agent_locations           = setproduct(range(var.agents_num), local.locations)
  server_locations          = setproduct(range(var.servers_num), local.locations)
}
