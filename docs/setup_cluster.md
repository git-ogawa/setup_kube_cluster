
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Setup cluster](#setup-cluster)
- [Requirements](#requirements)
- [Prerequisites](#prerequisites)
- [Run](#run)
- [Steps](#steps)
  - [Create cluster](#create-cluster)
  - [Add worker nodes](#add-worker-nodes)
  - [Deploy ingress controller](#deploy-ingress-controller)
    - [Access from outside cluster](#access-from-outside-cluster)
  - [OpenEBS](#openebs)
  - [Kubevious](#kubevious)
  - [Argocd](#argocd)
  - [Tekton](#tekton)
  - [Harbor](#harbor)
  - [Gitea](#gitea)
  - [Velero](#velero)
  - [Stackstorm](#stackstorm)
- [Clean up cluster](#clean-up-cluster)

<!-- /code_chunk_output -->


# Setup cluster
Setup cluster is to create a kubernetes cluster on compute instances with kubeadm. This makes it easy to create and destroy clusters for testing and development.


Create a cluster with the following configuration based on [official start guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

- CRI : [Containerd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)
- CNI : [Calico](https://github.com/projectcalico/calico) or [Flannel](https://github.com/flannel-io/flannel)
- Clsuter
    - Single control-plane node (no high availability).
    - [HA cluster by stacked control plane nodes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
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

- [Ansible kubernetes.core modules](https://galaxy.ansible.com/kubernetes/core?extIdCarryOver=true&sc_cid=701f2000001OH6uAAG) must be installed on machine running the playbook. If you don't install yet, install with `ansible-galaxy collection install kubernetes.core`.

Target nodes

- At least one instance for control-plane is required. The number of worker node is optional.
- Instance type have to be more than 2 GiB RAM and 2 vCPU. ([Requirements](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#before-you-begin))
- Check that [the required ports](https://kubernetes.io/docs/reference/ports-and-protocols/) are open in security group.
- It is recommended that more than 10 GB of storage.


Others

- On cloud instances, check that ports used by each component are open by security group.


# Prerequisites

At first, you need edit the host definition in `inventory` in top directory.

- `control_plane.hosts.control_plane`
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
        control_node:
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

If you want to install the CI/CD components, set the values to `true`.

```yaml
all:
  vars:
    openebs_install: true
    longhorn_install: true
    kubevious_install: true
    argocd_install: true
    tekton_install: true
    gitea_install: true
    harbor_install: true
    kube_prometheus_install: true
    octant_install: true
```

# Run
Run playbook `setup.yml` to create a cluster and deploy necessary components at once.
```
$ ansible-playbook setup.yml
```
The following steps will be run in setup process. If you want to run a part of steps, see the each section in [Steps](#steps).

- Create a cluster with kubeadm
- Add worker nodes to the cluster (if exists)
- Deploy components


# Steps

## Create cluster
Run `setup.yml` with tag `cluster` to create a kubernetes cluster on control_node with kubeadm.
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
To access the application on instances from outside the cluster, you need to create Application Load Balancer (ALB) on AWS after deployed ingress control_node.

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


## OpenEBS
OpenEBS is installed with helm and create storage class to use local PV hostpath. If you don't install, set `openebs_install` to false in `inventory`.


## Kubevious
Kubevious that is dashboard for visualizing the cluster resources is installed with helm.


Some settings can be changed to edit values in `group_vars/all.yml`. The list of parameters are the following.

| parameters | description | default |
| - | - | - |
| kubevious_release_name | Release name | kubevious |
| kubevious_namespace | Namespace | kubevious |



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
| harbor_storage_class | StorageClass used in persistentVolumeClaim | empty |


By default, PersistentVolume whose type is hostpath is created on the node and persistentVolumeClaim uses them. If `openebs` is already installed and used as pv provisioner, set the `harbor_pv_enabled` and `harbor_storage_class` in `group_vars/all.yml` as follows.

```yaml
harbor_storage_class: "openebs-hostpath"
harbor_pv_enabled: false
```


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


By default, PersistentVolume whose type is hostpath is created on the node and persistentVolumeClaim uses them. If `openebs` is already installed and used as pv provisioner, set the `gitea_pv_enabled` and `gitea_storage_class` in `group_vars/all.yml` as follows.

```yaml
gitea_storage_class: "openebs-hostpath"
gitea_pv_enabled: false
```

## Velero

Velero is an open source tool to safely backup and restore, perform disaster recovery, and migrate Kubernetes cluster resources and persistent volumes. In this project, user can use velero to restore a cluster from a backup created in advanced instead of installing components on setup. This will be useful to recreate a cluster repeatedly for test or development.

To restore a cluster from backup on setup, user have to create a backup to cloud providers using velero in advance. Only the aws provider is supported currently in this project. See [velero-plugin-for-aws setup](https://github.com/vmware-tanzu/velero-plugin-for-aws#setup) how to create a backup and store them in S3.


Make sure that a backup is stored and available in S3 using velero as below.

```
$ velero backup get
NAME                  STATUS      ERRORS   WARNINGS   CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
full-cluster-backup   Completed   0        8          2023-05-15 04:53:09 +0000 UTC   29d       default            <none>
```

To use the backup to create cluster on setup, set the following variables in `inventory`.

- velero_install : Set `true` to install velero in the cluster.
- velero_provider: Set `aws`.
- velero_aws_bucket : The S3 bucket name. The value must match the bucket name in which the backup is stored.
- velero_aws_region : The aws region. The region must match the one in which the bucket is created.
- velero_access_key_id : The access key of IAM user. The user must have permissions to access S3.
- velero_secret_key_id : The secret access key of IAM user. The user must have permissions to access S3.
- velero_backup_name : The name of backup. The name must match the resource name of velero backup (backups.velero.io) created in advance.
- velero_restore_name (optional) : The resource name of velero restore object. `full-cluster-restore` by default.

``` yaml
all:
  vars:
    ...
    velero_install: true
    velero_provider: aws
    velero_aws_bucket: velero-backup-bucket
    velero_aws_region: us-east-1
    velero_access_key_id: set-your-access-key
    velero_secret_access_key: set-your-secret-access-key
    velero_backup_name: full-cluster-backup
    velero_restore_name: full-cluster-restore  # Optional
```

Then run `setup.yml` to create a cluster and install velero.

```
$ ansible-playbook setup.yml
```

The velero pod for restore will be created after successfully finished. Run `tools/velero/restore.yml` to restore the cluster from the velero backup. By this play, all kubernetes resources included in the backup will be created in your cluster.

```
$ ansible-playbook tools/velero/restore.yml
```

Note: The restore is executed with policy `--existing-resource-policy=update`. See [Restore existing resource policy](https://velero.io/docs/v1.11/restore-reference/#restore-existing-resource-policy).


## Stackstorm

StackStorm is a platform for integration and automation across services and tools. To install stackstorm in the cluster, set the following variables in `inventory`.

- st2_install : Set `true` to install stackstorm in the cluster.
- st2_password: A password of admin user `st2admin`.

``` yaml
all:
  vars:
    st2_install: true
    st2_password: Ch@ngeMe
```

Then run `setup.yml` to create a cluster and install stackstorm. The tasks will take a while since many components in stackstorm are installed.

```
$ ansible-playbook setup.yml -t st2
```

If users want to install additional st2 packs in the k8s cluster after stackstorm is installed, there are two ways (See [Install custom st2 packs in the cluster](https://github.com/StackStorm/stackstorm-k8s#install-custom-st2-packs-in-the-cluster)). In this project, persistent volume is used as shared volume to store the packs. To enable shared volume, set the following environment variables in `inventory`. and make sure that PV provisioner such as openebs are installed in advance and default storage class is set.

- st2_persistent_volume_enabled : Set `true` to create persistent volume claim on setup.
- st2_persistent_volume_pack_name : The pvc name for packs.
- st2_persistent_volume_pack_storage : Volume size of storage for packs.
- st2_persistent_volume_config_name : The pvc name for configs.
- st2_persistent_volume_config_storage : Volume size of storage for configs.
- st2_persistent_volume_virtualenv_name : The pvc name for virtualenvs.
- st2_persistent_volume_virtualenv_storage : Volume size of storage for virtualenvs.

``` yaml
all:
  vars:
    ...
    st2_persistent_volume_enabled: true
    st2_persistent_volume_pack_name: pvc-st2-packs
    st2_persistent_volume_pack_storage: 5Gi
    st2_persistent_volume_config_name: pvc-st2-configs
    st2_persistent_volume_config_storage: 5Gi
    st2_persistent_volume_virtualenv_name: pvc-st2-virtualenvs
    st2_persistent_volume_virtualenv_storage: 5Gi
```

Run setup.yml to install stackstorm and pvc.


# Clean up cluster
To clean up the cluster, run the `cleanup_cluster.yml`. This play runs `kubeadm reset` on workers and controller.

```
$ ansible-playbook playbooks/cleanup_cluster.yml
```
