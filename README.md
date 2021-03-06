<p align="center">
    <img src="logo.svg" width="128px" alt="k-andy logo"/>
</p>
<h3 align="center">K-andy</h3>
<p align="center">Zero friction Kubernetes stack for startups, prototypes and playgrounds.</p>


This [terraform](https://www.terraform.io/) script will install a none HA [K3s](https://rancher.com/docs/k3s/latest/en/) Cluster in a private network on Hetzner Cloud. By default the following resources are provisionised:

1. **Controlplane**: Server (_CPX11_, 2GB RAM, 2VCPU, 40GB NVMe).
1. **Worker**: Server (_CPX31_, 8GB RAM, 4VCPU, 160GB NVMe).
1. **Network**: Private network with one subnet.

This setup should be sufficient to run a medium sized application with multiple services (Golang), message-queue (NATS) and a database (PostgreSQL). [Traefik](https://doc.traefik.io/traefik/) is already preinstalled. The total costs are ~**20€/mo**.

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with good defaults for storage and networking. K3s utilizes the host storage. You can use the storage of your servers (~170GB) for your workloads. In case of you need a more advanced solution k3s and this setup is compatible with [longhorn](https://github.com/longhorn/longhorn) a distributed block storage.

## Usage

Run the folling command to create a cluster. The process takes usually ~1min.

```sh
terraform init
terraform apply
```

`terraform apply` will display the public IP's of your servers. Use the controlplane IP to connect via SSH.

### Cluster access

Login into the controlplan server via ssh and copy the kubeconfig. You can use a tool like [Lens](https://k8slens.dev/) to work with Kubernetes in a more user friendly way. It also support cluster import by pasting the content of `/etc/rancher/k3s/k3s.yaml`. Don't forget to replace `127.0.0.1` with the public IP of the `controlplane` server.

```sh
ssh root@<controlplane_public_ip>
cat /etc/rancher/k3s/k3s.yaml
```

## Demo

A demo application is automatically deployed to test your setup. Visit to `http://<agent_public_ip>:8080`.

## Destroy cluster

If you no longer need the cluster don't forget to destroy it.

```sh
terraform destroy
```

## Limitations

This setup is not intented to use for critical production workloads. Services of type `LoadBalancer` are implemented via [Klipper Service Load Balancer](https://github.com/k3s-io/klipper-lb). PVC's are implemented via [Local Path Provisioner](https://github.com/rancher/local-path-provisioner).

### HA Cluster

If you need a Kubernetes cluster for production with deep Hetzner cloud integration I can recommend my [article](https://dustindeus.medium.com/managed-kubernetes-cluster-ha-for-side-projects-47f74e2f9436) on medium.

## Credits

- [terraform-module-k3s](https://github.com/xunleii/terraform-module-k3s/issues/50) If you want to provision a dynamic cluster.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)