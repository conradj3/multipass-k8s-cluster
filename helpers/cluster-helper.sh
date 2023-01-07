#!/bin/bash
set -e

# Set default versions for containerd, runc and cni.
containerdVersion=1.6.0
runcVersion=1.1.4
cniVersion=1.1.1

# Install Cluster Libraries and Kubernetes Repositories / Tools (kubeadm, kubectl, kubelet)
function install_libs {
  # Update package list and install libraries and tools
  sudo apt-get -qq update && sudo apt-get -y install -y libseccomp2 apt-transport-https curl git vim net-tools netcat || return 1

  # Add the Kubernetes GPG key
  sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - || return 1

  # Add the Kubernetes package repository
  sudo touch /etc/apt/sources.list.d/kubernetes.list
  cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  sudo apt-get -qq update || return 1

  # Install Kubernetes tools
  sudo apt-get -y install -y kubelet kubeadm kubectl || return 1
  sudo apt-mark hold kubelet kubeadm kubectl || return 1
}

function install_helm {
  # Fetch the latest release version of Helm
  latest_version=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)

  # Download the Helm binary
  curl -L https://get.helm.sh/helm-${latest_version}-linux-amd64.tar.gz -o helm.tar.gz

  # Extract the Helm binary
  tar -zxvf helm.tar.gz

  # Move the Helm binary to /usr/local/bin
  sudo mv linux-amd64/helm /usr/local/bin/helm

  # Clean up
  rm -rf linux-amd64 helm.tar.gz
}

# Download Containerd Tarball.
function download_containerd_tarball {
  echo '-> Downloading  containerd ${containerdVersion}'
  sudo wget https://github.com/containerd/containerd/releases/download/v${containerdVersion}/containerd-${containerdVersion}-linux-amd64.tar.gz
}

# Verify Containerd Tarball Checksum.
function verify_containerd_checksum {
  localSha=$(sha256sum containerd-${containerdVersion}-linux-amd64.tar.gz | awk '{ print $1 }')
  # Validate the checksum
  remoteSha=$(curl -sSL https://github.com/containerd/containerd/releases/download/v${containerdVersion}/containerd-${containerdVersion}-linux-amd64.tar.gz.sha256sum | awk '{ print $1 }')
  if [ $localSha = $remoteSha ]; then
    echo '-> [Success] Tarbal Checksum Matched!'
  else
    echo '--> [Error] Tarbal Checksum Mismatched!'
  fi
}

# Configure Containerd, Runc and CNI.
function configure_containerd {
  # Make sure the containerd version and runc version variables are set
  if [ -z "${containerdVersion}" ] || [ -z "${runcVersion}" ] || [ -z "${cniVersion}" ]; then
    echo "Error: containerdVersion, runcVersion, and cniVersion must be set"
    return 1
  fi

  # Display the contents of the containerd tarball
  echo '-> Displaying containerd tarball contents...'
  sudo tar -tf containerd-${containerdVersion}-linux-amd64.tar.gz

  # Extract the tarball to /usr/local
  echo '-> Extracting containerd tarball to /usr/local...'
  sudo tar Czxvf /usr/local containerd-${containerdVersion}-linux-amd64.tar.gz

  # Fetch the containerd.service file
  echo '-> Fetching containerd.service...'
  sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /usr/lib/systemd/system/containerd.service

  # Reload the system manager configuration
  sudo systemctl daemon-reload

  # Start the containerd service
  echo '-> Starting containerd.service...'
  sudo systemctl start containerd

  # Fetch the runc binary
  echo '-> Fetching runc...'
  sudo wget https://github.com/opencontainers/runc/releases/download/v${runcVersion}/runc.amd64

  # Install the runc binary to /usr/local/sbin/runc
  echo '-> Installing runc to /usr/local/sbin/runc...'
  sudo install -m 755 runc.amd64 /usr/local/sbin/runc

  # Create the directory for the containerd config file
  sudo mkdir -p /etc/containerd/

  # Generate the default containerd config and write it to /etc/containerd/config.toml
  echo '-> Configuring Containerd config...'
  containerd config default | sudo tee /etc/containerd/config.toml

  # Enable systemd cgroups in the containerd config
  echo '-> Setting Kubernetes C Group to Containerd...'
  sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

  # Restart the containerd service
  sudo systemctl restart containerd

  # Create the directory for the CNI plugins
  sudo mkdir -p /opt/cni/bin/

  # Fetch the CNI plugin tarball
  echo '-> Fetching Container Networking CNI...'
  sudo wget https://github.com/containernetworking/plugins/releases/download/v${cniVersion}/cni-plugins-linux-amd64-v${cniVersion}.tgz

  # Extract the CNI plugins to /opt/cni/bin
  echo '-> Installing Container Networking CNI...'
  sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v${cniVersion}.tgz

  # Restart the containerd service
  sudo systemctl restart containerd

}

# Configure Containerd Kubelet Config.
function create_containerd_kubelet_conf {
  echo '-> Creating containerd kubelet config...'
  cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/0-containerd.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF
  sudo systemctl daemon-reload
}

# Start Kubernetes Cluster.
function start_cluster {
  echo '-> Starting Kubernetes Cluster...'
  sudo modprobe br_netfilter
  sudo sysctl net.bridge.bridge-nf-call-iptables=1
  echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
  sudo kubeadm init
}

# Configure Kubectl.
function configure_kubectl_conf {
  echo '-> Setting up kubectl config...'
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

"$@"
