# k-andy

<img align="left" height="300" src="logo.svg"/>

### Zero friction Kubernetes stack on Hetzner Cloud

This [terraform](https://www.terraform.io/) script will install a High Availability [K3s](https://rancher.com/docs/k3s/latest/en/) Cluster with Embedded DB in a private network on [Hetzner Cloud](https://www.hetzner.com/de/cloud). The following resources are provisionised by default (customizable):

- 3x Control-plane: _CX11_, 2GB RAM, 1VCPU, 20GB NVMe, 20TB Traffic.
- 2x Worker: _CX21_, 4GB RAM, 2VCPU, 40GB NVMe, 20TB Traffic.
- Public Key: SSH Key to access all servers.
- Network: Private network with one subnet.

Total costs: **20€/mo**. The minimum configuration costs **6€/mo**.

**Hetzner Cloud integration**:

- Preinstalled [CSI-driver](https://github.com/hetznercloud/csi-driver) for volume support.

</br>
</br>

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with good defaults for storage and networking. We replaced the default storage class with hetzner [CSI-driver](https://github.com/hetznercloud/csi-driver) to work with volumes instead of host-storage. Traefik has been disabled because K3s ships an old version < 2.

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

`terraform apply` will copy the kubeconfig from the server to your current working directory. The file `kubeconfig.yaml` is created. You can use a tool like [Lens](https://k8slens.dev/) to work with Kubernetes in a more user friendly way. It also support cluster import by file.

## Demo

A demo application is automatically deployed to test your setup. Visit `http://<k3s-agent-0>:8080`.

## Destroy your cluster

If you no longer need the cluster don't forget to destroy it.

```sh
terraform destroy
```

## Inputs

| Name         | Description     | Type   | Default | Required |
| ------------ | --------------- | ------ | ------- | -------- |
| private_key  | Private ssh key | string |         | true     |
| public_key   | Public ssh key  | string |         | true     |
| hcloud_token | API token       | string |         | true     |

## Outputs

| Name                    | Description                                         | Type   |
| ----------------------- | --------------------------------------------------- | ------ |
| controlplanes_public_ip | The public IP addresses of the controlplane server. | string |
| agents_public_ip        | The public IP addresses of the agent server.        | string |

## Considerations

- Services of type `LoadBalancer` are implemented via [Klipper Service Load Balancer](https://github.com/k3s-io/klipper-lb).
- Storage is provionised via [Local Path Provisioner](https://github.com/rancher/local-path-provisioner).

## Hetzner Cloud integration

If you need a Kubernetes cluster with deep Hetzner Cloud integration I can recommend my article [Managed Kubernetes Cluster (HA) for Side Projects](https://dustindeus.medium.com/managed-kubernetes-cluster-ha-for-side-projects-47f74e2f9436). The same steps are valid for K3s. The kubelet arguments can be passed to the k3s installation script.

## Credits

- [terraform-module-k3s](https://github.com/xunleii/terraform-module-k3s) If you want to provision a cluster dynamically with advanced configuration.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)
