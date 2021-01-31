#!/usr/bin/env bash

# Error Handling
set -o errexit
set -o pipefail
set -o nounset

# # Debug
# cat /tmp/doesnotexist && rc=$? || rc=$?
# echo exitcode: $rc
# cat /dev/null && rc=$? || rc=$?
# echo exitcode: $rc


# Baking cloud image
IMG_URL=https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
IMG_PATH=/var/lib/libvirt/images/focal-server-cloudimg-amd64.img
# VM Instance
VM_NAME=Ubuntu204
DISK_SIZE=10G
VNC_PORT=5906


if [ ! -e ${IMG_PATH} ]; then
    sudo curl --output  ${IMG_PATH} ${IMG_URL}
fi

if [ -e ${VM_NAME}.xml ]; then
    rm -rfv ${VM_NAME}.xml
fi

if [ -e ${VM_NAME}-usb.xml ]; then
    rm -rfv ${VM_NAME}-usb.xml
fi

if [ -e /var/lib/libvirt/images/${VM_NAME}.qcow2 ]; then
    rm -rfv /var/lib/libvirt/images/${VM_NAME}.qcow2
fi

if [ -e /var/lib/libvirt/images/${VM_NAME}-seed.qcow2 ]; then
    rm -rfv /var/lib/libvirt/images/${VM_NAME}-seed.qcow2
fi

# Create disk image
qemu-img create -F qcow2 -b ${IMG_PATH} -f qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2 ${DISK_SIZE}
# Create seed image and injecting network-config, user-data and meta-data
cloud-localds -v -N network-config.yml /var/lib/libvirt/images/${VM_NAME}-seed.qcow2 user-data.yml

cat >${VM_NAME}.xml <<EOF
<domain type='kvm'>
    <name>${VM_NAME}</name>
    <memory unit='KiB'>1048576</memory>
    <currentMemory unit='KiB'>524288</currentMemory>
    <vcpu placement='static'>1</vcpu>
    <os>
        <type arch='x86_64' machine='pc-i440fx-bionic'>hvm</type>
        <boot dev='hd'/>
    </os>
    <features>
        <acpi/>
        <apic/>
    </features>
    <devices>
        <emulator>/usr/bin/kvm-spice</emulator>
        <disk type='file' device='disk'>
            <driver type='qcow2'/>
            <source file='/var/lib/libvirt/images/${VM_NAME}.qcow2'/>
            <target dev='vda' bus='virtio'/>
        </disk>
        <disk type='file' device='disk'>
            <driver type='raw'/>
            <source file='/var/lib/libvirt/images/${VM_NAME}-seed.qcow2'/>
            <target dev='vdb' bus='virtio'/>
        </disk>
        <interface type='bridge'>
            <source bridge='br0'/>
            <model type='virtio'/>
        </interface>
        <console type="pty">
           <target type="serial" port="0"/>
        </console>
        <graphics type='vnc' port="${VNC_PORT}" autoport='no' listen='0.0.0.0'>
            <listen type='address' address='0.0.0.0'/>
        </graphics>
    </devices>
</domain>
EOF

sudo virsh create ${VM_NAME}.xml