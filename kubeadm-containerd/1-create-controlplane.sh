#!/bin/bash
# Create Ubuntu 20.04 Controlplane.

echo "-> Creating Ubuntu 20.04 Virtual Machine. [controlplane]"
multipass launch 20.04 --name controlplane --cpus 2 --mem 4G --disk 30G

echo "-> Installing tools on Ubuntu 20.04 Virtual Machine. [controlplane]"
# Transfer cluster-helper.sh to the controlplane.
multipass transfer ./helpers/cluster-helper.sh controlplane:

# Execute cluster-helper.sh on the controlplane.
echo "-> Executing cluster-helper.sh functions on Ubuntu 20.04 Virtual Machine. [controlplane]"
multipass exec controlplane -- bash -c 'sudo chmod +x $HOME/cluster-helper.sh'
multipass exec controlplane -- bash -c 'cd $HOME'
multipass exec controlplane -- bash -c './cluster-helper.sh install_libs'
multipass exec controlplane -- bash -c './cluster-helper.sh install_helm'
multipass exec controlplane -- bash -c './cluster-helper.sh download_containerd_tarball'
multipass exec controlplane -- bash -c './cluster-helper.sh verify_containerd_checksum '
multipass exec controlplane -- bash -c './cluster-helper.sh configure_containerd'
multipass exec controlplane -- bash -c './cluster-helper.sh create_containerd_kubelet_conf'
multipass exec controlplane -- bash -c './cluster-helper.sh start_cluster'
multipass exec controlplane -- bash -c './cluster-helper.sh configure_kubectl_conf'

# Save to local output admin.conf -> kubeconfig.yaml
multipass exec controlplane -- bash -c 'sudo cat /etc/kubernetes/admin.conf' > kubeconfig.yaml

# Install Calico
echo "-> Installing Calico Meow. [controlplane]"
multipass exec controlplane -- bash -c 'kubectl create -f https://docs.projectcalico.org/manifests/calico-typha.yaml'
multipass exec controlplane -- bash -c 'kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml'
multipass exec controlplane -- bash -c 'kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml'


# Use local kubeconfig.yaml to get nodes.
KUBECONFIG=kubeconfig.yaml kubectl get nodes -o wide
