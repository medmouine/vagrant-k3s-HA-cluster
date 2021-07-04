def provision_script (vm:, path:, priv: true)
    vm.vm.provision "shell", privileged: priv, path: path
end

def provision_file (vm:, src:, dest:)
    vm.vm.provision "file", source: src, destination: dest
end

def provision_vip_config (vm:)
  vm.vm.provision "shell", privileged: true, inline: "curl https://kube-vip.io/manifests/rbac.yaml > /tmp/manifests/_rbac.yaml"
  vm.vm.provision "shell", privileged: true, inline: "mkdir -p /var/lib/rancher/k3s/server/manifests && mv /tmp/manifests/*.yaml /var/lib/rancher/k3s/server/manifests/"
end
