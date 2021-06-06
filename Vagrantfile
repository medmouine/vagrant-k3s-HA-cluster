# -*- mode: ruby -*-
# vi: set ft=ruby :

NODE_CONFIG = YAML.load_file('hosts.yaml')

IMAGE = NODE_CONFIG["image"]
IP_RANGE = NODE_CONFIG["ip_range"]
VIP = "#{NODE_CONFIG["lb"]["ip"]}"
K3S_VERSION = NODE_CONFIG["version"]
MASTER_COUNT = NODE_CONFIG["masters"]["count"]
NODE_COUNT = NODE_CONFIG["workers"]["count"]

Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-reload", "vagrant-vbguest"]

  config.vbguest.auto_update = false
  config.vm.provision "shell", privileged: true, path: "./scripts/setup_alpine.sh"
  config.vm.provision :reload
  config.vm.provision "shell", privileged: true, path: "./scripts/setup_user.sh"
  config.vm.provision "file", source: "./.ssh/id_rsa", destination: "/tmp/id_rsa"
  config.vm.provision "file", source: "./.ssh/id_rsa.pub", destination: "/tmp/id_rsa.pub"
  config.vm.provision "shell", privileged: true, path: "./scripts/setup_ssh.sh"

  config.vm.define "front_lb" do |traefik|
    traefik.vm.box = IMAGE
    traefik.vm.hostname = "traefik"
    traefik.vm.network :private_network, ip: VIP
    traefik.vm.network "forwarded_port", guest: 6443, host: 6443

    traefik.vm.provision "file", source: "./scripts/traefik/dynamic_conf.toml", destination: "/tmp/traefikconf/dynamic_conf.toml"
    traefik.vm.provision "file", source: "./scripts/traefik/static_conf.toml", destination: "/tmp/traefikconf/static_conf.toml"
    traefik.vm.provision "shell", privileged: true, path: "./scripts/setup_lb.sh"
    traefik.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", NODE_CONFIG["lb"]["resources"]["memory"]]
      vb.customize ["modifyvm", :id, "--cpus", NODE_CONFIG["lb"]["resources"]["cpu"]]
    end
  end

  FN_IP = ""
  (1..MASTER_COUNT).each do |i|
    config.vm.define "kubemaster#{i}" do |kubemasters|
      ID = i + 10
      IP = "#{IP_RANGE}#{ID}"
      kubemasters.vm.box = IMAGE
      kubemasters.vm.hostname = "kubemaster#{i}"
      kubemasters.vm.network :private_network, ip: IP
      kubemasters.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", NODE_CONFIG["masters"]["resources"]["memory"]]
        vb.customize ["modifyvm", :id, "--cpus", NODE_CONFIG["masters"]["resources"]["cpu"]]
      end

      kubemasters.vm.provision "file", source: "./scripts/manifests/.", destination: "/tmp/manifests/"
      kubemasters.vm.provision "shell", privileged: true, inline: "curl https://kube-vip.io/manifests/rbac.yaml > /tmp/manifests/_rbac.yaml"
      kubemasters.vm.provision "shell", privileged: true, inline: "mkdir -p /var/lib/rancher/k3s/server/manifests && mv /tmp/manifests/*.yaml /var/lib/rancher/k3s/server/manifests/"
      kubemasters.trigger.after :up do |t|
        if i == 1
          FN_IP = IP
          t.info = "m#{ID} Provisioning: Init Cluster. HOST:kubemaster#{i}, IP: #{IP}, args: init #{IP} #{VIP} #{K3S_VERSION}"
          t.run = { path: "scripts/provision.sh", args: "--action init --interface #{NODE_CONFIG["interface"]} --ip #{IP} --vip #{VIP} --version #{K3S_VERSION} --token #{NODE_CONFIG["token"]}" }
        elsif i > 1
          t.info = "m#{ID} Provisioning: New Master Node. HOST:kubemaster#{i}, IP: #{IP}, args: join #{IP} #{VIP} #{K3S_VERSION} #{FN_IP}"
          t.run = { path: "scripts/provision.sh", args: "--action join --interface #{NODE_CONFIG["interface"]} --ip #{IP} --vip #{VIP} --version #{K3S_VERSION} --sip #{FN_IP} --token #{NODE_CONFIG["token"]}" }
        end
      end
    end
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "kubenode#{i}" do |kubenodes|
      ID = i + 20
      IP = "#{IP_RANGE}#{ID}"

      kubenodes.vm.box = IMAGE
      kubenodes.vm.hostname = "kubenode#{i}"
      kubenodes.vm.network :private_network, ip: IP
      kubenodes.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", NODE_CONFIG["workers"]["resources"]["memory"]]
        vb.customize ["modifyvm", :id, "--cpus", NODE_CONFIG["workers"]["resources"]["cpu"]]
      end

      kubenodes.trigger.after :up do |t|
        t.info = "w#{i} Provisioning: Worker. HOST:kubenode#{i}, IP: #{IP}, args worker #{IP} #{VIP} #{K3S_VERSION}"
        t.run = { path: "scripts/provision.sh", args: "--action worker --interface #{NODE_CONFIG["interface"]} --ip #{IP} --vip #{VIP} --version #{K3S_VERSION} --token #{NODE_CONFIG["token"]}" }
      end
    end
  end
end
