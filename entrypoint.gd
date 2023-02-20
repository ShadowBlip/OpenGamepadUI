extends Node

const Gamescope := preload("res://core/global/gamescope.tres")
const InputManager := preload("res://core/global/input_manager.tres")
var qam_state = load("res://assets/state/states/quick_access_menu.tres")

var display := Gamescope.XWAYLAND.OGUI
var qam_window_id: int
var pid: int
var steam_window_id: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().get_root().transparent_bg = true

	var args := OS.get_cmdline_args()
	if "--qam-only" in args or "--only-qam" in args:
		_setup_qam_only()
		return

	# Launch the main interface
	get_tree().change_scene_to_file("res://core/main.tscn")


func _setup_qam_only() -> void:
	# Setup input manager
	var input_scene := load("res://core/systems/input/qam_input_manager.tscn") as PackedScene
	add_child(input_scene.instantiate())

	# Add the QAM
	var qam_scene := load("res://core/ui/menu/qam/quick_access_menu.tscn") as PackedScene
	var qam := qam_scene.instantiate()
	add_child(qam)
	qam.remove_child(qam.get_node("BackInputHandler"))

	pid = OS.get_process_id()
	qam_window_id = Gamescope.get_window_id(pid, display)

	# Find Steam in the display tree
	var root_win_id := Gamescope.get_root_window_id(display)
	var all_windows := Gamescope.get_all_windows(root_win_id, display)
	for window in all_windows:
		if window == qam_window_id:
			continue
		if Gamescope.has_xprop(window, "STEAM_OVERLAY", display):
			steam_window_id = window
			break

	qam_state.state_entered.connect(_on_qam_open)
	qam_state.state_exited.connect(_on_qam_closed)
	
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)
	# Launch Steam in the sandbox 
	var sandbox := PackedStringArray()

	sandbox.append_array(["--noprofile"])
	var blacklist := InputManager.get_managed_gamepads()
	for device in blacklist:
		sandbox.append("--blacklist=%s" % device)
	sandbox.append("--")
	sandbox.append_array(["steam", "-gamepadui", "-steamos3", "-steampal", "-steamdeck"])
	OS.create_process("firejail", sandbox)

func _on_qam_open(_from: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.ALL)
	Gamescope.set_external_overlay(qam_window_id, 1, display)
	Gamescope.set_app_id(qam_window_id, 769, display)
#	Gamescope.set_overlay(steam_window_id, 0, display)
#	Gamescope.set_app_id(steam_window_id, 7420, display)


func _on_qam_closed(_to: State) -> void:
	InputManager._set_intercept(ManagedGamepad.INTERCEPT_MODE.PASS_QAM)
	Gamescope.set_external_overlay(qam_window_id, 0, display)
	Gamescope.set_app_id(qam_window_id, 7420, display)
#	Gamescope.set_overlay(steam_window_id, 1, display)
#	Gamescope.set_app_id(steam_window_id, 769, display)
