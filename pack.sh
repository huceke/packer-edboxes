#!/bin/bash

tar --exclude packer-edboxes/images \
  --exclude packer-edboxes/http \
  --exclude packer-edboxes/packer_cache \
  --exclude packer-edboxes/builder-*.json \
  --exclude packer-edboxes/vagrant \
  --exclude packer-edboxes/.vagrant \
  --exclude packer-edboxes/iso \
  --exclude packer-edboxes/tmp \
  --exclude packer-edboxes/build \
  --exclude packer-edboxes/cloud-init \
  -czf ../packer-edboxes.tar.gz ../packer-edboxes
