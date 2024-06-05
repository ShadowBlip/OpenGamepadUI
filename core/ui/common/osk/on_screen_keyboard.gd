@tool
@icon("res://assets/editor-icons/keyboard.svg")
extends Control
class_name OnScreenKeyboard

signal layout_changed
signal mode_shifted(mode: MODE_SHIFT)
signal opened
signal closed

const Gamescope := preload("res://core/global/gamescope.tres")
const key_scene := preload("res://core/ui/components/button.tscn")
var input_icons := load("res://core/systems/input/input_icon_manager.tres") as InputIconManager

# Different states of mode shift (i.e. when the user presses "shift" or "caps")
enum MODE_SHIFT {
	OFF,
	ON,
	ONE_SHOT,
}

@export var layout: KeyboardLayout
@export var instance: KeyboardInstance = preload("res://core/global/keyboard_instance.tres")
var _mode_shift: MODE_SHIFT = MODE_SHIFT.OFF
var logger := Log.get_logger("OSK")

@onready var rows_container := $%KeyboardRowsContainer

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
	var idx := 0
	var button_rows: Array[Array] = []
	for r in (layout as KeyboardLayout).rows:
		var row := r as KeyboardRow
		button_rows.append([])
		
		# Create an HBox Container for the row
		var container := HBoxContainer.new()
		container.size_flags_vertical = HBoxContainer.SIZE_EXPAND_FILL
		rows_container.add_child(container)
		
		# Loop through the layout and create key buttons for each key
		for k in row.entries:
			var key := k as KeyboardKeyConfig
			if not key:
				continue

			# Create a button instance for this key
			var button := key_scene.instantiate()
			button.size_flags_stretch_ratio = key.stretch_ratio

			# Get the text to display for this key
			var display := key.get_text()
			button.text = display
			
			# Display the joypad icon if this key has controller shortcuts.
			if key.input:
				var is_shortcut_key := false
				if key.input.keycode == KEY_BACKSPACE:
					var textures := input_icons.parse_path("joypad/x", "", 1)
					if textures.size() > 0:
						button.icon = textures[0]
					is_shortcut_key = true
				if key.input.keycode == KEY_SHIFT:
					var textures := input_icons.parse_path("joypad/lt", "", 1)
					if textures.size() > 0:
						button.icon = textures[0]
					is_shortcut_key = true
				if key.input.keycode == KEY_ENTER:
					var textures := input_icons.parse_path("joypad/rt", "", 1)
					if textures.size() > 0:
						button.icon = textures[0]
					is_shortcut_key = true
				if is_shortcut_key:
					button.expand_icon = true
					button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			
			# Connect the keyboard key to a method to handle key presses
			button.button_up.connect(_on_key_pressed.bind(key))
			
			# Create a callback when the keyboard mode changes (i.e. shift is pressed)
			var on_mode_shift := func _on_mode_shift(mode: MODE_SHIFT) -> void:
				if mode > MODE_SHIFT.OFF:
					button.text = key.get_text(true)
					return
				button.text = key.get_text()
			mode_shifted.connect(on_mode_shift)
			
			container.add_child(button)
			button_rows[idx].append(button)
		idx += 1
		
	# Loop through all created buttons and setup focus
	for y in range(button_rows.size()):
		for x in range(button_rows[y].size()):
			var row := button_rows[y]
			var button := button_rows[y][x] as Button

			# LEFT
			button.focus_neighbor_left = row[x-1].get_path()

			# UP
			var row_above := button_rows[y-1]
			var top := _nearest_neighbor(x, row.size(), row_above.size())
			button.focus_neighbor_top = row_above[top].get_path()

			# RIGHT
			var right := x+1
			if right >= button_rows[y].size():
				right = 0
			button.focus_neighbor_right = row[right].get_path()

			# BOTTOM
			var bottom_y := y+1
			if bottom_y >= button_rows.size():
				bottom_y = 0
			var row_below := button_rows[bottom_y]
			var bottom := _nearest_neighbor(x, row.size(), row_below.size())
			button.focus_neighbor_bottom = row_below[bottom].get_path()

			button.focus_next = button.focus_neighbor_right
			button.focus_previous = button.focus_neighbor_left

	instance.keyboard_populated.emit()



# Returns the index that closest matches how far the given index is in an array 
# of the given size in comparision to the given 'to_size'. 
# E.g. 
#   var a := [1, 2, 3]
#   var b := [1, 2, 3, 4, 5, 6]
#   _nearest_neighbor(2, a.size(), b.size())
# Returns index in 'b' array: 4
func _nearest_neighbor(idx: int, from_size: int, to_size: int) -> int:
	var factor := float(to_size) / float(from_size)
	return int(round(idx * factor))


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

	# Try to scroll any scroll containers to the target node
	var target = instance.context.target
	if target:
		# TODO: Find a better way to scroll to the focused element after grow
		# effect finishes
		var timer := Timer.new()
		timer.wait_time = 0.2 # must be set to the grow time
		timer.one_shot = true
		timer.autostart = false
		add_child(timer)

		var scroll_containers := _find_scroll_containers(target)
		var on_timeout := func():
			for container in scroll_containers:
				container.ensure_control_visible(target)
			timer.queue_free()
		timer.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
		timer.start()

	opened.emit()


# Closes the OSK
func close() -> void:
	visible = false
	closed.emit()


# Sets the given keyboard layout and re-populates the keyboard
func set_layout(key_layout: KeyboardLayout) -> void:
	layout = key_layout
	populate_keyboard()
	layout_changed.emit()


# Sets the keyboard mode shift (i.e. pressing the "shift" key)
func set_mode_shift(mode: MODE_SHIFT) -> void:
	_mode_shift = mode
	mode_shifted.emit(mode)


# Handle gamepad keyboard shortcuts
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ogui_east"):
		instance.close()
		get_viewport().set_input_as_handled()
		return 
	if event.is_action_pressed("ogui_north"):
		var key := KeyboardKeyConfig.new()
		key.input = InputEventKey.new()
		key.input.keycode = KEY_BACKSPACE
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
		key.input = InputEventKey.new()
		key.input.keycode = KEY_ENTER
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
	if not instance.context:
		logger.warn("Keyboard context not set, nowhere to send key input.")
		return

	match instance.context.type:
		KeyboardContext.TYPE.GODOT:
			_handle_native(key)
			return
		KeyboardContext.TYPE.DBUS:
			_handle_input_map(key)
			return
		KeyboardContext.TYPE.X11:
			_handle_x11(key)
			return


# Handle sending key presses to an xwayland instance
func _handle_x11(key: KeyboardKeyConfig) -> void:
	var xwayland := Gamescope.get_xwayland(Gamescope.XWAYLAND.GAME)

	# Check for shift or capslock inputs 
	if key.input.keycode in [KEY_SHIFT, KEY_CAPSLOCK]:
		_handle_native_action(key)
		return

	# Get the input event based on mode shift
	var event := key.input
	if _mode_shift > MODE_SHIFT.OFF and key.mode_shift_input:
		event = key.mode_shift_input

	# Send a shift keypress if mode shifted
	if _mode_shift > MODE_SHIFT.OFF:
		xwayland.send_key(KEY_SHIFT, true)

	xwayland.send_key(event.keycode, true)
	xwayland.send_key(event.keycode, false)

	if _mode_shift > MODE_SHIFT.OFF:
		xwayland.send_key(KEY_SHIFT, false)

	# Reset the modeshift if this was a one shot
	if _mode_shift == MODE_SHIFT.ONE_SHOT:
		set_mode_shift(MODE_SHIFT.OFF)


func _find_scroll_containers(child: Node) -> Array[ScrollContainer]:
	var scroll_containers: Array[ScrollContainer]

	if child is ScrollContainer:
		scroll_containers.append(child)
	var parent := child.get_parent()

	# Break at the top-level node
	if parent == get_tree().root:
		return scroll_containers

	scroll_containers.append_array(_find_scroll_containers(parent))
	return scroll_containers


# Handles normal character inputs
func _handle_native(key: KeyboardKeyConfig) -> void:
	if instance.context.target == null:
		logger.warn("Keyboard target not set, nowhere to send key input.")
		return
	var target = instance.context.target

	# Get the input event based on mode shift
	var event := key.input
	if _mode_shift > MODE_SHIFT.OFF and key.mode_shift_input:
		event = key.mode_shift_input

	# Get the character to send to the target
	var character := String.chr(event.unicode)
	if _mode_shift == MODE_SHIFT.ONE_SHOT:
		set_mode_shift(MODE_SHIFT.OFF)
	
	# If no character was found for the key, then it is a special character
	# like shift, alt, etc.
	if character == "":
		_handle_native_action(key)
		return

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


# Handles action key inputs like shift, alt, ctrl, etc.
func _handle_native_action(key: KeyboardKeyConfig) -> void:
	if not instance.context:
		return
	var target = instance.context.target
	match key.input.keycode:
		KEY_SHIFT:
			if _mode_shift > MODE_SHIFT.OFF:
				set_mode_shift(MODE_SHIFT.OFF)
				return
			set_mode_shift(MODE_SHIFT.ONE_SHOT)
			return
		KEY_CAPSLOCK:
			if _mode_shift > MODE_SHIFT.OFF:
				set_mode_shift(MODE_SHIFT.OFF)
				return
			set_mode_shift(MODE_SHIFT.ON)
			return
		KEY_BACKSPACE:
			if target != null and target is TextEdit:
				var text_edit := target as TextEdit
				text_edit.backspace()
			if target != null and target is LineEdit:
				var line_edit := target as LineEdit
				line_edit.delete_char_at_caret()
			return
		KEY_ENTER:
			instance.context.submitted.emit()
			if instance.context.close_on_submit:
				instance.close()
			return


# Handle special keys that are not part of a real keyboard
func _handle_special(key: KeyboardKeyConfig) -> void:
	if key.action == key.ACTION.CLOSE_KEYBOARD:
		instance.close()
		return


# Handle cases where the KeyboardContext is set to INPUT_MAPPING
func _handle_input_map(key: KeyboardKeyConfig) -> void:
	# Get the input event based on mode shift
	var event := key.input
	if _mode_shift > MODE_SHIFT.OFF and key.mode_shift_input:
		event = key.mode_shift_input

	# Handle cases where the user wants to select a mode-shifted key. 
	# If the user selects SHIFT twice, select shift as the input
	if event.keycode == KEY_SHIFT and _mode_shift == MODE_SHIFT.OFF:
		set_mode_shift(MODE_SHIFT.ONE_SHOT)
		return

	# Create an InputPlumber event for the selected key
	var input_plumber_event := InputPlumberEvent.from_event(event)
	set_mode_shift(MODE_SHIFT.OFF)
	instance.context.keymap_input_selected.emit(input_plumber_event)
	instance.close()
