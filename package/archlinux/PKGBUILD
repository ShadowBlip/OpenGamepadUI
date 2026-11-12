# Maintainer: Derek J. Clark <derekjohn.clark@gmail.com>
pkgname=opengamepadui-bin
_pkgbase=opengamepadui
pkgver=0.47.0
pkgrel=1
pkgdesc="Open source game launcher"
arch=('x86_64' 'aarch64')
url="https://github.com/ShadowBlip/OpenGamepadUI"
license=('GPL')
depends=('glibc' 'gcc-libs' 'libx11' 'libxres' 'libxcb' 'libxext' 'libxau'
  'libxdmcp' 'gamescope' 'vulkan-tools' 'inputplumber'
  'mesa-utils'
)
optdepends=('firejail' 'bubblewrap' 'wireplumber' 'networkmanager' 'bluez' 'dbus' 'powerstation')
provides=('opengamepadui')
conflicts=('opengamepadui-git')
source_x86_64=(opengamepadui-v${pkgver}.tar.gz::https://github.com/ShadowBlip/OpenGamepadUI/releases/download/v${pkgver}/opengamepadui-x86_64.tar.gz)
source_aarch64=(opengamepadui-v${pkgver}.tar.gz::https://github.com/ShadowBlip/OpenGamepadUI/releases/download/v${pkgver}/opengamepadui-aarch64.tar.gz)

sha256sums_x86_64=('0c0b65ec8cb96ab961045a629eecda971e2be582c129b074899bfc424b09b734')
sha256sums_aarch64=('423537c2564267da079a55ad7c17d1b45ee77593ed38a4479071d1af0f6438f7')

package() {
  options=('!strip')
  cd "$srcdir/${_pkgbase}"

  make install PREFIX="${pkgdir}/usr" ARCH=${CARCH}
}
