# BoxArtProvider

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Base class for BoxArt implementations
## Description

The BoxArtProvider class provides an interface for providing sources of game artwork. To create a new BoxArtProvider, simply extend this class and implement its methods. When a BoxArtProvider node enters the scene tree, it will automatically register itself with the global [BoxArtManager](../BoxArtManager).  When a menu requires showing artwork for a particular game, it will request that artwork from the [BoxArtManager](../BoxArtManager). The manager, in turn, will request artwork from all registered boxart providers until it finds one.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [BoxArtManager](../BoxArtManager) | [BoxArtManager](./#BoxArtManager) | <unknown> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [provider_id](./#provider_id) |  |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [provider_icon](./#provider_icon) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [logger_name](./#logger_name) | provider_id |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [log_level](./#log_level) | 3 |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [get_boxart](./#get_boxart)(item: [LibraryItem](../LibraryItem), kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |


------------------

## Property Descriptions

### `BoxArtManager`


[BoxArtManager](../BoxArtManager) BoxArtManager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `provider_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) provider_id


Unique identifier for the boxart provider
### `provider_icon`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) provider_icon


Icon for boxart provider
### `logger_name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) logger_name = <span style="color: red;">provider_id</span>


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

### `get_boxart()`


[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) **get_boxart**(item: [LibraryItem](../LibraryItem), kind: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the game artwork as a texture for the given game in the given layout. This method should be overriden in the extending class.
