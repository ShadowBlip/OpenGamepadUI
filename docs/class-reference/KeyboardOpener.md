# KeyboardOpener

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Node that can open the on-screen keyboard in response to a signal firing
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [KeyboardInstance](../KeyboardInstance) | [osk](./#osk) | <unknown> |
| [StateMachine](../StateMachine) | [state_machine](./#state_machine) | <unknown> |
| [StateMachine](../StateMachine) | [popup_state_machine](./#popup_state_machine) | <Object> |
| [State](../State) | [in_game_menu_state](./#in_game_menu_state) | <Object> |
| [State](../State) | [main_menu_state](./#main_menu_state) | <Object> |
| [State](../State) | [quick_bar_state](./#quick_bar_state) | <Object> |
| [State](../State) | [osk_state](./#osk_state) | <Object> |
| [State](../State) | [popup_state](./#popup_state) | <Object> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [on_signal](./#on_signal) |  |
| [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) | [target](./#target) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [type](./#type) | 2 |



------------------

## Property Descriptions

### `osk`


[KeyboardInstance](../KeyboardInstance) osk


Reference to the on-screen keyboard instance to open when the OSK action is pressed.
### `state_machine`


[StateMachine](../StateMachine) state_machine


The Global State Machine
### `popup_state_machine`


[StateMachine](../StateMachine) popup_state_machine


Popup state machine to show the OSK popup.
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

### `on_signal`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) on_signal


Signal on our parent node to connect to
### `target`


[Control](https://docs.godotengine.org/en/stable/classes/class_control.html) target


Target control node to send keyboard input to.
### `type`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) type = <span style="color: red;">2</span>


The type of keyboard behavior. An "X11" keyboard will send keyboard events to a running game. A "Godot" keyboard will send text input to a control node.

