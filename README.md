# packer-edboxes

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)


*packer-edboxes* is a flexible tool that creates virtual machine images. It's based on [Packer](https://packer.io) and extendable with addons ([Ansible](https://ansible.com/) roles).

## Prerequisites

Basically packer-edboxes should run on any current Linux distro. The following tools are required:

- openssl
- packer
- ansible
- qemu
- virt-viewer
- spice-gtk
- spice
- libguestfs

Additional for EFI builds :

- edk2-ovmf

*Note that this list of package names applies to Archlinux. Naming might be different on your distro.*

##  Usage

### Preparing the packer environment

Find a suitable example box configuration file in the `configs/` folder, copy it to a new file and adjust it to your needs. E.g.:

```
cp configs/base_debian.yml yourbox.yml
```

*Not all parameters you initially find in the example files need to be present. If something's missing, a default value is taken from `ansible/boxconfig.yml`*

Run the builder.yml playbook to create the packer environment.

```
ansible-playbook ansible/builder.yml --extra-vars @yourbox.yml
```

### Running the packer build

The box_packer_run flag is set to "no" in all example box configuration files, which means the packer environment is created but Ansible doesn't start the actual packer build automatically.

Use the output from **TASK [print build command]** to start the packer build process.

Once you are happy with your build set **box_packer_run: yes** to automate this step. No packer output will be printed during **TASK [running packer]** then.


### The box configuration file

The example configuration looks like this:

```
box_distribution: archlinux
box_name: base
box_addon: []
box_boottype: mbr
box_encrypt: none
box_password: changeme1234
box_desktop_user: yourusername
box_ansible_run: yes
box_packer_run: no
box_packer_headless: "false"
box_disk_size: 16384M
box_locale: "en_US.UTF-8"
box_keymap: "de-latin1-nodeadkeys"
box_xorg_keymap: "de"
box_xorg_keymap_model: "pc105"
box_xorg_keymap_vatiant: "nodeadkeys"
```

The following configuration parameters are understood:

|Parameter|Value|Description|
| --- | --- | --- |
|box_boottype|mbr\|efi|mbr or efi boot for the box|
|box_encrypt|none\|luks|Encrypt box using luks|
|box_distribution|archlinux\|debian\|ununtu\|fedora\|rocky8\|rhel7\|rhel8|Box linux distribution|
|box_password|changeme1234|Password for encryption and created users|
|box_addon|[]|List of enabled box addons|
||[]|Basic system|
||['desktop']|Destop system|
||['desktop', 'youraddon']|Destop system with your addon|
|box_desktop_user|yourusername|Username for desktop box|
|box_ansible_run|yes\|no|Run Ansible inside the freshly built box|
|box_packer_run|yes\|no|Run packer to build the box|
|box_packer_headless|"true"\|"false"|Headless works only for non encrypted boxes|
|box_disk_size|16384M|Box disk Size|
|box_locale:|en_US.UTF-8|Box locale setting|
|box_timezone|Europe/Vienna|Box timezone|
|box_keymap|de-latin1-nodeadkeys|Box keymnap|
|box_xorg_keymap|de|Box xorg keymap|
|box_xorg_keymap_model|pc105|Box xorg keyboard model|
|box_xorg_keymap_vatiant|nodeadkeys|Box xorg keyboard variant|


### Running the box

```
ansible-playbook --ask-become-pass ansible/startvm.yml --extra-vars @yourbox.yml
```

### Where to find the created image file

The created box image is stored in **build/images/[box_distribution]**

### Example build output

In this case for archlinux mbr none encrypted :

```
build
|-- builder-archlinux-archlinux-mbr-none.json
|-- http
|   `-- archbootstrap.sh-mbr-none
|-- images
|   `-- archlinux
|       `-- archlinux-archlinux-mbr-none.qcow2

```

## Suported distributions

- Debian 11
- Fedora 34
- Archlinux 
- RedHat 8.4
- RedHat 7.9
- Rocky 8.4
- AlmaLinux 8.4
- Ubuntu 20.04

For RedHat create the directory **iso** inside **packer-edboxes** and put the Binary DVD for the desired RedHat version there.

## Inluded addons

The addons are ansible roles stored in **ansible/roles/**

### Addon : desktop

This addon provides a simple basic mate desktop system. It only works for the box distributions fedora,debian,ubuntu,archlinux


## Sealing VM

```
sudo virt-sysprep -a build/images/[distribution]/[yourbox]
```

## Author
Edgar Vichor

## License
Copyright &copy; 2021 Edgar Vichor, Released under the [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0). 

