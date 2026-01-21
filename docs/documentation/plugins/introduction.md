# Introduction

OpenGamepad UI uses a plugin system to extend functionality.

## Installing Plugins

Plugins can be installed through OpenGamepadUI from the plugin store in
the `Settings` menu. The [OpenGamepadUI Plugin
Store](https://github.com/ShadowBlip/OpenGamepadUI-plugins) provides
community submitted plugins that have been tested and approved.

Plugins can be manually installed by placing the plugin archive in
`~/.local/share/opengamepadui/plugins`.

!!! warning

    Plugins contain arbitrary code, which will be executed with the same
    privileges as OpenGamepadUI itself. An evil plugin may contain malware
    which can take over your computer, and destroy or steal your data. Do
    not install plugins from untrusted sources.

## Writing Plugins

The OpenGamepadUI plugin system is inspired by the modding system
implemented by
[Delta-V](https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd).
It works by taking advantage of Godot's
[ProjectSettings.load_resource_pack()](https://docs.godotengine.org/en/latest/classes/class_projectsettings.html#class-projectsettings-method-load-resource-pack)
method, which can allow OpenGamepadUI to load Godot scripts and scenes
from a zip file.

The plugin loader looks for zip files in the `user://plugins` directory
and parses the `plugin.json` file contained inside. If the plugin
metadata is valid, the plugin loader loads the zip file as a resource
pack. This system makes plugins incredibly powerful, and can be written
to modify nearly all aspects of OpenGamepadUI.
