extends PanelContainer

var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var logger := Log.get_logger("ContextBar")

@onready var time_label: Label = $%TimeLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)

	# Create a timer to update the time
	var time_timer: Timer = Timer.new()
	time_timer.timeout.connect(_on_update_time)
	time_timer.autostart = true
	add_child(time_timer)
	_on_update_time()


func _process(delta: float) -> void:
	var stack = []
	for s in state_machine._state_stack:
		var state := s as State
		stack.push_back(state.name)
	var state_stack = "-> ".join(stack)
	$%DebugLabel.text = state_stack


func _on_state_changed(from: State, to: State):
	var stack = []
	for s in state_machine._state_stack:
		var state := s as State
		stack.push_back(state.name)
	var state_stack = "-> ".join(stack)
	logger.debug(state_stack)


# Updates the current time on timer timeout
func _on_update_time():
	# year, month, day, weekday, hour, minute, second
	var time = Time.get_datetime_dict_from_system()
	time_label.text = _format_time(time)


func _format_time(time: Dictionary) -> String:
	time["meridium"] = "am"
	if time["hour"] > 11:
		time["meridium"] = "pm"
	if time["hour"] > 12:
		time["hour"] -= 12

	# Pad our minutes and hours
	time["minute"] = "%02d" % time["minute"]
	time["hour"] = "%02d" % time["hour"]

	return "{hour}:{minute}{meridium}".format(time)
