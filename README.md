# vagrant-k3s-HA-cluster

## Table of content
- [vagrant-k3s-HA-cluster](#vagrant-k3s-ha-cluster)
  * [Introduction](#introduction)
    + [Motivation](#motivation)
    + [Features](#features)
    + [Example and base config architecture](#example-and-base-config-architecture)
  * [Requirements](#requirements)
  * [Usage](#usage)
    + [Optional](#optional)
    + [1. Configuration:](#1-configuration-)
    + [2. Generate SSH key](#2-generate-ssh-key)
    + [3. Run](#3-run)
    + [4. Fetch cluster config file](#4-fetch-cluster-config-file)
    + [5. Test the cluster](#5-test-the-cluster)
    + [6. Enjoy!](#6-enjoy-)
  * [Related](#related)
  
## Introduction

This repository contains the Vagrantfile and scripts to easely configure a Highly Available Kubernetes (K3s) cluster. 

The cluster is composed of Controlplane nodes (default: 3), Worker nodes (default: 3), a Controlplane Loadbalancer ([Traefik](https://doc.traefik.io/traefik/providers/overview/)).

The k3s default flannel (xvlan) is replaced by [Calico](https://www.projectcalico.org/) as the base CNI due to an IP Forwarding bug when using K3s in VirtualBox VMs. 

K3s uses Traefik as an Ingress Controller by default. In this case, it is replaced by the [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/).

### Motivation
K3s is a lightweight Kubernetes distribution used for Edge-computing and IoT. It comes handy in the case of a local development environment with limited resources amd lacking the infrastructure provided by cloud providers.

I built this project in the context of the workshops for the Cloud Native course at Laval University. After wasting days debugging and finetuning the configuration to achieve a 
highly available, resource efficient and fully-working cluster, I realized the lack of documentation and resources regarding this use-case.

### Features
- [X] Working cluster
- [x] Editable configuration
- [x] Main documentation
- [ ] Document using other VM providers (Libirst)
- [ ] More K3s configuration through YAML config
- [ ] Configure other Controlplane LB (HAProxy)

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
## Usage

#### Optional
Regenerate [Kube-vip](https://kube-vip.io/) manifest with your desired configuration (see [Kube-vip docs](https://kube-vip.io/)) . Edit the `interface` and `vip` arguments if you changed the default configuration. You can use any container engine (ctr, podman...) to do this task.
```bash
$ docker run --network host --rm plndr/kube-vip:0.3.1 manifest daemonset \                                                                                               130
  --interface eth1 --controlplane \. 
  --vip 10.0.0.30 \
  --arp \
  --leaderElection  |  sed 's/path: \/etc\/kubernetes\/admin.conf/path: \/etc\/rancher\/k3s\/k3s.yaml/g' > scripts/manifests/vip.yaml
```

### 1. Configuration:
You can configure your cluster by editing the `hosts.yaml` file.

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
$ kubectl get nodes                                                                                                                                                      130
NAME          STATUS   ROLES                       AGE   VERSION
kubemaster1   Ready    control-plane,etcd,master   52m   v1.21.0+k3s1
kubemaster2   Ready    control-plane,etcd,master   49m   v1.21.0+k3s1
kubemaster3   Ready    control-plane,etcd,master   48m   v1.21.0+k3s1
kubenode1     Ready    <none>                      47m   v1.21.0+k3s1
kubenode2     Ready    <none>                      45m   v1.21.0+k3s1
kubenode3     Ready    <none>                      44m   v1.21.0+k3s1
```

### 6. Enjoy!

## Related 
- [K3s homepage](https://k3s.io/)
- [Vagrant homepage](https://www.vagrantup.com)
- [K3sup homepage](https://k3sup.dev/)
- [Kube-vip homepage](https://kube-vip.io)
- [Traefik LB](https://doc.traefik.io/traefik/providers/overview/)

