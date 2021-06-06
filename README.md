# vagrant-k3s-HA-cluster

## Table of content
- [vagrant-k3s-HA-cluster](#vagrant-k3s-ha-cluster)
  * [Table of content](#table-of-content)
  * [Introduction](#introduction)
    + [Motivation](#motivation)
    + [Features](#features)
    + [Example and base config architecture](#example-and-base-config-architecture)
  * [Requirements](#requirements)
    + [System](#system)
    + [Software](#software)
  * [Usage](#usage)
      - [(Optional) Generate VIP config manifest](#-optional--generate-vip-config-manifest)
    + [1. Configuration](#1-configuration)
    + [2. Generate SSH key](#2-generate-ssh-key)
    + [3. Run](#3-run)
    + [4. Fetch cluster config file](#4-fetch-cluster-config-file)
    + [5. Test the cluster](#5-test-the-cluster)
    + [6. Start hacking](#6-start-hacking)
  * [Related](#related)

## Introduction

This repository contains the Vagrantfile and scripts to easely configure a Highly Available Kubernetes (K3s) cluster. 

The cluster is composed of Controlplane nodes (default: 3), Worker nodes (default: 3), a Controlplane Loadbalancer ([Traefik](https://doc.traefik.io/traefik/providers/overview/)).

The k3s default flannel (vxlan) is replaced by [Calico](https://www.projectcalico.org/) as the base CNI due to an IP Forwarding bug when using K3s in VirtualBox VMs. 

K3s uses Traefik as an Ingress Controller by default. In this case, it is replaced by the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/).

In HA mode, K3s can either use an external data storage to sync its server or an [etcd](https://etcd.io/) cluster internally. In this case, it's the second option (etcd).


<img src="https://cdn.thenewstack.io/media/2020/08/0b8d5fc2-k3s-1-1024x671.png" alt="architecture diagram should be here :(" width="700"/>

### Motivation
K3s is a lightweight Kubernetes distribution used for Edge-computing and IoT. It comes handy in the case of a local development environment with limited resources amd lacking the infrastructure provided by cloud providers.

I built this project in the context of the workshops for the [Cloud Native application and DevOps](https://www.ulaval.ca/etudes/cours/glo-4008-applications-infonuagiques-natives-et-devops) course at Laval University. 

After wasting days debugging and finetuning the configuration to achieve a 
highly available, resource efficient and fully-working cluster, I realized the lack of documentation and resources regarding this use-case.

### Features
- [X] Working cluster
- [x] Editable configuration
- [x] Main documentation
- [ ] Document performance benchmarking and different architectures comparison
- [ ] Investigate MetalLB for external Loadbalancing
- [ ] Investigate using [Multipass](https://multipass.run/) instead of Vagrant
- [ ] Document Ingress controller integration and different layer networking solutions
- [ ] Fix start-up bug when cluster-init (alpine cgroups bug)
- [ ] Adapt configuration and scripts to use different VM images (Ubuntu/bionic64...)
- [ ] Invrestigate K3OS usage and integration
- [ ] Document and configure using other VM providers (Libvirt...)
- [ ] More configuration through YAML config (K3s, Ingress Controller...)
- [ ] Support different config formats (TOML, JSON...)
- [ ] Document and Configure other Controlplane LB (HAProxy)
- [ ] Bundle into a single package/script/binary

### Example and base config architecture
| Hostname      | Role                        | Ip Address  | OS               | CPUs   | Memory (mb)   |
| :-------------|:--------------------------- |:----------- |:-----------------|:-------|:------------- |
| front_lb      | Controlplane LB             | 10.0.0.30   | generic/alpine312| 1      | 512           |
| Kubemaster1   | Controlplane + cluster init | 10.0.0.11   | generic/alpine312| 2      | 2048          |
| Kubemaster2   | Controlplane                | 10.0.0.12   | generic/alpine312| 2      | 2048          |
| Kubemaster3   | Controlplane                | 10.0.0.13   | generic/alpine312| 2      | 2048          |
| Kubenode1     | Worker                      | 10.0.0.21   | generic/alpine312| 1      | 1024          |
| Kubenode2     | Worker                      | 10.0.0.22   | generic/alpine312| 1      | 1024          |
| Kubenode3     | Worker                      | 10.0.0.23   | generic/alpine312| 1      | 1024          |

## Requirements
### System
To work properly K3s requires:
* Linux 3.10 or higher
* 512 MB RAM (per server)
* 75 MB RAM per node
* 200 MB of free disk space
* 86/64/ARMV7/ARM64 chip

However, I highly recommend to provision VMs with more resources. With 1GB memory and 1 CPU controlplanes work fine on Alpine but other linux distros might struggle to keep all the servers up and running. Luckily, this solution offers load balancing to achieve HA so this is not an issue regarding availability of the cluster. However, You may encounter some connection timeouts and latency. This is most likely not an issue with Alpine as it is the most lightweight distro available.

I still recommend allocating more resources especially to the servers to speed up provisionning of the cluster and internal components. 

### Software
- [Vagrant](https://www.vagrantup.com/downloads)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [K3sup](https://k3sup.dev/)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- (Optional) [Docker](https://www.docker.com/get-started)

You can use [Arkade](https://github.com/alexellis/arkade) to install all the required binaries (not VirtualBox). 
```bash
$ arkade get vagrant
$ arkade get kubectl
$ arkade get k3sup
$ arkade get docker
```

As you can see in the [Vagrantfile](https://github.com/medmouine/vagrant-k3s-HA-cluster/blob/main/Vagrantfile#L14), you will need to install 2 vagrant plugins:
```
$ vagrant plugin install vagrant-vbguest
$ vagramt plugin install vagrant-reload
```

## Usage

#### (Optional) Generate VIP config manifest
Regenerate [Kube-vip](https://kube-vip.io/) manifest with your desired configuration (see [Kube-vip docs](https://kube-vip.io/)) . Edit the `interface` and `vip` arguments if you changed the default configuration. You can use any container engine (ctr, podman...) to do this task.
```bash
$ docker run --network host --rm plndr/kube-vip:0.3.1 manifest daemonset \                                                                                               130
  --interface eth1 --controlplane \. 
  --vip 10.0.0.30 \
  --arp \
  --leaderElection  |  sed 's/path: \/etc\/kubernetes\/admin.conf/path: \/etc\/rancher\/k3s\/k3s.yaml/g' > scripts/manifests/vip.yaml
```

### 1. Configuration
You can configure your cluster by editing the `hosts.yaml` file.

Resources:
- [k3s releases](https://github.com/k3s-io/k3s/releases) 
- [Vagrant boxes registry](https://app.vagrantup.com/boxes/search)
- [Vagrant + VirtualBox networking documentation](https://www.vagrantup.com/docs/providers/virtualbox/networking)

Example configuration:
```yaml
version: "v1.21.0+k3s1"
image: "generic/alpine312"
interface: "eth1" # ubuntu/bionic64 uses enp0s8. alpine uses eth1 by default, you can change the interface by configuring more specific attributes to the network provider of vagrant
token: "agent-token" # Generate random string or use any string as a token for in-cluster node communication and initialization
ip_range: "10.0.0." # Assert that the ip cidr `10.0.0.11` to `10.0.0.30` are available or edit this field
masters:
  count: 3
  resources:
    memory: "2048"
    cpu: "2"
workers:
  count: 3
  resources:
    memory: "1024"
    cpu: "1"
lb:
  id: 30
  resources:
    memory: "512"
    cpu: "1"

```

### 2. Generate SSH key
```
$ ssh-keygen -f ./.ssh/id_rsa
```

### 3. Run
```
$ vagrant up
```

### 4. Fetch cluster config file
To use the Kubernetes API from your local host run the following command:
```
$ k3sup install --skip-install --user root --ip 10.0.0.30 --ssh-key ./.ssh/id_rsa
```

### 5. Test the cluster
```
$ export KUBECONFIG=$(pwd)/kubeconfig
$ kubectl get nodes                                                                                                                                               
NAME          STATUS   ROLES                       AGE   VERSION
kubemaster1   Ready    control-plane,etcd,master   52m   v1.21.0+k3s1
kubemaster2   Ready    control-plane,etcd,master   49m   v1.21.0+k3s1
kubemaster3   Ready    control-plane,etcd,master   48m   v1.21.0+k3s1
kubenode1     Ready    <none>                      47m   v1.21.0+k3s1
kubenode2     Ready    <none>                      45m   v1.21.0+k3s1
kubenode3     Ready    <none>                      44m   v1.21.0+k3s1
```

### 6. Start hacking

Congratulations you are fully setup to start provisioning applications on your cluster.

## Related 
- [K3s homepage](https://k3s.io/)
- [Vagrant homepage](https://www.vagrantup.com)
- [K3sup homepage](https://k3sup.dev/)
- [Kube-vip homepage](https://kube-vip.io)
- [Traefik LB](https://doc.traefik.io/traefik/providers/overview/)

