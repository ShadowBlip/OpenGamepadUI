# Maintainer: Derek J. Clark <derekjohn.clark@gmail.com>
pkgname=opengamepadui-bin
_pkgbase=opengamepadui
pkgver=0.46.0
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

sha256sums_x86_64=('7e63c37cacf1c3fc1692062d1a196cc140bcaa59abe190081e44892ea43011d4')
sha256sums_aarch64=('6feeb101093d53ef7c30918f65853c13c0882d66382b9cddd11da308b6257ae7')

package() {
  options=('!strip')
  cd "$srcdir/${_pkgbase}"

  make install PREFIX="${pkgdir}/usr" ARCH=${CARCH}
}
