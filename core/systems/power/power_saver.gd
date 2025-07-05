@icon("res://assets/editor-icons/power-meter.svg")
extends Node
class_name PowerSaver

## TODO: Use inputmanager to send power_save events for every input!!

var display := load("res://core/global/display_manager.tres") as DisplayManager
var settings := load("res://core/global/settings_manager.tres") as SettingsManager
var power_manager := load("res://core/systems/power/power_manager.tres") as UPowerInstance
var gamescope := load("res://core/systems/gamescope/gamescope.tres") as GamescopeInstance

const MINUTE := 60

@export_category("Dim Screen")
@export var dim_screen_enabled := true
@export var dim_after_inactivity_mins := 5
@export var dim_percent := 10
@export var dim_when_charging := true
@export_category("Auto Suspend")
@export var auto_suspend_enabled := true
@export var suspend_after_inactivity_mins := 20
@export var suspend_when_charging := false

@onready var dim_timer := $%DimTimer as Timer
@onready var suspend_timer := $%SuspendTimer as Timer
@onready var gamescope_timer := $%GamescopeCheckTimer as Timer

var dimmed := false
var prev_brightness := {}
var supports_brightness := display.supports_brightness()
var has_battery := false
var display_device := power_manager.get_display_device()
var gamescope_input_counters: Dictionary[int, int] = {}
var logger := Log.get_logger("PowerSaver")


func _ready() -> void:
	gamescope_timer.timeout.connect(_on_gamescope_check_timeout)
	if display_device:
		has_battery = display_device.is_present
	
	if dim_screen_enabled and supports_brightness:
		dim_timer.timeout.connect(_on_dim_timer_timeout)
		dim_timer.start(dim_after_inactivity_mins * MINUTE)
	if auto_suspend_enabled:
		suspend_timer.timeout.connect(_on_suspend_timer_timeout)
		suspend_timer.start(suspend_after_inactivity_mins * MINUTE)


func _on_dim_timer_timeout() -> void:
	# If dimming is disabled when charging, check the battery state
	if has_battery and display_device and not dim_when_charging:
		var status := display_device.state
		if status in [UPowerDevice.STATE_CHARGING, UPowerDevice.STATE_FULLY_CHARGED]:
			logger.debug("Not dimming because battery is charging")
			return
	if not has_battery and not dim_when_charging:
		return

	# Save the old brightness setting
	prev_brightness = {}
	var backlights := display.get_backlight_paths()
	for backlight in backlights:
		prev_brightness[backlight] = display.get_brightness(backlight)

	# Set the brightness
	logger.debug("Dimming screen due to inactivty")
	var percent: float = dim_percent * 0.01
	display.set_brightness(percent)
	logger.debug("Lowering FPS due to inactivity")
	Engine.max_fps = 10
	dimmed = true


func _on_suspend_timer_timeout() -> void:
	# If suspend is disabled when charging, check the battery state
	if has_battery and display_device and not suspend_when_charging:
		var status := display_device.state
		if status in [UPowerDevice.STATE_CHARGING, UPowerDevice.STATE_FULLY_CHARGED]:
			logger.debug("Not suspending because battery is charging")
			return
	if not has_battery and not suspend_when_charging:
		return
		
	logger.info("Suspending due to inactivity")
	var output := []
	if OS.execute("systemctl", ["suspend"], output) != OK:
		logger.warn("Failed to suspend: '" + output[0] + "'")


func _input(_event: InputEvent) -> void:
	if dim_screen_enabled and supports_brightness:
		if dimmed:
			dimmed = false
			logger.debug("Reverting brightness setting from activity")
			for percent in prev_brightness.values():
				display.set_brightness(percent)
				break
			# Set the FPS limit
			logger.debug("Reverting FPS from activity")
			Engine.max_fps = settings.get_value("general", "max_fps", 60) as int
		dim_timer.start(dim_after_inactivity_mins * MINUTE)
	if auto_suspend_enabled:
		suspend_timer.start(suspend_after_inactivity_mins * MINUTE)


## Called at a regular interval to check if gamescope input counters have changed.
## Gamepad inputs will be routed to all running applications (including OpenGamepadUI)
## which can be used to check for inactivity, but keyboard/mouse inputs will not.
## To work around this, this method will check the input counter atom in gamescope
## which will change whenever keyboard/mouse input is detected.
func _on_gamescope_check_timeout() -> void:
	# Loop through each xwayland instance to see if any have received mouse or
	# keyboard inputs since the last check
	var detected_input := false
	for xwayland_type in [gamescope.XWAYLAND_TYPE_PRIMARY, gamescope.XWAYLAND_TYPE_OGUI]:
		if not _has_gamescope_input_counter_changed(xwayland_type):
			continue
		detected_input = true
		var xwayland := gamescope.get_xwayland(xwayland_type)
		if not xwayland:
			continue
		self.gamescope_input_counters[xwayland_type] = xwayland.get_input_counter()

	if not detected_input:
		return

	self._input(null)


## Returns true if input counter for the given gamescope type is different
## than the one recorded in `self.gamescope_input_counters`
func _has_gamescope_input_counter_changed(xwayland_type: int) -> bool:
	var xwayland := gamescope.get_xwayland(xwayland_type)
	if not xwayland:
		return false
	var last := _get_last_input_counter_for(xwayland_type)
	var current := xwayland.get_input_counter()

	return last != current


## Returns the last set input counter for the given XWayland type.
func _get_last_input_counter_for(xwayland_type: int) -> int:
	var counter := 0
	if xwayland_type in self.gamescope_input_counters:
		counter = self.gamescope_input_counters[xwayland_type]
	return counter
