data "template_file" "ccm_manifest" {
  template = file("${path.module}/manifests/hcloud-ccm-net.yaml")
}

data "template_file" "csi_manifest" {
  template = file("${path.module}/manifests/hcloud-csi.yaml")
}