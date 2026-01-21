# InputManager

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Manages global input
## Description

The InputManager class is responsible for handling global input that should happen everywhere in the application, regardless of the current menu. Examples include opening up the main or quick bar menus.

To include this functionality, add this as a node to the root node in the scene tree.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [KeyboardInstance](../KeyboardInstance) | [osk](./#osk) | <unknown> |
| [AudioManager](../AudioManager) | [audio_manager](./#audio_manager) | <unknown> |
| [InputPlumberInstance](../InputPlumberInstance) | [input_plumber](./#input_plumber) | <unknown> |
| [LaunchManager](../LaunchManager) | [launch_manager](./#launch_manager) | <unknown> |
| [StateMachine](../StateMachine) | [state_machine](./#state_machine) | <unknown> |
| [StateMachine](../StateMachine) | [popup_state_machine](./#popup_state_machine) | <Object> |
| [State](../State) | [in_game_menu_state](./#in_game_menu_state) | <Object> |
| [State](../State) | [main_menu_state](./#main_menu_state) | <Object> |
| [State](../State) | [quick_bar_state](./#quick_bar_state) | <Object> |
| [State](../State) | [osk_state](./#osk_state) | <Object> |
| [State](../State) | [popup_state](./#popup_state) | <Object> |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [actions_pressed](./#actions_pressed) | {} |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [current_touches](./#current_touches) | 0 |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_default_global_profile_path](./#get_default_global_profile_path)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_inputplumber_event](./#is_inputplumber_event)(event: [InputEvent](https://docs.godotengine.org/en/stable/classes/class_inputevent.html)) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_action_pressed](./#is_action_pressed)(action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [action_release](./#action_release)(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0) |
| void | [action_press](./#action_press)(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0) |


------------------

## Property Descriptions

### `osk`


[KeyboardInstance](../KeyboardInstance) osk


Reference to the on-screen keyboard instance to open when the OSK action is pressed.
### `audio_manager`


[AudioManager](../AudioManager) audio_manager


The audio manager to use to adjust the audio when audio input events happen.
### `input_plumber`


[InputPlumberInstance](../InputPlumberInstance) input_plumber


InputPlumber receives and sends DBus input events.
### `launch_manager`


[LaunchManager](../LaunchManager) launch_manager


LaunchManager provides context on the currently running app so we can switch profiles
### `state_machine`


[StateMachine](../StateMachine) state_machine


The Global State Machine
### `popup_state_machine`


[StateMachine](../StateMachine) popup_state_machine


State machine to use to switch menu states in response to input events.
### `in_game_menu_state`


[State](../State) in_game_menu_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `main_menu_state`


[State](../State) main_menu_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `quick_bar_state`


[State](../State) quick_bar_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `osk_state`


[State](../State) osk_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `popup_state`


[State](../State) popup_state


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `actions_pressed`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) actions_pressed = <span style="color: red;">{}</span>


Map of pressed actions to prevent double inputs
### `current_touches`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) current_touches = <span style="color: red;">0</span>


Number of currently pressed touches
### `logger`


[CustomLogger](../CustomLogger) logger


Will show logger events with the prefix InputManager



------------------

## Method Descriptions

### `get_default_global_profile_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_default_global_profile_path**()


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `is_inputplumber_event()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_inputplumber_event**(event: [InputEvent](https://docs.godotengine.org/en/stable/classes/class_inputevent.html))


Returns true if the given event is an InputPlumber event
### `is_action_pressed()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_action_pressed**(action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns true if the given action is currently pressed. If InputPlumber is not running, then Godot's Input system will be used to check if the action is pressed. Otherwise, the input manager will track the state of the action.
### `action_release()`


void **action_release**(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0)


Queue a release event for the given action
### `action_press()`


void **action_press**(dbus_path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), action: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), strength: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 1.0)


Queue a pressed event for the given action
