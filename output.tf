output "control_planes_public_ips" {
  value       = concat([hcloud_server.first_control_plane.ipv4_address], hcloud_server.control_plane[*].ipv4_address)
  description = "The public IP addresses of the control plane servers"
}

output "agents_public_ips" {
  value       = hcloud_server.agent[*].ipv4_address
  description = "The public IP addresses of the agent servers"
}