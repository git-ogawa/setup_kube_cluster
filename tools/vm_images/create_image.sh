#!/bin/bash

set -ue

CURRENT_DIR=$(cd $(dirname $0); pwd)

# Setup VMs
cd ../../
ansible-playbook setup.yml \
    -t module \
    -t components \
    -t k8s_plugins

# Create imggaes from VMs
cd ${CURRENT_DIR}
ansible-playbook create_image.yml
