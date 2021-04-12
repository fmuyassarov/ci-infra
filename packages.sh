#!/bin/bash

set -uex

source vars.sh

echo  "--------------------Installing Kubernetes binaries--------------------"
curl -L --remote-name-all "https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/{kubeadm,kubelet,kubectl}"
sudo chmod a+x kubeadm kubelet kubectl
sudo mv kubeadm kubelet kubectl /usr/local/bin/
sudo mkdir -p /etc/systemd/system/kubelet.service.d
sudo ./retrieve.configuration.files.sh https://raw.githubusercontent.com/kubernetes/release/v0.2.7/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service /etc/systemd/system/kubelet.service
sudo ./retrieve.configuration.files.sh https://raw.githubusercontent.com/kubernetes/release/v0.2.7/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo apt-get update
sudo apt install -y conntrack socat haproxy keepalived
sudo apt install python3-pip
sudo pip3 install yq

echo  "--------------------Installing CRIO--------------------"
sudo ./install_crio.sh