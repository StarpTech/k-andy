# k-andy

<img align="left" height="250" src="logo.svg"/>

### Zero friction Kubernetes stack on Hetzner Cloud

This [terraform](https://www.terraform.io/) module will install a High Availability [K3s](https://k3s.io/) Cluster with Embedded DB in a private network on [Hetzner Cloud](https://www.hetzner.com/de/cloud). The following resources are provisionised by default (**20€/mo**):

- 3x Control-plane: _CX11_, 2GB RAM, 1VCPU, 20GB NVMe, 20TB Traffic.
- 2x Worker: _CX21_, 4GB RAM, 2VCPU, 40GB NVMe, 20TB Traffic.
- Network: Private network with one subnet.
- Server and agent nodes are distributed across 3 Datacenters (nbg1, fsn1, hel1) for high availability.

</br>
</br>

**Hetzner Cloud integration**:

- Preinstalled [CSI-driver](https://github.com/hetznercloud/csi-driver) for volume support.
- Preinstalled [Cloud Controller Manager for Hetzner Cloud](https://github.com/hetznercloud/hcloud-cloud-controller-manager) for Load Balancer support.

**Auto-K3s-Upgrades**

We provide an example how to upgrade your K3s node and agents with the [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller). Check out [/upgrade](./upgrade)

**What is K3s?**

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with solid defaults for storage and networking but we replaced [local-path-provisioner](https://github.com/rancher/local-path-provisioner) with hetzner [CSI-driver](https://github.com/hetznercloud/csi-driver) and [klipper load-balancer](https://github.com/k3s-io/klipper-lb) with hetzner [Cloud Controller Manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager). The default ingress controller (traefik) has been disabled.

## Usage

See a more detailed example with walk-through in the [example folder](./example).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_server_count"></a> [agent\_server\_count](#input\_agent\_server\_count) | Number of agent nodes | `number` | `2` | no |
| <a name="input_agent_server_type"></a> [agent\_server\_type](#input\_agent\_server\_type) | Server type of agent servers | `string` | `"cx21"` | no |
| <a name="input_control_plane_server_count"></a> [control\_plane\_server\_count](#input\_control\_plane\_server\_count) | Number of control plane nodes | `number` | `3` | no |
| <a name="input_control_plane_server_type"></a> [control\_plane\_server\_type](#input\_control\_plane\_server\_type) | Server type of control plane servers | `string` | `"cx11"` | no |
| <a name="input_create_kubeconfig"></a> [create\_kubeconfig](#input\_create\_kubeconfig) | Create a local kubeconfig file to connect to the cluster | `bool` | `true` | no |
| <a name="input_hcloud_csi_driver_version"></a> [hcloud\_csi\_driver\_version](#input\_hcloud\_csi\_driver\_version) | n/a | `string` | `"v1.5.3"` | no |
| <a name="input_hcloud_token"></a> [hcloud\_token](#input\_hcloud\_token) | Token to authenticate against Hetzner Cloud | `any` | n/a | yes |
| <a name="input_k3s_version"></a> [k3s\_version](#input\_k3s\_version) | K3s version | `string` | `"v1.21.3+k3s1"` | no |
| <a name="input_name"></a> [name](#input\_name) | Cluster name (used in various places, don't use special chars) | `any` | n/a | yes |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | Network in which the cluster will be placed | `string` | `"10.0.0.0/16"` | no |
| <a name="input_server_locations"></a> [server\_locations](#input\_server\_locations) | Server locations in which servers will be distributed | `list` | <pre>[<br>  "nbg1",<br>  "fsn1",<br>  "hel1"<br>]</pre> | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | Subnet in which all nodes are placed | `string` | `"10.0.1.0/24"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_agents_public_ips"></a> [agents\_public\_ips](#output\_agents\_public\_ips) | The public IP addresses of the agent servers |
| <a name="output_control_planes_public_ips"></a> [control\_planes\_public\_ips](#output\_control\_planes\_public\_ips) | The public IP addresses of the control plane servers |
| <a name="output_k3s_token"></a> [k3s\_token](#output\_k3s\_token) | Secret k3s authentication token |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig with external IP address |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Auto-Upgrade

### Prerequisite

Install the system-upgrade-controller in your cluster.

```
KUBECONFIG=kubeconfig.yaml kubectl apply -f ./upgrade/controller.yaml
```

## Upgrade procedure

1. Mark the nodes you want to upgrade (The script will mark all nodes).

```
KUBECONFIG=kubeconfig.yaml kubectl label --all node k3s-upgrade=true
```

2. Run the plan for the **servers**.

```
KUBECONFIG=kubeconfig.yaml kubectl apply -f ./upgrade/server-plan.yaml
```

**Warning:** Wait for completion [before you start upgrading your agents](https://github.com/k3s-io/k3s/issues/2996#issuecomment-788352375).

3. Run the plan for the **agents**.

```
KUBECONFIG=kubeconfig.yaml kubectl apply -f ./upgrade/agent-plan.yaml
```

## Backups

K3s will automatically backup your embedded etcd datastore every 12 hours to `/var/lib/rancher/k3s/server/db/snapshots/`.
You can reset the cluster by pointing to a specific snapshot.

1. Stop the master server.

```sh
sudo systemctl stop k3s
```

2. Restore the master server with a snapshot

```sh
./k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=<PATH-TO-SNAPSHOT>
```

**Warning:** This forget all peers and the server becomes the sole member of a new cluster. You have to manually rejoin all servers.

3. Connect you with the different servers backup and delete `/var/lib/rancher/k3s/server/db` on each peer etcd server and rejoin the nodes.

```sh
sudo systemctl stop k3s
rm -rf /var/lib/rancher/k3s/server/db
sudo systemctl start k3s
```

This will rejoin the server with the master server and seed the etcd store.

**Info:** It exists no official tool to automate the procedure. In future, rancher might provide an operator to handle this ([issue](https://github.com/k3s-io/k3s/issues/3174)).

## Debugging

Cloud init logs can be found on the remote machines in:

- /var/log/cloud-init-output.log
- /var/log/cloud-init.log
- `journalctl -u k3s.service -e` last logs of the server
- `journalctl -u k3s-agent.service -e` last logs of the agent

## Known issues

- Sometimes at cluster bootstrapping the Cloud-Controllers reports that some routes couldn't be created. This issue was fixed in master but wasn't released yet. Restart the cloud-controller pod and it will recreate them.

## Credits

- [terraform-hcloud-k3s](https://github.com/cicdteam/terraform-hcloud-k3s) Terraform module which creates a single node cluster.
- [terraform-module-k3](https://github.com/xunleii/terraform-module-k3s) Terraform module which creates a k3s cluster, with multi-server and management features.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)
