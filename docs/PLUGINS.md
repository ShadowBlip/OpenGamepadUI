# Plugin Guide

OpenGamepad UI uses a plugin system to extend functionality.

## Installing Plugins

Plugins can be installed through OpenGamepadUI from the plugin store in the
`Settings` menu. The [OpenGamepadUI Plugin Store](https://github.com/ShadowBlip/OpenGamepadUI-plugins)
provides community submitted plugins that have been tested and approved.

Plugins can be manually installed by placing the plugin archive in
`~/.local/share/opengamepadui/plugins`.

> :warning: WARNING: Plugins contain arbitrary code, which will be executed with
> the same privileges as OpenGamepadUI itself. An evil plugin may contain malware
> which can take over your computer, and destroy or steal your data. Do not install
> plugins from untrusted sources.

## Writing Plugins

The OpenGamepadUI plugin system is inspired by the modding system
implemented by [Delta-V](https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd). It works by taking advantage of Godot's
[ProjectSettings.load_resource_pack()](https://docs.godotengine.org/en/latest/classes/class_projectsettings.html#class-projectsettings-method-load-resource-pack)
method, which can allow OpenGamepadUI to load Godot scripts and scenes from a
zip file.

The plugin loader looks for zip files in the `user://plugins` directory
and parses the `plugin.json` file contained inside. If the plugin metadata is
valid, the plugin loader loads the zip file as a resource pack. This system
makes plugins incredibly powerful, and can be written to modify nearly all
aspects of OpenGamepadUI.

### Getting Started

A typical plugin is structured like this:

```
.
├── assets/      # Assets like images and other resources
├── core/        # Scripts and scenes for your plugin
├── LICENSE      # License
├── Makefile     # Makefile
├── plugin.gd    # Entrypoint script to your plugin
├── plugin.json  # Metadata file
└── README.md    # Project README
```

The easiest way to get this structure and get started is to refer to the
[OpenGamepadUI Plugin Template](https://github.com/ShadowBlip/OpenGamepadUI-plugin-template)
repository and clicking on `Use this template`. This will fork the plugin
template and let you clone your repository to get started.

Once you have your repository cloned locally, clone the
[OpenGamepadUI](https://github.com/ShadowBlip/OpenGamepadUI) repository next
to your plugin folder. It should look something like this:

```bash
$ ls
OpenGamepadUI
OpenGamepadUI-plugin-template
```

Lastly, ensure that you have installed all of the build requirements from
the [Developer Guide](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/docs/DEVELOPER.md#build-requirements)
to ensure you can build your new plugin.

### Metadata

The `plugin.json` file is used by OpenGamepadUI and the plugin store to determine
how the plugin is loaded and shows up in the store. It is required for any
plugin.

It looks like this:

```yaml
{
  "plugin.id": "template",              # Unique ID of the plugin, lowercase
  "plugin.name": "Template Plugin",     # Display name of the plugin
  "plugin.version": "1.0.0",            # Plugin version
  "plugin.min-api-version": "1.0.0",    # Minimum OpenGamepadUI API version
  "plugin.link": "",                    # Link to your plugin's website
  "plugin.source": "",                  # Link to the plugin source code
  "plugin.description": "",             # Short description of your plugin
  "store.tags": [],                     # List of tags that describe your plugin
  "store.images": [],                   # Optional list of images that show your plugin
  "author.name": "First Last",          # Author of the plugin
  "author.email": "person@example.com", # Email address of the plugin author
  "entrypoint": "plugin.gd",            # Script to run when your plugin is loaded
}
```

### Editing your plugin

Once you have filled out the details of your plugin, you can use the
[Makefile](https://github.com/ShadowBlip/OpenGamepadUI-plugin-template/blob/main/Makefile)
from the plugin template to build and link your plugin to OpenGamepadUI. For
help using the Makefile, run this from your plugin directory:

```bash
make help
```

You can link and build your plugin by running:

```bash
make build
```

This will create a symlink to your plugin inside the
[OpenGamepadUI/plugins](https://github.com/ShadowBlip/OpenGamepadUI/tree/main/plugins)
project directory, allowing you to work on your plugin with the Godot
editor.

> :warning: NOTE: Ensure you only have one plugin linked at a time, or multiple
> plugins you're working on might get bundled together!

Once the symlink to your plugin is created, open the OpenGamepadUI project
directory and run `make edit` to start working on your plugin!

Depending on your plugin, you may want to consider looking at the number 
of [Global Systems](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/docs/DEVELOPER.md#global-systems)

## Tutorials

### Writing a Library plugin

Library plugins allow you to extend the library in OpenGamepadUI, offering ways 
to install and launch games and applications. Library plugins extend and 
implement the [Library](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/library/library.gd)
class. You can also look at the built-in [Desktop Library](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/library/library_desktop.gd)
implementation for an example of how to write a library plugin.

In this tutorial, we'll be writing a simple library plugin that will add a new 
item to our library that will launch the `vkcube` test program.

First, start off by cloning a fork of the [plugin template](https://github.com/ShadowBlip/OpenGamepadUI-plugin-template)
and filling out `plugin.json`. Then let's create a scene and script for our 
new library:

```
OpenGamepadUI-vkcube
├── core
│   ├── library.gd
│   └── library.tscn
├── Makefile
├── plugin.gd
├── plugin.json
└── README.md
```

With our new library scene, edit the script and implement the `get_library_launch_items`
method to return a list of library items:

**core/library.gd**

```gdscript
extends Library

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
        super()
        logger = Log.get_logger("vkCube", Log.LEVEL.DEBUG)
        logger.info("vkCube Library loaded")


# Return a list of installed steam apps. Called by the LibraryManager.
func get_library_launch_items() -> Array[LibraryLaunchItem]:
        var item: LibraryLaunchItem = LibraryLaunchItem.new()
        item.name = "vkCube"
        item.command = "vkcube"
        item.args = []
        item.tags = ["vkcube"]
        item.installed = true

        return [item]
```

Now in our entrypoint script, load our new library scene and add it as a child 
of the plugin.

**plugin.gd**

```gdscript
extends Plugin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
        logger = Log.get_logger("vkCube", Log.LEVEL.DEBUG)

        # Load the Library implementation
        var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
        add_child(library)
```

That's it! When your plugin gets loaded, your new library will automatically 
get registered with the library manager and games that your library provides 
will show up in your library!

Run `make install` to install your new plugin and test it out!

## Submitting Plugins

OpenGamepadUI maintains a plugin store where users can download and install
community created plugins. This list of plugins is maintained in the
[OpenGamepadUI-plugins](https://github.com/ShadowBlip/OpenGamepadUI-plugins)
repository.

To have your plugin considered for inclusion in the plugin store, ccreate a
pull request to the plugins repository with an entry for your plugin.

> :warning: Please be aware that we do not allow private repositories, "black-box"
> binaries, deliberately obfuscated code or any other items that would undermine
> the ability to verify the functionality of a plugin and or any underlying
> software.
