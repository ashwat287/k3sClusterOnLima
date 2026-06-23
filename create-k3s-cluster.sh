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

# Extract the kubeconfig from the master node and merge it with the existing kubeconfig if it exists
KUBECONFIG_PATH=$(limactl list k3s-master --format '{{.Dir}}/copied-from-guest/kubeconfig.yaml')
until [ -s "$KUBECONFIG_PATH" ]; do sleep 1; done

mkdir -p ~/.kube
for entry in lima-k3s default; do
  kubectl config delete-context "$entry" 2>/dev/null || true
  kubectl config delete-cluster "$entry"  2>/dev/null || true
  kubectl config delete-user "$entry"     2>/dev/null || true
done

KUBECONFIG="$HOME/.kube/config:$KUBECONFIG_PATH" kubectl config view --flatten > /tmp/kubeconfig-merged
mv /tmp/kubeconfig-merged ~/.kube/config
chmod 600 ~/.kube/config

kubectl config rename-context default lima-k3s 2>/dev/null || true
kubectl config use-context lima-k3s

kubectl get nodes

echo "k3s cluster created successfully!"