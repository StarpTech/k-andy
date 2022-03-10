variable "hcloud_token" {}

module "demo_cluster" {
  source = "./.."
  # Can also point to a git repository, e.g. git::https://github.com/StarpTech/k-andy.git?ref=main
  hcloud_token     = var.hcloud_token
  name             = "k-andy-demo"
  k3s_version      = "v1.21.10+k3s1"
  server_locations = ["nbg1", "fsn1"]
  agent_groups = {
    "storage" = {
      count     = 2
      type      = "cpx31"
      ip_offset = 13
      taints = [
        "component=storage:NoSchedule"
      ]
    }
    "small" = {
      count     = 2
      type      = "cx21"
      ip_offset = 24
      taints    = []
    }
    "medium" = {
      count     = 1
      type      = "cx31"
      ip_offset = 32
      taints    = []
    }
  }
}

output "control_plane_ips" {
  value = module.demo_cluster.control_planes_public_ips
}

output "k3s_token" {
  value     = module.demo_cluster.k3s_token
  sensitive = true
}
