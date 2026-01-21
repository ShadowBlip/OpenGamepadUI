# Plugin

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Base class for Plugins
## Description

The Plugin class provides an interface and light API for creating plugins. New plugins should inherit from this class and will automatically get added to the scene tree as a child of the [PluginLoader](../PluginLoader) when it is loaded.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [plugin_base](./#plugin_base) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [cache](./#cache) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [unload](./#unload)() |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [get_settings_menu](./#get_settings_menu)() |
| void | [add_library](./#add_library)(library: [Library](../Library)) |
| void | [add_store](./#add_store)(store: [Store](../Store)) |
| void | [add_boxart](./#add_boxart)(boxart: [BoxArtProvider](../BoxArtProvider)) |
| void | [add_to_qam](./#add_to_qam)(qb_item: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), icon: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html), focus_node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) = null) |
| void | [add_to_quick_bar](./#add_to_quick_bar)(qb_item: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), icon: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html), focus_node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) = null) |
| void | [add_overlay](./#add_overlay)(overlay: [OverlayProvider](../OverlayProvider)) |


------------------

## Property Descriptions

### `plugin_base`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) plugin_base


The base resource directory for a given plugin. This will be set by the [PluginLoader](../PluginLoader) when it is loaded. Useful for loading plugin-specific resources.
### `cache`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) cache


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `unload()`


void **unload**()


To be overridden by plugin implementation. Should unload changes done by the plugin.
### `get_settings_menu()`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **get_settings_menu**()


To be overridden by plugin implementation. Should return a scene with plugin settings. This scene will be included in the plugin settings menu to let users modify plugin-specific settings.
### `add_library()`


void **add_library**(library: [Library](../Library))


Adds the given library implementation as a child of the plugin. A [Library](../Library) node will automatically register itself with the [LibraryManager](../LibraryManager) when it enters the scene tree.
### `add_store()`


void **add_store**(store: [Store](../Store))


Adds the given store implementation as a child of the plugin. A [Store](../Store) node will automatically register itself with the [StoreManager](../StoreManager) when it enters the scene tree.
### `add_boxart()`


void **add_boxart**(boxart: [BoxArtProvider](../BoxArtProvider))


Adds the given boxart provider as a child of the plugin. A [BoxArtProvider](../BoxArtProvider) node will automatically register itself with the [BoxArtManager](../BoxArtManager) when it enters the scene tree.
### `add_to_qam()`


void **add_to_qam**(qb_item: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), icon: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html), focus_node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) = null)


Deprecated method for adding a plugin to the quick bar.
### `add_to_quick_bar()`


void **add_to_quick_bar**(qb_item: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html), icon: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html), focus_node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) = null)


Adds the given menu scene to the Quick Bar Menu
### `add_overlay()`


void **add_overlay**(overlay: [OverlayProvider](../OverlayProvider))


Adds the given overlay
