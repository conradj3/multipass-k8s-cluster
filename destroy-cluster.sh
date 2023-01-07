#!/bin/bash
# Delete the Multipass VMs.
multipass delete controlplane worker1 worker2
multipass purge
rm kubeconfig.yaml