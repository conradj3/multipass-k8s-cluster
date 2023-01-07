#!/bin/bash
# Create Ubuntu 20.04 Worker Nodes.
NODES=$(echo worker{1..2})

# Multipass Worker Node Initialization.
for NODE in ${NODES}; do 
echo "-> Creating multipass Ubuntu 20.04 Worker [${NODE}]"
multipass launch 20.04 --name ${NODE} --cpus 2 --mem 4G --disk 30G; done

# Mutlipass Configuration.
for NODE in ${NODES}; do
# Transfer cluster-helper.sh to the nodes.
multipass transfer ./helpers/cluster-helper.sh ${NODE}:
echo "-> Executing cluster-helper.sh functions on Ubuntu 20.04 Virtual Machine. [${NODE}]"
# Execute cluster-helper.sh on the nodes.
multipass exec ${NODE} -- bash -c 'cd $HOME'
multipass exec ${NODE} -- bash -c 'sudo chmod +x $HOME/cluster-helper.sh'
multipass exec ${NODE} -- bash -c './cluster-helper.sh install_libs'
multipass exec ${NODE} -- bash -c './cluster-helper.sh download_containerd_tarball'
multipass exec ${NODE} -- bash -c './cluster-helper.sh verify_containerd_checksum '
multipass exec ${NODE} -- bash -c './cluster-helper.sh configure_containerd'
multipass exec ${NODE} -- bash -c './cluster-helper.sh create_containerd_kubelet_conf'
multipass exec ${NODE} -- bash -c 'sudo swapoff -a'
multipass exec ${NODE} -- bash -c "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
multipass exec ${NODE} -- bash -c 'sudo modprobe br_netfilter'
multipass exec ${NODE} -- bash -c 'sudo sysctl net.bridge.bridge-nf-call-iptables=1'
multipass exec ${NODE} -- bash -c 'sudo echo 1 |  sudo tee  /proc/sys/net/ipv4/ip_forward'
multipass exec ${NODE} -- bash -c 'sudo systemctl enable kubelet.service'
done