#!/bin/bash
apt-get update -y
apt-get install -y curl wget apt-transport-https ca-certificates gnupg lsb-release

# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu

# Install k3s
curl -sfL https://get.k3s.io | sh -

sleep 10
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

