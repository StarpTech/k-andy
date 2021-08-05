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
  filename          = var.kubeconfig_filename == null ? "./kubeconfig-${var.name}.yaml" : var.kubeconfig_filename
  file_permission   = "400"
}

locals {
  kubeconfig_parsed = yamldecode(local.kubeconfig_external)
  kubeconfig_data = {
    host                   = local.kubeconfig_parsed["clusters"][0]["cluster"]["server"]
    client_certificate     = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-key-data"])
    cluster_ca_certificate = base64decode(local.kubeconfig_parsed["clusters"][0]["cluster"]["certificate-authority-data"])
  }
}

output "kubeconfig_file" {
  value       = local.kubeconfig_external
  description = "Kubeconfig file content with external IP address"
  sensitive   = true
}

output "kubeconfig" {
  description = "Structured kubeconfig data to supply to other providers"
  value       = local.kubeconfig_data
  sensitive   = true
}
