@tool
@icon("res://assets/icons/command.svg")
extends Control
class_name OnScreenKeyboard

signal keyboard_populated
signal layout_changed
signal context_changed(ctx: KeyboardContext)
signal mode_shifted(shifted: bool)

const key_scene := preload("res://core/ui/components/button.tscn")

@export var layout: KeyboardLayout = KeyboardLayout.new()
var _context: KeyboardContext
var _mode_shift: bool = false
var logger := Log.get_logger("OSK")

@onready var rows_container: VBoxContainer = $MarginContainer/VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not layout:
		logger.warn("No keyboard layout was defined")
		return
	populate_keyboard()


# Populate the keyboard based on the selected layout
func populate_keyboard() -> void:
	# Clear the current layout
	for child in rows_container.get_children():
		rows_container.remove_child(child)
	
	# Populate the keyboard keys based on the given layout
	for r in (layout as KeyboardLayout).rows:
		var row: Array = r
		
		# Create an HBox Container for the row
		var container := HBoxContainer.new()
		container.size_flags_vertical = HBoxContainer.SIZE_EXPAND_FILL
		rows_container.add_child(container)
		
		# Loop through the layout and create key buttons for each key
		for k in row:
			var key: KeyboardKeyConfig = k
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
			var on_mode_shift := func _on_mode_shift(shifted: bool) -> void:
				if shifted:
					button.text = key.display_uppercase
					return
				button.text = key.display
			mode_shifted.connect(on_mode_shift)
			
			container.add_child(button)
		
	keyboard_populated.emit()


# Sets the given keyboard layout and re-populates the keyboard
func set_layout(key_layout: KeyboardLayout) -> void:
	layout = key_layout
	populate_keyboard()
	layout_changed.emit()


# Returns the currently set keyboard context
func get_context() -> KeyboardContext:
	return _context


# Configure the keyboard to use the given context. The keyboard context determines where
# keyboard inputs should go, and how to handle submits.
func set_context(ctx: KeyboardContext) -> void:
	if _context == ctx:
		return
	_context = ctx
	context_changed.emit(ctx)


# Sets the keyboard mode shift (i.e. pressing the "shift" key)
func set_mode_shift(on: bool) -> void:
	_mode_shift = on
	mode_shifted.emit(on)


# Opens the OSK with the given context. The keyboard context determines where
# keyboard inputs should go, and how to handle submits.
func open(ctx: KeyboardContext) -> void:
	set_context(ctx)
	visible = true


# Closes the OSK
func close() -> void:
	visible = false


# Handle all kinds of key presses. Key inputs get processed depending on the
# currently set keyboard context.
func _on_key_pressed(key: KeyboardKeyConfig) -> void:
	if key.type == KeyboardKeyConfig.TYPE.CHAR:
		_handle_key_char(key)
		return
	_handle_key_special(key)


# Handles normal character inputs
func _handle_key_char(key: KeyboardKeyConfig) -> void:
	if _context == null:
		logger.warn("Keyboard context not set, nowhere to send key input.")
		return
		
	if _context.type == KeyboardContext.TYPE.X11:
		return
	
	if _context.target == null:
		logger.warn("Keyboard target not set, nowhere to send key input.")
		return
		
	if _context.target.get("text") == null:
		logger.warn("Non TextEdit nodes are not currently supported")
		return

# Handles special key inputs like shift, alt, ctrl, etc.
func _handle_key_special(key: KeyboardKeyConfig) -> void:
	match key.action:
		KeyboardKeyConfig.ACTION.SHIFT:
			set_mode_shift(!_mode_shift)
			return
		KeyboardKeyConfig.ACTION.CLOSE_KEYBOARD:
			close()
			return
