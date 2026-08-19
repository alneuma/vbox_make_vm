#!/bin/bash

# Before you run the script adjust the following variables to suite your needs.

name=linux_vm       # name of your vm can be chosen freely

ostype=Linux_64     # VirtualBox comes with different IDs for different OS types use the of the linux distro you are planning to install
                    # You can use "VBoxManage list ostypes" to see all the IDs and pipe the output into grep to find what you need
                    # hint: An ID for Rocky Linux does not exist, but there is something very similar

num_cpus=2          # How many CPUs would you need for a VM without GUI that does not do any heavy calculations?

memory=2048         # How much RAM would you need for a VM without GUI that does not do any heavy calculations?

vram=128            # video ram

hdsize=8192         # disk size
                    # What is the minimum disk size needed for the OS you want to install?
 
# The VMs networking will be setup with NAT.
# This means that a specific port on the host is mapped to a specific port on the VM.
# You can keep the defaults and everything should work just fine.
# Questions to think about later:
# Why do we use port 22 on the VM? If we would use a different port what could go wrong?
ssh_map_host=2222   # host port
ssh_map_vm=22       # VM port

vmhdpath=/sgoinfre/goinfre/Perso/your_intra/images  # path to new VM image
                                                    # This will need a lot of space and should be persistent between reboots

iso=/goinfre/your_intra/cool_linux_distro.iso       # path to your installation ISO

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
