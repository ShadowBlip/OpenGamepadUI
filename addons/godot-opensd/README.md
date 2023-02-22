# OpenSD
An open-source Linux userspace driver for Valve's Steam Deck hardware.

[![](https://img.shields.io/gitlab/license/open-sd/opensd?style=for-the-badge)](https://choosealicense.com/licenses/gpl-3.0/) [![](https://img.shields.io/badge/Written%20in-C%2B%2B-%23f34b7d?style=for-the-badge)]() [![](https://img.shields.io/badge/Donate-PayPal-blue?style=for-the-badge)](https://paypal.me/seekdev)

[![](https://img.shields.io/badge/Version-0.48-blue?style=for-the-badge)]() [![](https://img.shields.io/gitlab/last-commit/open-sd/opensd?style=for-the-badge)]() [![](https://img.shields.io/gitlab/issues/open/open-sd/opensd?style=for-the-badge)](https://paypal.me/seekdev)

<br>

## About
OpenSD is a highly-configurable userspace driver for the Steam Deck written in modern C++.

It aims to be lighweight, very fast and provide a way to fully utilize the hardware without running any closed-source, proprietary or anti-privacy software like Steam.

If you’re like me, you want to tinker with your hardware devices and build neat projects on them without needing to run any bloat.  As someone who builds and designs a lot of embedded systems, uses minimal Linux desktop envoronments and believes in Unix Philosophy: keeping things open, fast and small is paramount.

At the time of writing, there is no way to utilize the gamepad portion (buttons, thumbsticks, gyros, etc.) of the Steam Deck without also having to run Steam, since Steam implements an unpublished, undocumented, closed-source userspace driver to make it all work.  This means signing into an online service to access basic hardware functionality on a device that you own.  As good as Valve has been about Linux support and contributing to open-source initiatives, they’re not so good about keeping their hardware open, nor do they respect privacy as a human right.

This goal of this software is to provide a better, fully open-source implementation; ultimately unlocking the hardware to be used freely and unencumbered any by proprietary requirements.

<br>

## Features
Development is still ongoing, so several of the features are still incomplete.

- [x]   Small, fast, multi-threaded driver daemon.
- [x]   Fully configurable and mappable.
- [x]   Universal bindings system.
- [x]   Customizable gamepad profiles.
- [x]   Configurable by ini file.
- [ ]   GUI configuration tool.
- [ ]   CLI scripting tool.
- [x]   Fully configurable gamepad input (buttons, axes, etc.)
- [x]   Highly configurable trackpad support.
- [x]   Fully configurable mouse emulation.
- [ ]   Fully configurable motion controls.
- [x]   Configurable radial deadzones.
- [ ]   Full support for Force-Feedback / haptics.
- [ ]   Automatic and manual backlight control.
- [ ]   Battery reporting
- [x]   Install script
- [x]   Online documentation / Wiki
- [x]   Offline documentation
- [X]   manpage

<br>

## Current State
The current state is very usable.  Most of the main functionality of the driver is implemented and working reliably; more features will be added in time.  The GUI configuration tool does not exist yet, so all configuration is done with **ini** files (if you're like me you prefer that anyway, haha).

<br>

## Requirements
The code itself has very few dependencies other than the kernel.
- Kernel 4.9+
- GCC 8.0+ (for c++20 designated initializers)
- cmake 3.10+
- systemd (optional, for user service file)

Some of the hardware support for the Steam Deck is pretty recent, so using the most recent kernel is highly recommended.

<br>

## Getting started
Check out the Getting Started section in the [online documentation](https://open-sd.gitlab.io/opensd-docs) for steps on getting, building, installing.

A current git build of OpenSD is also available in the [Arch User Repository](https://aur.archlinux.org/packages/opensd-git).

<br>

## Using and configuring OpenSD
A beautiful online [user's manual](https://open-sd.gitlab.io/opensd-docs/opensd-docs/latest/users_manual/running.html) can also be found in the online documentation.

Offline documentation is also available in the *doc* directory of this repository.  If you've already installed OpenSD, documentation can be found in `/usr/local/share/doc/opensd/` as well as man pages: **opensdd(1)** and **opensd-files(5)**

## Roadmap
The next big steps are getting a good understanding of the haptic reports the Steam Deck uses and getting IPC working so clients can connect to the daemon.

This is *roughly* the roadmap I'm currently looking at:
- IPC
- CLI scripting tool
- Force Feedback / haptics
- Backlight control
- GUI configuration tool

<br>

## Steam Deck hardware documentation
I've published a group of [hardware notes](https://open-sd.gitlab.io/opensd-docs/opensd-docs/latest/hardware_notes/preface.html) over in the user documentation site which may be of interest to some of you.

<br>

## Contributing
There are still a lot of open questions about the Steam Deck HID reports, particularly feature reports.  Most of the the work has come from reverse engineering input reports and function documenetation from the kernel Steam Controller driver.  Anyone who can fill in blanks in the code would be appreciated, just open an issue or submit a PR.

The user documentation also has its own repo at https://gitlab.com/open-sd/opensd-docs if you'd like to help with that.  Please open an issue or submit a PR there for anything documentation related.

As always, feel free to buy me a coffee if you appreciate my work ;)

<br>

## License
OpenSD is licensed under THE GNU GPLv3+.  See LICENSE for details.

<br>

## Legal
I have no affiliation with Valve or any of their properties.

Valve, Steam, Steam Deck, Steam Controller or other Valve trademarks, are the property of Valve LLC.  Playstation, DualShock and DualSense or other Sony trademarks are the property of the Sony Corporation.  Any reference to these, or other tradmarks, are in fair use.

All hardware documentation and implementation is derived from legal reverse-engineering and referencing other GPL-licensed open-source code published in the Linux kernel.  No code or documentation in this project has been obtained from any method that could be considered a trade secret.
