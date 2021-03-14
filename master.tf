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
  # logs can be found in /var/log/cloud-init-output.log and /var/log/cloud-init.log
  user_data = <<-EOT
  #cloud-config
  runcmd:
    - curl -sfL https://get.k3s.io | K3S_TOKEN="${random_password.k3s_cluster_secret.result}" INSTALL_K3S_VERSION="${var.k3s_version}" sh -s - server --cluster-init --disable local-storage --disable-cloud-controller --disable traefik --disable servicelb --kubelet-arg="cloud-provider=external"
  EOT

  provisioner "remote-exec" {
    inline = [
      "until systemctl is-active --quiet k3s.service; do sleep 1; done",
      "until kubectl get node ${self.name}; do sleep 1; done",
      # Disable workloads on master node
      "kubectl taint node ${self.name} node-role.kubernetes.io/master=true:NoSchedule",
      # Install hetzner CCM
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name}",
      "kubectl apply -f -<<EOF\n${data.template_file.ccm_manifest.rendered}\nEOF",
      # Install hetzner CSI plugin
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl apply -f -<<EOF\n${data.template_file.csi_manifest.rendered}\nEOF",
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
