terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
    }
    remotefile = {
      source  = "mabunixda/remotefile"
      version = "0.1.1"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.hcloud_token
}
