# PluginLoader

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Manage and load plugins
## Description

The PluginLoader is responsible for downloading, loading, and initializing OpenGamepadUI plugins. The plugin system for OpenGamepadUI is inspired by the modding system implemented by Delta-V. 

The PluginLoader works by taking advantage of Godot's [method ProjectSettings.load_resource_pack](https://docs.godotengine.org/en/stable/classes/class_method projectsettings.load_resource_pack.html) method, which can allow us to load Godot scripts and scenes from a zip file. The PluginLoader looks for zip files in user://plugins, and parses the plugin.json file contained within them. If the plugin metadata is valid, the loader loads the zip as a resource pack.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [SettingsManager](../SettingsManager) | [SettingsManager](./#SettingsManager) | <unknown> |
| [PluginManager](../PluginManager) | [parent](./#parent) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [plugins](./#plugins) | {} |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [plugin_nodes](./#plugin_nodes) | {} |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [plugin_store_items](./#plugin_store_items) | {} |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [plugins_upgradable](./#plugins_upgradable) | [] |
| [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) | [plugin_filters](./#plugin_filters) | [] |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [init](./#init)(manager: [PluginManager](../PluginManager)) |
| void | [enable_plugin](./#enable_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [disable_plugin](./#disable_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_plugin_store_items](./#get_plugin_store_items)() |
| void | [install_plugin](./#install_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), download_url: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), sha256: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [uninstall_plugin](./#uninstall_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_extracted](./#is_extracted)(meta: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)) |
| void | [extract_plugin](./#extract_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [unload_plugin](./#unload_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [uninitialize_plugin](./#uninitialize_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_installed](./#is_installed)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_loaded](./#is_loaded)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_initialized](./#is_initialized)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_upgradable](./#is_upgradable)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Plugin](../Plugin) | [get_plugin](./#get_plugin)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [get_plugin_meta](./#get_plugin_meta)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [get_loaded_plugins](./#get_loaded_plugins)() |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [get_initialized_plugins](./#get_initialized_plugins)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [set_plugin_upgraded](./#set_plugin_upgraded)(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [initialize_plugin](./#initialize_plugin)(plugin_id: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html)) |
| void | [on_update_timeout](./#on_update_timeout)() |
| [String[]](https://docs.godotengine.org/en/stable/classes/class_string.html) | [filter_by_tag](./#filter_by_tag)(plugins: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html), tag: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [set_plugin_filters](./#set_plugin_filters)(filters: [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html)) |


------------------

## Property Descriptions

### `SettingsManager`


[SettingsManager](../SettingsManager) SettingsManager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `parent`


[PluginManager](../PluginManager) parent


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `plugins`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) plugins = <span style="color: red;">{}</span>


Dictionary of installed plugins on the root file system.
### `plugin_nodes`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) plugin_nodes = <span style="color: red;">{}</span>


Dictionary of instantiated plugins.
### `plugin_store_items`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) plugin_store_items = <span style="color: red;">{}</span>


Dictionary of available plugins in the defualt plugin store. Similair data struture to the plugins dict with some additonal fields.
### `plugins_upgradable`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) plugins_upgradable = <span style="color: red;">[]</span>


List of plugin_ids that are installed where a newer version of the plugin is available in the plugin store.
### `plugin_filters`


[Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html) plugin_filters = <span style="color: red;">[]</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `init()`


void **init**(manager: [PluginManager](../PluginManager))


Initializes the plugin loader. Loaded plugins will be added to the given manager node.
### `enable_plugin()`


void **enable_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Sets the given plugin to enabled
### `disable_plugin()`


void **disable_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Sets the given plugin to disabled
### `get_plugin_store_items()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_plugin_store_items**()


Returns the parsed dictionary of plugin store items. Returns null if there is a failure.
### `install_plugin()`


void **install_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), download_url: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), sha256: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Downloads and installs the given plugin
### `uninstall_plugin()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **uninstall_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Unloads and uninstalls the given plugin. Returns OK if removed successfully.
### `is_extracted()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_extracted**(meta: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html))


Returns whether or not the given plugin is already extracted. This takes the parsed plugin metadata as an argument.
### `extract_plugin()`


void **extract_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Extract the given plugin into the plugins directory
### `unload_plugin()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **unload_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Unloads the given plugin. Returns OK if successful.
### `uninitialize_plugin()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **uninitialize_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Uninitializes a plugin and calls its "unload" method
### `is_installed()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_installed**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the given plugin is installed.
### `is_loaded()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_loaded**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the given plugin is loaded.
### `is_initialized()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_initialized**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the given plugin is initialized and running
### `is_upgradable()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_upgradable**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the given plugin is upgradable.
### `get_plugin()`


[Plugin](../Plugin) **get_plugin**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the given plugin instance
### `get_plugin_meta()`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) **get_plugin_meta**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the metadata for the given plugin
### `get_loaded_plugins()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **get_loaded_plugins**()


Returns a list of plugin_ids that were loaded
### `get_initialized_plugins()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **get_initialized_plugins**()


Returns a list of plugin_ids that are initialized and running
### `set_plugin_upgraded()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **set_plugin_upgraded**(plugin_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `initialize_plugin()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **initialize_plugin**(plugin_id: [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html))


Instances the given plugin and adds it to the scene tree
### `on_update_timeout()`


void **on_update_timeout**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `filter_by_tag()`


[String[]](https://docs.godotengine.org/en/stable/classes/class_string.html) **filter_by_tag**(plugins: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html), tag: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_plugin_filters()`


void **set_plugin_filters**(filters: [Callable[]](https://docs.godotengine.org/en/stable/classes/class_callable.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

