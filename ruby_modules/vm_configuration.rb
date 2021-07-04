def setup_resources (vm:, cpus: 1, memory: 512)
    vm.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", memory]
      vb.customize ["modifyvm", :id, "--cpus", cpus]
    end
end

def setup_vm(vm:, hostname:, ip:, image:)
    vm.vm.box = image
    vm.vm.hostname = hostname
    vm.vm.network :private_network, ip: ip
end

def setup_common(config)
  config.vbguest.auto_update = false
  config.vm.provision "shell", privileged: true, path: "./scripts/setup_alpine.sh"
  config.vm.provision :reload
  config.vm.provision "shell", privileged: true, path: "./scripts/setup_user.sh"
  config.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
  config.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
  config.vm.provision "shell", privileged: true, path: "./scripts/setup_ssh.sh"
end
