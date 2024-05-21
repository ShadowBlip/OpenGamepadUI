@tool
extends VBoxContainer
class_name CardMappingButtonGroup

## The type of mapping this container is configured for.
enum MappingType {
	Joystick = 0,
	Button = 1,
}

var change_input_state := load("res://assets/state/states/gamepad_change_input.tres") as State
var button_scene := load("res://core/ui/components/card_mapping_button.tscn") as PackedScene
var logger := Log.get_logger("CardMappingContainer")

var _capability: String = ""
var _mappings: Array[InputPlumberMapping] = []
var _mapping_type: MappingType = MappingType.Joystick
var _on_press: Callable
var _source_icon_mapping := ""
var _target_icon_mapping := ""

@onready var container := self as VBoxContainer
@onready var focus_group := %FocusGroup as FocusGroup
@onready var dropdown := $%Dropdown as Dropdown
@onready var deadzone := $%DeadzoneSlider as ValueSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Populate the dropdown
	dropdown.clear()
	dropdown.add_item("Joystick", MappingType.Joystick)
	dropdown.add_item("Button", MappingType.Button)
	
	# Handle focus
	var on_focus := func():
		focus_group.grab_focus()
	focus_entered.connect(on_focus)
	
	# Update the mapping type when a dropdown selection is made
	var on_dropdown_select := func(idx: int):
		_mapping_type = idx as MappingType
		self.update()
	dropdown.item_selected.connect(on_dropdown_select)

	# Create a default mapping if a capability is set
	if _capability.is_empty():
		return
	var mapping := InputPlumberMapping.from_source_capability(_capability)
	if not mapping:
		logger.error("Failed to set source event with capability: " + _capability)
		return
	_mappings.append(mapping)

	# Ensure icons are up-to-date
	set_source_capability(_capability)
	set_source_device_icon_mapping(_source_icon_mapping)
	update()


## Set the source input icon's icon mapping
func set_source_device_icon_mapping(mapping_name: String) -> void:
	_source_icon_mapping = mapping_name


## Set the target input icon's icon mapping
func set_target_device_icon_mapping(mapping_name: String) -> void:
	_target_icon_mapping = mapping_name


## Set the source capability for this container
func set_source_capability(capability: String) -> void:
	_capability = capability


func set_callback(callback: Callable) -> void:
	_on_press = callback


## Returns true if the group has any mappings configured.
func has_mappings() -> bool:
	return self._mappings.size() > 0


## Update the group based on the mapping type.
func set_mapping_type(mapping_type: MappingType) -> void:
	_mapping_type = mapping_type
	dropdown.select(mapping_type)
	update()


## Configures the container for the given input mappings. This method assumes
## that the given mappings are all for the same source event.
func set_mappings(mappings: Array[InputPlumberMapping]) -> void:
	if not is_inside_tree():
		return
	logger.debug("Setting mappings: " + str(mappings))
	_mappings = mappings

	# Sort the mappings by their direction
	var mappings_by_direction := {}
	for mapping in mappings:
		var direction := mapping.source_event.get_direction()
		mappings_by_direction[direction] = mapping

	# Update the appropriate card mapping buttons
	for child: Node in container.get_children():
		if not child is CardMappingButton:
			continue
		var button := child as CardMappingButton
		var direction := button.get_meta("direction", "") as String
		
		# If the direction doesn't exist, skip updating
		if not direction in mappings_by_direction:
			continue
		
		var mapping := mappings_by_direction[direction] as InputPlumberMapping
		_update_button(button, mapping)



## Clear all mapping buttons from the container
func clear_mapping_buttons() -> void:
	for child in container.get_children():
		if not child is CardMappingButton:
			continue
		container.remove_child(child)
		child.queue_free()
	focus_group.current_focus = null


## Update the group based on the type
func update() -> void:
	# Clear the old buttons
	clear_mapping_buttons()
	
	# Create buttons based on the configuration
	match _mapping_type:
		MappingType.Joystick:
			deadzone.visible = false
			_add_button_for_capability(_capability)
		MappingType.Button:
			deadzone.visible = true
			_add_button_for_capability(_capability, "left")
			_add_button_for_capability(_capability, "right")
			_add_button_for_capability(_capability, "up")
			_add_button_for_capability(_capability, "down")


## Create a card mapping button for the given event under the given parent
func _add_button_for_capability(capability: String, direction: String = "") -> CardMappingButton:
	# Add the button after the dropdown
	var idx := dropdown.get_index() + 1

	# Create a new mapping button
	var button := button_scene.instantiate() as CardMappingButton
	button.set_meta("direction", direction)
	button.text = "-"
	var on_button_ready := func():
		button.set_target_device_icon_mapping(_target_icon_mapping)
		button.set_source_device_icon_mapping(_source_icon_mapping)
		button.set_source_capability(capability, direction)
	button.ready.connect(on_button_ready, CONNECT_ONE_SHOT)

	# Create a gamepad profile mapping when pressed
	var on_pressed := func():
		# Create a new mapping for this button
		var mapping := InputPlumberMapping.from_source_capability(capability)
		if not mapping:
			logger.error("Failed to set source event with capability: " + capability)
			return
		
		# If a direction was defined, configure the mapping with that direction
		if direction:
			if capability.begins_with("Gamepad:Axis"):
				mapping.source_event.gamepad.axis.direction = direction
				mapping.set_meta("group", capability)
				mapping.set_meta("direction", direction)
			# TODO: The rest
		
		# Switch to change_input_state with the selected mapping to be updated
		var texture: Texture
		if button.source_icon.textures.size() > 0:
			texture = button.source_icon.textures[0]
		change_input_state.set_meta("texture", texture)
		change_input_state.set_meta("mappings", mapping)
		
		# Call the provided callback to further configure the state and switch
		# to it.
		self._on_press.call()
	button.button_up.connect(on_pressed)

	# Add the button to the container and move it just under the dropdown
	container.add_child(button)
	container.move_child(button, idx)

	return button


## Update the button's target icon using the given mapping. This will only be
## called if a mapping already exists in a profile.
func _update_button(button: CardMappingButton, mapping: InputPlumberMapping) -> void:
	button.text = ""

	# Configure no target icon if there is no target events
	if not mapping or mapping.target_events.is_empty():
		logger.warn("Mapping '" + mapping.name + "' has no target events")
		return
	
	# Get the target capability to determine if this is a gamepad icon or keyboard/mouse
	# TODO: Figure out what to do if this maps to multiple types of input (e.g. Keyboard + Gamepad)
	var target_capability := mapping.target_events[0].to_capability()
	var target_input_type := 2 # gamepad
	if target_capability.begins_with("Mouse") or target_capability.begins_with("Keyboard"):
		target_input_type = 1 # kb/mouse
	button.target_icon.force_type = target_input_type

	# Set the icon mapping to use
	if target_input_type == 1:
		logger.debug("Using keyboard/mouse icon mapping")
		button.set_target_device_icon_mapping("")
	else:
		var icon_mapping := _target_icon_mapping
		logger.debug("Using target icon mapping: " + icon_mapping)
		button.set_target_device_icon_mapping(icon_mapping)

	# Set the target capability
	for event in mapping.target_events:
		button.set_target_capability(event.to_capability())
		# TODO: Figure out what to display if this maps to multiple inputs
		break
