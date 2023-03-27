# OpenGamepadUI Install Guide

> :warning: OpenGamepadUI is still in the early stages of development, so expect to
> encounter many bugs.

## Requirements

### Runtime Requirements

The following are required to run OpenGamepadUI:

- gamescope
- gcc-libs
- glibc
- libevdev
- libx11
- libxau
- libxcb
- libxdmcp
- libxext
- libxres
- ryzenadj (optional)
- mangoapp (optional)
- wireplumber (optional)
- nmcli (optional)
- firejail (optional)

## Installation

OpenGamepadUI offers a variety of installation methods. It can be installed
locally in your user directory or system-wide. Use one of the following
installation guides to install OpenGamepadUI on your system:

- [SteamOS/Steam Deck Install](/docs/install/INSTALL_STEAMOS.md)
- [ArchLinux Install](/docs/install/INSTALL_ARCH.md)
- [Binary Install](/docs/install/INSTALL_BINARY.md)
- [Source Install](/docs/install/INSTALL_SOURCE.md)

## Usage

Once OpenGamepadUI is installed, it should show up as an application you can
launch from your desktop environment.

Alternatively you can launch it from the command line with:

```bash
opengamepadui
```

or, if installed in the local user directory:

```bash
~/.local/bin/opengamepadui
```
