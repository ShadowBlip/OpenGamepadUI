@icon("res://assets/editor-icons/fluent--pipeline-20-filled.svg")
extends Node
class_name PipeManager

## Class for managing control messages sent through a named pipe
##
## The [PipeManager] creates a named pipe in `/run/user/<uid>/opengamepadui`
## that can be used as a communication mechanism to send OpenGamepadUI commands
## from another process. This is mostly done to handle custom `ogui://` URIs
## which can be used to react in different ways.

const RUN_FOLDER: String = "/run/user/{}/opengamepadui"
const URI_PREFIX: String = "ogui://"

signal line_written(line: String)

var launch_manager := load("res://core/global/launch_manager.tres") as LaunchManager
var library_manager := load("res://core/global/library_manager.tres") as LibraryManager
var settings_manager := load("res://core/global/settings_manager.tres") as SettingsManager

var pipe: FifoReader
var pipe_path: String
var logger := Log.get_logger("PipeManager", Log.LEVEL.DEBUG)


func _ready() -> void:
	# Ensure the run directory exists
	var run_path := get_run_path()
	DirAccess.make_dir_recursive_absolute(run_path)
	
	# Create a unix named pipe
	pipe_path = get_pipe_path()
	if pipe_path.is_empty():
		logger.error("Failed to get pipe path!")
		return
	logger.info("Opening pipe:", pipe_path)
	pipe = FifoReader.new()
	if pipe.open(pipe_path) != OK:
		return
	pipe.line_written.connect(_on_line_written)
	add_child(pipe)


## Returns the path to the named pipe (e.g. /run/user/1000/opengamepadui/opengamepadui-0)
func get_pipe_path() -> String:
	var run_path := get_run_path()
	if run_path.is_empty():
		return ""
	var path := "/".join([run_path, "opengamepadui-0"])
	return path


## Returns the run path for the current user (e.g. /run/user/1000/opengamepadui)
func get_run_path() -> String:
	var uid := get_uid()
	if uid < 0:
		return ""
	var run_folder := RUN_FOLDER.format([uid], "{}")

	return run_folder


## Returns the current user id (e.g. 1000)
func get_uid() -> int:
	var output: Array = []
	if OS.execute("id", ["-u"], output) != OK:
		return -1
	if output.is_empty():
		return -1
	var data := output[0] as String
	var uid := data.to_int()

	return uid


func _on_line_written(line: String) -> void:
	if line.is_empty():
		return
	logger.debug("Received piped message:", line)
	line_written.emit(line)

	# Check to see if the message is an ogui URI
	if line.begins_with(URI_PREFIX):
		_handle_uri_request(line)


func _handle_uri_request(uri: String) -> void:
	var path := uri.replace(URI_PREFIX, "")
	var parts: Array[String]
	parts.assign(path.split("/"))
	if parts.is_empty():
		return
	var cmd := parts.pop_front() as String
	logger.info("Received URI command:", cmd)
	match cmd:
		"run":
			_handle_run_cmd(parts)


func _handle_run_cmd(args: Array[String]) -> void:
	if args.is_empty():
		logger.debug("No game name was found in URI")
		return
	var game_name := args[0]
	var library_item := library_manager.get_app_by_name(game_name)
	if not library_item:
		logger.warn("Unable to find game with name:", game_name)
		return

	# Select the provider
	var launch_item := library_item.launch_items[0] as LibraryLaunchItem
	var section := "game.{0}".format([library_item.name.to_lower()])
	var provider_id = settings_manager.get_value(section, "provider", "")
	if provider_id != "":
		var p := library_item.get_launch_item(provider_id)
		if p != null:
			launch_item = p

	# Start the game
	logger.info("Starting game:", game_name)
	launch_manager.launch(launch_item)


func _exit_tree() -> void:
	if not pipe:
		return
	pipe.close()
