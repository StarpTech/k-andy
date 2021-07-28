variable "hcloud_token" {}

module "demo_cluster" {
  source = "./.."
  # Can also point to a git repository, e.g. git::https://github.com/toabi/k-andy.git?ref=feature/modularize
  hcloud_token     = var.hcloud_token
  name             = "demo"
  server_locations = ["nbg1", "fsn1"]
}
