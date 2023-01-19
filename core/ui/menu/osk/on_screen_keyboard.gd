@tool
@icon("res://assets/icons/command.svg")
extends Control
class_name OnScreenKeyboard

signal keyboard_opened
signal keyboard_closed
signal keyboard_populated
signal layout_changed
signal context_changed(ctx: KeyboardContext)
signal mode_shifted(mode: MODE_SHIFT)

const key_scene := preload("res://core/ui/components/button.tscn")

# Different states of mode shift (i.e. when the user presses "shift" or "caps")
enum MODE_SHIFT {
	OFF,
	ON,
	ONE_SHOT,
}

@export var layout: KeyboardLayout = KeyboardLayout.new()
var _context: KeyboardContext
var _mode_shift: MODE_SHIFT = MODE_SHIFT.OFF
var logger := Log.get_logger("OSK")

@onready var rows_container := $MarginContainer/VBoxContainer

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
		
	keyboard_populated.emit()


# Opens the OSK with the given context. The keyboard context determines where
# keyboard inputs should go, and how to handle submits.
func open(ctx: KeyboardContext) -> void:
	set_context(ctx)
	visible = true
	
	# Grab focus on the first key in the first row
	for r in rows_container.get_children():
		var row := r as HBoxContainer
		for k in row.get_children():
			var key := k as Button
			key.grab_focus.call_deferred()
			break
		break
	
	keyboard_opened.emit()


# Closes the OSK
func close() -> void:
	visible = false
	keyboard_closed.emit()


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
	# If the target is a Godot TextEdit, update the caret position on context change
	if ctx.target != null and ctx.target is TextEdit:
		var text_edit := ctx.target as TextEdit
		var lines := text_edit.get_line_count()
		text_edit.set_caret_line(lines-1)
		var current_line := text_edit.get_line(lines-1)
		text_edit.set_caret_column(current_line.length())
		#text_edit.clear()
		
	# Update our internal keyboard context
	if _context == ctx:
		return
	_context = ctx
	context_changed.emit(ctx)


# Sets the keyboard mode shift (i.e. pressing the "shift" key)
func set_mode_shift(mode: MODE_SHIFT) -> void:
	_mode_shift = mode
	mode_shifted.emit(mode)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_released("ogui_east"):
		close()

# Handle input when the keyboard is open and focused
func _gui_input(event: InputEvent) -> void:
	print(event)
	if event.is_action_released("ogui_east"):
		close()


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
		
	if not _context.target is TextEdit:
		logger.warn("Non-TextEdit nodes are not currently supported")
		return
	
	# Update the target text with the given character
	var text_edit := _context.target as TextEdit
	var char := key.output
	if _mode_shift > MODE_SHIFT.OFF:
		char = key.output_uppercase
		if _mode_shift == MODE_SHIFT.ONE_SHOT:
			set_mode_shift(MODE_SHIFT.OFF)
	text_edit.insert_text_at_caret(char)


# Handles special key inputs like shift, alt, ctrl, etc.
func _handle_key_special(key: KeyboardKeyConfig) -> void:
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
			close()
			return
		KeyboardKeyConfig.ACTION.BKSP:
			if _context.target != null and _context.target is TextEdit:
				var text_edit := _context.target as TextEdit
				text_edit.backspace()
			return
		KeyboardKeyConfig.ACTION.ENTER:
			if _context.target != null and _context.target is TextEdit:
				var text_edit := _context.target as TextEdit
				_context.submit.call(text_edit.text)
			if _context.close_on_submit:
				close()
			return
