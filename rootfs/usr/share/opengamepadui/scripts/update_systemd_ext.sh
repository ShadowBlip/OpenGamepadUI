#!/bin/bash
set -ex

cd ~/.var/lib/extensions
rm -rf squashfs-root
unsquashfs -no-xattrs opengamepadui.raw
grep '^ID=' /etc/os-release >squashfs-root/usr/lib/extension-release.d/extension-release.opengamepadui
grep '^VERSION_ID=' /etc/os-release >>squashfs-root/usr/lib/extension-release.d/extension-release.opengamepadui
rm -f opengamepadui.raw
mksquashfs squashfs-root opengamepadui.raw
