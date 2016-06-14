#!/usr/bin/env bash

#yum -y install perl
#cd /tmp
#mkdir /tmp/vmtools
#mount -t iso9660 -o loop /root/linux.iso /tmp/vmtools

# Install the drivers
#cp /tmp/vmtools/VMwareTools-*.gz /tmp
#tar -zxvf VMwareTools*.gz
#./vmware-tools-distrib/vmware-install.pl -d

# Cleanup
#umount vmtools
#rm -rf vmtools /root/linux.iso VMwareTools*.gz vmware-tools-distrib


cd /tmp
git clone https://github.com/rasa/vmware-tools-patches.git
cd vmware-tools-patches
source ./setup.sh
./download-tools.sh latest
./untar-and-patch-and-compile.sh
cp /etc/vmware-tools/services.sh /etc/init.d/vmware-tools
sed -i '/##VMWARE_INIT_INFO##/a# chkconfig: 235 03 99' /etc/init.d/vmware-tools
chkconfig --add vmware-tools
chkconfig vmware-tools on
service vmware-tools restart
cd /tmp
rm -rf vmware-tools-patches
rm -f ~/linux.iso

