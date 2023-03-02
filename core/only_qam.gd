extends Control
class_name OnlyQAM

const Gamescope := preload("res://core/global/gamescope.tres")
const InputManager := preload("res://core/global/input_manager.tres")

var qam_state = load("res://assets/state/states/quick_access_menu.tres")

var display := Gamescope.XWAYLAND.OGUI
var qam_window_id: int
var pid: int
var steam_window_id: int


func _ready() -> void:
	# Set window sizeto native resolution
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	var window : Window = get_window()
	window.set_size(screen_size)
	# Get arguments, remove "--only-qam"
	var args := OS.get_cmdline_args()
	args.remove_at(0)
	_setup_qam_only(args)


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
		print("Nothing to do")
		return
	# Launch underlay in the sandbox 
	var sandbox := PackedStringArray()
	sandbox.append_array(["firejail", "--noprofile"])
	var blacklist := InputManager.get_managed_gamepads()
	for device in blacklist:
		sandbox.append("--blacklist=%s" % device)
	sandbox.append("--")
	sandbox.append_array(args)
	sandbox.append_array([">", "~/.steam-stdout.log"])
	var sandbox_cmd = " ".join(sandbox)
	print("Sandbox cmd: ", sandbox_cmd)
	OS.create_process("bash", ["-c", sandbox_cmd])
	
	if not "steam" in args:
		return
		
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
				print("Found steam! ", steam_window_id)
				break
		# Wait a bit to reduce cpu load.
		OS.delay_msec(1000)

	var exit_timer := Timer.new()
	exit_timer.set_one_shot(false)
	exit_timer.set_timer_process_callback(Timer.TIMER_PROCESS_IDLE)
	exit_timer.timeout.connect(_check_exit)
	add_child(exit_timer)
	exit_timer.start()


func _on_qam_open(_from: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)
	Gamescope.set_external_overlay(qam_window_id, 1, display)
	Gamescope.set_app_id(qam_window_id, 769, display)


func _on_qam_closed(_to: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)
	Gamescope.set_external_overlay(qam_window_id, 0, display)
	Gamescope.set_app_id(qam_window_id, 7420, display)


func _check_exit() -> void:
	if Gamescope.has_xprop(steam_window_id, "STEAM_OVERLAY", display):
		return
	print("Steam closed. Shutting down.")
	get_tree().quit()
