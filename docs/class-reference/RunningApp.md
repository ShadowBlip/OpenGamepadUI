# RunningApp

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Defines a running application
## Description

RunningApp contains details and methods around running applications
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [GamescopeInstance](../GamescopeInstance) | [gamescope](./#gamescope) | <unknown> |
| [LibraryLaunchItem](../LibraryLaunchItem) | [launch_item](./#launch_item) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [pid](./#pid) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [display](./#display) |  |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [command](./#command) |  |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [environment](./#environment) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [state](./#state) | 0 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [state_steam](./#state_steam) | 0 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [steam_missing_window_timestamp](./#steam_missing_window_timestamp) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_suspended](./#is_suspended) | false |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [start_time](./#start_time) | <unknown> |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [window_ids](./#window_ids) | PackedInt64Array() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [last_focused_window_id](./#last_focused_window_id) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [ogui_id](./#ogui_id) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [app_id](./#app_id) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [app_type](./#app_type) | 0 |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [focused](./#focused) | false |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [created_window](./#created_window) | false |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [num_created_windows](./#num_created_windows) | 0 |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [not_running_count](./#not_running_count) | 0 |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_ogui_managed](./#is_ogui_managed) | true |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [RunningApp](../RunningApp) | [create](./#create)(app: [LibraryLaunchItem](../LibraryLaunchItem), env: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html), cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html)) |
| [RunningApp](../RunningApp) | [spawn](./#spawn)(app: [LibraryLaunchItem](../LibraryLaunchItem), env: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html), cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html)) |
| void | [start](./#start)() |
| void | [update](./#update)(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [discover_app_type](./#discover_app_type)(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| void | [update_wayland_app](./#update_wayland_app)(app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| void | [update_xwayland_app](./#update_xwayland_app)(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| void | [update_steam_xwayland_app](./#update_steam_xwayland_app)(app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| void | [suspend](./#suspend)(enable: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html)) |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_window_title](./#get_window_title)(win_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_window_id_from_pid](./#get_window_id_from_pid)() |
| [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) | [get_all_window_ids](./#get_all_window_ids)(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_running](./#is_running)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_focused](./#is_focused)() |
| void | [grab_focus](./#grab_focus)() |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [switch_window](./#switch_window)(win_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), focus: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |
| void | [kill](./#kill)(sig: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 15) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_steam_app](./#is_steam_app)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_steam_window](./#is_steam_window)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [find_steam](./#find_steam)(app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html)) |


------------------

## Property Descriptions

### `gamescope`


[GamescopeInstance](../GamescopeInstance) gamescope


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `launch_item`


[LibraryLaunchItem](../LibraryLaunchItem) launch_item


The LibraryLaunchItem associated with the running application
### `pid`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) pid


The PID of the launched application
### `display`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) display


The xwayland display that the application is running on (e.g. ":1")
### `command`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) command


The raw command that was used to launch the application
### `environment`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) environment


Environment variables that were set with the launched application
### `state`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) state = <span style="color: red;">0</span>


The state of the running app
### `state_steam`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) state_steam = <span style="color: red;">0</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `steam_missing_window_timestamp`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) steam_missing_window_timestamp


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `is_suspended`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) is_suspended = <span style="color: red;">false</span>


Whether or not the running app is suspended
### `start_time`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) start_time


Time in milliseconds when the app started
### `window_ids`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) window_ids = <span style="color: red;">PackedInt64Array()</span>


A list of all detected window IDs related to the application
### `last_focused_window_id`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) last_focused_window_id


The window id of the last focused window
### `ogui_id`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) ogui_id


The identifier that is set as the OGUI_ID environment variable
### `app_id`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) app_id


The current app ID of the application
### `app_type`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) app_type = <span style="color: red;">0</span>


The type of app
### `focused`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) focused = <span style="color: red;">false</span>


Whether or not the app is currently focused
### `created_window`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) created_window = <span style="color: red;">false</span>


Whether or not the running app has created at least one valid window
### `num_created_windows`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) num_created_windows = <span style="color: red;">0</span>


The number of windows that have been discovered from this app
### `not_running_count`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) not_running_count = <span style="color: red;">0</span>


Number of times this app has failed its "is_running" check
### `is_ogui_managed`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) is_ogui_managed = <span style="color: red;">true</span>


Flag for if OGUI should manage this app. Set to false if app is launched outside OGUI and we just want to track it.
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `create()`


[RunningApp](../RunningApp) **create**(app: [LibraryLaunchItem](../LibraryLaunchItem), env: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html), cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html))


Create a [RunningApp](../RunningApp) with the given command without starting it.
### `spawn()`


[RunningApp](../RunningApp) **spawn**(app: [LibraryLaunchItem](../LibraryLaunchItem), env: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html), cmd: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), args: [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html))


Run the given command and return it as a [RunningApp](../RunningApp)
### `start()`


void **start**()


Start the running app
### `update()`


void **update**(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


Updates the state of the running app and fires signals using the given list of window ids from XWayland and list of process ids that match the OGUI_ID of this application.
### `discover_app_type()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **discover_app_type**(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


Tries to discover if the launched app is an X11 or Wayland application
### `update_wayland_app()`


void **update_wayland_app**(app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `update_xwayland_app()`


void **update_xwayland_app**(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `update_steam_xwayland_app()`


void **update_steam_xwayland_app**(app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `suspend()`


void **suspend**(enable: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html))


Pauses/Resumes the running app by running 'kill -STOP' or 'kill -CONT'
### `get_window_title()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_window_title**(win_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the window title of the given window. If the window ID does not belong to this app, it will return an empty string.
### `get_window_id_from_pid()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_window_id_from_pid**()


Attempt to discover the window ID from the PID of the given application
### `get_all_window_ids()`


[PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html) **get_all_window_ids**(all_windows: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html), app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


Attempt to discover all window IDs from the PID of the given application and the PIDs of all processes in the same process group.
### `is_running()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_running**()


Returns true if the app's PID is running or any decendents with the same process group.
### `is_focused()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_focused**()


Return true if the currently running app is focused
### `grab_focus()`


void **grab_focus**()


Focuses to the app's window
### `switch_window()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **switch_window**(win_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html), focus: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


Switches the app window to the given window ID. Returns an error if unable to switch to the window
### `kill()`


void **kill**(sig: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 15)


Kill the running app
### `is_steam_app()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_steam_app**()


Returns true if the running app was launched through Steam
### `is_steam_window()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_steam_window**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns true if the given window id is detected as a Steam window
### `find_steam()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **find_steam**(app_pids: [PackedInt64Array](https://docs.godotengine.org/en/stable/classes/class_packedint64array.html))


Finds the steam process so it can be killed when a game closes
