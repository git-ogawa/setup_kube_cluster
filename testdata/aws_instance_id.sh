#!/bin/bash

TAG=${1}
instance_id=$(aws ec2 describe-instances  --output json | jq ".Reservations[].Instances[] | select(.Tags[].Value == \"${TAG}\") | .InstanceId")

if [[ ${instance_id} == "" ]]; then
    echo "ERR: cannot get instances id"
    exit 1
else
    echo ${instance_id//\"/}
fi
