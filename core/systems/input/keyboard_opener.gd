@tool
@icon("res://assets/ui/icons/keyboard-rounded.svg")
extends Node
class_name KeyboardOpener

## Node that can open the on-screen keyboard in response to a signal firing

## Reference to the on-screen keyboard instance to open when the OSK action is
## pressed.
var osk := load("res://core/global/keyboard_instance.tres") as KeyboardInstance
## The Global State Machine
var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
## Popup state machine to show the OSK popup.
var popup_state_machine := (
	preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
)
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State
var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var quick_bar_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var osk_state := preload("res://assets/state/states/osk.tres") as State
var popup_state := preload("res://assets/state/states/popup.tres") as State

## Signal on our parent node to connect to
var on_signal: String
## Target control node to send keyboard input to.
var target: Control

## The type of keyboard behavior. An "X11" keyboard will send keyboard events
## to a running game. A "Godot" keyboard will send text input to a control node.
@export var type: KeyboardContext.TYPE = KeyboardContext.TYPE.X11:
	set(v):
		type = v
		notify_property_list_changed()


func _init() -> void:
	ready.connect(_on_ready)


func _on_ready() -> void:
	notify_property_list_changed()
	# Do nothing if running in the editor
	if Engine.is_editor_hint():
		return
	if on_signal != "":
		get_parent().connect(on_signal, _on_signal)


## Fires when the given signal is emitted.
func _on_signal(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null, _arg4: Variant = null):
	var state := popup_state_machine.current_state()
	if state == osk_state:
		osk.close()
		popup_state_machine.pop_state()
		return

	if state in [main_menu_state, in_game_menu_state, quick_bar_state]:
		popup_state_machine.replace_state(osk_state)
	else:
		popup_state_machine.push_state(osk_state)
	state_machine.push_state(popup_state)

	var context := KeyboardContext.new()
	context.type = type
	if type == KeyboardContext.TYPE.GODOT:
		context.target = target
	osk.open(context)


# Customize editor properties that we expose. Here we dynamically look up
# the parent node's signals so we can display them in a list.
func _get_property_list():
	# By default, `on_signal` is not visible in the editor.
	var property_usage := PROPERTY_USAGE_NO_EDITOR

	var parent_signals := []
	if get_parent() != null:
		property_usage = PROPERTY_USAGE_DEFAULT
		for sig in get_parent().get_signal_list():
			parent_signals.push_back(sig["name"])

	# Build the exported node properties
	var properties := []
	properties.append(
		{
			"name": "on_signal",
			"type": TYPE_STRING,
			"usage": property_usage,  # See above assignment.
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(parent_signals)
		}
	)
	
	# Only show the control node target property if "Godot" type is selected
	if self.type == KeyboardContext.TYPE.GODOT:
		properties.append(
			{
				"name": "target",
				"type": TYPE_OBJECT,
				"usage": property_usage,
				"hint": PROPERTY_HINT_NODE_TYPE,
				"hint_string": "Control",
			}
		) 

	return properties
