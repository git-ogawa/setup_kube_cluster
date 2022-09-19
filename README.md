# setup ec2
This repository is for setting up a kubernetes cluster and the necessary packages on compute instances of the cloud service (AWS EC2).

You can install (or create) the following components on instances by `Ansible`.

- Docker, Containerd
- kubernetes (CLI)
- kubernetes cluster with kubeadm
- helm
- nginx ingress controller
- tekton
- argocd



# Table of contents

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=2 orderedList=false} -->

<!-- code_chunk_output -->

- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Usage](#usage)
- [Components](#components)
  - [Kubernetes cluster](#kubernetes-cluster)
  - [Helm](#helm)
  - [Docker](#docker)
  - [Tekton](#tekton)
  - [Argocd](#argocd)
- [Support distributions](#support-distributions)

<!-- /code_chunk_output -->


# Requirements
- ansible >= 2.10.0
- ansible-playbook >= 2.10.0

# Quickstart
Clone the repository.

```
git clone https://github.com/git-ogawa/setup_ec2
cd setup_ec2
```

In `inventory`, set global ip address, username, port and ssh key of your instance under `controller` section.

```yml
---
all:
  ...
  children:
    control_plane:
      hosts:
        controller:
          ansible_host: 10.10.10.10  # Global IPv4 address
          ansible_user: ubuntu  # Username
          ansible_ssh_port: 22  # SSH port
          ansible_ssh_private_key_file: ~/.ssh/id_rsa  # Path to key
```

To add worker nodes to cluster, set values for worker1, worker2 and more in the same way under `worker` section.


Then, run the following command to create the cluster.
```
$ ansible-playbook setup.yml
```

# Usage
See [setup_cluster.md](docs/setup_cluster.md) for details.

# Components
The list of components to be installed on nodes by playbooks. See [setup_cluster.md](docs/setup_cluster.md) for details.


## Kubernetes cluster
The latest version of the following components will be installed with package manager (apt, dnf).

- kubelet
- kubectl
- kubeadm

The kuebernetes cluster are created with kubeadm.

- CRI : Containerd
- CNI : Flannel

## Helm
Helm binary is installed on all nodes.

## Docker
The latest version of the following components will be installed with package manager (apt, dnf).

- docker
- `podman` will be installed instead of docker on RHEL-clone OS (such as Rocky linux).

## Tekton
Deploy tekton components to a cluster from manifest file.

## Argocd
Deploy argocd components to a cluster from manifest file.

# Support distributions
The following distribution (platform) instances are supported.

- RHEL-based distribution (such as rocky linux)
- Ubuntu 22.04
- Amazon linux
  - Supported only to install commands
