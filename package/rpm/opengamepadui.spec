Name:           opengamepadui
Version:        0.45.0
Release:        1
Summary:        A free and open source game launcher and overlay written using the Godot Game Engine 4 designed with a gamepad native experience in mind
License:        GPL-3.0-only
URL:            https://github.com/ShadowBlip/OpenGamepadUI

Source:         https://github.com/ShadowBlip/OpenGamepadUI/releases/download/v%{version}/opengamepadui-%{_arch}.tar.gz

Requires:       gamescope

BuildRequires:  make
BuildRequires:  systemd-rpm-macros

%description
A free and open source game launcher and overlay written using the Godot Game Engine 4 designed with a gamepad native experience in mind

%define debug_package %{nil}
%define _build_id_links none
%define __os_install_post %{nil}

%prep
%autosetup -p1 -n opengamepadui

%install
make install PREFIX=%{buildroot}%{_prefix} INSTALL_PREFIX=%{_prefix} ARCH=%{_arch}

%files
/usr/bin/opengamepadui
/usr/share/opengamepadui/*.so
/usr/share/opengamepadui/reaper
/usr/share/opengamepadui/scripts/*
/usr/share/opengamepadui/opengamepad-ui.%{_arch}
/usr/share/opengamepadui/opengamepad-ui.pck
/usr/share/applications/opengamepadui.desktop
/usr/share/icons/hicolor/scalable/apps/opengamepadui.svg
/usr/share/polkit-1/actions/*
/usr/lib/systemd/user/*

%changelog
%autochangelog
