
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Setup cluster](#setup-cluster)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Set inventory](#set-inventory)
  - [Setup](#setup)
- [Steps](#steps)
  - [Create cluster](#create-cluster)
  - [Add worker nodes](#add-worker-nodes)
  - [Deploy ingress controller](#deploy-ingress-controller)
    - [Access from outside cluster](#access-from-outside-cluster)
  - [Argocd](#argocd)
  - [Tekton](#tekton)
  - [Harbor](#harbor)
  - [Gitea](#gitea)
  - [Clean up cluster](#clean-up-cluster)

<!-- /code_chunk_output -->


# Setup cluster
Setup cluster is to create a kubernetes cluster on ompute instances with kubeadm. This makes it easy to create and reset clusters for testing and development.


Create a cluster with the following configuration based on [official start guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

- CRI : [Containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)
- CNI : [Flannel](https://github.com/flannel-io/flannel)
- Single control-plane node (no high availability).
- Worker nodes (optional)
- nginx ingress controller (optional)

The following CI/CD components can be installed on setup.

- Tekton
- Argocd
- Harbor
- Gitea


It is recommended to use the project for development environment.


# Requirements
The machine where the playbooks will be run

- [Ansible kubernets.core modules](https://galaxy.ansible.com/kubernetes/core?extIdCarryOver=true&sc_cid=701f2000001OH6uAAG) must be installed on machine running the playbook. If you don't install yet, install with `ansible-galaxy collection install kubernetes.core`.

Target nodes

- At least one instance for contorol-plane is required. The number of worker node is optional.
- Instance type have to be more than 2 GiB RAM and 2 vCPU. ([Requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#before-you-begin))
- Check that [the required ports](https://kubernetes.io/docs/reference/ports-and-protocols/) are open in security group.


# Usage

## Set inventory
At first, you need edit the host definition in `inventory` in top directory.

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


The example of inventory when control node 1x and worker node 1x is the following.
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

By default, CI/CD components are deployed to the cluster on setup. If you don't install the components, Set the value to `false`.

```yaml
all:
  vars:
    argocd_install: true
    tekton_install: true
    gitea_install: true
    harbor_install: true
```


## Setup
Run playbook `setup.yml` to create a cluster and deploy necessary components at once.
```
$ ansible-playbook setup.yml
```
The following steps will be run in setup process. If you want to run a part of steps, see the each section in [Steps](#steps).

- Create a clsuter with kubeadm
- Add worker nodes to the cluster (if exists)
- Deploy nginx ingress controller
- Deploy argocd
- Deploy tekton
- Deploy harbor
- Deploy gitea

# Steps

## Create cluster
Run `setup.yml` with tag `cluster` to create a kubernetes cluster on controller with kubeadm.
```
$ ansible-playbook setup.yml -t cluster
```

After the playbook successfully finished, check that status of controller is ready.
```
[rocky@ip-172-31-15-107 ~]$ kubectl get node
NAME                                               STATUS   ROLES           AGE     VERSION
ip-172-31-15-107.ap-northeast-1.compute.internal   Ready    control-plane   2m25s   v1.24.3
```

## Add worker nodes
Run `setup.yml` with tag `add_worker` to add instances to the cluster as worker nodes. The worker nodes must be defined in the `inventory` in advance.
```
$ ansible-playbook setup.yml -t add_worker
```

After the playbook successfully finished, check that the instances are added as worker nodes.
```
[rocky@ip-172-31-15-107 ~]$ kubectl get node
NAME                                               STATUS   ROLES           AGE     VERSION
ip-172-31-10-24.ap-northeast-1.compute.internal    Ready    <none>          70s     v1.24.3
ip-172-31-15-107.ap-northeast-1.compute.internal   Ready    control-plane   2m25s   v1.24.3
```

## Deploy ingress controller
As an additional option, you can deploy [nginx ingress controller](https://github.com/kubernetes/ingress-nginx) to access to the applications on instances from outside the cluster.

Run `setup.yml` with tag `ingress` to deploy manifest-based nginx ingress controller (See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start).

```
$ ansible-playbook setup.yml -t ingress
```

Service: `ingress-nginx-controller` will be created in the cluster.
```
$ kubectl get svc -A
NAMESPACE          NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                              AGE
ingress-nginx      ingress-nginx-controller             LoadBalancer   10.106.239.169   <pending>     80:32323/TCP,443:30398/TCP           70m
ingress-nginx      ingress-nginx-controller-admission   ClusterIP      10.110.88.234    <none>        443/TCP                              70m
```

NodePort of ingress-nginx-controller is fixed to `32323` by default. If you change this value, set extra variables `nginx_ingress_node_port` when running the playbook.
```
$ ansible-playbook setup_ingress_controller.yml -e nginx_ingress_node_port=[port_number]
```

### Access from outside cluster
To access the application on instances from outside the cluster, you need to create Application Load Balancer (ALB) on AWS after deployed ingress controller.

Note the following.

- The port of an instance in the target groups specifies the `nodePort` above (32323 by default).
- Check that [DNS name] of the created ALB (for example `[ALB-name]-123456789.ap-northeast-1.elb.amazonaws.com`).

To check that you can access the application on instances from outside the cluster, you can deploy the example application (nginx) by the following command. `example_app_host`, is the DNS name above, is required.

```
$ ansible-playbook playbooks/setup_example_app.yml -e example_app_host=[DNS name]
```

After deployed, you can access the app by `http://[dns_name]` in web browser.


To delete the app from the cluster, run the same playbook with `-e example_app_state=absent`.
```
$ ansible-playbook playbooks/setup_example_app.yml -e example_app_state=absent
```

## Argocd
Argocd components (server, dashboard and others) and argocd CLI are installed on all nodes.

To deploy argocd, Run the play `setup.yml` with tag `argocd`.
```
$ ansible-playbook setup.yml -t argocd
```


## Tekton
Deploy the following tekton components to a cluster.

- pipeline
- dashboard
- tekton CLI (tkn)

To deploy tekton, Run the play `setup.yml` with tags `tekton`.
```
$ ansible-playbook setup.yml -t tekton
```

## Harbor
Harbor components are installed with helm. To deploy harbor, Run the play `setup.yml` with tags `harbor`.

```
$ ansible-playbook setup.yml -t harbor
```

Some settings about harbor server can be changed to edit values in `group_vars/all.yml`. The list of parameters are the following.

| parameters | description | default |
| - | - | - |
| harbor_release_name | Release name | harbor |
| harbor_namespace | Namespace | harbor |
| harbor_domain | Server domain name of harbor | core.harbor.domain |
| harbor_node_port | HTTPS port of harbor nodePort | 30003 |
| harbor_admin_password | Admin user password | Harbor12345 |


PersistentVolume to store data set `host_path` and directory `/opt/kube/harbor/[components]` will be created on all nodes in cluster. The path can be changed to `harbor_host_path_dir`.


## Gitea
Gitea components are installed with helm. To deploy gitea, Run the play `setup.yml` with tags `gitea`.

```
$ ansible-playbook setup.yml -t gitea
```

Some settings about gitea server can be changed to edit values in `group_vars/all.yml`. The list of parameters are the following.

| parameters | description | default |
| - | - | - |
| gitea_release_name | Release name | gitea |
| gitea_namespace | Namespace | gitea |
| gitea_admin_username | Admin user name | gitea_admin |
| gitea_admin_password | Admin user password | r8sA8CPHD9!bt6d |
| gitea_admin_email | Admin user email | gitea@local.domain |
| gitea_config_server_domain | Server domain name | git.example.com |


PersistentVolume to store data set `host_path` and directory `/opt/kube/gitea/[components]` will be created on all nodes in cluster. The path can be changed to `gitea_host_path_dir`.



## Clean up cluster
To clean up the cluster, run the `cleanup_cluster.yml`. This play runs `kubeadm reset` on workers and controller.

```
$ ansible-playbook playbooks/cleanup_cluster.yml
```
