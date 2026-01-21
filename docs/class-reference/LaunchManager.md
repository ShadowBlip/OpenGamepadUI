# LaunchManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Launch and manage the lifecycle of subprocesses
## Description

The LaunchManager class is responsible starting and managing the lifecycle of games and is one of the most complex systems in OpenGamepadUI. Using gamescope, it manages what games start, if their process is still running, and fascilitates window switching between games. It also provides a mechanism to kill running games and discover child processes. It uses a timer to periodically check on launched games to see if they have exited, or are opening new windows that might need attention. Example:
```gdscript

    var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
    ...
    # Create a LibraryLaunchItem to run something
    var item := LibraryLaunchItem.new()
    item.command = "vkcube"

    # Launch the app with LaunchManager
    var running_app := launch_manager.launch(item)

    # Get a list of running apps
    var running := launch_manager.get_running()
    print(running)

    # Stop an app with LaunchManager
    launch_manager.stop(running_app)

```


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [GamescopeInstance](../GamescopeInstance) | [gamescope](./#gamescope) | <Object> |
| [InputPlumberInstance](../InputPlumberInstance) | [input_plumber](./#input_plumber) | <unknown> |
| [StateMachine](../StateMachine) | [state_machine](./#state_machine) | <Object> |
| [State](../State) | [in_game_state](./#in_game_state) | <Object> |
| [State](../State) | [in_game_menu_state](./#in_game_menu_state) | <Object> |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [PID](./#PID) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [should_manage_overlay](./#should_manage_overlay) | true |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [setup](./#setup)(input_manager: [InputManager](../InputManager)) |
| [RunningApp](../RunningApp) | [launch](./#launch)(app: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [RunningApp](../RunningApp) | [launch_in_background](./#launch_in_background)(app: [LibraryLaunchItem](../LibraryLaunchItem)) |
| void | [stop](./#stop)(app: [RunningApp](../RunningApp)) |
| [Array](https://docs.godotengine.org/en/stable/classes/class_array.html) | [get_recent_apps](./#get_recent_apps)() |
| void | [update_recent_apps](./#update_recent_apps)(app: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [RunningApp[]](../RunningApp) | [get_running](./#get_running)() |
| [RunningApp[]](../RunningApp) | [get_running_background](./#get_running_background)() |
| [RunningApp](../RunningApp) | [get_running_from_window_id](./#get_running_from_window_id)(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| [RunningApp](../RunningApp) | [get_current_app](./#get_current_app)() |
| [LibraryItem](../LibraryItem) | [get_current_app_library_item](./#get_current_app_library_item)() |
| void | [set_app_gamepad_profile](./#set_app_gamepad_profile)(app: [RunningApp](../RunningApp)) |
| void | [set_gamepad_profile](./#set_gamepad_profile)(profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target_gamepad: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "") |
| void | [set_current_app](./#set_current_app)(app: [RunningApp](../RunningApp), _switch_baselayer: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [can_switch_app](./#can_switch_app)(app: [RunningApp](../RunningApp)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_running](./#is_running)(app_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [check_running](./#check_running)() |


------------------

## Property Descriptions

### `gamescope`


[GamescopeInstance](../GamescopeInstance) gamescope


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `input_plumber`


[InputPlumberInstance](../InputPlumberInstance) input_plumber


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `state_machine`


[StateMachine](../StateMachine) state_machine


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `in_game_state`


[State](../State) in_game_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `in_game_menu_state`


[State](../State) in_game_menu_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `PID`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) PID


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `should_manage_overlay`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) should_manage_overlay = <span style="color: red;">true</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `setup()`


void **setup**(input_manager: [InputManager](../InputManager))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `launch()`


[RunningApp](../RunningApp) **launch**(app: [LibraryLaunchItem](../LibraryLaunchItem))


Launches the given application and switches to the in-game state. Returns a [RunningApp](../RunningApp) instance of the application.
### `launch_in_background()`


[RunningApp](../RunningApp) **launch_in_background**(app: [LibraryLaunchItem](../LibraryLaunchItem))


Launches the given app in the background. Returns the [RunningApp](../RunningApp) instance.
### `stop()`


void **stop**(app: [RunningApp](../RunningApp))


Stops the game and all its children with the given PID
### `get_recent_apps()`


[Array](https://docs.godotengine.org/en/stable/classes/class_array.html) **get_recent_apps**()


Returns a list of apps that have been launched recently
### `update_recent_apps()`


void **update_recent_apps**(app: [LibraryLaunchItem](../LibraryLaunchItem))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `get_running()`


[RunningApp[]](../RunningApp) **get_running**()


Returns a list of currently running apps
### `get_running_background()`


[RunningApp[]](../RunningApp) **get_running_background**()


Returns a list of currently running background apps
### `get_running_from_window_id()`


[RunningApp](../RunningApp) **get_running_from_window_id**(window_id: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Returns the running app from the given window id
### `get_current_app()`


[RunningApp](../RunningApp) **get_current_app**()


Returns the currently running app
### `get_current_app_library_item()`


[LibraryItem](../LibraryItem) **get_current_app_library_item**()


Returns the library item for the currently running app (if one is running).
### `set_app_gamepad_profile()`


void **set_app_gamepad_profile**(app: [RunningApp](../RunningApp))


Sets the gamepad profile for the running app with the given profile
### `set_gamepad_profile()`


void **set_gamepad_profile**(profile_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), target_gamepad: [String](https://docs.godotengine.org/en/stable/classes/class_string.html) = "")


Sets the gamepad profile for the running app with the given profile
### `set_current_app()`


void **set_current_app**(app: [RunningApp](../RunningApp), _switch_baselayer: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) = true)


Sets the given running app as the current app
### `can_switch_app()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **can_switch_app**(app: [RunningApp](../RunningApp))


Returns true if the given app can be switched to via Gamescope
### `is_running()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_running**(app_name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns whether the given app is running
### `check_running()`


void **check_running**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

