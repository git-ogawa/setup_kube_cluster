
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=2 orderedList=false} -->

<!-- code_chunk_output -->

- [setup ec2](#setup-ec2)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Preparation](#preparation)
  - [Install commands](#install-commands)
  - [Kubernetes cluster](#kubernetes-cluster)
  - [Tekton](#tekton)
- [Support distributions](#support-distributions)

<!-- /code_chunk_output -->

# setup ec2
This is a repository for set up compute instances of cloud service (AWS EC2).

You can install (or create) the following components on instances by `Ansible`.

- docker
- kubernetes (CLI)
- kubernetes cluster with kubeadm
    - nginx ingress controller
    - tekton

# Requirements
- ansible >= 2.10.0
- ansible-playbook >= 2.10.0

# Usage

## Preparation
Make sure that make a key pair for ssh and log in with ssh to a target instance from the machine where the ansible playbook will be run.


At first, clone this project.
```
git clone https://github.com/git-ogawa/setup_ec2
cd setup_ec2
```

Then, Edit `inventory` in top directory to set following variables accroding to your instance.

- ansible_host: Global IPv4 address of an instance.
- ansible_user: Username on an instance.
- ansible_port: SSH port. Default to 22.
- ansible_ssh_private_key_file: Path to the private key file on the host where run the playbook.
- ansible_become_password: If run sudo command with a password on an instance, Set the password.

To install with multiple instances at the same time, Set values for worker2, worker3 and more in the same way.

```yaml
---
all:
  children:
    worker:
      hosts:
        worker1:
          ansible_host: xx.xx.xx.xx
          ansible_user: ubuntu
          ansible_ssh_port: 22
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
          ansible_become_password: xxxx
        # worker2:
          # ansible_host: xx.xx.xx.xx
          # ....
```


## Install commands
To install CLI commands (docker, kubernetes) of components on your instances, run the following playbook.

```
$ ansible-playbook install.yml
```

To install only specified component, use `-t` options
```
# Install only docker
$ ansible-playbook install.yml -t docker

# Install only kubernetes
$ ansible-playbook install.yml -t kubernetes
```


### docker
The latest version of the following components will be installed with package manager (apt, dnf).

- docker
- `podman` will be installed instead of docker on RHEL-clone OS (such as Rocky linux).


### kubernetes
The latest version of the following components will be installed with package manager (apt, dnf).

- kubelet
- kubectl
- kubeadm


## Kubernetes cluster
Create a kubernetes cluster with kubeadm. See [setup_cluster.md](docs/setup_cluster.md) for details.


## Tekton
Deploy tekton components to a cluster. See [setup_cluster.md](docs/setup_cluster.md#tekton-optional) for details.

# Support distributions
The following distribution (platform) instances are supported.

- RHEL-based distribution (such as rocky linux)
- Ubuntu
  - Supported only to install commands
- Amazon linux
  - Supported only to install commands
