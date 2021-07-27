resource "hcloud_server" "first_control_plane" {
  name = "${var.name}-control-plane-0"

  image       = data.hcloud_image.ubuntu.name
  server_type = var.control_plane_server_type
  location    = var.server_locations[0]

  ssh_keys = [hcloud_ssh_key.provision_public.id]
  labels = merge({
    node_type = "control-plane"
  }, local.common_labels)
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
      "kubectl taint node ${self.name} CriticalAddonsOnly=true:NoExecute",
      # Install hetzner CCM
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token} --from-literal=network=${hcloud_network.k3s.name}",
      "kubectl apply -f -<<EOF\n${data.template_file.ccm_manifest.rendered}\nEOF",
      # Install hetzner CSI plugin
      "kubectl -n kube-system create secret generic hcloud-csi --from-literal=token=${var.hcloud_token}",
      "kubectl apply -f -<<EOF\n${data.http.hcloud_csi_driver_manifest.body}\nEOF",
    ]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = tls_private_key.provision.private_key_pem
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${local_file.ssh_private_key.filename} root@${self.ipv4_address}:/etc/rancher/k3s/k3s.yaml ./kubeconfig-${var.name}.yaml"
  }

  provisioner "local-exec" {
    command = "sed -i -e 's/127.0.0.1/${self.ipv4_address}/g' ./kubeconfig-${var.name}.yaml"
  }
}

resource "hcloud_server_network" "first_control_plane" {
  subnet_id = hcloud_network_subnet.k3s_nodes.id
  server_id = hcloud_server.first_control_plane.id
  ip        = local.first_control_plane_ip
}
