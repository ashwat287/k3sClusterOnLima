# K3s Cluster on Lima

This repo provides shell scripts to spin up and clean up a local 2-node K3s cluster on Lima.

## What Gets Created

`./create-k3s-cluster.sh` creates:

- `k3s-master` (control plane): `1 CPU`, `2GiB RAM`, `30GiB disk`
- `k3s-worker` (agent): `2 CPU`, `4GiB RAM`, `40GiB disk`

Both VMs use the `template:k3s` Lima template and `lima:user-v2` network.

## Prerequisites

- `lima` / `limactl`
- `kubectl`

Verify:

```bash
limactl --version
kubectl version --client
```

## Create Cluster

```bash
./create-k3s-cluster.sh
```

The script:

1. Starts `k3s-master`
2. Reads the cluster join token from master
3. Starts `k3s-worker` and joins it to master
4. Merges the master kubeconfig into `~/.kube/config`, removing or replacing any conflicting `default` entries
5. Switches `kubectl` to the `lima-k3s` context and runs `kubectl get nodes`

If you want `KUBECONFIG` in your current interactive shell, run:

```bash
export KUBECONFIG="$HOME/.kube/config"
kubectl get nodes -o wide
```

## Cleanup Lima VMs

Remove all Lima VMs (with confirmation):

```bash
./cleanup-lima-vms.sh
```

Remove all Lima VMs without confirmation:

```bash
./cleanup-lima-vms.sh -f
```

Show cleanup help:

```bash
./cleanup-lima-vms.sh -h
```
