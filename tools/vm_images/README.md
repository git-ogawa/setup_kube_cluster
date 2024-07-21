


- [VM images](#vm-images)
- [Prerequisites](#prerequisites)
  - [Openstack](#openstack)
    - [cloud.yaml](#cloudyaml)
    - [vars.yml](#varsyml)
- [Usage](#usage)
  - [Examples](#examples)
    - [Openstack](#openstack-1)
- [Create k8s cluster on VM created from the images](#create-k8s-cluster-on-vm-created-from-the-images)


# VM images

Since it takes a little time to install the packages required for k8s cluster, it is more effective to create a VM image containing the required packages (so-called Golden image) in order to reduce time spent to provisioning.
These playbooks are tools to create images or snapshots from the existing VM that have completed setup for k8s but yet created a cluster, and to quickly create cluster the next time.

# Prerequisites

The prerequisites for using this depends on which provider to use in order to create images. Support providers are the following.

- openstack


## Openstack

The openstack provider is used when the user uses the VMs on openstack. Create images from VMs on openstack as snapshot and store them on openstack image store (glance).
The following packages are required.

- openstack CLI

Install with pip.
```
pip install python-openstackclient
```

- [Ansible OpenStack Collection](https://galaxy.ansible.com/ui/repo/published/openstack/cloud/)

Install with ansible galaxy.
```
ansible-galaxy collection install openstack.cloud
```


### cloud.yaml

clouds.yaml is a configuration file that contains everything needed to connect to openstack cloud (see [openstack page](https://docs.openstack.org/python-openstackclient/pike/configuration/index.html) for details).
Cloud.yaml is required for execute node where run playbook to connect openstack server.
Cloud name is arbitrary but `auth` and the following fields are required.

```yml
clouds:
  kolla-admin:
    auth:
      auth_url: http://192.168.3.2:5000
      project_domain_name: Default
      user_domain_name: Default
      project_name: admin
      username: admin
      password: xxxyyyzz
```

### vars.yml

Define to create image from which server and other properties in `vars.yml`. The following field are needed.

- provider: Set `openstack`.
- openstack_cloud: Must match the cloud name in `clouds.yaml`.
- servers (list): Define server and image.

Supported field in servers are the following.

| Field | Description | Required |
| - | - | - |
| server_name | Name of openstack server | yes |
| image_name | Name of image create by the server above.<br> The image name must not be the same as the existing image on openstack.| yes |
| properties | Properties added to the image. Set key-value pairs. | no |


Examples

```yml
provider: openstack
openstack_cloud: kolla-admin
servers:
  - server_name: k8s-m1
    image_name: k8s-master_ubuntu-23.04_20240721
  - server_name: k8s-w1
    image_name: k8s-worker_ubuntu-23.04_20240721
    properties:
      os_type: linux
      os_distro: ubuntu
      os_version: "23.04"
      os_admin_user: debian
```


# Usage

To create image users need to install packages for k8s cluster. Create a VM as usual and set the host information in `inventory.yml` and put it in project root directory.

```yml
...
    control_plane:
      hosts:
        k8s-m1:
          ansible_host: 192.168.3.2
    worker:
      hosts:
        k8s-w1:
          ansible_host: 192.168.3.3
```

Set which VM to create the image from, the image name and other properties in `vars.yml` and put it in the current directory.
A configuration file for each provider is also required.

Then run `create_image.sh`. This script runs the following steps.

1. Install packages required for k8s cluster on VMs.
2. Stop VMs.
3. Create images or snapshots from the VMs and upload them to image store in cloud provider you selected.



## Examples

### Openstack

Set host information such as IP Address, user and etc. in `inventory.yml` of project root directory.

```yml
    control_plane:
      hosts:
        k8s-m1:
          ansible_host: 192.168.3.2
    worker:
      hosts:
        k8s-w1:
          ansible_host: 192.168.3.3
```

Prepare `clouds.yaml` to connect to the openstack.
```yml
clouds:
  kolla-admin:
    auth:
      auth_url: http://192.168.3.2:5000
      project_domain_name: Default
      user_domain_name: Default
      project_name: admin
      username: admin
      password: xxxyyyzz
```

Set server and image name in `vars.yml`.
```yml
provider: openstack
openstack_cloud: kolla-admin
servers:
  - server_name: k8s-m1
    image_name: k8s-master_ubuntu-23.04_20240721
  - server_name: k8s-w1
    image_name: k8s-worker_ubuntu-23.04_20240721
    properties:
      os_type: linux
      os_distro: ubuntu
      os_version: "23.04"
      os_admin_user: debian
```

Run `create_image.sh`.
```
./create_image.sh
```

When all tasks successfully finished the image would be created from each server and uploaded to the openstack.
```
$ openstack image list
+--------------------------------------+----------------------------------+--------+
| ID                                   | Name                             | Status |
+--------------------------------------+----------------------------------+--------+
| 6bd3c9b2-810e-4af0-9c33-fb57cf18fa6d | k8s-master_ubuntu-23.04_20240721 | active |
| 8058dce8-bb1d-4275-adda-7955a2f0d2df | k8s-worker_ubuntu-23.04_20240721 | active |
|--------------------------------------+----------------------------------+--------+
```



The status of servers would be `SHUTOFF` since the snapshot can be created only when server is stopped.
```
$ openstack server list -c ID -c Name -c Status
+--------------------------------------+------------+---------+
| ID                                   | Name       | Status  |
+--------------------------------------+------------+---------+
| 403d1e8b-d9f6-435d-9d65-ae7865b8fb91 | k8s-m1     | SHUTOFF |
| 3152301c-43ff-48da-935a-b7606dd3aade | k8s-w1     | SHUTOFF |
+--------------------------------------+------------+---------+
```



# Create k8s cluster on VM created from the images

VMs created from the image above contains all required packages for k8s cluster, so no need to run tasks to install the packages. To create k8s cluster just run the following steps.

1. Create VMs from the images.
2. Run `setup.yml` with `--skip-tags module,components,k8s_plugins`.
```
ansible-playbook setup.yml --skip-tags module,components,k8s_plugins
```
