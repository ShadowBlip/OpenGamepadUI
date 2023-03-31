extends Control
class_name OnlyQAM

const Gamescope := preload("res://core/global/gamescope.tres")
const InputManager := preload("res://core/global/input_manager.tres")

var qam_state = load("res://assets/state/states/quick_access_menu.tres")
var display := Gamescope.XWAYLAND.OGUI
var qam_window_id: int
var pid: int
var shared_thread: SharedThread
var steam_log: FileAccess
var steam_process: InteractiveProcess
var steam_window_id: int

var logger := Log.get_logger("OQMain", Log.LEVEL.INFO)

func _init():
	logger.debug("Init only_qam mode.")
	var plugin_loader := load("res://core/global/plugin_loader.tres") as PluginLoader
	var filters : Array[Callable] = [plugin_loader.filter_by_tag.bind("qam")]
	plugin_loader.set_plugin_filters(filters)
	var plugin_manager_scene := load("res://core/systems/plugin/plugin_manager.tscn") as PackedScene
	var plugin_manager := plugin_manager_scene.instantiate()
	add_child(plugin_manager)


## Starts the --only-qam/--qam-only session.
func _ready() -> void:
	shared_thread = SharedThread.new()
	shared_thread.start()
	# Set window size to native resolution
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	var window : Window = get_window()
	window.set_size(screen_size)

	var steam_log_path = OS.get_environment("HOME") + "/.steam-stdout.log"
	steam_log = FileAccess.open(steam_log_path, FileAccess.WRITE)
	var error := steam_log.get_open_error()
	if error != OK:
		logger.warn("Got error opening log file.")
	else:
		logger.debug("Opened Steam log at " + steam_log_path)
	# Get user arguments
	var args := OS.get_cmdline_user_args()
	_setup_qam_only(args)


## Creates teh input manager, qam scene, and starts teh user defined program (steam) in firejail.
func _setup_qam_only(args: Array) -> void:
	# Setup input manager
	var input_scene := load("res://core/systems/input/only_qam_input_manager.tscn") as PackedScene
	add_child(input_scene.instantiate())

	# Add the QAM
	var qam_scene := load("res://core/ui/menu/qam/only_quick_access_menu.tscn") as PackedScene
	var qam := qam_scene.instantiate()
	add_child(qam)
	qam.remove_child(qam.get_node("BackInputHandler"))

	pid = OS.get_process_id()
	qam_window_id = Gamescope.get_window_id(pid, display)
	qam_state.state_entered.connect(_on_qam_open)
	qam_state.state_exited.connect(_on_qam_closed)
	
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)

	# Don't crash if we're not launching another program.
	if args == []:
		logger.warn("only-qam mode started with no launcher arguments.")
		return
	# Launch underlay in the sandbox 
	var sandbox := PackedStringArray()
	sandbox.append_array(["--noprofile"])
	var blacklist := InputManager.get_managed_gamepads()
	for device in blacklist:
		sandbox.append("--blacklist=%s" % device)
	sandbox.append("--")
	sandbox.append_array(args)
	steam_process = InteractiveProcess.new("firejail", sandbox)
	if steam_process.start() != OK:
		logger.error("Failed to start steam process.")
	if not "steam" in args:
		return
	var logger_func := func(delta: float):
		steam_process.output_to_log_file(steam_log)
	shared_thread.add_process(logger_func)
	# Look for steam
	while not steam_window_id:
		
		# Find Steam in the display tree
		var root_win_id := Gamescope.get_root_window_id(display)
		var all_windows := Gamescope.get_all_windows(root_win_id, display)
		for window in all_windows:
			if window == qam_window_id:
				continue
			if Gamescope.has_xprop(window, "STEAM_OVERLAY", display):
				steam_window_id = window
				logger.debug("Found steam! " + str(steam_window_id))
				break
		# Wait a bit to reduce cpu load.
		OS.delay_msec(1000)
	var exit_timer := Timer.new()
	exit_timer.set_one_shot(false)
	exit_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
	exit_timer.timeout.connect(_check_exit)
	add_child(exit_timer)
	exit_timer.start()


## Called when "qam_state" is entered. Makes the QAM visible.
func _on_qam_open(_from: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)
	Gamescope.set_overlay(qam_window_id, 1, display)
	Gamescope.set_overlay(steam_window_id, 0, display)


## Called when "qam_state" is exited. Makes the QAM invisible.
func _on_qam_closed(_to: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)
	Gamescope.set_overlay(qam_window_id, 0, display)
	Gamescope.set_overlay(steam_window_id, 1, display)

## Verifies steam is still running by checking for the steam overlay, closes otherwise.
func _check_exit() -> void:
	if Gamescope.has_xprop(steam_window_id, "STEAM_OVERLAY", display):
		return
	logger.debug("Steam closed. Shutting down.")
	get_tree().quit()
