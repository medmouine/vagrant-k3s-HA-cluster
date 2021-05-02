#!/bin/ash
set -eu
set -x

apk add --no-cache curl
apk add --no-cache cni-plugins --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

export PATH=$PATH:/usr/share/cni-plugins/bin
echo -e '#!/bin/sh\nexport PATH=$PATH:/usr/share/cni-plugins/bin' > /etc/profile.d/cni.sh

apk add iptables
apk add sudo
apk add openssh
apk add ca-certificates
apk add openssl

rc-update add sshd
rc-status

cat > /etc/ssh/sshd_config << EOF
Port 22
PasswordAuthentication no
PubkeyAuthentication yes
LogLevel VERBOSE
ChallengeResponseAuthentication no
EOF

echo "root:root" | chpasswd

mkdir -p /root/.ssh &&  chmod 700 /root/.ssh

install -d -m 700 /root/.ssh
chown -R root:root /root/.ssh
