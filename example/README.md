# Example Usage

## Environment Setup

It's easiest if you set up some environment variables.

This example uses [direnv](https://direnv.net) with an `.envrc` for that,
but you can also just execute the `export` statements in your session.

Our `.envrc` here looks like this:

```shell
export TF_VAR_hcloud_token=THETOKENYOUGETFROMTHECLOUDCONSOLE
export KUBECONFIG=$(pwd)/kubeconfig-demo.yaml
```

The `hcloud_token` is an API Token from a [Hetzner Cloud](https://console.hetzner.cloud/projects) project.  

We also set `KUBECONFIG` so we can later just run `kubectl` in here to interact with the created cluster.

If you use `direnv`, don't forget to run `direnv allow`.

## Cluster Creation

Now you bring up the cluster with terraform and then test if it's there and looking good.

```shell
terraform init
terraform apply
kubectl cluster-info
kubectl get node
```

## Demo Application

A demo application can be found in [manifests](manifests/hello-kubernetes.yaml). Run:

```sh
kubectl apply -f ../manifests/hello-kubernetes.yaml
```

and try to access `http://<load-balancer-ip>:8080`.

You can find the public IP of the service with `kubectl get service hello-kubernetes -o jsonpath='{.status.loadBalancer.ingress}'`

## Destroy your cluster

If you no longer need the cluster don't forget to destroy it. Load-Balancers and volumes must be deleted manually.

```sh
terraform destroy
```
