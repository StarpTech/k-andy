terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.27"
    }
  }
  required_version = ">= 0.13"
}
