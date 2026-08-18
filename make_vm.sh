#!/bin/bash

name=linux_vm       # name of your vm
ostype=Linux_64     # "VBoxManage list ostypes" with grep to find what you need
num_cpus=2          # cpus
memory=2048         # ram
vram=128            # video ram
hdsize=8192         # size of harddrive
ssh_map_host=2222   # port to use ssh on host
ssh_map_vm=22       # port to use ssh on vm
vmhdpath=/sgoinfre/goinfre/Perso/your_intra/images  # path to new image
iso=/goinfre/your_intra/cool_linux_distro.iso       # path to install.iso

# check if vm already exists
if VBoxManage list vms | grep -q "${name}" 2> /dev/null; then
    echo "virtual machine \"${name}\" already exists" >&2
    exit 1
elif [ $? -eq 2 ]; then
    echo "failed checking for duplicate virtual machine" >&2
    exit 1
fi

# check if iso exists
if [ ! -e "${iso}" ]; then
    echo "file \"${iso}\" does not exist" >&2
    exit 1
fi

# try to create path for vdi
if ! mkdir -p ${vmhdpath}/${name}; then
    exit 1
fi

# create vm
VBoxManage createvm --name ${name} --ostype ${ostype} --register

# add cpus ram and vram
VBoxManage modifyvm ${name} --cpus ${num_cpus} --memory ${memory} --vram ${vram}

# enable more modern way to handle hardware interrupts
VBoxManage modifyvm ${name} --ioapic on

# configure graphics
VBoxManage modifyvm ${name} --graphicscontroller vmsvga
VBoxManage modifyvm ${name} --accelerate3d on

# add network interfaces
VBoxManage modifyvm ${name} --nic1 nat
VBoxManage modifyvm ${name} --nictype1 virtio

# configure nat for ssh
VBoxManage modifyvm ${name} --natpf1 "ssh,tcp,,${ssh_map_host},,${ssh_map_vm}"

# create and attach a harddrive
VBoxManage createhd --filename ${vmhdpath}/${name}/${name}.vdi --size ${hdsize}
VBoxManage storagectl ${name} --name "sata_controller_${name}" --add sata --bootable on
VBoxManage storageattach ${name} --storagectl "sata_controller_${name}" --port 0 --device 0 --type hdd --medium ${vmhdpath}/${name}/${name}.vdi

# attach installation iso
VBoxManage storagectl ${name} --name "ide_controller_${name}" --add ide --bootable on
VBoxManage storageattach ${name} --storagectl "ide_controller_${name}" --port 0 --device 0 --type dvddrive --medium ${iso}

# specify bootorder
VBoxManage modifyvm ${name} --boot1 disk --boot2 dvd --boot3 none --boot4 none
