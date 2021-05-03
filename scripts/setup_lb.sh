#!/bin/bash
set -xeu

curl https://github.com/containous/traefik/releases/download/v2.4.8/traefik_v2.4.8_linux_amd64.tar.gz -o /tmp/traefik.tar.gz -L
cd /tmp/
tar xvfz ./traefik.tar.gz
nohup ./traefik --configFile=/tmp/traefikconf/static_conf.toml &> /dev/null&