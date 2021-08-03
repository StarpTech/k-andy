terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.27"
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
