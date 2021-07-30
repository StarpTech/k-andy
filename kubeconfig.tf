data "remotefile" "kubeconfig" {
  conn {
    host        = hcloud_server.first_control_plane.ipv4_address
    port        = 22
    username    = "root"
    private_key = local.ssh_private_key
  }
  path = "/etc/rancher/k3s/k3s.yaml"
}

locals {
  kubeconfig_external = replace(data.remotefile.kubeconfig.content, "127.0.0.1", hcloud_server.first_control_plane.ipv4_address)
}

resource "local_file" "kubeconfig" {
  count             = var.create_kubeconfig ? 1 : 0
  sensitive_content = local.kubeconfig_external
  filename          = "./kubeconfig-${var.name}.yaml"
  file_permission   = "400"
}

output "kubeconfig" {
  value       = local.kubeconfig_external
  description = "Kubeconfig with external IP address"
  sensitive   = true
}
