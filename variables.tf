# Hetzner Cloud

variable "hcloud_token" {
  description = "Token to authenticate against Hetzner Cloud"
}

# Cluster Configuration

variable "name" {
  description = "Cluster name (used in various places, don't use special chars)"
}

variable "create_kubeconfig" {
  description = "Create a local kubeconfig file to connect to the cluster"
  default     = true
}

## Network

variable "network_cidr" {
  description = "Network in which the cluster will be placed"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet in which all nodes are placed"
  default     = "10.0.1.0/24"
}

## Servers

variable "control_plane_server_count" {
  description = "Number of control plane nodes"
  default     = 3
}

variable "control_plane_server_type" {
  description = "Server type of control plane servers"
  default     = "cx11"
}

variable "agent_server_count" {
  description = "Number of agent nodes"
  default     = 2
}

variable "agent_server_type" {
  description = "Server type of agent servers"
  default     = "cx21"
}

variable "server_locations" {
  description = "Server locations in which servers will be distributed"
  default     = ["nbg1", "fsn1", "hel1"]
}

## Versions

variable "k3s_version" {
  description = "K3s version"
  default     = "v1.21.3+k3s1"
}

variable "hcloud_csi_driver_version" {
  default = "v1.5.3"
}

# Labels

locals {
  common_labels = {
    cluster     = var.name
    provisioner = "terraform",
    module      = "k-andy"
    engine      = "k3s",
  }
}