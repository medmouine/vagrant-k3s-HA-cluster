#!/bin/bash
set -xu

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
        --k3s-extra-args "-t $token --flannel-iface $interface --flannel-backend=wireguard --no-deploy servicelb --no-deploy traefik --disable-network-policy --cluster-cidr=192.168.0.0/16 --tls-san $vip --tls-san $ip --node-external-ip $ip --node-ip $ip" \
        --merge \
        --ssh-key .ssh/id_rsa \
        --user root || true

elif [[ "$action" == "join" ]]; then
    k3sup join --print-command \
        --ip $ip \
        --k3s-version $version \
        --ssh-key .ssh/id_rsa \
        --user root \
        --server-ip $sip \
        --server \
        --server-user root \
        --k3s-extra-args "-t $token --flannel-iface $interface --flannel-backend=wireguard --no-deploy servicelb --no-deploy traefik --tls-san $vip --tls-san $ip --node-external-ip $ip --node-ip $ip"

    # to regenerate nginx manifest, you can then use the helm command to output the file directly (helm template)
    # arkade install ingress-nginx --host-mode --namespace default

elif [[ "$action" == "worker" ]]; then
    k3sup join --print-command \
        --ip $ip \
        --k3s-version $version \
        --ssh-key .ssh/id_rsa \
        --user root \
        --server-ip $vip \
        --server-user root \
        --k3s-extra-args "--flannel-iface $interface -t $token --node-ip $ip --node-external-ip $ip"
fi
