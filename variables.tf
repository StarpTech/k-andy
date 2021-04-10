variable "hcloud_token" {}

provider "hcloud" {
  token = var.hcloud_token
}
variable "public_key" {
  description = "SSH public Key."
  type        = string
}
variable "private_key" {
  description = "SSH private Key."
  type        = string
}

variable "server_location" {
  description = "Server location."
  default = "nbg1"
}

variable "servers_num" {
  description = "Number of control plane nodes."
  default     = 3
}

variable "agents_num" {
  description = "Number of agent nodes."
  default     = 2
}

variable "k3s_version" {
  description = "K3s version"
  default     = "v1.20.5+k3s1"
}