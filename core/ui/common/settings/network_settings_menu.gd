extends Control

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance

var connecting := false
@onready var no_net_label := $%NoNetworkLabel
@onready var wifi_tree := $%WifiNetworkTree as WifiNetworkTree
@onready var wireless_toggle := $%WirelessEnableToggle as Toggle
@onready var wifi_label := $%WifiLabel
@onready var password_button := $%WifiPasswordButton
@onready var password_input := $%WifiPasswordTextInput
@onready var password_popup := $%PopupContainer
@onready var ip_text := $%IPAddressText as SelectableText
@onready var mask_text := $%SubnetText as SelectableText
@onready var gateway_text := $%GatewayText as SelectableText


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Display label if no networking is available
	var on_networking_available := func():
		no_net_label.visible = not network_manager.is_running()
	network_manager.started.connect(on_networking_available)
	network_manager.stopped.connect(on_networking_available)
	on_networking_available.call()

	# Connect the wireless enable toggle
	var wireless_enabled := network_manager.wireless_enabled
	wireless_toggle.button_pressed = wireless_enabled
	wifi_label.visible = wireless_enabled
	wifi_tree.visible = wireless_enabled
	var on_wireless_toggled := func(enabled: bool):
		network_manager.wireless_enabled = enabled
		wifi_label.visible = enabled
		wifi_tree.visible = enabled
		if enabled:
			await get_tree().create_timer(4.0).timeout
			wifi_tree.refresh_networks()
	wireless_toggle.toggled.connect(on_wireless_toggled)

	# Fill out the connection details
	var connection := network_manager.primary_connection
	_on_connection_changed(connection)
	network_manager.primary_connection_changed.connect(_on_connection_changed)

	# Connect visibility and challenge signals
	visibility_changed.connect(_on_visible_changed)
	wifi_tree.challenge_required.connect(_on_wifi_challenge)

	# Configure the OSK with the password input box
	var password_context := password_input.keyboard_context as KeyboardContext
	var on_submit := func():
		password_button.pressed.emit()
	password_context.submitted.connect(on_submit)
	password_context.close_on_submit = true


func _on_connection_changed(connection: NetworkActiveConnection) -> void:
	await get_tree().create_timer(3.0).timeout
	if not connection:
		ip_text.text = "0.0.0.0"
		mask_text.text = "0"
		gateway_text.text = "0.0.0.0"
		return
	var devices := connection.devices
	if devices.is_empty():
		ip_text.text = "0.0.0.0"
		mask_text.text = "0"
		gateway_text.text = "0.0.0.0"
		return
	var device := devices[0]
	var ip := device.ip4_config
	if not ip:
		ip_text.text = "0.0.0.0"
		mask_text.text = "0"
		gateway_text.text = "0.0.0.0"
		return
	var gateway := ip.gateway
	if not gateway.is_empty():
		gateway_text.text = gateway
	var addresses := ip.addresses
	if addresses.is_empty():
		ip_text.text = "0.0.0.0"
		mask_text.text = "0"
		gateway_text.text = "0.0.0.0"
		return
	var info := addresses[0]
	if "prefix" in info:
		mask_text.text = str(info["prefix"])
	if "address" in info:
		ip_text.text = info["address"]


func _on_visible_changed() -> void:
	_on_connection_changed(network_manager.primary_connection)
	wifi_tree.refresh_networks()
	password_popup.visible = false


func _on_wifi_challenge(callback: Callable) -> void:
	password_popup.visible = true
	password_input.grab_focus.call_deferred()

	var on_pass_submit := func():
		connecting = true
		password_popup.visible = false
		wifi_tree.grab_focus.call_deferred()
		var password := password_input.text as String
		callback.call(password)
	password_button.pressed.connect(on_pass_submit, CONNECT_ONE_SHOT)


# Intercept back input when the password dialog is open
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not password_popup.visible:
		return
	if not event.is_action("ogui_east"):
		return
	password_input.grab_focus.call_deferred()
	get_viewport().set_input_as_handled()
