@tool
@icon("res://assets/icons/command.svg")
extends Control
class_name OnScreenKeyboard

signal layout_changed
signal mode_shifted(mode: MODE_SHIFT)

const key_scene := preload("res://core/ui/components/button.tscn")

# Different states of mode shift (i.e. when the user presses "shift" or "caps")
enum MODE_SHIFT {
	OFF,
	ON,
	ONE_SHOT,
}

@export var layout: KeyboardLayout = KeyboardLayout.new()
@export var instance: KeyboardInstance = preload("res://core/global/keyboard_instance.tres")
var _mode_shift: MODE_SHIFT = MODE_SHIFT.OFF
var logger := Log.get_logger("OSK")

@onready var rows_container := $MarginContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not layout:
		logger.warn("No keyboard layout was defined")
		return
	instance.keyboard_opened.connect(open)
	instance.keyboard_closed.connect(close)
	populate_keyboard()


# Populate the keyboard based on the selected layout
func populate_keyboard() -> void:
	# Clear the current layout
	for child in rows_container.get_children():
		rows_container.remove_child(child)
	
	# Populate the keyboard keys based on the given layout
	for r in (layout as KeyboardLayout).rows:
		var row := r as Array
		
		# Create an HBox Container for the row
		var container := HBoxContainer.new()
		container.size_flags_vertical = HBoxContainer.SIZE_EXPAND_FILL
		rows_container.add_child(container)
		
		# Loop through the layout and create key buttons for each key
		for k in row:
			var key := k as KeyboardKeyConfig
			if not key:
				continue
			var button := key_scene.instantiate()
			button.size_flags_stretch_ratio = key.stretch_ratio
			if key.type == KeyboardKeyConfig.TYPE.CHAR and key.display != "":
				button.text = key.display
			elif key.type == KeyboardKeyConfig.TYPE.SPECIAL and key.icon == null:
				button.text = key.display
			
			# Connect the keyboard key to a method to handle key presses
			button.button_up.connect(_on_key_pressed.bind(key))
			
			# Create a callback when the keyboard mode changes (i.e. shift is pressed)
			var on_mode_shift := func _on_mode_shift(mode: MODE_SHIFT) -> void:
				if mode > MODE_SHIFT.OFF:
					button.text = key.display_uppercase
					return
				button.text = key.display
			mode_shifted.connect(on_mode_shift)
			
			container.add_child(button)
		
	instance.keyboard_populated.emit()


# Opens the OSK with the given context. The keyboard context determines where
# keyboard inputs should go, and how to handle submits.
func open() -> void:
	visible = true
	
	# Grab focus on the first key in the first row
	for r in rows_container.get_children():
		var row := r as HBoxContainer
		for k in row.get_children():
			var key := k as Button
			key.grab_focus.call_deferred()
			break
		break


# Closes the OSK
func close() -> void:
	visible = false


# Sets the given keyboard layout and re-populates the keyboard
func set_layout(key_layout: KeyboardLayout) -> void:
	layout = key_layout
	populate_keyboard()
	layout_changed.emit()


# Sets the keyboard mode shift (i.e. pressing the "shift" key)
func set_mode_shift(mode: MODE_SHIFT) -> void:
	_mode_shift = mode
	mode_shifted.emit(mode)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_released("ogui_east"):
		instance.close()
		get_viewport().set_input_as_handled()
		return 
	if event.is_action_released("ogui_north"):
		var key := KeyboardKeyConfig.new()
		key.type = key.TYPE.SPECIAL
		key.action = key.ACTION.BKSP
		_on_key_pressed(key)
		get_viewport().set_input_as_handled()
		return
	if event.is_action("ogui_left_trigger"):
		if event.get_action_strength("ogui_left_trigger") > 0.5:
			if _mode_shift != MODE_SHIFT.ON:
				set_mode_shift(MODE_SHIFT.ON)
		else:
			if _mode_shift != MODE_SHIFT.OFF:
				set_mode_shift(MODE_SHIFT.OFF)
		return
	if event.is_action("ogui_right_trigger"):
		if event.get_action_strength("ogui_right_trigger") < 0.5:
			return
		var key := KeyboardKeyConfig.new()
		key.type = key.TYPE.SPECIAL
		key.action = key.ACTION.ENTER
		_on_key_pressed(key)
		return


# Handle input when the keyboard is open and focused
func _gui_input(event: InputEvent) -> void:
	if event.is_action_released("ogui_east"):
		instance.close()
		get_viewport().set_input_as_handled()


# Handle all kinds of key presses. Key inputs get processed depending on the
# currently set keyboard context.
func _on_key_pressed(key: KeyboardKeyConfig) -> void:
	if key.type == KeyboardKeyConfig.TYPE.CHAR:
		_handle_key_char(key)
		return
	_handle_key_special(key)


# Handles normal character inputs
func _handle_key_char(key: KeyboardKeyConfig) -> void:
	if instance.context == null:
		logger.warn("Keyboard context not set, nowhere to send key input.")
		return
	
	if instance.context.type == KeyboardContext.TYPE.X11:
		return
	
	if instance.context.target == null:
		logger.warn("Keyboard target not set, nowhere to send key input.")
		return
	var target = instance.context.target

	# Get the character to send to the target
	var character := key.output
	if _mode_shift > MODE_SHIFT.OFF:
		character = key.output_uppercase
		if _mode_shift == MODE_SHIFT.ONE_SHOT:
			set_mode_shift(MODE_SHIFT.OFF)
	
	# Update the target text with the given character
	if target is TextEdit:
		var text_edit := instance.context.target as TextEdit
		text_edit.insert_text_at_caret(character)
		return
	
	if target is LineEdit:
		var line_edit := instance.context.target as LineEdit
		line_edit.insert_text_at_caret(character)
		return

	logger.warn("Keyboard target is not a supported type. Can't send key input.")


# Handles special key inputs like shift, alt, ctrl, etc.
func _handle_key_special(key: KeyboardKeyConfig) -> void:
	if not instance.context:
		return
	var target = instance.context.target
	match key.action:
		KeyboardKeyConfig.ACTION.SHIFT:
			if _mode_shift > MODE_SHIFT.OFF:
				set_mode_shift(MODE_SHIFT.OFF)
				return
			set_mode_shift(MODE_SHIFT.ONE_SHOT)
			return
		KeyboardKeyConfig.ACTION.CAPS:
			if _mode_shift > MODE_SHIFT.OFF:
				set_mode_shift(MODE_SHIFT.OFF)
				return
			set_mode_shift(MODE_SHIFT.ON)
			return
		KeyboardKeyConfig.ACTION.CLOSE_KEYBOARD:
			instance.close()
			return
		KeyboardKeyConfig.ACTION.BKSP:
			if target != null and target is TextEdit:
				var text_edit := target as TextEdit
				text_edit.backspace()
			if target != null and target is LineEdit:
				var line_edit := target as LineEdit
				line_edit.delete_char_at_caret()
			return
		KeyboardKeyConfig.ACTION.ENTER:
			instance.context.submitted.emit()
			if instance.context.close_on_submit:
				instance.close()
			return
