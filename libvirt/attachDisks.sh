
#!/bin/bash

DISK_NUM=${DISK_NUM:-300}
NODE_NAME=${NODE_NAME:-node_0}

# Generate disk names
for i in {a..z}; do
    for j in {a..z}; do
        echo $i$j ;
    done;
done > /tmp/disknames.txt

mkdir -p disks

# generate sample disk
for COUNTER in {1..$DISK_NUM};do
cat << EOF | tee "disks/disk_$COUNTER.xml"
<disk type="file" device="disk">
 <driver name="qemu" type="raw" cache="none"/>
 <source file="/var/lib/libvirt/images/node_sample.qcow2" index="$COUNTER"/>
 <backingStore/>
 <shareable/>
 <target dev="DISKNAME" bus="scsi"/>
 <serial>cooldiskroot</serial>
 <wwn>deadbeef00001111</wwn>
 <vendor>3PARdato</vendor>
 <product>VVmeh</product>
 <alias name="scsi0-0-0-$COUNTER"/>
 <address type="drive" controller="0" bus="0" target="0" unit="$COUNTER"/>
</disk>
EOF
done

# Creteate unique disks xml files
for i in {1..$DISK_NUM}; do 
        dname=$(cat /tmp/disknames.txt | head -n $i | tail -n 1;)
        sed -i "s/DISKNAME/sdf$dname/g" disks/disk_$i.xml;
done    

# Attach disks one by one
for i in {1..$DISK_NUM};do 
    virsh attach-device --persistent $NODE_NAME disks/disk_$i.xml;
done

# echo =============== verifying ===============
# kubectl get bmh $NODE_NAME  -n metal3 -ojson | jq .status.hardware.storage[].name

ATTACHED_DISKS=$(virsh dumpxml $NODE_NAME |grep "<target dev=" | cut -f2 -d\' | grep -v sda | head -n $DISK_NUM | wc -l)
echo $ATTACHED_DISKS