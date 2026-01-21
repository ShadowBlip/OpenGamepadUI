# Core systems & architecture

This section describes the organization of OpenGamepadUI's source code,
and provides an overview of the architecture and systems that it uses.

## Project Layout

```bash
OpenGamepadUI
├── addons                  # 3rd party libraries & Compiled rust extensions
├── assets                  # Images, sound, state, themes, shaders, etc.
├── core
│   ├── global              # (Deprecated) Global systems
│   ├── main.{gd,tscn}      # Loads the appropriate UI (e.g. Card UI)
│   ├── platform            # Platform-specific logic
│   ├── systems             # Core application logic and systems
│   └── ui                  # Menus and menu components
├── CREDITS.md              # Attributions for contributors
├── docs
├── entrypoint.{gd,tscn}    # Application entrypoint script/scene
├── extensions              # Rust GDExtension source code
├── export_presets.cfg
├── icon.svg
├── LICENSE                 # License file
├── Makefile                # Makefile
├── plugins                 # Used for plugin development
├── project.godot
├── README.md               # Project README
└── rootfs                  # Filesystem and scripts for final package
```

### Addons

The `addons` directory contains 3rd party libraries used by OpenGamepadUI
as well as compiled [GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html)
code from the `extensions` folder. Some 3rd party libraries include the
[GUT testing framework ](https://github.com/bitwes/Gut) and more.

### Extensions

Godot Engine provides a lot of functionality, but not everything that OpenGamepadUI
needs.

The `extensions` directory contains the Rust source code used to extend the
functionality of the engine using [GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html).
This is typically done to add performance-sensitive code as well as add
support for interacting with systems like Gamescope and DBus.
When OpenGamepadUI is built, these extensions are compiled to the `addons`
directory.

### Assets

The `assets` directory contains all of the images, icons, sounds,
shaders, themes, state, etc.

```bash
assets/
├── animations
├── audio
├── crypto
├── editor-icons
├── gamepad
├── icons
├── images
├── keyboard
├── label
├── shaders
├── state
├── styles
├── themes
├── ui
└── videos
```

### Global Systems

The `core/global` directory contains "global" systems that can be used
from any script in the project. This directory has been deprecated in
favor of just putting these systems in the `systems` directory instead.

OpenGamepadUI has several global systems that are typically implemented
as a [custom
resource](https://docs.godotengine.org/en/latest/tutorials/scripting/resources.html#creating-your-own-resources).
Resources in Godot are unique in that they are only ever loaded once by
the engine. This allows nodes to access their functionality regardless
of where they are in the scene tree.

### Platform

The `core/platform` directory contains platform-specific logic, such as
modifying the behavior, look, or feel of OpenGamepadUI when running on
different hardware or OS platforms.

Examples of this might be using custom gamepad icons for a handheld, or
running specific logic to start a driver.

### Systems

The `core/systems` directory contains all the core application logic of
OpenGamepadUI. These systems should not contain any UI-specific logic.
An example of a core system is
`BluetoothManager`, which provides methods for interacting with bluetooth.

Systems are usually implemented as a
[Node](https://docs.godotengine.org/en/stable/classes/class_node.html)
that can be added to the scene tree or implemented as a [custom
resource](https://docs.godotengine.org/en/latest/tutorials/scripting/resources.html#creating-your-own-resources)
that can be loaded and referenced regardless of where it is called from
the scene tree.

### UI

The `core/ui` directory contains all of the user interface scenes and
scripts of OpenGamepadUI. That includes things like menus as well as UI
components like buttons and text boxes. Each menu scene provides the
glue between the various UI components and backend systems.

### Root Filesystem

The `rootfs` directory contains additional system configuration and
supplemental scripts that should be part of the OpenGamepadUI package
when installed. It includes things like polkit policies for executing
certain commands with elevated privileges and helper scripts to interact
with the system.

```bash
rootfs
├── Makefile
└── usr
    ├── bin
    │   └── opengamepadui
    ├── lib
    │   └── systemd
    │       └── user
    │           ├── ogui-overlay-mode.service
    │           └── systemd-sysext-updater.service
    └── share
        ├── applications
        │   └── opengamepadui.desktop
        ├── icons
        │   └── hicolor
        │       └── scalable
        │           └── apps
        │               └── opengamepadui.svg
        ├── opengamepadui
        │   └── scripts
        │       ├── make_nice
        │       ├── manage_input
        │       └── update_systemd_ext.sh
        └── polkit-1
            └── actions
                ├── org.shadowblip.manage_input.policy
                ├── org.shadowblip.nixos_updater.policy
                └── org.shadowblip.setcap.policy
```
