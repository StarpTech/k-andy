<p align="center">
    <img src="logo.svg" width="128px" alt="k-andy logo"/>
</p>
<h3 align="center">K-andy</h3>
<p align="center">Bootstrap a High Availability <a href="https://rancher.com/docs/k3s/latest/en/">K3s</a> Cluster with Embedded DB < 1 min 🚀</p>

This [terraform](https://www.terraform.io/) script will install a High Availability [K3s](https://rancher.com/docs/k3s/latest/en/) Cluster with Embedded DB in a private network on Hetzner Cloud. By default the following resources are provisionised:

1. **3x Control-plane**: Server (_CX11_, 2GB RAM, 1VCPU, 20GB NVMe, 20TB Traffic).
1. **3x Worker**: Server (_CPX21_, 4GB RAM, 3VCPU, 80GB NVMe, 20TB Traffic).
1. **Network**: Private network with one subnet.

Total costs: **~33€/mo**.

This setup should be sufficient to run a medium sized application with multiple services, message-queue and a database. [Traefik](https://doc.traefik.io/traefik/) is already preinstalled by K3s.

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with good defaults for storage and networking. K3s utilizes the host storage. You can use the storage of your servers (~200GB) for your workloads. In case of you need a more advanced solution k3s and this setup is compatible with [longhorn](https://github.com/longhorn/longhorn) a distributed block storage.

## Usage

Run the following command to create a cluster. The process usually takes ~1min.

```sh
terraform init
terraform apply
```

### Cluster access

`terraform apply` will display the public IP's of your control-plane server. Login into the control-plane server via ssh and copy the kubeconfig. You can use a tool like [Lens](https://k8slens.dev/) to work with Kubernetes in a more user friendly way. It also support cluster import by pasting the content of `/etc/rancher/k3s/k3s.yaml`. Don't forget to replace `127.0.0.1` with the public IP of the `k3s-control-plane-0` server.

```sh
ssh root@<k3s-control-plane-0>
cat /etc/rancher/k3s/k3s.yaml
```

## Demo

A demo application is automatically deployed to test your setup. Visit `http://<k3s-agent-0>:8080`.

## Destroy your cluster

If you no longer need the cluster don't forget to destroy it.

```sh
terraform destroy
```

## Inputs

| Name         | Description                             | Type   | Default            | Required |
| ------------ | --------------------------------------- | ------ | ------------------ | -------- |
| ssh_key      | Public key to use for all your server   | string |                    | true     |
| hcloud.token | API token of your hetzner cloud project | string | HCLOUD_TOKEN (ENV) | true     |

## Outputs

| Name                   | Description                                                      | Type   |
| ---------------------- | ---------------------------------------------------------------- | ------ |
| controlplane_public_ip | The public IP address of the first controlplane server instance. | string |
| agent_public_ip        | The public IP address of the first agent server instance.        | string |

## Disallow scheduling on the control-plane node

K3s doesn't configure taints for the control-plane node. If you want to ensure that workloads are only scheduled on worker nodes add the following taints to the control-plane nodes.

```sh
kubectl taint nodes -l node-role.kubernetes.io/controlplane=true node-role.kubernetes.io/control-plane=true:NoSchedule
```

## Considerations

We don't use hetzners [cloud-controller](https://kubernetes.io/docs/concepts/architecture/cloud-controller/). Services of type `LoadBalancer` are implemented via [Klipper Service Load Balancer](https://github.com/k3s-io/klipper-lb). PVC's are implemented via [Local Path Provisioner](https://github.com/rancher/local-path-provisioner).

### Hetzner Cloud integration

If you need a Kubernetes cluster with deep Hetzner Cloud integration I can recommend my article [Managed Kubernetes Cluster (HA) for Side Projects](https://dustindeus.medium.com/managed-kubernetes-cluster-ha-for-side-projects-47f74e2f9436).

## Credits

- [terraform-module-k3s](https://github.com/xunleii/terraform-module-k3s) If you want to provision a cluster dynamically with advanced configuration.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)
