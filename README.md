# setup kube-cluster
This repository is for setting up a kubernetes cluster for development on cloud instances (AWS EC2) by `Ansible`. It is useful to build a cluster in the following environments.

- Cluster on EC2 instances instead of cloud-managed service (EKS).
- Baremetal cluster on your local environment such as raspberry pi.


A node that runs Ansible (referred to as executor here) creates the following components by using kubeadm.

- Control node with control plane components
- Worker nodes (optional)

![Cannot load image](docs/images/component.png)


# Requirements
An executor requires ansible module.

- ansible >= 2.10.0
- ansible-playbook >= 2.10.0

The control node and workers need to meet [kubernetes hardware requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin).


# Quickstart
Clone the repository.    harbor_storage_class: "openebs-hostpath"


```
git clone https://github.com/git-ogawa/setup_kube_cluster
cd setup_kube_cluster
```

In `inventory`, set global ip address, username, port and ssh key of your instance under `control_node` section.

```yml
---
all:
  ...
  children:
    control_plane:
      hosts:
        control_node:
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

The setup playbook installs the necessary tools, builds the cluster, and deploys the following components. You can manage whether each component is installed during the installation process by editing the inventory file. See [setup_cluster.md](docs/setup_cluster.md) for details.


| Component | Used for | Installed by default |
| - | - | - |
| Nginx controller | Ingress controller | yes |
| OpenEBS | Storage | no |
| Longhorn | Storage | no |
| Kubevious | Dashboard | no |
| Tekton | CI/CD platform | no |
| Argocd | CD tool | no |
| Harbor | Image registry | no |
| Gitea | Git server | no |


# Support distributions
The following distribution (platform) instances are supported.

- RHEL-based distribution (such as rocky linux)
- Ubuntu 22.04
- Amazon linux
  - Supported only to install CLI commands such as kubectl
