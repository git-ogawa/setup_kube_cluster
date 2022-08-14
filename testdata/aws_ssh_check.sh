#!/bin/bash

username=${1}
ip_address=${2}
ssh_key_path=${3}

count=0
while [[ ${count} -lt 20 ]]
do
    ssh -i ${ssh_key_path} ${username}@${ip_address} -o StrictHostKeyChecking=no ls -l > /dev/null
    if [[ $? == 0 ]]; then
        break
    fi
    echo "Retry :${count}"
    sleep 5
    count=$((count+1))
done

