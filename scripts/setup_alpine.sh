#!/bin/bash
set -xeu

echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> /etc/fstab
swapoff -a
rc-update add cgroups default

apk add -U wireguard-tools

sed -i 's/default_kernel_opts="/default_kernel_opts="cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory /g' /etc/update-extlinux.conf

update-extlinux
