#!/bin/bash

set -euo pipefail
export KUBEADM_CONFIG=${KUBEADM_CONFIG:-"/tmp/kubeadm.yaml"}
echo "Printing to $KUBEADM_CONFIG"

if [ -d "$KUBEADM_CONFIG" ]; then
    echo "$KUBEADM_CONFIG is a directory!"
    exit 1
fi

if [ ! -d $(dirname "$KUBEADM_CONFIG") ]; then
    echo "please create directory $(dirname $KUBEADM_CONFIG)"
    exit 1
fi

if [ ! $(which yq) ]; then
    echo "please install yq"
    exit 1
fi

if [ ! $(which kubeadm) ]; then
    echo "please install kubeadm"
    exit 1
fi

sudo kubeadm config print init-defaults --component-configs=KubeletConfiguration > "$KUBEADM_CONFIG"                                                                                                                                  
yq -i eval 'select(.nodeRegistration.criSocket) |= .nodeRegistration.criSocket = "unix:///var/run/crio/crio.sock"' "$KUBEADM_CONFIG"
yq -i eval 'select(di == 1) |= .cgroupDriver = "systemd"' "$KUBEADM_CONFIG"