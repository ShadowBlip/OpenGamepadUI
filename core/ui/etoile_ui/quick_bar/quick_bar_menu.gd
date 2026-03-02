extends Control

var launch_manager := preload("res://core/global/launch_manager.tres") as LaunchManager
var state_machine := preload("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var popup_state_machine := preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
var quick_bar_state_machine := preload("res://assets/state/state_machines/quick_bar_state_machine.tres") as StateMachine
var quick_bar_menu_state := preload("res://assets/state/states/quick_bar_menu.tres") as State
var gamepad_settings_state := preload("res://assets/state/states/gamepad_settings.tres") as State

var audio_manager := preload("res://core/global/audio_manager.tres") as AudioManager
var display_manager := preload("res://core/global/display_manager.tres") as DisplayManager

@onready var glass_rect := %GlassPanel
@onready var focus_group := %FocusGroup as FocusGroup
@onready var notifications_button := %NotificationsButton as CollapsibleButton
@onready var exit_button := %ExitGameButton as CollapsibleButton
@onready var network_button := %NetworkButton as CollapsibleButton
@onready var bluetooth_button := %BluetoothButton as CollapsibleButton
@onready var performance_button := %PerformanceButton as CollapsibleButton
@onready var overlay_button := %OverlayButton as CollapsibleButton
@onready var controllers_button := %ControllersButton as CollapsibleButton
@onready var back_button := %BackButton as CollapsibleButton

@onready var menu := %MainContainer as Control
@onready var menu_label := %MenuLabel as Label
@onready var sub_menu := %SubMenuContainer as Control
@onready var sub_menu_content := %SubMenuContentContainer as Control
@onready var performance_menu := %Performance as Control
@onready var network_menu := %NetworkSettings as Control
@onready var bluetooth_menu := %BluetoothSettingsMenu as Control
@onready var notifications_menu := %NotificationMenu as Control

@onready var volume_slider := %VolumeSlider as ComponentSlider
@onready var brightness_slider := %BrightnessSlider as ComponentSlider

func _ready() -> void:
	quick_bar_menu_state.state_entered.connect(_on_state_entered)
	quick_bar_menu_state.state_exited.connect(_on_state_exited)
	launch_manager.app_launched.connect(_on_app_launched)
	launch_manager.app_stopped.connect(_on_app_stopped)
	notifications_button.button_up.connect(_on_submenu_switch.bind(notifications_menu))
	network_button.button_up.connect(_on_submenu_switch.bind(network_menu))
	bluetooth_button.button_up.connect(_on_submenu_switch.bind(bluetooth_menu))
	performance_button.button_up.connect(_on_submenu_switch.bind(performance_menu))
	controllers_button.player_button_up.connect(_on_controllers_button_pressed)
	back_button.button_up.connect(_on_back_button_pressed)

	# Flip back button texture
	var back_texture := back_button.get_node("%Icon") as TextureRect
	back_texture.flip_h = true

	# Connect volume slider
	volume_slider.value_changed.connect(_on_volume_changed)
	audio_manager.volume_changed.connect(_on_volume_changed_from_manager)
	
	# Connect brightness slider
	brightness_slider.value_changed.connect(_on_brightness_changed)
	if display_manager.supports_brightness():
		var backlights := display_manager.get_backlight_paths()
		if backlights.size() > 0:
			brightness_slider.value = display_manager.get_brightness(backlights[0]) * 100
		else:
			brightness_slider.visible = false
	else:
		brightness_slider.visible = false


func _on_state_entered(_from: State) -> void:
	if focus_group:
		focus_group.grab_focus()


func _on_state_exited(_to: State) -> void:
	sub_menu.visible = false
	menu.visible = true


func _on_app_launched(_app: RunningApp) -> void:
	exit_button.visible = true


func _on_app_stopped(_app: RunningApp) -> void:
	if launch_manager.get_running().is_empty():
		exit_button.visible = false


func _on_submenu_switch(menu_to_switch_to: Control) -> void:
	for child in sub_menu_content.get_children():
		child.visible = false
	sub_menu.visible = true
	menu_to_switch_to.visible = true
	menu.visible = false
	menu_label.text = ""

	# Update the label based on the submenu
	# TODO: Derive the name from the node name instead
	var menu_name := menu_to_switch_to.name
	match menu_name:
		"Performance":
			menu_label.text = tr("Performance")
		"NetworkSettings":
			menu_label.text = tr("Network")
		"BluetoothSettingsMenu":
			menu_label.text = tr("Bluetooth")
		"NotificationsMenu":
			menu_label.text = tr("Notifications")

	var focusable := FocusGroup.find_focusable([menu_to_switch_to])
	if focusable:
		focusable.grab_focus.call_deferred()


func _on_controllers_button_pressed() -> void:
	popup_state_machine.push_state(gamepad_settings_state)


func _on_volume_changed(value: float) -> void:
	if not audio_manager.supports_audio():
		return
	# Convert slider value (0-100) to volume (0.0-1.0) and set
	var volume := value * 0.01
	audio_manager.set_volume(volume)


func _on_brightness_changed(value: float) -> void:
	if not display_manager.supports_brightness():
		return
	# Convert slider value (0-100) to brightness (0.0-1.0) and set
	var brightness := value * 0.01
	# Get the first backlight path
	var backlights := display_manager.get_backlight_paths()
	if backlights.size() > 0:
		display_manager.set_brightness(brightness, DisplayManager.VALUE.ABSOLUTE, backlights[0])


func _on_volume_changed_from_manager(value: float) -> void:
	if not audio_manager.supports_audio():
		return
	volume_slider.value = value * 100


func _on_back_button_pressed() -> void:
	sub_menu.visible = false
	menu.visible = true
	var focusable := FocusGroup.find_focusable([menu])
	if focusable:
		focusable.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if state_machine.current_state() != quick_bar_menu_state:
		return
	if event.is_action_released("ogui_back") or event.is_action_released("ogui_east"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_released("ogui_back") or event.is_action_released("ogui_east"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
		return
