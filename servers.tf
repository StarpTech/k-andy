resource "hcloud_server" "first_control_plane" {
  name = "k3s-control-plane-0"

  image       = data.hcloud_image.ubuntu.name
  server_type = local.control_plane_server_type
  location    = local.server_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "control-plane"
  }

  user_data = <<-EOT
  #cloud-config
  # Update packages after first boot
  package_update: true
  # Install additional packages
  packages:
  # Initialize cluster after first boot
  # Manifest at this location will automatically be deployed to K3s in a manner similar to kubectl apply
  write_files:
  # Deploy example application
  - content: ${filebase64("./hello-kubernetes.yaml")}
    path: /var/lib/rancher/k3s/server/manifests/hello-kubernetes.yaml
    encoding: b64
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_cluster_secret.result}" INSTALL_K3S_VERSION="${var.k3s_version}" sh -s - server --cluster-init --disable traefik --disable local-storage
  EOT

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl taint nodes ${self.name} node-role.kubernetes.io/control-plane=true:NoSchedule",
      # Install hetzner CSI plugin
      "kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.5.1/deploy/kubernetes/hcloud-csi.yml",
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key)
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.public_key} root@${self.ipv4_address}:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml"
  }

  provisioner "local-exec" {
    command = "sed -i -e 's/127.0.0.1/${self.ipv4_address}/g' ./kubeconfig.yaml"
  }
}

resource "hcloud_server_network" "first_control_plane" {
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.first_control_plane.id
  ip        = local.first_control_plane_ip
}

resource "hcloud_server" "control_planes" {
  count = var.servers_num - 1
  name  = "k3s-control-plane-${count.index + 1}"

  image       = data.hcloud_image.ubuntu.name
  server_type = local.control_plane_server_type
  location    = local.server_location

  ssh_keys = [hcloud_ssh_key.default.id]
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "control-plane"
  }

  user_data = <<-EOT
  #cloud-config
  # Update packages after first boot
  package_update: true
  # Install additional packages
  packages:
  # Initialize cluster after first boot
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_cluster_secret.result}" INSTALL_K3S_VERSION="${var.k3s_version}" sh -s - server --server https://${local.first_control_plane_ip}:6443 --disable traefik --disable local-storage
  EOT

  network {
    ip         = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3 + count.index)
    network_id = hcloud_network.k3s.id
  }

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      "kubectl taint nodes ${self.name} node-role.kubernetes.io/control-plane=true:NoSchedule"
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key)
    }
  }

  depends_on = [
    hcloud_server.first_control_plane
  ]
}

resource "hcloud_server_network" "control_planes" {
  count     = var.servers_num - 1
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.control_planes[count.index].id
  ip        = cidrhost(hcloud_network_subnet.k3s_nodes.ip_range, 3 + count.index)
}
