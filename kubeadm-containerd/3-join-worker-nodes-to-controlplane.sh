#!/bin/bash
# Join Worker Nodes to the Controlplane.

NODES=$(echo worker{1..2})

for NODE in ${NODES}; do
echo "Deploying kubeconfig.yaml to [${NODE}]"
multipass exec ${NODE} -- bash -c "sudo mkdir -p /home/ubuntu/.kube/"
multipass exec ${NODE} -- bash -c "sudo chown ubuntu:ubuntu /home/ubuntu/.kube/"
multipass transfer kubeconfig.yaml ${NODE}:/home/ubuntu/.kube/config

echo "-> Copying kubeconfig.yaml to /root/.kube/config"
multipass exec ${NODE} -- bash -c "sudo mkdir -p /root/.kube/"
multipass exec ${NODE} -- bash -c "sudo cp /home/ubuntu/.kube/config /root/.kube/config"

echo "-> Joining ${NODE} to the [controlplane]."
multipass exec ${NODE} -- bash -c "sudo kubeadm token create --print-join-command >> kubeadm-join-controlplane.sh"
multipass exec ${NODE} -- bash -c "sudo chmod +x kubeadm-join-controlplane.sh"
multipass exec ${NODE} -- bash -c "sudo sh ./kubeadm-join-controlplane.sh"
done

echo "-> Sleeping for 40 seconds to allow the nodes to join the cluster."
sleep 40
echo "-> Labeling the nodes via localhost."
KUBECONFIG=kubeconfig.yaml kubectl label node worker1 node-role.kubernetes.io/node=
KUBECONFIG=kubeconfig.yaml kubectl label node worker2 node-role.kubernetes.io/node=

# Check Node Readiness
ready_nodes=0
# Loop until all nodes are ready
while [ $ready_nodes -lt $(KUBECONFIG=kubeconfig.yaml kubectl get nodes | grep -v "NAME" | wc -l) ]; do
  # Get the number of ready nodes
  echo "-> Checking nodes for readiness."
  ready_nodes=$(KUBECONFIG=kubeconfig.yaml kubectl get nodes | grep "Ready" | wc -l)
  # Sleep for 5 seconds
  sleep 5
done
echo "-> All nodes are ready."
KUBECONFIG=kubeconfig.yaml kubectl get nodes