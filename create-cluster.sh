#!/bin/bash

# Save the start time
start_time=$(date +%s)

# Create a k8s cluster with multipass.
./kubeadm-containerd/1-create-controlplane.sh
controlplane_end_time=$(date +%s)
./kubeadm-containerd/2-create-worker-nodes.sh
worker1_end_time=$(date +%s)
./kubeadm-containerd/3-join-worker-nodes-to-controlplane.sh
worker2_end_time=$(date +%s)

# Save the end time
end_time=$(date +%s)

# Calculate the elapsed times
controlplane_time=$((controlplane_end_time-start_time))
worker1_time=$((worker1_end_time-controlplane_end_time))
worker2_time=$((worker2_end_time-worker1_end_time))
elapsed_time=$((end_time-start_time))

# Print the elapsed times
echo "Controlplane Time: $controlplane_time seconds"
echo "Worker1 Time: $worker1_time seconds"
echo "Worker2 Time: $worker2_time seconds"
echo "Total Elapsed Time: $elapsed_time seconds"