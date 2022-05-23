#!/bin/sh

mkdir /media/rhel8
mount /dev/cdrom /media/rhel8

subscription-manager config --rhsm.manage_repos=0
subscription-manager config --rhsm.auto_enable_yum_plugins=0

cat << EOF > /etc/yum.repos.d/rhel8.repo
[InstallMedia-BaseOS]
name=Red Hat Enterprise Linux 8 - BaseOS
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///media/rhel8/BaseOS
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[InstallMedia-AppStream]
name=Red Hat Enterprise Linux 8 - AppStream
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///media/rhel8/AppStream
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

subscription-manager clean
dnf clean all

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y ansible-core
