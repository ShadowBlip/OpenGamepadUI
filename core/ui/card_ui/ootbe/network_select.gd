extends MarginContainer

var state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var next_state := load("res://assets/state/states/first_boot_plugin_select.tres") as State
var network_state := load("res://assets/state/states/first_boot_network.tres") as State

var network_state_machine := load("res://assets/state/state_machines/first_boot_network_state_machine.tres") as StateMachine
var password_popup_state := load("res://assets/state/states/first_boot_network_password.tres") as State

var logger := Log.get_logger("NetworkSelect")

@onready var wifi_tree := $%WifiNetworkTree as WifiNetworkTree
@onready var wifi_pass_box := $%WifiPasswordTextInput
@onready var wifi_pass_button := $%WifiPasswordButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	network_state.state_entered.connect(_on_state_entered)
	wifi_tree.challenge_required.connect(_on_challenge_required)


# When this menu is shown, check if networking is supported. If not,
# proceed to the next OOBE menu.
func _on_state_entered(_from: State) -> void:
	if NetworkManager.supports_network():
		return
	logger.info("Networking is not supported. Skipping.")
	state_machine.replace_state(next_state)


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
