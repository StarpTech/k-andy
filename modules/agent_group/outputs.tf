output "public_ips" {
  value = [for server in hcloud_server.agent : server.ipv4_address]
}

output "agent_name_map" {
  value = local.agent_name_map
}
