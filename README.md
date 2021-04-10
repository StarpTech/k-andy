# k-andy

<img align="left" height="250" src="logo.svg"/>

### Zero friction Kubernetes stack on Hetzner Cloud

This [terraform](https://www.terraform.io/) script will install a High Availability [K3s](https://k3s.io/) Cluster with Embedded DB in a private network on [Hetzner Cloud](https://www.hetzner.com/de/cloud). The following resources are provisionised by default (**17€/mo or**):

- 2x Control-plane: _CX11_, 2GB RAM, 1VCPU, 20GB NVMe, 20TB Traffic.
- 2x Worker: _CX21_, 4GB RAM, 2VCPU, 40GB NVMe, 20TB Traffic.
- Network: Private network with one subnet.

</br>
</br>

**Hetzner Cloud integration**:

- Preinstalled [CSI-driver](https://github.com/hetznercloud/csi-driver) for volume support.
- Preinstalled [Cloud Controller Manager for Hetzner Cloud](https://github.com/hetznercloud/hcloud-cloud-controller-manager) for Load Balancer support.

**Auto-K3s-Upgrades**

We provide an example how to upgrade your K3s node and agents with the [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller). Check out [/upgrade](./upgrade)

**What is K3s?**

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with solid defaults for storage and networking but we replaced [local-path-provisioner](https://github.com/rancher/local-path-provisioner) with hetzner [CSI-driver](https://github.com/hetznercloud/csi-driver) and [klipper load-balancer](https://github.com/k3s-io/klipper-lb) with hetzner [Cloud Controller Manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager). The Ingress controller (traefik) has been disabled because K3s provides an old version of traefik < 2. We prefer to install traefik v2 or a different controller.

## Usage

Run the following command to create a cluster.

```sh
terraform init
terraform apply \
    -var "hcloud_token=${hcloud_token}" \
    -var "private_key=${private_key_location}" \
    -var "public_key=${public_key_location}"
```

## Cluster access

`terraform apply` will copy the kubeconfig from the master server to your current working directory. The file `kubeconfig.yaml` is created. Run:

```sh
KUBECONFIG=kubeconfig.yaml kubectl get node
```

## Demo

A demo application can be found in [manifests](manifests/hello-kubernetes.yaml). Run:

```sh
KUBECONFIG=kubeconfig.yaml kubectl apply -f manifests/hello-kubernetes.yaml
```

and try to access `http://<load-balancer-ip>:8080`.

## Destroy your cluster

If you no longer need the cluster don't forget to destroy it. Load-Balancers and volumes must be deleted manually.

```sh
terraform destroy
```

## Inputs

| Name            | Description                   | Type   | Default      | Required |
| --------------- | ----------------------------- | ------ | ------------ | -------- |
| private_key     | Private ssh key               | string |              | true     |
| public_key      | Public ssh key                | string |              | true     |
| hcloud_token    | API token                     | string |              | true     |
| k3s_version     | K3s version                   | string | v1.20.5+k3s1 | false    |
| servers_num     | Number of control plane nodes | string | 2            | false    |
| agents_num      | Number of agent nodes         | string | 2            | false    |
| server_location | Server location               | string | nbg1         | false    |

## Outputs

| Name                    | Description                                        | Type   |
| ----------------------- | -------------------------------------------------- | ------ |
| controlplanes_public_ip | The public IP addresses of the controlplane server | string |
| agents_public_ip        | The public IP addresses of the agent server        | string |

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

```sh
./k3s server \
  --cluster-reset \
  --cluster-reset-restore-path=<PATH-TO-SNAPSHOT>
```

**Warning:** This forget all peers and the server becomes the sole member of a new cluster. You have to manually rejoin your server and agents. For production you should use an external datastore to automate this process.

## Debugging

Cloud init logs can be found on the remote machines in:

- /var/log/cloud-init-output.log
- /var/log/cloud-init.log

## Known issues

- Sometimes at cluster bootstrapping the Cloud-Controllers reports that some routes couldn't be created. This issue was fixed in master. Just restart the cloud-controller and it will recreate them.

## Credits

- [terraform-hcloud-k3s](https://github.com/cicdteam/terraform-hcloud-k3s) Terraform module which creates a single node cluster.
- [terraform-module-k3](https://github.com/xunleii/terraform-module-k3s) Terraform module which creates a k3s cluster, with multi-server and management features.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)
