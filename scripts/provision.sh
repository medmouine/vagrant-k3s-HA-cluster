#!/bin/sh
set -eu

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi
  shift
done

if [[ "$action" == "init" ]]; then
    k3sup install --print-command \
        --ip $ip \
        --cluster \
        --tls-san $vip \
        --k3s-version $version \
        --k3s-extra-args "-t $token --flannel-iface $interface --flannel-backend=none  --disable servicelb --disable traefik --disable-network-policy --cluster-cidr=192.168.0.0/16 --tls-san $vip --tls-san $ip" \
        --merge \
        --ssh-key .ssh/id_rsa \
        --user root

elif [[ "$action" == "join" ]]; then
    k3sup join --print-command \
        --ip $ip \
        --k3s-version $version \
        --ssh-key .ssh/id_rsa \
        --user root \
        --server-ip $sip \
        --server \
        --server-user root \
        --k3s-extra-args "-t $token --flannel-iface $interface --tls-san $vip --tls-san $ip"

elif [[ "$action" == "worker" ]]; then
    k3sup join --print-command \
        --ip $ip \
        --k3s-version $version \
        --ssh-key .ssh/id_rsa \
        --user root \
        --server-ip $vip \
        --server-user root \
        --k3s-extra-args "--flannel-iface $interface -t $token --node-ip $ip"
fi

export KUBECONFIG=$(pwd)/kubeconfig
