#!/bin/bash

set -e

sudo apt update
sudo apt install -y docker.io conntrack curl

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker ubuntu

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Start Minikube in a fresh login shell so the docker group is active.
sudo su - ubuntu -c '
minikube delete || true

minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=1800mb \
  --ports=30080:30080
'
