@tool
@icon("res://assets/ui/icons/screenshot-2-fill.svg")
extends Node
class_name Screenshotter

## Take a gamescope screenshot when a signal fires
##
## The [Screenshotter] can be added as a child to any node that exposes signals.
## Upon entering the scene tree, the [Screenshotter] connects to a given signal
## on its parent, and will take a screenshot when the given signal fires.

signal screenshot_taken

var gamescope := load("res://core/global/gamescope.tres") as Gamescope
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager

## Signal on our parent to connect to. When this signal fires, the [Screenshotter] 
## will take a screenshot with gamescope
var on_signal: String
## Path to move the screenshot file to
@export var destination_folder := "user://screenshots"
## Whether or not a notification should be shown after taking a screenshot
@export var show_notification := true

var logger := Log.get_logger("Screenshotter")


func _ready() -> void:
	notify_property_list_changed()
	get_parent().connect(on_signal, _on_signal)


func _on_signal():
	# Take a screenshot
	gamescope.request_screenshot()
	
	# Wait for gamescope to write the screenshot
	await get_tree().create_timer(3).timeout
	var msg := "Screenshot saved"
	
	# Move the screenshot to the destination
	var output_file := "/tmp/gamescope.png"
	if FileAccess.file_exists(output_file):
		var date := Time.get_time_string_from_system()
		var file_name := "opengamepadui-{0}.png".format([date.replace(":", "_")])
		var dest_path := "/".join([destination_folder, file_name])
		DirAccess.make_dir_recursive_absolute(destination_folder)
		var err := DirAccess.rename_absolute(output_file, dest_path)
		if err != OK:
			msg = "Unable to save screenshot to " + ProjectSettings.globalize_path(dest_path)
			logger.error(msg)
		else:
			msg = "Saved screenshot to: " + ProjectSettings.globalize_path(dest_path)
			logger.info(msg)
	screenshot_taken.emit()
	
	# Send a notification if configured
	if show_notification:
		var notify := Notification.new(msg)
		notification_manager.show(notify)


# Customize editor properties that we expose. Here we dynamically look up
# the parent node's signals so we can display them in a list.
func _get_property_list():
	# By default, `on_signal` is not visible in the editor.
	var property_usage := PROPERTY_USAGE_NO_EDITOR

	var parent_signals := []
	if get_parent() != null:
		property_usage = PROPERTY_USAGE_DEFAULT
		for sig in get_parent().get_signal_list():
			parent_signals.push_back(sig["name"])

	var properties := []
	properties.append(
		{
			"name": "on_signal",
			"type": TYPE_STRING,
			"usage": property_usage,  # See above assignment.
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(parent_signals)
		}
	)

	return properties
