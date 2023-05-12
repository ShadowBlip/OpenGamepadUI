extends MarginContainer

var state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var next_state := load("res://assets/state/states/first_boot_plugin_select.tres") as State
var network_state := load("res://assets/state/states/first_boot_network.tres") as State

var logger := Log.get_logger("NetworkSelect")


# Called when the node enters the scene tree for the first time.`
func _ready() -> void:
	network_state.state_entered.connect(_on_state_entered)


func _on_state_entered(_from: State) -> void:
	if NetworkManager.supports_network():
		return
	logger.info("Networking is not supported. Skipping.")
	state_machine.replace_state(next_state)
