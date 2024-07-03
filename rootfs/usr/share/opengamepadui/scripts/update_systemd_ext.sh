#!/bin/bash
set -ex

cd ~/.var/lib/extensions
rm -rf squashfs-root
rm -rf opengamepadui.raw.updated

echo "Extracting extension"
unsquashfs -no-xattrs opengamepadui.raw

# Check the OS version
OS_ID=$(grep '^ID=' /etc/os-release)
OS_VERSION=$(grep '^VERSION_ID=' /etc/os-release)

# Check the extension version
EXT_ID=$(grep '^ID=' squashfs-root/usr/lib/extension-release.d/extension-release.opengamepadui)
EXT_VERSION=$(grep '^VERSION_ID=' squashfs-root/usr/lib/extension-release.d/extension-release.opengamepadui)

echo "Details:"
echo "  ${OS_ID}"
echo "  ${OS_VERSION}"
echo "  ${EXT_ID}"
echo "  ${EXT_VERSION}"
if [[ "${OS_ID}" == "${EXT_ID}" && "${OS_VERSION}" == "${EXT_VERSION}" ]]; then
  echo "Extension is already up-to-date"
  rm -rf squashfs-root
  exit 0
fi

echo "Extension version does not match OS version. Updating extension."
echo "${OS_ID}" >squashfs-root/usr/lib/extension-release.d/extension-release.opengamepadui
echo "${OS_VERSION}" >>squashfs-root/usr/lib/extension-release.d/extension-release.opengamepadui
mksquashfs squashfs-root opengamepadui.raw.updated
mv opengamepadui.raw.updated opengamepadui.raw
rm -rf squashfs-root
