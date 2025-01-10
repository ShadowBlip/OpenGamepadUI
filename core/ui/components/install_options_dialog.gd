@icon("res://assets/editor-icons/solar--dialog-2-bold.svg")
@tool
extends Control
class_name InstallOptionDialog

## Emitted when the dialog window is opened
signal opened
## Emitted when the dialog window is closed
signal closed
## Emitted when the user selects an option
signal choice_selected(accepted: bool, choices: Dictionary)

## Text to display in the dialog box
@export var text: String:
	set(v):
		text = v
		if label:
			label.text = v
## Cancel button text
@export var cancel_text: String = "Cancel":
	set(v):
		cancel_text = v
		if cancel_button:
			cancel_button.text = v
@export var cancel_visible: bool = true:
	set(v):
		cancel_visible = v
		if cancel_button:
			cancel_button.visible = v
## Close the dialog when the user selects an option
@export var close_on_selected := true

@onready var label := $%Label as Label
@onready var confirm_button := $%ConfirmButton as CardButton
@onready var cancel_button := $%CancelButton as CardButton
@onready var fade_effect := $%FadeEffect as Effect
@onready var content := $%VBoxContainer as Control

var _return_node: Control = null
var _install_options: Array[Library.InstallOption] = []
var _selected_options: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	confirm_button.button_up.connect(_on_selected.bind(true))
	cancel_button.button_up.connect(_on_selected.bind(false))


## Invoked when confirm or cancel is selected
func _on_selected(accepted: bool) -> void:
	if close_on_selected:
		closed.emit()
	choice_selected.emit(accepted, self._selected_options.duplicate())
	if _return_node:
		_return_node.grab_focus.call_deferred()
	_return_node = null
	_clear_option_nodes()


## Clear any previous menu items
func _clear_option_nodes() -> void:
	for child: Node in content.get_children():
		if child.name in ["Label", "ConfirmButton", "CancelButton"]:
			continue
		content.remove_child(child)
		child.queue_free()


## Creates a [Control] node to configure the given [Library.InstallOption].
func _create_option_node(option: Library.InstallOption) -> Control:
	var option_node: Control
	var values := option.values
	match option.value_type:
		TYPE_BOOL:
			var toggle_scene := load("res://core/ui/components/toggle.tscn") as PackedScene
			var toggle := toggle_scene.instantiate() as Toggle
			toggle.text = option.name
			toggle.description = option.description
			var on_toggled := func(pressed: bool):
				self._selected_options[option.id] = pressed
			toggle.toggled.connect(on_toggled)
			option_node = toggle
		TYPE_STRING:
			var dropdown_scene := load("res://core/ui/components/dropdown.tscn") as PackedScene
			var dropdown := dropdown_scene.instantiate() as Dropdown
			dropdown.clear()
			dropdown.title = option.name
			dropdown.description = option.description
			for value in values:
				dropdown.add_item(str(value))
			var on_selected := func(idx: int):
				self._selected_options[option.id] = values[idx]
			dropdown.item_selected.connect(on_selected)
			option_node = dropdown
		_:
			pass

	return option_node


## Opens the dialog box with the given settings
func open(return_node: Control, options: Array[Library.InstallOption], message: String = "") -> void:
	self._install_options = options
	self._selected_options = {}

	# Clear any previous menu items
	_clear_option_nodes()

	# Build the menu based on the install options
	for option in options:
		var option_node := _create_option_node(option)
		if option_node:
			content.add_child(option_node)
			content.move_child(confirm_button, -1)
			content.move_child(cancel_button, -1)
	
	if message != "":
		text = message
	_return_node = return_node
	opened.emit()
	await fade_effect.effect_finished
	confirm_button.grab_focus.call_deferred()
