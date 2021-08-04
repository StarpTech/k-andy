data "hcloud_image" "ubuntu" {
  name = "ubuntu-20.04"
}

resource "random_pet" "agent_suffix" {
  count = var.server_count
}

locals {
  agent_pet_names = [for pet in random_pet.agent_suffix : pet.id]
  agent_name_map  = { for i in range(0, var.server_count) : random_pet.agent_suffix[i].id => i }
}
