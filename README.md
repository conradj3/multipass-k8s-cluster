# Multipass Ubuntu 20.04 Kubernetes Cluster 

The following code produces a Kubernetes environment consisting of `controlplane` and `worker1` and `worker2` nodes.

## Controlplane

### Resources

- 2 CPUs
- 4 GB Memory
- 30 GB Storage

### Software

- Kubernetes 1.26
- Containerd 1.6.0
- Kubelet
- Kudeadm
- Kubectl
- Runc 1.1.4
- CNI Plugins 1.1.1
- Calico Typha
- Calico Tigera Operator
- Calico Custom Resources

### Libraries and Packages 

- libseccomp2 
- apt-transport-https 
- curl 
- git 
- vim 
- net-tools 
- netcat

## Worker Nodes

The worker node multipass configuration uses the same components as the controlplane.  There is an auto join to `controlplane` that is performed so the cluster powers up in a working status.

## Resources

- 2 CPUs
- 4 GB Memory
- 30 GB Storage

## Start Cluster

There is convient `create-cluster.sh` script which will create your cluster.

```sh
make
```

## Cleanup Cluster

There is a `destroy-cluster.sh` which will tear down your Kubernetes cluster entirely.

```sh
make destroy
```

## Contribute

More to come in the feature as many of these components will be controlled through a configuration file for ease of modificaton.  If you presently want to make modifications it will be the shell scripts directly.
