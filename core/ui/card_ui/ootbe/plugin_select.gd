extends MarginContainer

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance
var state_machine := load("res://assets/state/state_machines/first_boot_state_machine.tres") as StateMachine
var next_state := load("res://assets/state/states/first_boot_plugin_select.tres") as State
var no_networking_state := load("res://assets/state/states/first_boot_finished.tres") as State
var plugin_store_state := load("res://assets/state/states/settings_plugin_store.tres") as State
var plugin_select_state := load("res://assets/state/states/first_boot_plugin_select.tres") as State


var logger := Log.get_logger("PluginSelect")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	plugin_select_state.state_entered.connect(_on_state_entered)


# When this menu is shown, check if networking is supported. If not,
# proceed to the next OOBE menu.
func _on_state_entered(_from: State) -> void:
	if not network_manager.is_running():
		logger.info("Networking is not supported. Skipping.")
		state_machine.replace_state(no_networking_state)
		return
	if network_manager.state < network_manager.NM_STATE_CONNECTED_GLOBAL:
		logger.info("Network is not available. Skipping.")
		state_machine.replace_state(no_networking_state)
		return
