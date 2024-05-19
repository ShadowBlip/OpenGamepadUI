extends Control
class_name GamepadMapper

const state_machine := preload(
	"res://assets/state/state_machines/gamepad_settings_state_machine.tres"
)
var change_input_state := load("res://assets/state/states/gamepad_change_input.tres") as State
var tabs_state := load("res://core/ui/card_ui/gamepad/gamepad_mapper_tabs_state.tres") as TabContainerState
var card_button_scene := load("res://core/ui/components/card_input_icon_button.tscn") as PackedScene

signal mapping_selected(mapping: InputPlumberMapping)

var input_icons := load("res://core/systems/input/input_icon_manager.tres") as InputIconManager
var keyboard_context := KeyboardContext.new(KeyboardContext.TYPE.DBUS)
var current_mapping: InputPlumberMapping
var logger := Log.get_logger("GamepadMapper", Log.LEVEL.DEBUG)

@onready var tab_container := $%TabContainer as TabContainer
@onready var osk := $%OnScreenKeyboard as OnScreenKeyboard
@onready var modifying_input_texture := $%ModifyingInputTexture as TextureRect
@onready var clear_button := $%ClearButton as CardIconButton
@onready var gamepad_diagram := $%GamepadDiagram as TextureRect
@onready var gamepad_input_container := $%GamepadInputContainer as Container
@onready var gamepad_focus_group := $%GamepadFocusGroup as FocusGroup
@onready var mouse_input_container := $%MouseInputContainer as Container
@onready var mouse_focus_group := $%MouseFocusGroup as FocusGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_input_state.state_entered.connect(_on_state_entered)
	change_input_state.state_exited.connect(_on_state_exited)
	
	# Listen for tab container changes
	var on_tab_container_tab_changed := func(tab: int):
		tab_container.current_tab = tab
		osk.instance.close()
		if tab == 0:
			gamepad_focus_group.grab_focus.call_deferred()
		elif tab == 1:
			osk.instance.open(keyboard_context)
		elif tab == 2:
			mouse_focus_group.grab_focus.call_deferred()
		elif tab == 3:
			pass #system
	tabs_state.tab_changed.connect(on_tab_container_tab_changed)

	# Setup the clear button
	var on_clear_button := func():
		mapping_selected.emit(null)
		state_machine.pop_state()
	clear_button.button_up.connect(on_clear_button)

	## Setup the mouse input select
	##var on_mouse_button := func():
		##mouse_container.visible = true
		##mouse_focus_group.grab_focus()
	##mouse_button.button_up.connect(on_mouse_button)

	# Handle selecting a key input
	var on_key_selected := func(event: InputPlumberEvent) -> void:
		# Update the mapping with the selected capability
		if not self.current_mapping:
			logger.error("No current mapping is set to update!")
			return

		# Set the target capability for the input mapping
		self.current_mapping.target_events.append(event)

		# Exit the menu
		state_machine.pop_state()
		
		# Emit the updated mapping
		self.mapping_selected.emit(self.current_mapping)
	keyboard_context.keymap_input_selected.connect(on_key_selected)


func _on_state_entered(_from: State) -> void:
	var texture := change_input_state.get_meta("texture") as Texture2D
	var mapping := change_input_state.get_meta("mappings") as InputPlumberMapping
	var gamepad := change_input_state.get_meta("gamepad") as InputPlumber.CompositeDevice
	var gamepad_type := change_input_state.get_meta("gamepad_type") as String
	var gamepad_icons_type := change_input_state.get_meta("gamepad_type_icon_map") as String
	
	# Set the currently modifying mapping
	self.current_mapping = mapping

	# Set the input we're mapping
	modifying_input_texture.texture = texture

	# Get the available capabilities of all target devices
	var target_capabilities := gamepad.target_capabilities
	
	# Set the gamepad diagram
	var diagrams := input_icons.parse_path("joypad/diagram", gamepad_icons_type, InputIconManager.InputType.GAMEPAD)
	if diagrams.is_empty():
		gamepad_diagram.texture = load("res://assets/images/gamepad/xbox/XboxOne_Diagram_Simple.png")
	else:
		gamepad_diagram.texture = diagrams[0]
	
	# Populate the gamepad menu based on the target gamepad capabilities
	self.populate_gamepad_mappings_for(target_capabilities.duplicate(), gamepad_icons_type)

	# Populate the mouse menu based on target gamepad capabilities
	self.populate_mouse_mappings_for(target_capabilities.duplicate())

	# Switch to the "gamepad" tab
	tabs_state.current_tab = 0
	
	# Grab focus
	mouse_focus_group.current_focus = null
	gamepad_focus_group.current_focus = null
	gamepad_focus_group.grab_focus.call_deferred()


func _on_state_exited(_to: State) -> void:
	pass


## Populates the mappings for the given capabilities
func populate_gamepad_mappings_for(capabilities: PackedStringArray, gamepad_icons_type: String) -> void:
	logger.debug("Found target capabilities for gamepad: " + str(capabilities))

	# Sort the capabilities
	capabilities = InputPlumberEvent.sort_capabilities(capabilities)
	capabilities.reverse()

	# Delete any old buttons
	for child in gamepad_input_container.get_children():
		if child is CardInputIconButton or child is CardButton:
			gamepad_input_container.remove_child(child)
			child.queue_free()

	# Organize all the capabilities
	var button_events := PackedStringArray()
	var axes_events := PackedStringArray()
	var trigger_events := PackedStringArray()
	var accel_events := PackedStringArray()
	var gyro_events := PackedStringArray()
	var touchpad_events := PackedStringArray()
	for capability: String in capabilities:
		logger.debug("Capability: " + capability)
		if capability.begins_with("Gamepad:Button"):
			button_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Axis"):
			axes_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Trigger"):
			trigger_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Accelerometer"):
			accel_events.append(capability)
			continue
		if capability.begins_with("Gamepad:Gyro"):
			gyro_events.append(capability)
			continue
		if capability.begins_with("TouchPad:"):
			touchpad_events.append(capability)
			continue
		logger.warn("Unhandled capability: " + capability)
	
	# Create all the button mappings
	var label := $%ButtonsLabel
	label.visible = button_events.size() > 0
	for capability in button_events:
		_add_button_for_capability(capability, gamepad_input_container, label, gamepad_icons_type)

	label = $%AxesLabel
	label.visible = axes_events.size() > 0
	for capability in axes_events:
		_add_button_for_capability(capability, gamepad_input_container, label, gamepad_icons_type)

	label = $%TriggersLabel
	label.visible = trigger_events.size() > 0
	for capability in trigger_events:
		_add_button_for_capability(capability, gamepad_input_container, label, gamepad_icons_type)

	label = $%AccelerometerLabel
	label.visible = accel_events.size() > 0
	for capability in accel_events:
		_add_button_for_capability(capability, gamepad_input_container, label, gamepad_icons_type)

	label = $%GyroLabel
	label.visible = gyro_events.size() > 0
	for capability in gyro_events:
		_add_button_for_capability(capability, gamepad_input_container, label, gamepad_icons_type)

	label = $%TouchpadsLabel
	label.visible = touchpad_events.size() > 0
	for capability in touchpad_events:
		_add_button_for_capability(capability, gamepad_input_container, label, gamepad_icons_type)


## Populates the mouse mappings for the given capabilities
func populate_mouse_mappings_for(caps: PackedStringArray) -> void:
	# Filter only mouse capabilities
	var mouse_capabilities := PackedStringArray()
	for capability in caps:
		if capability.begins_with("Mouse:"):
			mouse_capabilities.append(capability)

	logger.debug("Found target capabilities for mouse: " + str(mouse_capabilities))

	# Sort the capabilities
	mouse_capabilities = InputPlumberEvent.sort_capabilities(mouse_capabilities)
	mouse_capabilities.reverse()

	# Organize all the capabilities
	var button_events := PackedStringArray()
	var motion_events := PackedStringArray()
	for capability: String in mouse_capabilities:
		logger.debug("Capability: " + capability)
		if capability.begins_with("Mouse:Button"):
			button_events.append(capability)
			continue
		if capability.begins_with("Mouse:Motion"):
			motion_events.append(capability)
			continue

	# Delete any old buttons
	for child in mouse_input_container.get_children():
		if child is CardInputIconButton or child is CardButton:
			mouse_input_container.remove_child(child)
			child.queue_free()

	# Create all the button mappings
	var label := $%MouseButtonsLabel as Label
	label.visible = button_events.size() > 0
	for capability in button_events:
		_add_button_for_capability(capability, mouse_input_container, label, "")

	# Create the motion mappings
	label = $%MouseMotionLabel as Label
	label.visible = motion_events.size() > 0
	for capability in motion_events:
		_add_button_for_capability(capability, mouse_input_container, label, "")


## Create a button for the given event under the given parent
func _add_button_for_capability(capability: String, parent: Node, neighbor: Node, gamepad_icons_type: String) -> CardInputIconButton:
	var idx := neighbor.get_index() + 1

	var button := card_button_scene.instantiate() as CardInputIconButton
	button.name = capability
	var on_button_ready := func():
		button.set_target_device_icon_mapping(gamepad_icons_type)
		button.input_icon.force_type = 1 # Force type to keyboard/mouse
		var button_parent := button.get_parent()
		if button.set_target_icon(capability) != OK:
			logger.debug("Failed to set icon for capability: " + capability)
			button_parent.remove_child(button)
			button.queue_free()
		if button.input_icon.textures.is_empty():
			button_parent.remove_child(button)
			button.queue_free()
	button.ready.connect(on_button_ready)

	# Update the mapping with the selected capability
	var on_pressed := func():
		if not self.current_mapping:
			logger.error("No current mapping is set to update!")
			return
		
		# Set the target capability for the input mapping
		var target_event := InputPlumberEvent.from_capability(capability)
		if not target_event:
			logger.error("Unsupported capability: " + str(capability))
			return
		self.current_mapping.target_events.append(target_event)

		# Exit the menu
		state_machine.pop_state()
		
		# Emit the updated mapping
		self.mapping_selected.emit(self.current_mapping)

	button.button_up.connect(on_pressed)

	# Add the button to the container and move it just under the given neighbor
	parent.add_child(button)
	parent.move_child(button, idx)

	return button


#
#func _on_mouse_button(button: MouseButton) -> void:
	#var input_event := InputEventMouseButton.new()
	#input_event.button_index = button
	##var mappable_event := NativeEvent.new()
	##mappable_event.event = input_event
	##for mapping in mappings:
		##if mapping.output_events.size() - 1 < output_index:
			##mapping.output_events.resize(output_index+1)
		##mapping.output_events[output_index] = mappable_event
	##mappings_selected.emit(mappings)
	#state_machine.pop_state()
#
#
#func _on_mouse_motion() -> void:
	##for mapping in mappings:
		##var input_event := InputEventMouseMotion.new()
		##var mappable_event := NativeEvent.new()
		##mappable_event.event = input_event
		##print("Mapping: " + str(mapping))
		##if mapping.output_events.size() - 1 < output_index:
			##mapping.output_events.resize(output_index+1)
		##mapping.output_events[output_index] = mappable_event
		##
		### Set the relative x/y. This is used in ManagedGamepad to determine which axis should be moved.
		##var source_event := mapping.source_event as EvdevEvent
		##var event := mapping.output_events[output_index].event as InputEventMouseMotion
		##if source_event.input_device_event.get_code_name().contains("X"):
			##event.relative.x = 1
			##event.relative.y = 0
		##elif source_event.input_device_event.get_code_name().contains("Y"):
			##event.relative.x = 0
			##event.relative.y = 1
##
	##mappings_selected.emit(mappings)
	#state_machine.pop_state()

