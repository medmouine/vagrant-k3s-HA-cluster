#!/bin/bash

set -e

k3sup install --skip-install --user root --ip 10.0.0.30 --ssh-key ./.ssh/id_rsa
export KUBECONFIG=$(pwd)/kubeconfig

for name in `vagrant status | grep -i master | awk -F " " '{print $1}'`
do 
  echo "Tainting $name to disable Pod scheduling"
  kubectl taint --overwrite node $name node-role.kubernetes.io/master=true:NoSchedule
done


