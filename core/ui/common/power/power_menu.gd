extends Control

var state_machine := (
	preload("res://assets/state/state_machines/popup_state_machine.tres") as StateMachine
)
var power_state := load("res://assets/state/states/power_menu.tres") as State
var logger := Log.get_logger("PowerMenu")

@onready var focus_group := $%FocusGroup
@onready var suspend_button := $%SuspendButton
@onready var reboot_button := $%RebootButton
@onready var shutdown_button := $%ShutdownButton
@onready var exit_button := $%ExitButton
@onready var cancel_button := $%CancelButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	power_state.state_entered.connect(_on_state_entered)
	suspend_button.button_down.connect(_on_systemctl_cmd.bind("suspend"))
	shutdown_button.button_down.connect(_on_systemctl_cmd.bind("poweroff"))
	reboot_button.button_down.connect(_on_systemctl_cmd.bind("reboot"))
	exit_button.button_down.connect(_on_exit)
	cancel_button.button_up.connect(_on_cancel)


func _on_state_entered(_from: State) -> void:
	if focus_group:
		focus_group.grab_focus()


func _on_systemctl_cmd(command: String) -> void:
	state_machine.clear_states()
	var exec := func():
		var output: Array = []
		if OS.execute("systemctl", [command], output) != OK:
			logger.warn("Failed to " + command + ": '" + output[0] + "'")
	exec.call_deferred()


func _on_exit() -> void:
	get_tree().quit()


func _on_cancel() -> void:
	state_machine.pop_state()
