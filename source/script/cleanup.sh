#!/bin/sh

## Zero out the free space to save space in the final image
# makes only sense in non encrypted images
#dd if=/dev/zero of=/EMPTY bs=1M
#rm -f /EMPTY
#sync

history -c

exit 0
