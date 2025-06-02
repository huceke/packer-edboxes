#!/bin/sh

rpm -e epel-release > /dev/null
rpm -e puppet6-release > /dev/null

subscription-manager clean
dnf clean all

subscription-manager config --rhsm.manage_repos=1
subscription-manager config --rhsm.auto_enable_yum_plugins=1

umount /media/rhel10
rm -rf /media/rhel10

rm -f /etc/yum.repos.d/rhel9.repo

exit 0
