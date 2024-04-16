extends ScrollContainer

# Ways we can save launch settings to the config file
enum UPDATE {
	STRING,
	ARRAY,
	DICT,
	BOOL,
}

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var library_item: LibraryItem
var settings_section: String
var provider_id: String

@onready var provider_dropdown := $%LaunchProviderDropdown
@onready var cmd_input := $%CommandTextInput
@onready var args_input := $%ArgsTextInput
@onready var cwd_input := $%CWDTextInput
@onready var env_input := $%EnvTextInput
@onready var sandbox_toggle := $%UseSandboxToggle as Toggle


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_settings_state.state_entered.connect(_on_game_settings_entered)
	provider_dropdown.item_selected.connect(_on_provider_selected)
	cmd_input.focus_exited.connect(_on_input_update.bind(cmd_input, "command"))
	args_input.focus_exited.connect(_on_input_update.bind(args_input, "args", UPDATE.ARRAY))
	cwd_input.focus_exited.connect(_on_input_update.bind(cwd_input, "cwd"))
	env_input.focus_exited.connect(_on_input_update.bind(env_input, "env", UPDATE.DICT))
	sandbox_toggle.toggled.connect(_on_toggle_update.bind(sandbox_toggle, "use_sandboxing"))


func _on_game_settings_entered(_from: State) -> void:
	if not "item" in game_settings_state.data:
		return
	library_item = game_settings_state.data["item"] as LibraryItem
	settings_section = "game.%s" % library_item.name.to_lower()

	# Get the provider used for this game
	var selected_provider = settings_manager.get_value(settings_section, "provider")

	# Populate the launch providers this game can use
	provider_dropdown.clear()
	var provider_idx := 0
	var i := 0
	for item in library_item.launch_items:
		var launch_item := item as LibraryLaunchItem
		if launch_item._provider_id == selected_provider:
			provider_idx = i
		var provider_name := launch_item._provider_id
		provider_dropdown.add_item(provider_name)
		i += 1

	# Select the provider from the user's settings
	provider_dropdown.select(provider_idx)
	_on_provider_selected(provider_idx)


# Update the menu whenever a library provider changes.
func _on_provider_selected(idx: int) -> void:
	if not library_item:
		return
	if library_item.launch_items.size() < idx:
		return

	# Get the library launch item for the selected provider
	var launch_item := library_item.launch_items[idx] as LibraryLaunchItem

	# Write the provider used to the user's settings for this game
	provider_id = launch_item._provider_id
	if settings_section != "" or settings_section != "game.":
		settings_manager.set_value(settings_section, "provider", provider_id)

	# Populate the fields of the menu
	cmd_input.placeholder_text = launch_item.command
	args_input.placeholder_text = " ".join(launch_item.args)
	cwd_input.placeholder_text = launch_item.cwd
	env_input.placeholder_text = _dict_to_string(launch_item.env)

	# Load any overridden properties
	var cmd = settings_manager.get_value(settings_section, ".".join(["command", provider_id]))
	if cmd and cmd is String:
		cmd_input.text = cmd
	var args = settings_manager.get_value(settings_section, ".".join(["args", provider_id]))
	if args and args is PackedStringArray:
		args_input.text = " ".join(args)
	var cwd = settings_manager.get_value(settings_section, ".".join(["cwd", provider_id]))
	if cwd and cwd is String:
		cwd_input.text = cwd
	var env_vars = settings_manager.get_value(settings_section, ".".join(["env", provider_id]))
	if env_vars and env_vars is Dictionary:
		env_input.text = _dict_to_string(env_vars)
	var use_sandboxing = settings_manager.get_value(settings_section, ".".join(["use_sandboxing", provider_id]))
	if use_sandboxing is bool:
		sandbox_toggle.button_pressed = use_sandboxing
	else:
		sandbox_toggle.button_pressed = true


# Converts the given dictionary into a string representation. E.g. foo=bar
func _dict_to_string(d: Dictionary, key_delim: String = "=", delim: String = " ") -> String:
	var values := []
	for key in d.keys():
		var value := "{0}{1}{2}".format([key, key_delim, d[key]])
		values.push_back(value)
	return delim.join(values)


# Update settings when a user has changed a toggle setting
func _on_toggle_update(value: bool, node: Toggle, subsection: String) -> void:
	var key := ".".join([subsection, provider_id])
	var setting = settings_manager.get_value(settings_section, key)
	settings_manager.set_value(settings_section, key, value)


# Updates our settings when a user has possibly changed launch settings
func _on_input_update(node: Control, subsection: String, update: UPDATE = UPDATE.STRING) -> void:
	var key := ".".join([subsection, provider_id])
	var setting = settings_manager.get_value(settings_section, key)

	# Delete the setting from the config if one is set and the user set
	# the text to empty
	if node.text == "":
		if setting != null:
			settings_manager.erase_section_key(settings_section, key)
		return

	# If the text input should be an array, convert it and save it
	if update == UPDATE.ARRAY:
		var arr := PackedStringArray(node.text.split(" ", false) as Array)
		settings_manager.set_value(settings_section, key, arr)
		return

	# TODO: Handle env vars with spaces. E.g. MY_VAR="foo bar"
	if update == UPDATE.DICT:
		var dict := {}
		var by_item := node.text.split(" ", false) as Array
		# Only save if we have valid env vars
		if by_item.size() == 0:
			return
		for item in by_item:
			var key_value := item.split("=") as Array
			if key_value.size() != 2:
				continue
			dict[key_value[0]] = key_value[1]
		if dict.size() > 0:
			settings_manager.set_value(settings_section, key, dict)
		return

	# Update our settings for text values
	settings_manager.set_value(settings_section, key, node.text)
