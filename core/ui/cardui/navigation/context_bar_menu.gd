extends PanelContainer

const thread := preload("res://core/systems/threading/thread_pool.tres")

var state_machine := load("res://assets/state/state_machines/global_state_machine.tres") as StateMachine
var battery_capacity := -1
var logger := Log.get_logger("ContextBar")

@onready var accept_icon := $%AcceptButtonIcon as ControllerTextureRect
@onready var back_icon := $%BackButtonIcon as ControllerTextureRect
@onready var qam_mod_icon := $%QAMModifierIcon as ControllerTextureRect
@onready var qam_button_icon := $%QAMButtonIcon as ControllerTextureRect
@onready var battery: String = Battery.find_battery_path()
@onready var time_label: Label = $%TimeLabel
@onready var battery_container: HBoxContainer = $%BatteryContainer
@onready var battery_icon: TextureRect = $%BatteryIcon
@onready var battery_label: Label = $%BatteryLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	ControllerIcons.input_type_changed.connect(_on_input_type_changed)

	# Create a timer to update the time
	var time_timer: Timer = Timer.new()
	time_timer.timeout.connect(_on_update_time)
	time_timer.autostart = true
	add_child(time_timer)
	_on_update_time()
	_on_update_battery()
	battery_capacity = Battery.get_capacity(battery)
	
	# Create a timer to check battery status
	var battery_timer := Timer.new()
	battery_timer.timeout.connect(_on_update_battery_status)
	battery_timer.wait_time = 5
	battery_timer.autostart = true
	add_child(battery_timer)
	_on_update_battery_status()


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


# Update the icons in the context bar based on input type
func _on_input_type_changed(input_type: ControllerIcons.InputType) -> void:
	if input_type == ControllerIcons.InputType.CONTROLLER:
		accept_icon.path = "joypad/a"
		back_icon.path = "joypad/b"
		qam_mod_icon.path = "joypad/home"
		qam_button_icon.path = "joypad/a"
	else:
		accept_icon.path = "ui_accept"
		back_icon.path = "ogui_east"
		qam_mod_icon.path = "key/ctrl"
		qam_button_icon.path = "ogui_guide_action_qam"


## Updates the battery status on timer timeout
func _on_update_battery_status():
	if battery == "":
		if battery_container.visible:
			battery_container.visible = false
		return
	var status: int = Battery.get_status(battery)
	battery_icon.texture = Battery.get_capacity_texture(battery_capacity, status)
	if status < Battery.STATUS.CHARGING and battery_capacity < 10:
		battery_icon.modulate = Color(255, 0, 0)
	else:
		battery_icon.modulate = Color(255, 255, 255)


# Updates the battery capacity on timer timeout
func _on_update_battery():
	var get_capacity := func() -> int:
		return Battery.get_capacity(battery)
	var current_capacity: int = await thread.exec(get_capacity)
	battery_capacity = current_capacity
	battery_label.text = "{0}%".format([current_capacity])


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
