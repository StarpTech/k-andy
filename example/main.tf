variable "hcloud_token" {}

module "demo_cluster" {
  source = "./.."
  # Can also point to a git repository, e.g. git::https://github.com/StarpTech/k-andy.git?ref=main
  hcloud_token     = var.hcloud_token
  name             = "demo"
  server_locations = ["nbg1", "fsn1"]
}

output "control_plane_ips" {
  value = module.demo_cluster.control_planes_public_ips
}

output "k3s_token" {
  value     = module.demo_cluster.k3s_token
  sensitive = true
}
