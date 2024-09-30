@icon("res://assets/editor-icons/power-meter.svg")
extends Node
class_name PowerSaver

## TODO: Use inputmanager to send power_save events for every input!!

var display := load("res://core/global/display_manager.tres") as DisplayManager
var settings := load("res://core/global/settings_manager.tres") as SettingsManager
var power_manager := load("res://core/systems/power/power_manager.tres") as UPowerInstance

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

var dimmed := false
var prev_brightness := {}
var supports_brightness := display.supports_brightness()
var has_battery := false
var display_device := power_manager.get_display_device()
var logger := Log.get_logger("PowerSaver")


func _ready() -> void:
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


func _input(event: InputEvent) -> void:
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
