# Setup cluster
Setup cluster is for creating kubernetes cluster on compute instances with kubeadm.

Create a cluster with the following configuration based on [official start guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

- CRI : [containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)
- CNI : [flannel](https://github.com/flannel-io/flannel)
- Single control-plane node (no high availability).


It is recommended to use the project for development environment.


# Requirements
- At least one instance for contorol-plane is required. The number of worker node is optional.
- Instance type have to be more than 2 GiB RAM and 2 vCPU. ([Requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#before-you-begin))

- [Ansible kubernets.core modules](https://galaxy.ansible.com/kubernetes/core?extIdCarryOver=true&sc_cid=701f2000001OH6uAAG) must be installed on machine running the playbook. If you don't install yet, install with `ansible-galaxy collection install kubernetes.core`.


# Usage

## Set inventory
In `inventory` in top directory, you need edit the host definition.

- `control_plane.hosts.controller`
    - An instance belonging to the control-plane, on which a cluster is created.

- `worker.hosts.worker` (optional)
    - An instance added to cluster as a worker node.

---
Set the variables for each host.

- ansible_host: Global IPv4 address of an instance.
- ansible_user: Username on an instance.
- ansible_port: SSH port. Default to 22.
- ansible_ssh_private_key_file: Path to the private key file on the host where run the playbook.
- ansible_become_password: If run sudo command with a password on an instance, Set the password.


The example of inventory are the following.
```yaml
---
all:
  children:
    control_plane:
      hosts:
        controller:
          ansible_host: 35.78.70.178
          ansible_user: rocky
          ansible_ssh_port: 22
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
    worker:
      hosts:
        worker1:
          ansible_host: xx.xx.xx.xx
          ansible_user: ec2-user
          ansible_ssh_port: 22
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
```


## Create cluster
Run the following command to create kubernetes cluster on controller.
```
$ ansible-playbook setup_cluster.yml
```

After the playbook successfully finished, check that status of controller is ready.
```
[rocky@ip-172-31-15-107 ~]$ kubectl get node
NAME                                               STATUS   ROLES           AGE     VERSION
ip-172-31-15-107.ap-northeast-1.compute.internal   Ready    control-plane   2m25s   v1.24.3
```

## Add worker node to cluster (optional)

Run the following command to create kubernetes cluster on controller.
```
$ ansible-playbook add_worker.yml
```

After the playbook successfully finished, check that the worker node is added as node on control-plane node.
```
[rocky@ip-172-31-15-107 ~]$ kubectl get node
NAME                                               STATUS   ROLES           AGE     VERSION
ip-172-31-10-24.ap-northeast-1.compute.internal    Ready    <none>          70s     v1.24.3
ip-172-31-15-107.ap-northeast-1.compute.internal   Ready    control-plane   2m25s   v1.24.3
```

## Support distributions
- rhel-based distribution (such as Rocky linux)
