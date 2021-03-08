locals {
  server_location           = "nbg1"
  control_plane_server_type = "cx11"
  agent_server_type         = "cpx11"
  first_control_plane_ip    = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 2)
}
