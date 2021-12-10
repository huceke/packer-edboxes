# packer edboxes : extensible box ( vm ) creation tool.
#
# Copyright (C) 2021  Edgar Vichor ebsi4711 at gmail dot com
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

#!/usr/bin/env bash

set -e
set -x

DEVICE=/dev/vda
NAME={ box_name }
{ http_efi_boot }
VGNAME=vg_$NAME
LUKSNAME=luks_$NAME
ROOTLV=lv_$NAME
BOOTDEV=${DEVICE}1
LUKSDEV=${DEVICE}2
#NTFSDEV=${DEVICE}3
BOOTUUID=""
ROOTUUID=""
{ http_encryption_settings }
LUKSUUID=$(uuidgen)
ROOTUUID=$(uuidgen)

CHROOT_DIR="/mnt"
MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=AT&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"
PASSWORD=$(/usr/bin/openssl passwd -6 '{ box_password }')
LUKS_PASSWORD={ box_password }
PASSWORD_VAGRANT=$(/usr/bin/openssl passwd -6 '{ vagrant_password }')

echo -e "Downloading mirror list..."
curl -s "$MIRRORLIST" | sed 's/^#Server/Server/' >/etc/pacman.d/mirrorlist

echo -e "Clearing partition table..."
/usr/bin/sgdisk --zap $DEVICE

echo -e "Wiping disk..."
/usr/bin/dd if=/dev/zero of=$DEVICE bs=512 count=2048
/usr/bin/wipefs --all $DEVICE

echo -e "Creating partitions..."
if [ "$BOOTTYPE" == "mbr" ]; then
  BOOTUUID=$(uuidgen)
  parted --script $DEVICE mklabel msdos
  parted --script $DEVICE mkpart primary ext4 0% 513M
  mkfs.ext4 -U $BOOTUUID -q -F $BOOTDEV
  tune2fs -c 0 -i 0 $BOOTDEV
  BOOTFS=ext4
else
  BOOTUUID=$(printf '%X' $(date +%s))
  parted --script $DEVICE mklabel gpt
  parted --script $DEVICE mkpart ESP fat32 0% 513M
  mkfs.fat -i $BOOTUUID -s2 -F32 $BOOTDEV
  BOOTFS=vfat
  BOOTUUID=${BOOTUUID:0:4}-${BOOTUUID:4:8}
fi
parted --script $DEVICE mkpart primary 513M 100%

parted --script $DEVICE set 1 boot on
parted --script $DEVICE set 2 lvm on

if [ "$ENCRYPT" == "yes" ]; then
  echo -n ${LUKS_PASSWORD} | cryptsetup --uuid $LUKSUUID --key-file - --batch-mode --cipher aes-xts-plain --key-size 512 --verify-passphrase luksFormat $LUKSDEV
  echo -n ${LUKS_PASSWORD} | cryptsetup --key-file - luksOpen $LUKSDEV $LUKSNAME
  pvcreate -ff -y /dev/mapper/$LUKSNAME
  sleep 1
  vgcreate -y $VGNAME /dev/mapper/$LUKSNAME
  sleep 1
else
  pvcreate -ff -y $LUKSDEV
  sleep 1
  vgcreate -y $VGNAME $LUKSDEV
  sleep 1
fi

sleep 1
lvcreate -L +12288M -n $ROOTLV /dev/$VGNAME
sleep 1

mkfs.ext4 -U $ROOTUUID -q -F /dev/$VGNAME/$ROOTLV
tune2fs -c 0 -i 0 /dev/$VGNAME/$ROOTLV
mount -t ext4 /dev/$VGNAME/$ROOTLV $CHROOT_DIR
mkdir -p $CHROOT_DIR/boot
mount $BOOTDEV $CHROOT_DIR/boot

#echo -e "Creating /root filesystem..."
#/usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root $ROOT_PART

echo -e "Bootstrapping base installation..."
echo "Server = http://mirror.digitalnova.at/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
/usr/bin/pacstrap $CHROOT_DIR base linux linux-firmware
/usr/bin/arch-chroot $CHROOT_DIR pacman -S --noconfirm dhcpcd openssh efibootmgr grub lvm2 cryptsetup sudo openssh dhclient vim networkmanager parted

echo -e "Create fstab..."
cat >> $CHROOT_DIR/etc/fstab << EOF
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    nodev,noexec,nosuid 0       0
UUID=${ROOTUUID} /              ext4    errors=remount-ro,noatime,discard 0       1
UUID=${BOOTUUID} /boot          ${BOOTFS}    defaults        0       2
EOF

echo -e "Grub config..."
if [ "$ENCRYPT" == "yes" ]; then
  #GRUBROOTDEV="cryptdevice=\/dev\/disk\/by-uuid\/${LUKSUUID}:${LUKSNAME} root=UUID=${ROOTUUID}"
  GRUBROOTDEV="cryptdevice=UUID=${LUKSUUID}:${LUKSNAME} root=UUID=${ROOTUUID}"
  INITHOOK="encrypt"
  # generate crypttab
  echo "${LUKSNAME} UUID=${LUKSUUID} none luks" >> $TMPDIR/etc/crypttab
else
  GRUBROOTDEV="root=UUID=${ROOTUUID}"
fi

echo -e "Installing grub..."
if [ "$BOOTTYPE" == "mbr" ]; then
  # install grub based on boottype
  sed "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUBROOTDEV} lang={ box_xorg_keymap }  quiet splash\"/" -i $CHROOT_DIR/etc/default/grub
  sed "s/^GRUB_TIMEOUT=.*/#GRUB_TIMEOUT=5/" -i $CHROOT_DIR/etc/default/grub
  sed "s/^#GRUB_HIDDEN_TIMEOUT=.*/GRUB_HIDDEN_TIMEOUT=1/" -i $CHROOT_DIR/etc/default/grub
  sed "s/^#GRUB_HIDDEN_TIMEOUT_QUIET=.*/GRUB_HIDDEN_TIMEOUT_QUIET=true/" -i $CHROOT_DIR/etc/default/grub

  /usr/bin/arch-chroot $CHROOT_DIR /usr/bin/grub-install --no-nvram --removable --target=i386-pc ${DEVICE}

  /usr/bin/arch-chroot $CHROOT_DIR sh -c "/usr/bin/grub-mkconfig > /boot/grub/grub.cfg"
else
  #/usr/bin/arch-chroot $CHROOT_DIR /usr/bin/grub-install --no-nvram --removable --target=x86_64-efi \
  #  --efi-directory=/boot --boot-directory=/boot
  #/usr/bin/arch-chroot $CHROOT_DIR mkdir -p /boot/efi/boot >/dev/null 2>&1
  #/usr/bin/arch-chroot $CHROOT_DIR cp /boot/efi/arch/grubx64.efi /boot/efi/boot/bootx64.efi
  /usr/bin/arch-chroot $CHROOT_DIR bootctl install

cat <<-EOF >"$CHROOT_DIR/boot/loader/loader.conf"
timeout 5
#console-mode keep
default archlinux
EOF

cat <<-EOF >"$CHROOT_DIR/boot/loader/entries/archlinux.conf"
title ArchLinux
linux /vmlinuz-linux
#initrd /intel-ucode.img
initrd /initramfs-linux.img
options ${GRUBROOTDEV} 
#options root=/dev/nvme0n1p3 rw intel_iommu=on intel_pstate=disable pci=noaer
EOF

fi

echo -e "Extra silent book..."
echo "kernel.printk = 3 3 3 3" >> $CHROOT_DIR/etc/sysctl.d/20-quiet-printk.conf

echo -e "Inject inithook into ramdisk..."
sed "s/^HOOKS=.*/HOOKS=\"base udev modconf keyboard block ${INITHOOK} lvm2 filesystems fsck\"/" -i $CHROOT_DIR/etc/mkinitcpio.conf
/usr/bin/arch-chroot $CHROOT_DIR sh -c "/usr/bin/mkinitcpio -p linux"

#echo -e "Generating filesystem table..."
#/usr/bin/genfstab -p $CHROOT_DIR >>"$CHROOT_DIR/etc/fstab"

echo -e "Generating config script..."
/usr/bin/install --mode=0755 /dev/null "$CHROOT_DIR/usr/local/bin/arch-config.sh"

cat <<-EOF >"$CHROOT_DIR/usr/local/bin/arch-config.sh"
    echo -e "Configuring base system..."
    echo "{ box_name }" > /etc/hostname
    /usr/bin/ln -s /usr/share/zoneinfo/{ box_timezone } /etc/localtime
    echo 'KEYMAP={ box_keymap }' > /etc/vconsole.conf
    echo 'LANG={ box_locale }' > /etc/locale.conf
    /usr/bin/sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    /usr/bin/sed -i 's/#{ box_locale }/{ box_locale }/' /etc/locale.gen
    /usr/bin/locale-gen
    /usr/bin/mkinitcpio -p linux
    #/usr/bin/usermod --password $PASSWORD root
    echo root:{ box_password } | /usr/bin/chpasswd
    /usr/bin/systemctl enable NetworkManager
    /usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
    /usr/bin/systemctl enable sshd.service
    /usr/bin/pacman -S --noconfirm rng-tools
    /usr/bin/systemctl enable rngd

    echo -e "Configuring Vagrant specific settings..."
    #/usr/bin/useradd --password $PASSWORD_VAGRANT --comment 'Vagrant User' --create-home --user-group vagrant
    /usr/bin/useradd --comment 'Vagrant User' --create-home --user-group vagrant
    echo vagrant:{ vagrant_password } | /usr/bin/chpasswd
    echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
    echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
    /usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
#    /usr/bin/install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
#    /usr/bin/curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
#    /usr/bin/chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
#    /usr/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys
    rm -f /usr/bin/vi
    ln -s /usr/bin/vim /usr/bin/vi
    # reset password expiration
EOF

echo -e "Entering chroot to install..."
/usr/bin/arch-chroot $CHROOT_DIR /usr/local/bin/arch-config.sh
rm $CHROOT_DIR/usr/local/bin/arch-config.sh

echo -e "Completing installation and rebooting..."
/usr/bin/sleep 3
/usr/bin/umount $CHROOT_DIR/boot
/usr/bin/umount $CHROOT_DIR
/usr/bin/systemctl reboot
