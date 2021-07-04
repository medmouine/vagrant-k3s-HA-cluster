# -*- mode: ruby -*-
# vi: set ft=ruby :

require './ruby_modules/provisioning.rb'
require './ruby_modules/optionals.rb'
require './ruby_modules/vm_configuration.rb'

NODE_CONFIG = YAML.load_file('hosts.yaml')

IMAGE = NODE_CONFIG["image"]
IP_RANGE = NODE_CONFIG["ip_range"]
VIP = "#{NODE_CONFIG["lb"]["ip"]}"
K3S_VERSION = NODE_CONFIG["version"]
MASTER_COUNT = NODE_CONFIG["masters"]["count"]
NODE_COUNT = NODE_CONFIG["workers"]["count"]

Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-reload", "vagrant-vbguest"]
  setup_common config

  config.vm.define "front_lb" do |traefik|
    setup_vm(vm: traefik, hostname: "traefik", ip: VIP, image: IMAGE)
    traefik.vm.network "forwarded_port", guest: 6443, host: 6443

    provision_file(vm: traefik, src: "./scripts/traefik/dynamic_conf.toml", dest: "/tmp/traefikconf/dynamic_conf.toml")
    provision_file(vm: traefik, src: "./scripts/traefik/static_conf.toml", dest: "/tmp/traefikconf/static_conf.toml")
    provision_script(vm: traefik, path: "./scripts/setup_lb.sh")
    setup_resources(vm: traefik, cpus:  NODE_CONFIG["lb"]["resources"]["cpu"], memory: NODE_CONFIG["lb"]["resources"]["memory"])
  end

  FN_IP = ""
  (1..MASTER_COUNT).each do |i|
    config.vm.define "kubemaster#{i}" do |kubemasters|
      ID = i + 10
      IP = "#{IP_RANGE}#{ID}"
      setup_vm(vm: kubemasters, hostname: "kubemaster#{i}", ip: IP, image: IMAGE)
      setup_resources(vm: kubemasters, 
                      cpus: NODE_CONFIG["masters"]["resources"]["cpu"], 
                      memory: NODE_CONFIG["masters"]["resources"]["memory"])
      
      provision_file(vm: kubemasters, src:  "./scripts/manifests/.", dest: "/tmp/manifests/")
      
      provision_optionals(vm: kubemasters, 
                          registry_config: NODE_CONFIG["local_registry"], 
                          repository_config: NODE_CONFIG["git_repo"])

      provision_vip_config(vm: kubemasters)
      kubemasters.trigger.after :up do |t|
        info = ""
        args = ""
        if i == 1
          FN_IP = IP
          info = "m#{ID} Provisioning: Init Cluster. HOST:kubemaster#{i}, IP: #{IP}, args: init #{IP} #{VIP} #{K3S_VERSION}"
          args = "--action init --interface #{NODE_CONFIG["interface"]} --ip #{IP} --vip #{VIP} --version #{K3S_VERSION} --token #{NODE_CONFIG["token"]}" 
        elsif i > 1
          info = "m#{ID} Provisioning: New Master Node. HOST:kubemaster#{i}, IP: #{IP}, args: join #{IP} #{VIP} #{K3S_VERSION} #{FN_IP}"
          args = "--action join --interface #{NODE_CONFIG["interface"]} --ip #{IP} --vip #{VIP} --version #{K3S_VERSION} --sip #{FN_IP} --token #{NODE_CONFIG["token"]}" 
        end

        configure_trigger_run(trigger: t, info: info, path:  "scripts/provision.sh", args: args)
      end
    end
  end

  (1..NODE_COUNT).each do |i|
    config.vm.define "kubenode#{i}" do |kubenodes|
      ID = i + 20
      IP = "#{IP_RANGE}#{ID}"

      setup_vm(vm: kubenodes, hostname: "kubenode#{i}", ip: IP, image: IMAGE)
      setup_resources(vm: kubenodes, 
                      cpus: NODE_CONFIG["workers"]["resources"]["cpu"], 
                      memory: NODE_CONFIG["workers"]["resources"]["memory"])
      provision_optionals(vm: kubenodes, 
                          registry_config: NODE_CONFIG["local_registry"], 
                          repository_config: NODE_CONFIG["git_repo"],
                          is_master: false)
      kubenodes.trigger.after :up do |t|
        info = "w#{i} Provisioning: Worker. HOST:kubenode#{i}, IP: #{IP}, args worker #{IP} #{VIP} #{K3S_VERSION}"
        args = "--action worker --interface #{NODE_CONFIG["interface"]} --ip #{IP} --vip #{VIP} --version #{K3S_VERSION} --token #{NODE_CONFIG["token"]}" 
        configure_trigger_run(trigger: t, info: info, path:  "scripts/provision.sh", args: args)
      end
    end
  end
end

