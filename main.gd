extends Control

# We need:
# - "Shortcut" structure
# - Plugin Store
# - Ability to foreground the overlay
# - Main menu

# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	pass # Replace with function body.
	var pid = OS.create_process("bash", ["-c", "DISPLAY=:3 vkcube"])
	#var pid = OS.create_process("bash", ["-c", "DISPLAY=:3 steam steam://rungameid/219740"])
	#var pid = OS.create_process("bash", ["-c", "DISPLAY=:3 xdg-open heroic://launch/4f272a49a39742b795d63e1f483a7c7d"])
	print("PID: ", pid)

# Look in XDG_APP_PATH for .desktop files
func _discover_apps() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
