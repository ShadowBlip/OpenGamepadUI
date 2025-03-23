extends OSPlatform
class_name PlatformNixOS

const UPDATER_CMD: String = "os-updater"

var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager
var sections_label_scene := load("res://core/ui/components/section_label.tscn") as PackedScene
var button_scene := load("res://core/ui/components/card_button_setting.tscn") as PackedScene
var toggle_scene := load("res://core/ui/components/toggle.tscn") as PackedScene

var update_available := false
var update_installed := false


func _init() -> void:
	logger.set_name("PlatformNixOS")
	logger.set_level(Log.LEVEL.INFO)
	logger.info("Detected NixOS platform")


## Ready will be called after the scene tree has initialized.
func ready(root: Window) -> void:
	logger.info("READY")

	# Wait for the scene tree to be ready
	await root.get_tree().process_frame

	var main := root.get_tree().get_first_node_in_group("main") as Node
	if not main:
		logger.warn("Unable to find main scene")
		return

	# Remove the existing updater
	_remove_updater(main)

	# Add the update interface if the os update script exists
	if _has_updater():
		_add_updater(main)



## NixOS typically cannot execute regular binaries, so downloaded binaries will
## be run with 'steam-run'. 
func get_binary_compatibility_cmd(cmd: String, args: PackedStringArray) -> Array[String]:
	# Hack for steam plugin running steamcmd on NixOS
	var command: Array[String] = []
	if not cmd.ends_with("steamcmd.sh"):
		return command

	command.push_back("steam-run")
	command.push_back(cmd)
	command.append_array(args)

	return command


# Returns true if the OS updater script is installed on the system
func _has_updater() -> bool:
	return OS.execute("which", [UPDATER_CMD]) == OK


# Removes the update buttons/toggles in the general settings menu
func _remove_updater(root: Node) -> void:
	# Find the general settings menu in the scene tree
	var general_settings_menu := root.get_tree().get_first_node_in_group("settings_general_menu")
	if not general_settings_menu:
		logger.warn("Unable to find general settings menu")
		return

	var updates_label := general_settings_menu.auto_update_toggle.get_parent().get_node("UpdatesLabel") as Node
	if updates_label:
		_remove_node(updates_label)

	# Remove UI elements that we will replace
	var nodes_to_remove: Array[Node] = [
		general_settings_menu.updater,
		general_settings_menu.update_timer,
		general_settings_menu.auto_update_toggle,
		general_settings_menu.check_update_button,
		general_settings_menu.update_button,
	]
	for node in nodes_to_remove:
		_remove_node(node)
	general_settings_menu.updater = null
	general_settings_menu.update_timer = null
	general_settings_menu.auto_update_toggle = null
	general_settings_menu.check_update_button = null
	general_settings_menu.update_button = null


# Adds the NixOS-specific update buttons/toggles to the general settings menu
func _add_updater(root: Node) -> void:
	# Find the general settings menu in the scene tree
	var general_settings_menu := root.get_tree().get_first_node_in_group("settings_general_menu")
	if not general_settings_menu:
		logger.warn("Unable to find general settings menu")
		return

	# Get the container that will have the updater elements
	var container := general_settings_menu.lang_dropdown.get_parent() as Container

	# Create the updates label
	var updates_label := sections_label_scene.instantiate() as Label
	updates_label.text = "Updates"
	container.add_child(updates_label)
	container.move_child(updates_label, 0)

	# Create a timer for auto-updates
	var update_timer := Timer.new()
	update_timer.wait_time = 120
	general_settings_menu.add_child(update_timer)

	# Add the auto-updates toggle
	var auto_update_toggle := toggle_scene.instantiate() as Toggle
	auto_update_toggle.text = "Automatic Updates"
	auto_update_toggle.separator_visible = false
	auto_update_toggle.description = "Automatically download and apply updates in the background when they are available"
	container.add_child(auto_update_toggle)
	container.move_child(auto_update_toggle, 1)

	# Add the check for updates button
	var check_update_button := button_scene.instantiate() as CardButtonSetting
	check_update_button.text = "Check for updates"
	check_update_button.button_text = "Check for updates"
	check_update_button.disabled = false
	container.add_child(check_update_button)
	container.move_child(check_update_button, 2)

	# Add the check for updates button
	var update_button := button_scene.instantiate() as CardButtonSetting
	update_button.text = "Install Updates"
	update_button.button_text = "Update"
	update_button.disabled = true
	container.add_child(update_button)
	container.move_child(update_button, 3)

	# Reset the focus group's initial focus
	var focus_group := container.get_node("FocusGroup") as FocusGroup
	focus_group.current_focus = auto_update_toggle

	# Configure auto updates toggle
	var auto_update := settings_manager.get_value("general.updates", "auto_update", false) as bool
	auto_update_toggle.button_pressed = auto_update
	var on_auto_update_toggled := func(toggled: bool):
		settings_manager.set_value("general.updates", "auto_update", toggled)
		if toggled:
			update_timer.start()
			_on_autoupdate(update_button, check_update_button)
		else:
			update_timer.stop()
	auto_update_toggle.toggled.connect(on_auto_update_toggled)
	update_timer.timeout.connect(_on_autoupdate.bind(update_button, check_update_button))
	if auto_update:
		update_timer.start()

	# Configure check for updates button
	check_update_button.button_up.connect(_on_check_for_updates.bind(update_button, check_update_button))

	# Configure update button
	update_button.button_up.connect(_on_update.bind(update_button, check_update_button))

	# TODO: Add branch selector


# Invoked whenever the updater timer times out
func _on_autoupdate(update_button: CardButtonSetting, check_update_button: CardButtonSetting) -> void:
	logger.info("Automatically checking for updates...")
	update_button.disabled = true
	check_update_button.disabled = true
	check_update_button.button_text = "Checking..."

	var cmd := Command.create(UPDATER_CMD, ["has-update"])
	if cmd.execute() != OK:
		logger.warn("Failed to check for updates")
		update_available = false
		_reset_update_buttons(update_button, check_update_button)
		return
	if await cmd.finished != OK:
		logger.warn("Failed to check for updates:", cmd.stdout, cmd.stderr)
		update_available = false
		_reset_update_buttons(update_button, check_update_button)
		return

	update_available = cmd.stdout.contains("1")
	_reset_update_buttons(update_button, check_update_button)
	if not update_available:
		logger.info("No new updates available")
		return

	logger.info("New update was found. Trying to install it.")
	update_button.disabled = true
	update_button.button_text = "Updating..."
	check_update_button.disabled = true

	# Update the flake.lock file
	cmd = Command.create(UPDATER_CMD, ["update"])
	if cmd.execute() != OK:
		logger.warn("Failed to update flake.lock")
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button)
		return
	if await cmd.finished != OK:
		logger.warn("Failed to update flake.lock:", cmd.stdout, cmd.stderr)
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button)
		return

	# Download and apply the upgrade
	cmd = Command.create(UPDATER_CMD, ["upgrade"])
	if cmd.execute() != OK:
		logger.warn("Failed to download and apply upgrade")
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button)
		return
	if await cmd.finished != OK:
		logger.warn("Failed to download and apply upgrade:", cmd.stdout, cmd.stderr)
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button)
		return

	update_button.button_text = "Update"
	_reset_update_buttons(update_button, check_update_button)


# Invoked whenever the "Check for updates" button is pressed
func _on_check_for_updates(update_button: CardButtonSetting, check_update_button: CardButtonSetting) -> void:
	update_button.disabled = true
	check_update_button.disabled = true
	check_update_button.button_text = "Checking..."

	var cmd := Command.create(UPDATER_CMD, ["has-update"])
	if cmd.execute() != OK:
		logger.warn("Failed to check for updates")
		update_available = false
		_reset_update_buttons(update_button, check_update_button, "Unable to check for updates")
		return
	if await cmd.finished != OK:
		logger.warn("Failed to check for updates:", cmd.stdout, cmd.stderr)
		update_available = false
		_reset_update_buttons(update_button, check_update_button, "Unable to check for updates")
		return

	update_available = cmd.stdout.contains("1")
	var msg := "Already up to date"
	if update_available:
		msg = "New update is available"
	_reset_update_buttons(update_button, check_update_button, msg)


# Reset the update buttons state and optionally show the given message
func _reset_update_buttons(update_button: CardButtonSetting, check_update_button: CardButtonSetting, msg: String = "") -> void:
	update_button.disabled = !update_available
	check_update_button.disabled = false
	check_update_button.button_text = "Check for updates"
	if msg.is_empty():
		return
	var notify := Notification.new(msg)
	notification_manager.show(notify)


# Invoked when the update button is pressed
func _on_update(update_button: CardButtonSetting, check_update_button: CardButtonSetting) -> void:
	if not update_available:
		return
	logger.info("Downloading and applying upgrade")
	update_button.disabled = true
	update_button.button_text = "Updating..."
	check_update_button.disabled = true

	# Update the flake.lock file
	var cmd := Command.create(UPDATER_CMD, ["update"])
	if cmd.execute() != OK:
		logger.warn("Failed to update flake.lock")
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button, "Unable to download update")
		return
	if await cmd.finished != OK:
		logger.warn("Failed to update flake.lock:", cmd.stdout, cmd.stderr)
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button, "Unable to download update")
		return

	# Download and apply the upgrade
	cmd = Command.create(UPDATER_CMD, ["upgrade"])
	if cmd.execute() != OK:
		logger.warn("Failed to download and apply upgrade")
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button, "Unable to download update")
		return
	if await cmd.finished != OK:
		logger.warn("Failed to download and apply upgrade:", cmd.stdout, cmd.stderr)
		update_button.button_text = "Update"
		_reset_update_buttons(update_button, check_update_button, "Unable to download update")
		return

	update_available = false
	update_button.button_text = "Update"
	_reset_update_buttons(update_button, check_update_button, "Upgrade complete. Reboot to finish applying latest update.")


func _remove_node(node: Node) -> void:
	if not node:
		return
	var parent := node.get_parent()
	parent.remove_child(node)
	node.queue_free()
	logger.debug("Removed node:", node.name)
