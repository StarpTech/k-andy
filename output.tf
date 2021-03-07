output "controlplane_public_ip" {
  value       = hcloud_server.first_control_plane.ipv4_address
  description = "The public IP address of the first controlplane server instance."
}

output "agent_public_ip" {
  value       = hcloud_server.agent[0].ipv4_address
  description = "The public IP address of the first agent server instance."
}