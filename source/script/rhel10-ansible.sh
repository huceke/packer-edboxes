#!/bin/sh

mkdir /media/rhel10
mount /dev/cdrom /media/rhel10

subscription-manager config --rhsm.manage_repos=0
subscription-manager config --rhsm.auto_enable_yum_plugins=0

cat << EOF > /etc/yum.repos.d/rhel10.repo
[InstallMedia-BaseOS]
name=Red Hat Enterprise Linux 8 - BaseOS
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///media/rhel10/BaseOS
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[InstallMedia-AppStream]
name=Red Hat Enterprise Linux 8 - AppStream
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///media/rhel10/AppStream
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF

subscription-manager clean
dnf clean all

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y ansible-core
