# Tutorials

## Writing a Library plugin

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
        logger = Log.get_logger("vkCube", Log.LEVEL.INFO)
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
        logger = Log.get_logger("vkCube", Log.LEVEL.INFO)

        # Load the Library implementation
        var library: Library = load(plugin_base + "/core/library.tscn").instantiate()
        add_child(library)
```

That's it! When your plugin gets loaded, your new library will automatically
get registered with the library manager and games that your library provides
will show up in your library!

Run `make install` to install your new plugin and test it out!
