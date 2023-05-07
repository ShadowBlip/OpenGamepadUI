extends Control
class_name OnlyQAM

const Gamescope := preload("res://core/global/gamescope.tres")
const InputManager := preload("res://core/global/input_manager.tres")

var qam_state = load("res://assets/state/states/quick_access_menu.tres")
var display := Gamescope.XWAYLAND.OGUI
var qam_window_id: int
var pid: int
var shared_thread: SharedThread
var underlay_log: FileAccess
var underlay_process: InteractiveProcess
var underlay_window_id: int

var logger := Log.get_logger("Main-OnlyQAM", Log.LEVEL.INFO)

## Sets up PluginManager for QAM only mode.
func _init():
	var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
	var filters : Array[Callable] = [plugin_loader.filter_by_tag.bind("qam")]
	plugin_loader.set_plugin_filters(filters)
	var plugin_manager_scene := load("res://core/systems/plugin/plugin_manager.tscn") as PackedScene
	var plugin_manager := plugin_manager_scene.instantiate()
	add_child(plugin_manager)


## Starts the --only-qam/--qam-only session.
func _ready() -> void:
	# Set window size to native resolution
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	var window : Window = get_window()
	window.set_size(screen_size)

	# Set up the session
	var args := OS.get_cmdline_user_args()
	_setup_qam_only(args)


## Finds needed PID's and global vars, Starts the user defined program in the sandbox.
func _setup_qam_only(args: Array) -> void:
	pid = OS.get_process_id()
	qam_window_id = Gamescope.get_window_id(pid, display)
	qam_state.state_entered.connect(_on_qam_open)
	qam_state.state_exited.connect(_on_qam_closed)

	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)

	# Don't crash if we're not launching another program.
	if args == []:
		logger.warn("only-qam mode started with no launcher arguments.")
		return

	if "steam" in args:
		_start_steam_process(args)
	else:
		var log_path := OS.get_environment("HOME") + "/.underlay-stdout.log"
		_start_underlay_process(args, log_path)


func _start_steam_process(args: Array) -> void:
	# Setup steam
	var underlay_log_path = OS.get_environment("HOME") + "/.steam-stdout.log"
	_start_underlay_process(args, underlay_log_path)

	# Look for steam and save window ID
	while not underlay_window_id:
		# Find Steam in the display tree
		var root_win_id := Gamescope.get_root_window_id(display)
		var all_windows := Gamescope.get_all_windows(root_win_id, display)
		for window in all_windows:
			if window == qam_window_id:
				continue
			if Gamescope.has_xprop(window, "STEAM_OVERLAY", display):
				underlay_window_id = window
				logger.debug("Found steam! " + str(underlay_window_id))
				break
		# Wait a bit to reduce cpu load.
		OS.delay_msec(1000)

	# Start timer to check if steam has exited.
	var exit_timer := Timer.new()
	exit_timer.set_one_shot(false)
	exit_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
	exit_timer.timeout.connect(_check_exit)
	add_child(exit_timer)
	exit_timer.start()


func _start_underlay_process(args: Array, log_path: String) -> void:
	# Start the shared thread we use for logging.
	shared_thread = SharedThread.new()
	shared_thread.start()

	# Setup logging
	underlay_log = FileAccess.open(log_path, FileAccess.WRITE)
	var error := underlay_log.get_open_error()
	if error != OK:
		logger.warn("Got error opening log file.")
	else:
		logger.info("Started logging underlay process at " + log_path)
	var command: String = args[0]
	args.remove_at(0)
	underlay_process = InteractiveProcess.new(command, args)
#	var sandbox := PackedStringArray()
#	sandbox.append_array(["--noprofile"])
#	var blacklist := InputManager.get_managed_gamepads()
#	for device in blacklist:
#		sandbox.append("--blacklist=%s" % device)
#	sandbox.append("--")
#	sandbox.append_array(args)
#	underlay_process = InteractiveProcess.new("firejail", sandbox)
	if underlay_process.start() != OK:
		logger.error("Failed to start child process.")
		return
	var logger_func := func(delta: float):
		underlay_process.output_to_log_file(underlay_log)
	shared_thread.add_process(logger_func)


## Called when "qam_state" is entered.
func _on_qam_open(_from: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)
	Gamescope.set_overlay(qam_window_id, 1, display)
	if underlay_window_id:
		Gamescope.set_overlay(underlay_window_id, 0, display)


## Called when "qam_state" is exited.
func _on_qam_closed(_to: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)
	Gamescope.set_overlay(qam_window_id, 0, display)
	if underlay_window_id:
		Gamescope.set_overlay(underlay_window_id, 1, display)


## Verifies steam is still running by checking for the steam overlay, closes otherwise.
func _check_exit() -> void:
	if Gamescope.has_xprop(underlay_window_id, "STEAM_OVERLAY", display):
		return
	logger.debug("Steam closed. Shutting down.")
	get_tree().quit()
