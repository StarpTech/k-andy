variable "ssh_key" {
  description = "SSH public Key content needed to provision the instances."
  type        = string
}
variable "k3s_key" {
  description = "K3s Token - Shared secret to join servers on the private network"
  type        = string
  sensitive = true
}