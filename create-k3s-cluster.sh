#!/bin/bash

set -euo pipefail


echo "Creating k3s cluster with 2 nodes (master + 1 worker) using lima..."

echo "Creating master node (k3s-master)..."
limactl start -y --name k3s-master \
  --network lima:user-v2 \
  template:k3s \
  --set ".cpus=1 | .memory=\"2GiB\" | .disk=\"30GiB\""


# Wait for the master node to be ready and the node token to be generated
until limactl shell k3s-master -- sudo test -f /var/lib/rancher/k3s/server/node-token; do
  sleep 0.5
done

sleep 1 # Ensure the token file is fully written

TOKEN=$(limactl shell k3s-master -- sudo cat /var/lib/rancher/k3s/server/node-token)
URL="https://lima-k3s-master.internal:6443"


echo "Creating worker node (k3s-worker)..."
limactl start -y --name k3s-worker \
  --network lima:user-v2 \
  template:k3s \
  --set ".cpus=2 | .memory=\"4GiB\" | .disk=\"40GiB\" | .param.url=\"$URL\" | .param.token=\"$TOKEN\""

export KUBECONFIG=$(limactl list k3s-master --format 'unix://{{.Dir}}/copied-from-guest/kubeconfig.yaml')

kubectl get nodes

echo "k3s cluster created successfully!"