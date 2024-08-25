extends MarginContainer

var state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var next_state := load("res://assets/state/states/first_boot_finished.tres") as State
var plugin_setup_state := load("res://assets/state/states/first_boot_plugin_setup.tres") as State
var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
var visibility_manager_scene := load("res://core/systems/state/visibility_manager.tscn") as PackedScene

var plugin_state_machine := StateMachine.new()
var logger := Log.get_logger("PluginSetup")

@onready var content := $%PluginContent
@onready var name_label := $%PluginNameLabel
@onready var next_button := $%NextButton as CardButton
@onready var focus_group := $%FocusGroup as FocusGroup


# Called when the node enters the scene tree for the first time.`
func _ready() -> void:
	plugin_state_machine.minimum_states = 0
	plugin_setup_state.state_entered.connect(_on_state_entered)
	next_button.button_up.connect(_on_next_pressed)


func _on_state_entered(_from: State) -> void:
	# Get all plugin setup menus
	var menus := get_plugin_setup_menus()
	
	# If no plugin settings are available, skip to the next state
	if menus.size() == 0:
		logger.info("No plugin settings, skipping.")
		state_machine.replace_state.call_deferred(next_state)
		return
	
	# Add the plugin settings menus
	var states: Array[State] = []
	for plugin_id in menus.keys():
		logger.debug("Adding menu for plugin: " + plugin_id)
		var menu := menus[plugin_id] as Control
		var state := _add_plugin_menu(plugin_id, menu)
		states.append(state)
	
	# Set the plugin state. As the user hits next, we'll pop each state off
	# the stack until none remain.
	states.reverse()
	plugin_state_machine.set_state(states)


# When the next button is pressed, pop the plugin state machine stack to configure
# the next plugin. When none are left, leave the plugin setup menu state.
func _on_next_pressed() -> void:
	# Popping the plugin state machine will proceed to the next plugin setup
	plugin_state_machine.pop_state()
	if plugin_state_machine.stack_length() > 0:
		return
	
	# If no more plugin states remain, proceed to the next menu.
	state_machine.replace_state(next_state)


## Configures and adds the given plugin settings menu to the scene.
func _add_plugin_menu(plugin_id: String, menu: Control) -> State:
	# Create a new state for entering the menu
	var state := State.new()
	state.name = plugin_id
	
	# Get the plugin metadata
	var meta := plugin_loader.get_plugin_meta(plugin_id)
	var plugin_name := meta["plugin.name"] as String
	
	# Add a visibility manager to the menu using the new state
	var visibility_manager := visibility_manager_scene.instantiate() as VisibilityManager
	visibility_manager.state_machine = plugin_state_machine
	visibility_manager.state = state
	menu.add_child(visibility_manager)
	
	# Ensure the menu is set to fill/expand
	menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create a focus group for the plugin settings
	var plugin_focus_group := FocusGroup.new()
	plugin_focus_group.name = "FocusGroup"
	menu.add_child(plugin_focus_group)

	# Update the section label when the plugin state is entered and update the
	# focus groups.
	var on_state_entered := func(_from: State):
		name_label.text = plugin_name + " Setup"
		focus_group.focus_neighbor_top = plugin_focus_group
		focus_group.focus_neighbor_bottom = plugin_focus_group
		plugin_focus_group.focus_neighbor_bottom = focus_group
		plugin_focus_group.focus_neighbor_top = focus_group
		plugin_focus_group.recalculate_focus()
		focus_group.recalculate_focus()
	state.state_entered.connect(on_state_entered)

	# Add the menu to the scene
	content.add_child(menu)
	
	return state


## Returns all plugin settings menus. This is returned as a Dictionary that maps
## the plugin ID to the settings menu. E.g. {"steam": <Control>}
func get_plugin_setup_menus() -> Dictionary:
	var menus := {}
	for plugin_id in plugin_loader.get_loaded_plugins():
		# Get the settings menu from the plugin if it exists
		var plugin := plugin_loader.get_plugin(plugin_id)
		if not plugin:
			continue
		var plugin_settings := plugin.get_settings_menu()
		if not plugin_settings:
			continue

		menus[plugin_id] = plugin_settings
	
	return menus
