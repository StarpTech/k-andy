# k-andy

<img align="left" height="300" src="logo.svg"/>

### Zero friction Kubernetes stack on Hetzner Cloud

This [terraform](https://www.terraform.io/) script will install a High Availability [K3s](https://rancher.com/docs/k3s/latest/en/) Cluster with Embedded DB in a private network on [Hetzner Cloud](https://www.hetzner.com/de/cloud). The following resources are provisionised by default (customizable):

- **3x Control-plane**: _CX11_, 2GB RAM, 1VCPU, 20GB NVMe, 20TB Traffic.
- **2x Worker**: _CX21_, 4GB RAM, 2VCPU, 40GB NVMe, 20TB Traffic.
- **Public Key**: SSH Key to access all servers.
- **Network**: Private network with one subnet.

Total costs: **20€/mo**. The minimum configuration costs **6€/mo**.

</br>
</br>

This setup should be sufficient to run a medium sized application with multiple services, message-queue and a database. [Traefik](https://doc.traefik.io/traefik/) is already preinstalled by K3s.

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with good defaults for storage and networking. K3s utilizes the host storage. You can use the storage of your servers (~60GB) for your workloads. In case of you need a more advanced solution k3s and this setup is compatible with [longhorn](https://github.com/longhorn/longhorn) a distributed block storage. In addition to this, hetzner provides a [cloud-controller-manager](https://github.com/hetznercloud/hcloud-cloud-controller-manager) and [CSI](https://github.com/hetznercloud/csi-driver) to integrate your Kubernets cluster with the Hetzner Cloud API (Load-Balancer, Volumes, Networking).

## Usage

Run the following command to create a cluster.

```sh
HCLOUD_TOKEN=XXX
terraform init
terraform apply -var "private_key=${private_key_location}" -var "public_key=${public_key_location}"
```

## Cluster access

`terraform apply` will copy the kubeconfig from the server to your current working directory. The file `kubeconfig.yaml` is created. You can use a tool like [Lens](https://k8slens.dev/) to work with Kubernetes in a more user friendly way. It also support cluster import by file.

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
| private_key  | Private ssh key                         | string |                    | true     |
| public_key   | Public ssh key                          | string |                    | true     |
| hcloud.token | API token of your hetzner cloud project | string | HCLOUD_TOKEN (ENV) | true     |

## Outputs

| Name                   | Description                                                      | Type   |
| ---------------------- | ---------------------------------------------------------------- | ------ |
| controlplane_public_ip | The public IP address of the first controlplane server instance. | string |
| agent_public_ip        | The public IP address of the first agent server instance.        | string |

## Considerations

- Services of type `LoadBalancer` are implemented via [Klipper Service Load Balancer](https://github.com/k3s-io/klipper-lb).
- Storage is provionised via [Local Path Provisioner](https://github.com/rancher/local-path-provisioner).

## Hetzner Cloud integration

If you need a Kubernetes cluster with deep Hetzner Cloud integration I can recommend my article [Managed Kubernetes Cluster (HA) for Side Projects](https://dustindeus.medium.com/managed-kubernetes-cluster-ha-for-side-projects-47f74e2f9436). The same steps are valid for K3s. The kubelet arguments can be passed to the k3s installation script.

## Credits

- [terraform-module-k3s](https://github.com/xunleii/terraform-module-k3s) If you want to provision a cluster dynamically with advanced configuration.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)
