#!/bin/bash

set +x

echo "🎬  Finalizing setup..."

vip="10.0.0.30"
sshpath="./.ssh/id_rsa"
kubeconfpath=$(pwd)/kubeconfig

echo "⚙️   Pulling kubeconfig from $vip using ssh key at $sshpath"
k3sup install --skip-install --user root --ip $vip --ssh-key $sshpath > /dev/null

if [[ -f $kubeconfpath ]]
then
    echo "✅  Kubeconfig pulled to $kubeconfpath"
else
    echo "❌  Could not fetch Kubeconfig. Ensure Load balancer (VIP) or Control-plane is reachable at $vip through SSH (Port 22)"
    return 1
fi

echo "🎨  Tainting Control-plane nodes to disable Pod scheduling..."

controlplanes=( $(vagrant status | grep -i master | awk -F " " '{print $1}') )
echo "🤖  Detected Control-plane nodes: $controlplanes"

for name in "${controlplanes[@]}"
do
  echo "👩‍🎨  Tainting $name"
  kubectl taint --overwrite node $name node-role.kubernetes.io/master=true:NoSchedule --kubeconfig $kubeconfpath
done
echo "✅  Tanting done."

echo "\n"
export KUBECONFIG=$(pwd)/kubeconfig
echo "⚙️   KUBECONFIG exported to: $(pwd)/kubeconfig"
echo "\n"
echo "🤙   Test your setup by running:"
echo "Command:  \$ kubectl get nodes"
echo "Expected output:"
echo "NAME          STATUS   ROLES                       AGE   VERSION
kubemaster1   Ready    control-plane,etcd,master   79m   v1.21.0+k3s1
kubemaster2   Ready    control-plane,etcd,master   77m   v1.21.0+k3s1
kubenode1     Ready    <none>                      75m   v1.21.0+k3s1"
echo "\n"
echo "Or by running:"
echo "Command:  \$ curl $vip"
echo "Expected output:"
echo "<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>"
echo "\n"
echo "💔   Troubleshooting:"
echo "😓   If you get an error similar to"
echo "  >> The connection to the server 127.0.0.1:58123 was refused - did you specify the right host or port?"
echo "🤔   Try sourcing this script instead of executing it:"
echo "Command: "
echo "  \$ source ./finalize_setup.sh"
echo "\n"

echo "🚀  Ready to launch!"

