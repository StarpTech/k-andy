data "http" "hcloud_csi_driver_manifest" {
  url = "https://raw.githubusercontent.com/hetznercloud/csi-driver/${var.hcloud_csi_driver_version}/deploy/kubernetes/hcloud-csi.yml"
}

