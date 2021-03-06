output "controlplane_public_ip" {
  value       = hcloud_server.control_plane.ipv4_address
  description = "The public IP address of the controlplane server instance."
}

output "agent_public_ip" {
  value       = hcloud_server.agent.ipv4_address
  description = "The public IP address of the agent server instance."
}