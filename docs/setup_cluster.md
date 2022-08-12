
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Setup cluster](#setup-cluster)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Set inventory](#set-inventory)
  - [Create cluster](#create-cluster)
  - [Add worker nodes to cluster (optional)](#add-worker-nodes-to-cluster-optional)
  - [Deploy ingress controller](#deploy-ingress-controller)
    - [Access from outside cluster](#access-from-outside-cluster)
- [Support distributions](#support-distributions)

<!-- /code_chunk_output -->


# Setup cluster
Setup cluster is to create a kubernetes cluster on ompute instances with kubeadm. This makes it easy to create and reset clusters for testing and development.


Create a cluster with the following configuration based on [official start guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

- CRI : [containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)
- CNI : [flannel](https://github.com/flannel-io/flannel)
- Single control-plane node (no high availability).
- Worker nodes (optional)
- nginx ingress controller (optional)

It is recommended to use the project for development environment.


# Requirements
- At least one instance for contorol-plane is required. The number of worker node is optional.
- Instance type have to be more than 2 GiB RAM and 2 vCPU. ([Requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#before-you-begin))
- Check that [the required ports](https://kubernetes.io/docs/reference/ports-and-protocols/) are open in security group.
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

## Add worker nodes to cluster (optional)

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

## Deploy ingress controller
As an additional option, you can deploy [nginx ingress controller](https://github.com/kubernetes/ingress-nginx) to access to the applications on instances from outside the cluster.

Run the following playbook to deploy manifest-based nginx controller (See https://kubernetes.github.io/ingress-nginx/deploy/#quick-start).

```
$ ansible-playbook setup_ingress_controller.yml
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

To check that you can access the application on instances from outside the cluster, you can deploy the example application (nginx) by the following command. `aws_alb_dns`, is the DNS name above, is required.

```
$ ansible-playbook setup_example_app.yml -e aws_alb_dns=[DNS name]
```

After deployed, you can access the app by `http://[dns_name]` in web browser.


To delete the app from the cluster, run the same playbook with `-e example_app_state=absent`.
```
$ ansible-playbook setup_example_app.yml -e example_app_state=absent
```


# Support distributions
- RHEL-based distribution (such as Rocky linux)
