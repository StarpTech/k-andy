variable "cluster_name" {
  description = "Cluster name (used in naming the servers)"
}

variable "group_name" {
  description = "Name of the agent group"
}

variable "server_locations" {
  description = "Server locations to create agents in"
}

variable "additional_packages" {
  default = []
}

variable "server_count" {
  description = "Number of agent nodes"
  default     = 2
}

variable "server_type" {
  description = "Server type of agent server group"
  default     = "cx21"
}

variable "provisioning_ssh_key_id" {
  description = "ID of the hcloud SSH key to provision the node group with"
}

variable "control_plane_ip" {
  description = "Control plane IP to connect to"
}


variable "k3s_version" {
  description = "K3S version, should match the control plane"
}


variable "k3s_cluster_secret" {
  description = "K3S cluster token to authenticate against control plane"
}


variable "network_id" {
  description = "Network ID to place agents in"
}

variable "subnet_id" {
  description = "ID of the subnet in which agents are started"
}

variable "subnet_ip_range" {
  description = "CIDR block of the subnet"
}

variable "ip_offset" {
  description = "Offset from which agents are IPs are counted upwards. Needs to be adjusted to not cause collisions!"
}


variable "ssh_private_key" {
  description = "SSH private key to connect directly to server (used for remote-exec)"
}

variable "common_labels" {
  description = "Additional labels to add to server instances"
  default     = {}
}