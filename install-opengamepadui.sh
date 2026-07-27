#!/bin/bash
set -e

# Config

TARBALL_URL="https://github.com/ShadowBlip/OpenGamepadUI/releases/latest/download/opengamepadui.tar.gz"
STEAMOS_SCRIPT_URL="https://raw.githubusercontent.com/ShadowBlip/OpenGamepadUI/main/docs/install/deck_install_script.sh"

TMPDIR=""
cleanup() { [ -n "$TMPDIR" ] && rm -rf "$TMPDIR"; }
trap cleanup EXIT

log() { echo "[ogui] $1"; }
err() { echo "[ogui][error] $1" >&2; }

# Helpers

# Checks if /usr is read only(steamos is immutable)
usr_is_readonly() {
  mount | grep -E ' on /usr ' | grep -q '(ro,|,ro)'
}

download_tarball() {
  TMPDIR="$(mktemp -d)"
  cd "$TMPDIR"

  log "Downloading OpenGamepadUI tarball"
  curl -fL "$TARBALL_URL" -o opengamepadui.tar.gz

  log "Extracting tarball"
  tar xzf opengamepadui.tar.gz
  cd opengamepadui
}

# Install paths

install_steamos() {
  log "Running SteamOS installer"
  curl -fsSL "$STEAMOS_SCRIPT_URL" -o /tmp/ogui-steamos.sh
  chmod +x /tmp/ogui-steamos.sh
  exec /tmp/ogui-steamos.sh
}

install_system() {
  if usr_is_readonly; then
    err "/usr is read-only. System-wide install not possible."
    exit 1
  fi

  log "Installing OpenGamepadUI system-wide (/usr)"
  download_tarball
  sudo make install PREFIX=/usr
}

install_local() {
  log "Installing OpenGamepadUI locally (~/.local)"
  download_tarball
  make install
}

# Uninstall paths

uninstall_system() {
  log "Uninstalling system-wide OpenGamepadUI"
  sudo rm -rf \
    /usr/bin/opengamepadui \
    /usr/share/opengamepadui \
    /usr/share/applications/opengamepadui.desktop \
    /usr/share/icons/hicolor/scalable/apps/opengamepadui.svg \
    /usr/lib/systemd/user/systemd-sysext-updater.service \
    /usr/lib/systemd/user/ogui-overlay-mode.service
}

uninstall_local() {
  log "Uninstalling local OpenGamepadUI"
  rm -rf \
    ~/.local/bin/opengamepadui \
    ~/.local/share/opengamepadui \
    ~/.local/share/applications/opengamepadui.desktop \
    ~/.local/share/icons/hicolor/scalable/apps/opengamepadui.svg \
    ~/.local/lib/systemd/user/systemd-sysext-updater.service \
    ~/.local/lib/systemd/user/ogui-overlay-mode.service
}

uninstall_steamos() {
  log "Running SteamOS uninstaller"
  curl -fsSL "$STEAMOS_SCRIPT_URL" -o /tmp/ogui-steamos.sh
  chmod +x /tmp/ogui-steamos.sh
  exec /tmp/ogui-steamos.sh
}

# Menu

echo "===================================="
echo " OpenGamepadUI Installer"
echo "===================================="
echo

echo "0) Install OGUI (SteamOS)"
echo "1) Install OGUI (System wide Installation)"
echo "2) Install OGUI (Local Installation)"
echo "3) Uninstall OGUI"
echo

read -rp "Select an option [0-3] (Ctrl+C to cancel): " option

case "$option" in
0)
  install_steamos
  ;;
1)
  install_system
  ;;
2)
  install_local
  ;;
3)
  echo
  echo "Uninstall:"
  echo "  1) System wide"
  echo "  2) Local"
  echo "  3) From SteamOS"
  read -rp "Choice [1-3] (Ctrl+C to cancel): " uopt

  case "$uopt" in
  1) uninstall_system ;;
  2) uninstall_local ;;
  3) uninstall_steamos ;;
  *)
    err "Invalid uninstall option"
    exit 1
    ;;
  esac
  ;;
*)
  err "Invalid option"
  exit 1
  ;;
esac
