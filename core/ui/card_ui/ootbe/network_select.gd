extends MarginContainer

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance
var state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var no_networking_state := load("res://assets/state/states/first_boot_finished.tres") as State
var network_state_machine := load("res://assets/state/state_machines/first_boot_network_state_machine.tres") as StateMachine
var password_popup_state := load("res://assets/state/states/first_boot_network_password.tres") as State

var logger := Log.get_logger("NetworkSelect")

@onready var next_button := $%NextButton as CardButton
@onready var wifi_tree := $%WifiNetworkTree as WifiNetworkTree
@onready var wifi_pass_box := $%WifiPasswordTextInput
@onready var wifi_pass_button := $%WifiPasswordButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_button.button_up.connect(_on_next_button)
	wifi_tree.challenge_required.connect(_on_challenge_required)


func _on_next_button() -> void:
	# Determine the next state to go to
	if not network_manager.is_running():
		state_machine.push_state(no_networking_state)
		return
	var next_state: State
	if network_manager.state >= network_manager.NM_STATE_CONNECTED_GLOBAL:
		next_state = load("res://assets/state/states/first_boot_plugin_select.tres") as State
	else:
		next_state = load("res://assets/state/states/first_boot_finished.tres") as State
	state_machine.push_state(next_state)


# If a wifi password is needed, this method will be called. The callback
# function should be called with the password entered by the user.
func _on_challenge_required(callback: Callable) -> void:
	# Show the password popup prompt and focus it
	network_state_machine.set_state([password_popup_state])

	# Connect to the submit button so we can invoke the callback
	# with the entered password
	var on_submit := func():
		# Execute the challenge callback with the entered password.
		callback.call(wifi_pass_box.text)
		
	wifi_pass_button.button_up.connect(on_submit, CONNECT_ONE_SHOT)
