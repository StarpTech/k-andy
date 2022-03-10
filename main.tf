resource "random_password" "k3s_cluster_secret" {
  length  = 48
  special = false
}

resource "hcloud_ssh_key" "provision_public" {
  name       = "${var.name} - provisioning SSH key"
  public_key = local.ssh_public_key
  labels     = local.common_labels
}

data "hcloud_image" "ubuntu" {
  name = "ubuntu-20.04"
}

locals {
  server_base_packages = ["wireguard"]
  cluster_dns_ip       = cidrhost(var.service_cidr, 10)
  k3s_setup_args       = "--cluster-cidr ${var.cluster_cidr} --service-cidr ${var.service_cidr} --cluster-dns ${local.cluster_dns_ip} --disable local-storage --disable-cloud-controller --disable traefik --disable servicelb --flannel-backend=wireguard --kubelet-arg='cloud-provider=external'"
  k3s_server_join_cmd  = "sh -s - server --server 'https://${local.primary_control_plane_ip}:6443' ${local.k3s_setup_args}"
  k3s_server_init_cmd  = "sh -s - server --cluster-init ${local.k3s_setup_args}"
}
