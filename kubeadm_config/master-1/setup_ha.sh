#!/bin/bash

source "$PWD"/vars.sh

echo "{MASTER1_IP}  ${MASTER1_HOSTNAME}"  | sudo tee -a /etc/hosts
echo "{MASTER2_IP}  ${MASTER2_HOSTNAME}"  | sudo tee -a /etc/hosts
echo "{MASTER3_IP}  ${MASTER3_HOSTNAME}"  | sudo tee -a /etc/hosts
echo "{VIP_IP}  ${VIP_HOSTNAME}"  | sudo tee -a /etc/hosts

cat <<EOF | sudo tee /etc/keepalived/check_apiserver.sh
#!/bin/sh
APISERVER_VIP="{VIP_IP}"
APISERVER_DEST_PORT=6443

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"
if ip addr | grep -q ${APISERVER_VIP}; then
    curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"
fi
EOF

sudo chmod +x /etc/keepalived/check_apiserver.sh
sudo sh -c '> /etc/keepalived/keepalived.conf'


cat <<EOF | sudo tee /etc/keepalived/keepalived.conf
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens3
    virtual_router_id 151
    priority 255
    authentication {
        auth_type PASS
        auth_pass PRow#@!
    }
    virtual_ipaddress {
        "{VIP_IP}"/24
    }
    track_script {
        check_apiserver
    }
}
EOF

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# apiserver frontend which proxys to the masters
#---------------------------------------------------------------------
frontend apiserver
    bind *:8443
    mode tcp
    option tcplog
    default_backend apiserver
#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server ${MASTER1_HOSTNAME}" "{MASTER1_IP}:6443 check
        server ${MASTER2_HOSTNAME}" "{MASTER2_IP}:6443 check
        server ${MASTER3_HOSTNAME}" "{MASTER3_IP}:6443 check
EOF

sudo systemctl enable keepalived haproxy kubelet --now
sudo swapoff -a 
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Generate Kubeadm config file
"$PWD"/kubeadm/master-1/generate_config.sh
# Create a local path for hostPath type of PersistentStorage 
if [ ! -d /mnt/data ]; then
  sudo mkdir -p /mnt/data;
fi

kubeadm init --control-plane-endpoint "{VIP_HOSTNAME}:8443" --upload-certs --config=$KUBEADM_CONFIG
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml