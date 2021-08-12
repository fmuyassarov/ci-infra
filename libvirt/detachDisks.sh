#!/bin/bash

DISK_NUM=${DISK_NUM:-300}
NODE_NAME=${NODE_NAME:-node_0}

# Fetch the list of attached disks
sudo virsh dumpxml $NODE_NAME | grep "<target dev=" | cut -f2 -d\' | grep -v sda | head -n $DISK_NUM > /tmp/remove.disks.txt

# please make sure to NOT delete dev/sda because it is running boot OS
for disk in $(cat /tmp/remove.disks.txt);do 
    sudo virsh detach-disk --persistent $NODE_NAME $disk;
done