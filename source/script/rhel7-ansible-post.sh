#!/bin/sh

rpm -e epel-release > /dev/null
rpm -e puppet6-release > /dev/null

subscription-manager clean
yum clean all

subscription-manager config --rhsm.manage_repos=1
subscription-manager config --rhsm.auto_enable_yum_plugins=1

umount /media/rhel7
rm -rf /media/rhel7

rm -f /etc/yum.repos.d/rhel7.repo

exit 0
