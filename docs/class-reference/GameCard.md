# GameCard

**Inherits:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [BoxArtManager](../BoxArtManager) | [boxart_manager](./#boxart_manager) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [show_label](./#show_label) | false |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [text](./#text) | "Game Name" |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [show_progress](./#show_progress) | false |
| [float](https://docs.godotengine.org/en/stable/classes/class_float.html) | [value](./#value) | 50.0 |
| [LibraryItem](../LibraryItem) | [library_item](./#library_item) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [tapped_count](./#tapped_count) | 0 |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) | [texture](./#texture) | <unknown> |
| [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) | [name_container](./#name_container) | <unknown> |
| [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) | [name_label](./#name_label) | <unknown> |
| [ProgressBar](https://docs.godotengine.org/en/stable/classes/class_progressbar.html) | [progress](./#progress) | <unknown> |
| [Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) | [tap_timer](./#tap_timer) | <unknown> |
| [ColorRect](https://docs.godotengine.org/en/stable/classes/class_colorrect.html) | [shine_rect](./#shine_rect) | <unknown> |
| [ColorRect](https://docs.godotengine.org/en/stable/classes/class_colorrect.html) | [god_rays_rect](./#god_rays_rect) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [set_texture](./#set_texture)(new_texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) |
| void | [set_library_item](./#set_library_item)(item: [LibraryItem](../LibraryItem), free_on_remove: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |


------------------

## Property Descriptions

### `boxart_manager`


[BoxArtManager](../BoxArtManager) boxart_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `show_label`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) show_label = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `text`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) text = <span style="color: red;">"Game Name"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `show_progress`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) show_progress = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `value`


[float](https://docs.godotengine.org/en/stable/classes/class_float.html) value = <span style="color: red;">50.0</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `library_item`


[LibraryItem](../LibraryItem) library_item


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `tapped_count`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) tapped_count = <span style="color: red;">0</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `texture`


[Node](https://docs.godotengine.org/en/stable/classes/class_node.html) texture


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `name_container`


[Node](https://docs.godotengine.org/en/stable/classes/class_node.html) name_container


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `name_label`


[Node](https://docs.godotengine.org/en/stable/classes/class_node.html) name_label


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `progress`


[ProgressBar](https://docs.godotengine.org/en/stable/classes/class_progressbar.html) progress


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `tap_timer`


[Timer](https://docs.godotengine.org/en/stable/classes/class_timer.html) tap_timer


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `shine_rect`


[ColorRect](https://docs.godotengine.org/en/stable/classes/class_colorrect.html) shine_rect


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `god_rays_rect`


[ColorRect](https://docs.godotengine.org/en/stable/classes/class_colorrect.html) god_rays_rect


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `set_texture()`


void **set_texture**(new_texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html))


Sets the texture on the given card and sets the shader params
### `set_library_item()`


void **set_library_item**(item: [LibraryItem](../LibraryItem), free_on_remove: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


Configures the card with the given library item.
