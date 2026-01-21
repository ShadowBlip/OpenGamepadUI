# Library

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Base class for Library implementations
## Description

The Library class provides an interface for creating new library implementations. To create a new library, simply extend this class and implement its methods. When a Library node is added to the scene tree, it will automatically register itself with the global [LibraryManager](../LibraryManager).
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [LibraryManager](../LibraryManager) | [LibraryManager](./#LibraryManager) | <unknown> |
| [LibraryManager](../LibraryManager) | [library_manager](./#library_manager) | <unknown> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [library_id](./#library_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [store_id](./#store_id) |  |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [library_icon](./#library_icon) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [supports_uninstall](./#supports_uninstall) | true |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [logger_name](./#logger_name) | library_id |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [log_level](./#log_level) | 3 |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [LibraryLaunchItem[]](../LibraryLaunchItem) | [get_library_launch_items](./#get_library_launch_items)() |
| [Library.InstallLocation[]](../Library.InstallLocation) | [get_available_install_locations](./#get_available_install_locations)(item: [LibraryLaunchItem](../LibraryLaunchItem) = null) |
| [Library.InstallOption[]](../Library.InstallOption) | [get_install_options](./#get_install_options)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [AppLifecycleHook[]](../AppLifecycleHook) | [get_app_lifecycle_hooks](./#get_app_lifecycle_hooks)() |
| void | [install](./#install)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| void | [install_to](./#install_to)(item: [LibraryLaunchItem](../LibraryLaunchItem), location: [Library.InstallLocation](../Library.InstallLocation) = null, options: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) = {}) |
| void | [update](./#update)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_update](./#has_update)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| void | [uninstall](./#uninstall)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| void | [move](./#move)(item: [LibraryLaunchItem](../LibraryLaunchItem), to_location: [Library.InstallLocation](../Library.InstallLocation)) |


------------------

## Property Descriptions

### `LibraryManager`


[LibraryManager](../LibraryManager) LibraryManager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `library_manager`


[LibraryManager](../LibraryManager) library_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `library_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) library_id


Unique identifier for the library
### `store_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) store_id


Optional store that this library is linked to
### `library_icon`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) library_icon


Icon for library provider
### `supports_uninstall`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) supports_uninstall = <span style="color: red;">true</span>


Whether or not the library provider supports uninstalls
### `logger_name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) logger_name = <span style="color: red;">library_id</span>


Logger name used for debug messages
### `log_level`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) log_level = <span style="color: red;">3</span>


Log level of the logger.
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_library_launch_items()`


[LibraryLaunchItem[]](../LibraryLaunchItem) **get_library_launch_items**()


Returns an array of available library launch items that this library provides. This method should be overriden in the child class. Example:
```gdscript

    func get_library_launch_items() -> Array[LibraryLaunchItem]:
            var item: LibraryLaunchItem = LibraryLaunchItem.new()
            item.name = "vkCube"
            item.command = "vkcube"
            item.args = []
            item.tags = ["vkcube"]
            item.installed = true

            return [item]

```


### `get_available_install_locations()`


[Library.InstallLocation[]](../Library.InstallLocation) **get_available_install_locations**(item: [LibraryLaunchItem](../LibraryLaunchItem) = null)


Returns an array of available install locations for this library provider. This method should be overridden in the child class. Example:
```gdscript

  func get_available_install_locations() -> Array[InstallLocation]:
      var location := InstallLocation.new()
      location.name = "/"
      return [location]

```


### `get_install_options()`


[Library.InstallOption[]](../Library.InstallOption) **get_install_options**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Returns an array of install options for the given [LibraryLaunchItem](../LibraryLaunchItem). Install options are arbitrary and are provider-specific. They allow the user to select things like the language of a game to install, etc. Example:
```gdscript

  func get_install_options(item: LibraryLaunchItem) -> Array[InstallOption]:
      var option := InstallOption.new()
      option.id = "lang"
      option.name = "Language"
      option.description = "Language of the game to install"
      option.values = ["english", "spanish"]
      option.value_type = TYPE_STRING
      return [option]

```


### `get_app_lifecycle_hooks()`


[AppLifecycleHook[]](../AppLifecycleHook) **get_app_lifecycle_hooks**()


This method should be overridden if the library requires executing callbacks at certain points in an app's lifecycle, such as when an app is starting or stopping.
### `install()`


void **install**(item: [LibraryLaunchItem](../LibraryLaunchItem))


!!! warning

    This is deprecated

 Installs the given library item. This method should be overriden in the child class, if it supports it.
### `install_to()`


void **install_to**(item: [LibraryLaunchItem](../LibraryLaunchItem), location: [Library.InstallLocation](../Library.InstallLocation) = null, options: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) = {})


Installs the given library item to the given location. This method should be overridden in the child class, if it supports it.
### `update()`


void **update**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Updates the given library item. This method should be overriden in the child class, if it supports it.
### `has_update()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_update**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Should return true if the given library item has an update available
### `uninstall()`


void **uninstall**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Uninstalls the given library item. This method should be overriden in the child class if it supports it.
### `move()`


void **move**(item: [LibraryLaunchItem](../LibraryLaunchItem), to_location: [Library.InstallLocation](../Library.InstallLocation))


Move the given library item to the given install location. This method should be overriden in the child class if it supports it.
