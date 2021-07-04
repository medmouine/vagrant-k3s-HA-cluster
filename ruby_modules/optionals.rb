
def provision_optionals (vm:, registry_config:, repository_config:, is_master: true)
  if registry_config["enabled"] == true
    provision_registry(vm: vm, host: registry_config["host"], ip: registry_config["external_ip"], is_master: is_master)
  end
  if repository_config["enabled"] == true
    provision_repository(vm: vm, host: repository_config["host"], ip: repository_config["external_ip"], is_master: is_master)
  end
end

def provision_repository(vm:, host:, ip:, is_master: true)
  if is_master
    vm.vm.provision "file", source: "./scripts/optional/git_repo.yaml", destination: "/tmp/manifests/git_repo.yaml"
  end
  vm.vm.provision "shell", privileged: true, inline: "echo \"#{ip} #{host}\" >> /etc/hosts"
end

def provision_registry(vm:, host:, ip:, is_master: true)
  if is_master
    vm.vm.provision "file", source: "./scripts/optional/local-registry.yaml", destination: "/tmp/manifests/local_registry.yaml"
  end
  vm.vm.provision "file", source: "./scripts/optional/registries.yaml", destination: "/tmp/manifests/registries.yaml"
  vm.vm.provision "shell", privileged: true, inline: "mkdir -p /etc/rancher/k3s/ && mv /tmp/manifests/registries.yaml /etc/rancher/k3s/registries.yaml"
  vm.vm.provision "shell", privileged: true, inline: "echo \"#{ip} #{host}\" >> /etc/hosts"
end
