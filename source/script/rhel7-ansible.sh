#!/bin/sh

mkdir /media/rhel7
mount /dev/cdrom /media/rhel7

subscription-manager config --rhsm.manage_repos=0
subscription-manager config --rhsm.auto_enable_yum_plugins=0

cat << EOF > /etc/yum.repos.d/rhel7.repo
[LocalRepo]
name=LocalRepository
baseurl=file:///media/rhel7
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

subscription-manager clean
yum clean all

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y ansible
