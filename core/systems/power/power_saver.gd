@icon("res://assets/editor-icons/power-meter.svg")
extends Node
class_name PowerSaver

## TODO: Use inputmanager to send power_save events for every input!!

var DisplayManager := preload("res://core/global/display_manager.tres") as DisplayManager

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

@onready var battery_path: String = Battery.find_battery_path()
@onready var dim_timer := $%DimTimer as Timer
@onready var suspend_timer := $%SuspendTimer as Timer

var dimmed := false
var prev_brightness := {}
var supports_brightness := DisplayManager.supports_brightness()
var has_battery := false
var logger := Log.get_logger("PowerSaver")


func _ready() -> void:
	if battery_path != "":
		has_battery = true
	if dim_screen_enabled and supports_brightness:
		dim_timer.timeout.connect(_on_dim_timer_timeout)
		dim_timer.start(dim_after_inactivity_mins * MINUTE)
	if auto_suspend_enabled:
		suspend_timer.timeout.connect(_on_suspend_timer_timeout)
		suspend_timer.start(suspend_after_inactivity_mins * MINUTE)


func _on_dim_timer_timeout() -> void:
	# If dimming is disabled when charging, check the battery state
	if has_battery and not dim_when_charging:
		var status: int = Battery.get_status(battery_path)
		if status in [Battery.STATUS.CHARGING, Battery.STATUS.FULL]:
			return
	if not has_battery and not dim_when_charging:
		return

	# Save the old brightness setting
	prev_brightness = {}
	var backlights := DisplayManager.get_backlight_paths()
	for backlight in backlights:
		prev_brightness[backlight] = DisplayManager.get_brightness(backlight)

	# Set the brightness
	var percent: float = dim_percent * 0.01
	DisplayManager.set_brightness(percent)
	dimmed = true


func _on_suspend_timer_timeout() -> void:
	# If suspend is disabled when charging, check the battery state
	if has_battery and not suspend_when_charging:
		var status: int = Battery.get_status(battery_path)
		if status in [Battery.STATUS.CHARGING, Battery.STATUS.FULL]:
			logger.debug("Not suspending because battery is charging")
			return
	if not has_battery and not suspend_when_charging:
		return
		
	logger.info("Suspending due to inactivity")
	var output := []
	if OS.execute("systemctl", ["suspend"], output) != OK:
		logger.warn("Failed to suspend: '" + output[0] + "'")


func _input(event: InputEvent) -> void:
	if dim_screen_enabled and supports_brightness:
		if dimmed:
			dimmed = false
			for percent in prev_brightness.values():
				DisplayManager.set_brightness(percent)
				break
		dim_timer.start(dim_after_inactivity_mins * MINUTE)
	if auto_suspend_enabled:
		suspend_timer.start(suspend_after_inactivity_mins * MINUTE)
