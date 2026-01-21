# Writing a Box Art plugin

Box Art plugins allow you to use artwork from different sources in
OpenGamepadUI. When the UI requires artwork for a particular game, it
uses the `BoxArtManager` to fetch artwork for a particular game, which in turn
queries all registered
`BoxArtProvider`
nodes for artwork for that game.

In this tutorial, we'll be writing a simple box art plugin that will
return a static image for every library item.

First, start off by cloning a fork of the [plugin
template](https://github.com/ShadowBlip/OpenGamepadUI-plugin-template)
and filling out `plugin.json`. Then let's create a scene and script for
our new box art provider:

```bash
OpenGamepadUI-boxart-tutorial
├── assets
├── core
│   ├── boxart.gd
│   └── boxart.tscn
├── Makefile
├── plugin.gd
├── plugin.json
└── README.md
```

Next, let's download the artwork we want to return and place it in our
`assets` directory. Find and download an image from somewhere like
[SteamGridDB](https://www.steamgriddb.com/) and save it as `image.png`.

With our new boxart scene, edit the script and implement the
`get_boxart` method to return a texture:

```gdscript title="core/boxart.gd" linenums="1"
extends BoxArtProvider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
        super()
        logger = Log.get_logger("BoxArtTutorial", Log.LEVEL.INFO)
        logger.info("BoxArtTutorial plugin loaded")


# Return the boxart texture for the given library item and layout
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
        return null
```

Returning `null` will tell the
`BoxArtManager` that
we don't have artwork for the given library item for the given
`LAYOUT`.
There are several kinds of artwork
`LAYOUT` types
such as:

- `GRID_PORTRAIT`
- `GRID_LANDSCAPE`
- `BANNER`
- `LOGO`

Each artwork layout will be used in different parts of the UI that
request it. You should always return `null` if you can't provide the
artwork for a given layout for a game to allow other box art providers a
chance to find it.

For the purpose of this tutorial, let's only return artwork for the
`GRID_PORTRAIT` layout:

```gdscript title="core/boxart.gd" linenums="1"
extends BoxArtProvider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
        super()
        logger = Log.get_logger("BoxArtTutorial", Log.LEVEL.INFO)
        logger.info("BoxArtTutorial plugin loaded")


# Return the boxart texture for the given library item and layout
func get_boxart(item: LibraryItem, kind: LAYOUT) -> Texture2D:
        if kind == LAYOUT.GRID_PORTRAIT:
            var texture: Texture2D = load("res://plugins/boxart-tutorial/assets/image.png")
            return texture

        return null
```

Now in our entrypoint script, load our new boxart scene and add it as a
child of the plugin.

```gdscript title="plugin.gd" linenums="1"
extends Plugin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
        logger = Log.get_logger("BoxArtTutorial", Log.LEVEL.INFO)

        # Load the boxart implementation
        var boxart: BoxArtProvider = load("res://plugins/boxart-tutorial/core/boxart.tscn").instantiate()
        add_child(boxart)
```

That's it! When your plugin gets loaded, your new box art provider will
automatically get registered with the
`BoxArtManager` and
games in your library will show the artwork you used!

Run `make install` to install your new plugin and test it out!

If you want to take your boxart plugin further, try taking a look at the
`HTTPImageFetcher`
and `Cache` classes to more
dynamically fetch artwork for a given library item.

