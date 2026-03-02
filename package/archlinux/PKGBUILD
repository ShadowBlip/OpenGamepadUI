# Maintainer: Derek J. Clark <derekjohn.clark@gmail.com>
pkgname=opengamepadui-bin
_pkgbase=opengamepadui
pkgver=0.44.3
pkgrel=1
pkgdesc="Open source game launcher"
arch=('x86_64')
url="https://github.com/ShadowBlip/OpenGamepadUI"
license=('GPL')
depends=('glibc' 'gcc-libs' 'libx11' 'libxres' 'libxcb' 'libxext' 'libxau'
  'libxdmcp' 'gamescope' 'vulkan-tools' 'inputplumber'
  'mesa-utils'
)
optdepends=('firejail' 'bubblewrap' 'wireplumber' 'networkmanager' 'bluez' 'dbus' 'powerstation')
provides=('opengamepadui')
conflicts=('opengamepadui-git')
source=(opengamepadui-v$pkgver.tar.gz::https://github.com/ShadowBlip/OpenGamepadUI/releases/download/v$pkgver/opengamepadui.tar.gz)

sha256sums=('b301b501c0e42d92ff13d5bee78df30f3adf064e287255ca5d80fb0d5c960037')

package() {
  options=('!strip')
  cd "$srcdir/${_pkgbase}"

  make install PREFIX="${pkgdir}/usr"
}
