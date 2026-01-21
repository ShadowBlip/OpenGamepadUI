# LibraryManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Unified interface to manage games from multiple sources
## Description

The LibraryManager is responsible for managing any number of [Library](../Library) providers and offers a unified interface to manage games from multiple sources. New game library sources can be created in the core code base or in plugins by implementing/extending the [Library](../Library) class and registering the provider with the library manager.

With registered library providers, other systems can request library items from the LibraryManager, and it will use all available sources to return a unified library item: 
```gdscript

    const LibraryManager := preload("res://core/global/library_manager.tres")
    ...
    # Return a dictionary of all installed games from every library provider
    var installed_games := LibraryManager.get_installed()

```


 Games in the LibraryManager are stored as [LibraryItem](../LibraryItem) resources, which contains information about each game. Each [LibraryItem](../LibraryItem) has a list of [LibraryLaunchItems](https://docs.godotengine.org/en/stable/classes/class_librarylaunchitems.html) which contains the data for how to launch that game through a specific Library provider.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [SettingsManager](../SettingsManager) | [settings_manager](./#settings_manager) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [LibraryItem[]](../LibraryItem) | [get_library_items](./#get_library_items)(modifiers: [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) = [...]) |
| [LibraryItem[]](../LibraryItem) | [sort_by_name](./#sort_by_name)(apps: [LibraryItem[]](../LibraryItem)) |
| [LibraryItem[]](../LibraryItem) | [filter_installed](./#filter_installed)(apps: [LibraryItem[]](../LibraryItem)) |
| [LibraryItem[]](../LibraryItem) | [filter_by_library](./#filter_by_library)(apps: [LibraryItem[]](../LibraryItem), library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [LibraryItem[]](../LibraryItem) | [filter_by_hidden](./#filter_by_hidden)(apps: [LibraryItem[]](../LibraryItem)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [get_available](./#get_available)() |
| void | [reload_library](./#reload_library)() |
| void | [add_library_launch_item](./#add_library_launch_item)(library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| void | [remove_library_launch_item](./#remove_library_launch_item)(library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [load_library](./#load_library)(library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_app](./#has_app)(name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [LibraryItem](../LibraryItem) | [get_app_by_name](./#get_app_by_name)(name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_library](./#has_library)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Library](../Library) | [get_library_by_id](./#get_library_by_id)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Library[]](../Library) | [get_libraries](./#get_libraries)() |
| void | [register_library](./#register_library)(library: [Library](../Library)) |
| void | [unregister_library](./#unregister_library)(library: [Library](../Library)) |


------------------

## Property Descriptions

### `settings_manager`


[SettingsManager](../SettingsManager) settings_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_library_items()`


[LibraryItem[]](../LibraryItem) **get_library_items**(modifiers: [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) = [...])


Returns library items based on the given modifiers. A modifier is a [Callable](https://docs.godotengine.org/en/stable/classes/class_callable.html) that takes an array of [LibraryItem](../LibraryItem) objects and returns an array of those items that may be sorted or filtered out.


```gdscript

    const LibraryManager := preload("res://core/global/library_manager.tres")
    ...
    var filter := func(apps: Array[LibraryItem]) -> Array[LibraryItem]:
        return apps.filter(func(item: LibraryItem): not item.is_installed())

    # Return non-installed games
    var not_installed := LibraryManager.get_library_items([filter])

```


### `sort_by_name()`


[LibraryItem[]](../LibraryItem) **sort_by_name**(apps: [LibraryItem[]](../LibraryItem))


Sorts the given array of apps by name
### `filter_installed()`


[LibraryItem[]](../LibraryItem) **filter_installed**(apps: [LibraryItem[]](../LibraryItem))


Filters the given array of apps by installed status
### `filter_by_library()`


[LibraryItem[]](../LibraryItem) **filter_by_library**(apps: [LibraryItem[]](../LibraryItem), library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Filter the given array of apps by library provider
### `filter_by_hidden()`


[LibraryItem[]](../LibraryItem) **filter_by_hidden**(apps: [LibraryItem[]](../LibraryItem))


Filters the given array of apps by hidden
### `get_available()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **get_available**()


Returns an dictionary of all available apps
### `reload_library()`


void **reload_library**()


Loads all library items from each provider and sorts them. This can take a while, so should be called asyncronously
### `add_library_launch_item()`


void **add_library_launch_item**(library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), item: [LibraryLaunchItem](../LibraryLaunchItem))


Add the given library launch item to the list of available apps.
### `remove_library_launch_item()`


void **remove_library_launch_item**(library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Remove the given library launch item from the list of available apps.
### `load_library()`


void **load_library**(library_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Loads the launch items from the given library
### `has_app()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_app**(name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the app with the given name exists in the library.
### `get_app_by_name()`


[LibraryItem](../LibraryItem) **get_app_by_name**(name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the library item for the given app for all library providers
### `has_library()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_library**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the library with the given id is registered
### `get_library_by_id()`


[Library](../Library) **get_library_by_id**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the given library implementation by id
### `get_libraries()`


[Library[]](../Library) **get_libraries**()


Returns a list of all registered libraries
### `register_library()`


void **register_library**(library: [Library](../Library))


Registers the given library with the library manager.
### `unregister_library()`


void **unregister_library**(library: [Library](../Library))


Unregisters the given library with the library manager
