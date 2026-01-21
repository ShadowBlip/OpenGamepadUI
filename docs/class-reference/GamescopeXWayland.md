# GamescopeXWayland

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [allow_tearing](./#allow_tearing) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [baselayer_app](./#baselayer_app) |  |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [baselayer_apps](./#baselayer_apps) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [baselayer_window](./#baselayer_window) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [blur_mode](./#blur_mode) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [blur_radius](./#blur_radius) |  |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [focusable_apps](./#focusable_apps) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [focusable_window_names](./#focusable_window_names) |  |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [focusable_windows](./#focusable_windows) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [focused_app](./#focused_app) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [focused_app_gfx](./#focused_app_gfx) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [focused_window](./#focused_window) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [fps_limit](./#fps_limit) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_primary](./#is_primary) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [overlay_focused](./#overlay_focused) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [root_window_id](./#root_window_id) |  |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [watched_windows](./#watched_windows) |  |

## Methods

| Returns | Signature |
| ------- | --------- |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [get_all_windows](./#get_all_windows)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_app_id](./#get_app_id)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_input_counter](./#get_input_counter)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_overlay](./#get_overlay)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [get_pids_for_window](./#get_pids_for_window)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [get_window_children](./#get_window_children)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_window_depth](./#get_window_depth)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_window_name](./#get_window_name)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Vector2i](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) | [get_window_position](./#get_window_position)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_window_root](./#get_window_root)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Vector2i](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) | [get_window_size](./#get_window_size)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [Vector2i[]](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) | [get_window_sizes](./#get_window_sizes)(window_ids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [get_windows_for_pid](./#get_windows_for_pid)(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_app_id](./#has_app_id)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_input_focus](./#has_input_focus)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_notification](./#has_notification)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_overlay](./#has_overlay)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_focusable_app](./#is_focusable_app)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [remove_app_id](./#remove_app_id)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [remove_baselayer_app](./#remove_baselayer_app)() |
| void | [remove_baselayer_window](./#remove_baselayer_window)() |
| void | [request_screenshot](./#request_screenshot)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_app_id](./#set_app_id)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), app_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_external_overlay](./#set_external_overlay)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_input_focus](./#set_input_focus)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_main_app](./#set_main_app)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_notification](./#set_notification)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [set_overlay](./#set_overlay)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [unwatch_window](./#unwatch_window)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [watch_window](./#watch_window)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |


------------------

## Property Descriptions

### `allow_tearing`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) allow_tearing


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `baselayer_app`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) baselayer_app


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `baselayer_apps`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) baselayer_apps


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `baselayer_window`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) baselayer_window


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `blur_mode`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) blur_mode


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `blur_radius`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) blur_radius


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focusable_apps`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) focusable_apps


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focusable_window_names`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) focusable_window_names


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focusable_windows`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) focusable_windows


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focused_app`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) focused_app


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focused_app_gfx`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) focused_app_gfx


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `focused_window`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) focused_window


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `fps_limit`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) fps_limit


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `is_primary`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) is_primary


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `overlay_focused`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) overlay_focused


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `root_window_id`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) root_window_id


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `watched_windows`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) watched_windows


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_all_windows()`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) **get_all_windows**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_app_id()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_app_id**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_input_counter()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_input_counter**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_overlay()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_overlay**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_pids_for_window()`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) **get_pids_for_window**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_children()`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) **get_window_children**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_depth()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_window_depth**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_name()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_window_name**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_position()`


[Vector2i](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) **get_window_position**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_root()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_window_root**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_size()`


[Vector2i](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) **get_window_size**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_window_sizes()`


[Vector2i[]](https://docs.godotengine.org/en/stable/classes/class_vector2i.html) **get_window_sizes**(window_ids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_windows_for_pid()`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) **get_windows_for_pid**(pid: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `has_app_id()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_app_id**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `has_input_focus()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_input_focus**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `has_notification()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_notification**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `has_overlay()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_overlay**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `is_focusable_app()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_focusable_app**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `remove_app_id()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **remove_app_id**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `remove_baselayer_app()`


void **remove_baselayer_app**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `remove_baselayer_window()`


void **remove_baselayer_window**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `request_screenshot()`


void **request_screenshot**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_app_id()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_app_id**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), app_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_external_overlay()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_external_overlay**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_input_focus()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_input_focus**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_main_app()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_main_app**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_notification()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_notification**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `set_overlay()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **set_overlay**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), value: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `unwatch_window()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **unwatch_window**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `watch_window()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **watch_window**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

