output "control_planes_public_ips" {
  value       = concat([hcloud_server.first_control_plane.ipv4_address], hcloud_server.control_plane[*].ipv4_address)
  description = "The public IP addresses of the control plane servers"
}

output "agents_public_ips" {
  value       = hcloud_server.agent[*].ipv4_address
  description = "The public IP addresses of the agent servers"
}

output "k3s_token" {
  description = "Secret k3s authentication token"
  value       = random_password.k3s_cluster_secret.result
  sensitive   = true
}