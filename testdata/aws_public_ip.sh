#!/bin/bash

TAG=${1}

count=0
while [[ ${count} -lt 20 ]]
do
    public_ip=$(aws ec2 describe-instances --output json | jq ".Reservations[].Instances[] | select(.Tags[].Value==\"${TAG}\") | .NetworkInterfaces[].Association.PublicIp")
    if [[ ${public_ip} != "null" ]]; then
        break
    fi
    echo "Retry :${count}"
    sleep 5
    count=$((count+1))
done

if [[ ${public_ip} == "null" || ${public_ip} == "" ]]; then
    echo "ERR: cannot get public ip"
    exit 1
else
    echo ${public_ip//\"/} > ${TAG}_ip.txt
fi
