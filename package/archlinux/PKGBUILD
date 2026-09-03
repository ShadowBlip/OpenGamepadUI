# Maintainer: Derek J. Clark <derekjohn.clark@gmail.com>
pkgname=opengamepadui-bin
_pkgbase=opengamepadui
pkgver=0.46.1
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

sha256sums_x86_64=('05fe8b0ecb89d3303126ba26fe3e10b9b095c8b6bba46d4d500b7fc58571a90a')
sha256sums_aarch64=('84b075f8f8c3925b9e0925705adab37f9237a8ff6eeabc6cf4c3af927520413c')

package() {
  options=('!strip')
  cd "$srcdir/${_pkgbase}"

  make install PREFIX="${pkgdir}/usr" ARCH=${CARCH}
}
