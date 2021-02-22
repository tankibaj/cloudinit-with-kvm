#!/usr/bin/env bash

# Error Handling
set -o errexit
set -o pipefail
set -o nounset

# Check for arguments
if [ $# = 4 ]; then
    VM_NAME=$1
    os=$2
    DISK_SIZE=$3G
    VNC_PORT=$4
else
    echo
    echo "Usage: $0 VMname OSname DiskSize VNCPort"
    echo
    echo "Example: bash $0 instance1 ubuntu 20 5901"
    exit 1
fi

# Check for cloud-image-utils and install if don't have it
if test ! $(which cloud-localds); then
    sudo apt-get -y install cloud-image-utils
fi

# Check for net-tools and install if don't have it
if test ! $(which netstat); then
    sudo apt-get -y install net-tools
fi

# Check port availability
if [[ "$VNC_PORT" = "$(sudo netstat -tulpn | grep $VNC_PORT | awk '{ print $4}' | cut -d ":" -f 2)" ]]; then
    echo "$VNC_PORT is already used"
    exit 1
fi

if [ -n $os ]; then
    case $os in
    ubuntu | Ubuntu)
        # IMG_URL=https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
        # IMG_PATH=/var/lib/libvirt/images/bionic-server-cloudimg-amd64.img
        IMG_URL=https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
        IMG_PATH=/var/lib/libvirt/images/focal-server-cloudimg-amd64.img
        ;;
    debian | Debian)
        IMG_URL=http://cdimage.debian.org/cdimage/openstack/current/debian-10-openstack-amd64.qcow2
        IMG_PATH=/var/lib/libvirt/images/debian-10-openstack-amd64.qcow2
        ;;
    *)
        echo "$os is not supported"
        exit 1
        ;;
    esac
fi

if [ ! -e ${IMG_PATH} ]; then
    sudo curl --output ${IMG_PATH} ${IMG_URL}
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


if [ ! "qcow2" = $(qemu-img info ${IMG_PATH} | grep 'file format' | cut -d ':' -f 2) ]; then
echo "Image format is not supported!"
fi


# # Create disk image
# qemu-img create -F qcow2 -b ${IMG_PATH} -f qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2 ${DISK_SIZE}

# Copy master disk and convert to qcow2 | Even through its a qcow2 image , still copy and ensures target file is qcow2
qemu-img convert -f qcow2 ${IMG_PATH} -O qcow2 /var/lib/libvirt/images/${VM_NAME}.qcow2
# cp -v ${IMG_PATH} /var/lib/libvirt/images/${VM_NAME}.qcow2

# Resize virtual disk
qemu-img resize /var/lib/libvirt/images/${VM_NAME}.qcow2 ${DISK_SIZE}

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
