terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.27"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.13"
    }
    remote = {
      source  = "tenstad/remote"
      version = "~> 0.0.23"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.hcloud_token
}
