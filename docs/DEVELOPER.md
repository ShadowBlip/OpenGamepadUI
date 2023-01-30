# Developer Guide

This guide explains how to contribute to OpenGamepadUI core codebase. It
has information about best practices, code style, and the internal structure of
the codebase.

## Contributing

OpenGamepadUI is a free and open source project. Its contributors develop it
pro bono in their free time out of personal interest.

Before working on a feature or bug, be sure to look for the issue in the
[issue tracker](https://github.com/ShadowBlip/OpenGamepadUI/issues)
to see if the issue is already being tracked or worked on by another member
of the community. If not, open a new issue describing the bug or feature. It's
important to discuss bugs and features with other contributors.

## Best practices

### #1 Always start with an issue

Coordinating an open source project is hard. One of the most important steps to
contributing is opening an issue describing the bug or feature you want to work
on, and discussing if/how the problem should be resolved or implemented.
Maintaining a large code base is difficult and implementation and coordination
is key.

### #2 Prefer small scope pull requests

Pull requests should try to be small in scope and only address one relevant
feature or bug. Try not to include unrelated fixes or features in the same
pull request. Open a separate one for each issue you address.

### #3 Prefer standalone, composable, decoupled solutions

When contributing code for bugs or features, try to ensure that your solution
is as independent and decoupled from other systems as possible. This usually
means taking advantage of Godot's [signals](https://docs.godotengine.org/en/latest/getting_started/step_by_step/signals.html)
feature, [node groups](https://docs.godotengine.org/en/latest/tutorials/scripting/groups.html),
and [resources](https://docs.godotengine.org/en/latest/tutorials/scripting/resources.html).
Your solution should be able to run independently, even if other systems you
rely on might not be available.

### #4 Prefer solutions without external dependencies

OpenGamepadUI aims to be portable and not rely on system-installed dependencies.
In some cases not every problem has a simple solution, so sometimes the right
choice is to rely on a third-party dependency, but try to create a self-contained
solution, if possible.

## Building from source

### Getting the source

Before building OpenGamepadUI, you first need to actually download the source
code using `git`. Ensure you have `git` installed, and run the following to
clone the project locally:

```bash
git clone https://github.com/ShadowBlip/OpenGamepadUI.git
```

### Build Requirements

The following are required to build Open Gamepad UI:

- Godot 4.x
- GCC 7+ or Clang 6+.
- Python 3.5+.
- SCons 3.0+ build system
- pkg-config (used to detect the dependencies below).
- X11, Xcursor, Xinerama, Xi and XRandR development libraries.
- MesaGL development libraries.
- ALSA development libraries.
- PulseAudio development libraries.
- make (optional)
- unzip (optional)
- wget (optional)

If you are using ArchLinux, you can run the following:

```bash
pacman -S --needed scons pkgconf gcc libxcursor libxinerama libxi libxrandr mesa glu libglvnd alsa-lib make unzip wget git
```

### Building

OpenGamepadUI uses `make` to help make developing the project easier. You can
view the things you can do with `make` by running `make help`:

![](./media/makefile.png)

You can build the OpenGamepadUI binary using the following:

```bash
make build
```

Godot imports and converts assets when it builds. If you see
errors related to failing to load resources. Try running:

```bash
make import
```

### Usage

Open Gamepad UI works in conjunction with [gamescope](https://github.com/Plagman/gamescope/)
to manage launching games in a seamless way.

To run OpenGamepadUI, run the following to launch through gamescope:

```bash
make run
```

You can also run OpenGamepadUI in gamescope in debug mode with the Godot editor
open with:

```bash
make debug
```

## Core systems & architecture

This section describes the organization of OpenGamepadUI's source code, and
provides an overview of the architecture and systems that it uses.

### Global Systems

OpenGamepadUI has several global systems that are typically implemented as
an always running [global singleton](https://docs.godotengine.org/en/latest/tutorials/scripting/singletons_autoload.html).
This section describes some of those systems and what they do.

#### BoxArtManager

The [BoxArtManager](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/boxart_manager.gd)
is responsible for managing any number of [BoxArtProviders](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/boxart/boxart_provider.gd)
and providing a unified way to provide box art from multiple sources to any
systems that might need them. New box art sources can be created in the core
code base or in plugins by implementing/extending the
[BoxArtProvider](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/boxart/boxart_provider.gd)
class and registering the provider with the box art manager.

With registered box art providers, other systems can request box art from the
BoxArtManager, and it will use all available sources to return the best artwork:

```gdscript
var boxart := BoxArtManager.get_boxart(library_item, BoxArtProvider.LAYOUT.LOGO)
```

#### Gamescope

The [Gamescope](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/gamescope.gd)
class is responsible for interacting with Gamescope, usually via the means of
setting gamescope-specific window properties. It can be used to discover
Gamescope displays, list windows and their children, and set gamescope-specific
window atoms to switch windows, set blur, limit FPS, etc.

For example, to limit the FPS, you can do the following:

```gdscript
Gamescope.set_fps_limit(display, 30)
```

Most of the core functionality of this class is provided by the
[godot-xlib](https://github.com/ShadowBlip/OpenGamepadUI/tree/main/addons/godot-xlib)
module, which is a [GDExtension](https://docs.godotengine.org/en/latest/getting_started/step_by_step/scripting_languages.html#c-and-c-via-gdextension)
that exposes Xlib methods to Godot.

#### InputManager

The [InputManager](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/input_manager.gd)
class is responsible for handling global input that should happen everywhere in
the application. This usually means processing input for when the guide button
is pressed to bring up the overlay or main menu. It is also responsible for
setting some Gamescope atoms to redirect input focus to either a running game
or the OpenGamepadUI overlay.

#### LaunchManager

The [LaunchManager](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/launch_manager.gd)
class is responsible starting and managing the lifecycle of games and is one
of the most complex systems in OpenGamepadUI. Using gamescope, it manages
what games start, if their process is still running, and fascilitates window
switching between games. It also provides a mechanism to kill running games and
discover child processes. It uses a timer to periodically check on launched
games to see if they have exited, or are opening new windows that might need
attention.

Example:

```gdscript
# Create a LibraryLaunchItem to run something
var item := LibraryLaunchItem.new()
item.command = "vkcube"

# Launch the app with LaunchManager
var running_app := LaunchManager.launch(item)

# Get a list of running apps
var running := LaunchManager.get_running()
print(running)

# Stop an app with LaunchManager
LaunchManager.stop(running_app)
```

#### LibraryManager

The [LibraryManager](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/library_manager.gd)
is responsible for managing any number of [Library](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/library/library.gd)
providers and offers a unified interface to manage games from multiple sources.
New game library sources can be created in the core code base or in plugins by
implementing/extending the
[Library](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/library/library.gd)
class and registering the provider with the library manager.

With registered library providers, other systems can request library items from the
LibraryManager, and it will use all available sources to return a unified library
item:

```gdscript
# Return a dictionary of all installed games from every library provider
var installed_games := LibraryManager.get_installed()
```

Games in the LibraryManager are stored as [LibraryItems](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/library/library_item.gd),
which contains information about each game. Each `LibraryItem` has a list of
[LibraryLaunchItems](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/systems/library/library_launch_item.gd)
which contains the data for how to launch that game through a specific `Library`
provider.

```gdscript
# Get a LibraryItem by name
var library_item := LibraryManager.get_app_by_name("Hollow Knight")

# List all of the ways to launch the game through different library providers
for launch_item in library_item.launch_items:
	print(launch_item._provider_id)
	print(launch_item.command, launch_item.args)
```

#### NotificationManager

The [NotificationManager](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/notification_manager.gd)
is responsible for providing an API to display arbitrary notifications
to the user and maintain a history of those notifications. It also manages
a queue of notifications so only one notification shows at a time.

Notifications can be sent with:

```gdscript
var notify := Notification.new("Hello world!")
notify.icon = load("res://assets/icons/critical.png")
NotificationManager.show(notify)
```

#### PluginLoader

The [PluginLoader](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/plugin_loader.gd)
is responsible for downloading, loading, and initializing OpenGamepadUI plugins.
The plugin system for OpenGamepadUI is heavily based upon the modding system
implemented by [Delta-V](https://gitlab.com/Delta-V-Modding/Mods/-/blob/main/game/ModLoader.gd).

The PluginLoader works by taking advantage of Godot's
[ProjectSettings.load_resource_pack()](https://docs.godotengine.org/en/latest/classes/class_projectsettings.html#class-projectsettings-method-load-resource-pack)
method, which can allow us to load Godot scripts and scenes from a zip file.
The PluginLoader looks for zip files in `user://plugins`, and parses the
`plugin.json` file contained within them. If the plugin metadata is valid, the
loader loads the zip as a resource pack.

#### SettingsManager

The [SettingsManager](https://github.com/ShadowBlip/OpenGamepadUI/blob/main/core/autoload/settings_manager.gd)
is a simple class responsible for getting and setting user-specific settings.
These settings are stored in a single file at `user://settings.cfg`. User
customizable settings can be used with:

```gdscript
# Get a value from the settings file
var value := SettingsManager.get_value("general.home", "max_home_items")

# Set a value in the settings file
SettingsManager.set_value("general.home", "max_home_items", 6)
```
