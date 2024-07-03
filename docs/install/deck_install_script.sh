#!/bin/bash
# OpenGamepadUI installer based on Decky installer:
# https://github.com/SteamDeckHomebrew/decky-installer

TITLE="OpenGamepadUI Installer"

# if a password was set by installer, this will run when the program closes
temp_pass_cleanup() {
  echo $PASS | sudo -S -k passwd -d deck
}

# removes unhelpful GTK warnings
zen_nospam() {
  zenity 2> >(grep -v 'Gtk' >&2) "$@"
}

# check if JQ is installed
if ! command -v jq &>/dev/null; then
  echo "JQ could not be found, please install it"
  echo "Info on how to install it can be found at https://stedolan.github.io/jq/download/"
  exit
fi

# check if github.com is reachable
if ! curl -Is https://github.com | head -1 | grep 200 >/dev/null; then
  echo "Github appears to be unreachable, you may not be connected to the internet"
  exit 1
fi

# if the script is not root yet, get the password and rerun as root
if (($EUID != 0)); then
  PASS_STATUS=$(passwd -S deck 2>/dev/null)
  if [ "$PASS_STATUS" = "" ]; then
    echo "Deck user not found. Continuing anyway, as it probably just means user is on a non-steamos system."
  fi

  if [ "${PASS_STATUS:5:2}" = "NP" ]; then # if no password is set
    if (zen_nospam --title="${TITLE}" --width=300 --height=200 --question --text="You appear to have not set an admin password.\nOpenGamepadUI can still install by temporarily setting your password to 'OGUI!' and continuing, then removing it when the installer finishes\nAre you okay with that?"); then
      yes "OGUI!" | passwd deck
      trap temp_pass_cleanup EXIT # make sure password is removed when application closes
      PASS="OGUI!"
    else exit 1; fi
  else
    # get password
    FINISHED="false"
    while [ "$FINISHED" != "true" ]; do
      PASS=$(zen_nospam --title="${TITLE}" --width=300 --height=100 --entry --hide-text --text="Enter your sudo/admin password")
      if [[ $? -eq 1 ]] || [[ $? -eq 5 ]]; then
        exit 1
      fi
      if (echo "$PASS" | sudo -S -k true); then
        FINISHED="true"
      else
        zen_nospam --title="${TITLE}" --width=150 --height=40 --info --text "Incorrect Password"
      fi
    done
  fi

  # get user dir before rerunning as root, otherwise it'll just be 'home/root'

  echo "$PASS" | sudo -S -k bash "$0" "$@" # rerun script as root
  exit 1
fi

# all code below should be run as root
USER_DIR="$(getent passwd $SUDO_USER | cut -d: -f6)"
EXTENSIONS_FOLDER="${USER_DIR}/.var/lib/extensions"

# if OpenGamepadUI is already installed, then also add an 'uninstall' prompt
if [[ -f "${EXTENSIONS_FOLDER}/opengamepadui.raw" ]]; then
  BRANCH=$(zen_nospam --title="${TITLE}" --width=360 --height=170 --list --radiolist --text "Select Option:" --hide-header --column "Buttons" --column "Choice" --column "Info" TRUE "release" "(Recommended option)" FALSE "uninstall OpenGamepadUI" "")
else
  BRANCH=$(zen_nospam --title="${TITLE}" --width=300 --height=100 --list --radiolist --text "Select Branch:" --hide-header --column "Buttons" --column "Choice" --column "Info" TRUE "release" "(Recommended option)")
fi
if [[ $? -eq 1 ]] || [[ $? -eq 5 ]]; then
  exit 1
fi

# uninstall if uninstall option was selected
if [ "$BRANCH" == "uninstall OpenGamepadUI" ]; then
  (
    echo "20"
    echo "# Disabling and removing services"
    sudo -u $SUDO_USER systemctl --user disable --now systemd-sysext-updater.service >/dev/null
    rm -f "${USER_DIR}/.config/systemd/user/systemd-sysext-updater.service"

    echo "50"
    echo "# Removing OpenGamepadUI"
    rm -rf "${EXTENSIONS_FOLDER}/opengamepadui.raw"
    rm -rf "${EXTENSIONS_FOLDER}/squashfs-root"
    rm -rf "${EXTENSIONS_FOLDER}/extensions"
    rm -f "${USER_DIR}/Desktop/return-opengamepadui.desktop"
    #rm -rf "${USER_DIR}/.local/share/opengamepadui"

    echo "80"
    echo "# Refreshing extensions"
    systemd-sysext refresh >/dev/null

    echo "100"
    echo "# Uninstall finished, installer can now be closed"
  ) |
    zen_nospam --progress \
      --title="${TITLE}" \
      --width=300 --height=100 \
      --text="Uninstalling..." \
      --percentage=0 \
      --no-cancel
  exit 1
fi

# otherwise install OpenGamepadUI
(
  echo "15"
  echo "# Creating file structure"
  sudo -u $SUDO_USER mkdir -p "${EXTENSIONS_FOLDER}" "${USER_DIR}/.config/systemd/user" "${USER_DIR}/.local/bin"
  if ! [ -s /var/lib/extensions ]; then
    ln -s "${EXTENSIONS_FOLDER}" /var/lib/extensions
  fi

  echo "30"
  echo "# Finding latest $BRANCH"
  DOWNLOADURL="https://github.com/ShadowBlip/OpenGamepadUI/releases/latest/download/opengamepadui.raw"

  echo "35"
  echo "# Installing systemd extension updater"
  curl -L https://raw.githubusercontent.com/ShadowBlip/OpenGamepadUI/main/rootfs/usr/lib/systemd/user/systemd-sysext-updater.service -o "${USER_DIR}/.config/systemd/user/systemd-sysext-updater.service"
  chown $SUDO_USER "${USER_DIR}/.config/systemd/user/systemd-sysext-updater.service"
  curl -L https://raw.githubusercontent.com/ShadowBlip/OpenGamepadUI/main/rootfs/usr/share/opengamepadui/scripts/update_systemd_ext.sh -o "${USER_DIR}/.local/bin/update_systemd_ext.sh"
  chown $SUDO_USER "${USER_DIR}/.local/bin/update_systemd_ext.sh"

  echo "45"
  echo "# Installing OpenGamepadUI extension"
  curl -L $DOWNLOADURL -o ${EXTENSIONS_FOLDER}/opengamepadui.raw 2>&1 | stdbuf -oL tr '\r' '\n' | sed -u 's/^ *\([0-9][0-9]*\).*\( [0-9].*$\)/\1\n#Download Speed\:\2/' | zen_nospam --progress --title "Downloading OpenGamepadUI" --text="Download Speed: 0" --width=300 --height=100 --auto-close --no-cancel
  chown $SUDO_USER "${EXTENSIONS_FOLDER}/opengamepadui.raw"

  echo "60"
  echo "# Updating extension"
  sudo -u $SUDO_USER "${USER_DIR}/.local/bin/update_systemd_ext.sh"

  echo "75"
  echo "# Enabling systemd extension updater"
  sudo -u $SUDO_USER systemctl --user enable systemd-sysext-updater
  sudo -u $SUDO_USER systemctl --user start systemd-sysext-updater
  sleep 3

  echo "80"
  echo "# Enabling systemd extensions"
  systemctl enable systemd-sysext
  systemctl start systemd-sysext
  systemd-sysext refresh
  systemd-sysext status

  echo "85"
  echo "# Enabling powerstation service"
  systemctl reload dbus
  systemctl enable powerstation
  systemctl start powerstation

  echo "90"
  echo "# Creating desktop shortcuts"
  cat >"${USER_DIR}/Desktop/return-opengamepadui.desktop" <<-EOM
		#!/usr/bin/env xdg-open
		[Desktop Entry]
		Version=1.0
		Name=Return to OpenGamepadUI
		GenericName=Game launcher and overlay
		Type=Application
		Comment=Game launcher and overlay
		Icon=opengamepadui
		Exec=opengamepadui-session-select opengamepadui
		Terminal=false
	EOM

  echo "100"
  echo "# Install finished, installer can now be closed"
) |
  zen_nospam --progress \
    --title="${TITLE}" \
    --width=300 --height=100 \
    --text="Installing..." \
    --percentage=0 \
    --no-cancel # not actually sure how to make the cancel work properly, so it's just not there unless someone else can figure it out

if [ "$?" = -1 ]; then
  zen_nospam --title="${TITLE}" --width=150 --height=70 --error --text="Download interrupted."
fi
