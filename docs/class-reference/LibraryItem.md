# LibraryItem

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

LibraryItem is a high-level structure that contains data about a game.
## Description

A LibraryItem is a single game title that may have one or more library providers. It contains an array of [LibraryLaunchItem](../LibraryLaunchItem) resources that can tell us how to launch a game.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [LibraryLaunchItem[]](../LibraryLaunchItem) | [launch_items](./#launch_items) | [] |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [tags](./#tags) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [categories](./#categories) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_hidden](./#is_hidden) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [LibraryItem](../LibraryItem) | [new_from_launch_item](./#new_from_launch_item)(launch_item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [LibraryLaunchItem](../LibraryLaunchItem) | [get_launch_item](./#get_launch_item)(provider_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_launch_item](./#has_launch_item)(provider_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [erase_launch_item](./#erase_launch_item)(provider_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_installed](./#is_installed)() |


------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


Name of the game
### `launch_items`


[LibraryLaunchItem[]](../LibraryLaunchItem) launch_items = <span style="color: red;">[]</span>


An array of [LibraryLaunchItem](../LibraryLaunchItem) resources that this game supports
### `tags`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) tags


An array of tags associated with this game
### `categories`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) categories


An array of categories the game belongs to
### `is_hidden`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) is_hidden


Whether or not this library item should be hidden in the library



------------------

## Method Descriptions

### `new_from_launch_item()`


[LibraryItem](../LibraryItem) **new_from_launch_item**(launch_item: [LibraryLaunchItem](../LibraryLaunchItem))


Creates a new library item from the given library launch item
### `get_launch_item()`


[LibraryLaunchItem](../LibraryLaunchItem) **get_launch_item**(provider_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the library launch item for the given provider. Returns null if the given provider doesn't manage this game.
### `has_launch_item()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_launch_item**(provider_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the [LibraryItem](../LibraryItem) has a [LibraryLaunchItem](../LibraryLaunchItem) from the given provider
### `erase_launch_item()`


void **erase_launch_item**(provider_id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Removes the [LibraryLaunchItem](../LibraryLaunchItem) associated with the given launch provider.
### `is_installed()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_installed**()


Returns true if at least one library provider has this item installed.
