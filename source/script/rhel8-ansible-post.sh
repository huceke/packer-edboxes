#!/bin/sh

subscription-manager clean
dnf clean all

subscription-manager config --rhsm.manage_repos=1
subscription-manager config --rhsm.auto_enable_yum_plugins=1

umount /media/rhel8
rm -rf /media/rhel8

rm -f /etc/yum.repos.d/rhel8.repo
