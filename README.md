# k-andy

<img align="left" height="250" src="logo.svg"/>

### Zero friction Kubernetes stack on Hetzner Cloud

This [terraform](https://www.terraform.io/) script will install a High Availability [K3s](https://k3s.io/) Cluster with Embedded DB in a private network on [Hetzner Cloud](https://www.hetzner.com/de/cloud). The following resources are provisionised by default (**25€/mo**):

- 3x Control-plane: _CX11_, 2GB RAM, 1VCPU, 20GB NVMe, 20TB Traffic.
- 2x Worker: _CX21_, 4GB RAM, 2VCPU, 40GB NVMe, 20TB Traffic.
- Load-Balancer: _LB11_, 5 Services, 25 Targets
- Network: Private network with one subnet.

</br>

**Hetzner Cloud integration**:

- Preinstalled [CSI-driver](https://github.com/hetznercloud/csi-driver) for volume support.
- Preinstalled [Cloud Controller Manager for Hetzner Cloud](https://github.com/hetznercloud/hcloud-cloud-controller-manager) for Load Balancer support.

K3s is a lightweight certified kubernetes distribution. It's packaged as single binary and comes with solid defaults for storage and networking but we replaced [Local-path-provisioner](https://github.com/rancher/local-path-provisioner) with hetzner [CSI-driver](https://github.com/hetznercloud/csi-driver). The Ingress controller (traefik) has been disabled because K3s provides an old version (traefik < 2). You can install v2 or a different controller.

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

`terraform apply` will copy the kubeconfig from the server to your current working directory. The file `kubeconfig.yaml` is created. Run:

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

## Credits

- [terraform-hcloud-k3s](https://github.com/cicdteam/terraform-hcloud-k3s) Terraform module which creates a single node cluster.
- [terraform-module-k3](https://github.com/xunleii/terraform-module-k3s) Terraform module which creates a k3s cluster, with multi-server and management features.
- Icon created by [Freepik](https://www.freepik.com) from [www.flaticon.com](https://www.flaticon.com/de/)
