extends Control

var boxart_manager := preload("res://core/global/boxart_manager.tres") as BoxArtManager
var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var install_manager := preload("res://core/global/install_manager.tres") as InstallManager
var settings_manager := preload("res://core/global/settings_manager.tres") as SettingsManager

var tween: Tween
var state_machine := preload("res://assets/state/state_machines/menu_state_machine.tres") as StateMachine
var state := preload("res://assets/state/states/game_launcher.tres") as State

@onready var logo := %Logo as TextureRect
@onready var launch_button := %LaunchButton as CardButton
@onready var manage_button := %ManageButton as CardButton
@onready var links_button := %LinksButton as CardButton
@onready var uinstall_button := %UninstallButton as CardButton


func _ready() -> void:
	state.state_entered.connect(_on_state_entered)
	state.state_exited.connect(_on_state_exited)
	state.refreshed.connect(_on_state_refreshed)


# Show the game details on state entered
func _on_state_entered(_from: State) -> void:
	self.visible = true
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "size_flags_stretch_ratio", 2.0, 0.5)
	launch_button.grab_focus.call_deferred()


# Hide the game details on state exit
func _on_state_exited(_to: State) -> void:
	var tree := get_tree()
	if not tree:
		return
	if tween:
		tween.kill()
	tween = tree.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "size_flags_stretch_ratio", 0.0, 0.5)
	var on_finished := func() -> void:
		self.visible = false
	tween.finished.connect(on_finished, CONNECT_ONE_SHOT)


# Update the details page if the state is refreshed
func _on_state_refreshed() -> void:
	if not state.has_meta("library_item"):
		return
	var library_item := state.get_meta("library_item") as LibraryItem
	var texture := await boxart_manager.get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.LOGO)
	logo.texture = texture
	var launch_item := _get_launch_item(library_item)
	_update_launch_button(launch_item)


# Lookup the current launch provider for the library item
func _get_launch_item(library_item: LibraryItem) -> LibraryLaunchItem:
	var launch_item := library_item.launch_items[0] as LibraryLaunchItem
	var section := "game.{0}".format([library_item.name.to_lower()])
	var provider_id := settings_manager.get_value(section, "provider", "") as String
	if provider_id != "":
		var possible_launch_item := library_item.get_launch_item(provider_id)
		if possible_launch_item != null:
			launch_item = possible_launch_item

	return launch_item


# Update the launch button based on the state
func _update_launch_button(launch_item: LibraryLaunchItem) -> void:
	if not launch_item:
		return
	if launch_item.installed:
		launch_button.text = tr("Play Now")
	else:
		launch_button.text = tr("Install")
	if launch_manager.is_running(launch_item.name):
		launch_button.text = tr("Resume")
	if install_manager.is_queued(launch_item):
		launch_button.text = tr("Queued")
	if install_manager.is_installing(launch_item):
		launch_button.text = tr("Installing")


func _input(event: InputEvent) -> void:
	var focused_node := get_viewport().gui_get_focus_owner()
	if focused_node and not self.is_ancestor_of(focused_node):
		return
	if state_machine.current_state() != state:
		return
	if event.is_action_pressed("ui_up") or event.is_action_released("ogui_back") or event.is_action_pressed("ui_cancel") or event.is_action_released("ogui_east"):
		state_machine.pop_state()
		get_viewport().set_input_as_handled()
		return
