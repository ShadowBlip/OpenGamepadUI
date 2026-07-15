# Maintainer: Derek J. Clark <derekjohn.clark@gmail.com>
pkgname=opengamepadui-bin
_pkgbase=opengamepadui
pkgver=0.45.1
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

sha256sums_x86_64=('571844af911a0f7f187fed7f07e9cfccad45695d602c36f9091412024f55c6ed')
sha256sums_aarch64=('090b392cfa9fb8c558f7ddeede1032afdde4784aad308e90f35f27be64a55dd7')

package() {
  options=('!strip')
  cd "$srcdir/${_pkgbase}"

  make install PREFIX="${pkgdir}/usr" ARCH=${CARCH}
}
