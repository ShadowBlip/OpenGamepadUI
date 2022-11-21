extends Control

# We need:
# - "Shortcut" structure
# - Plugin Store
# - Ability to foreground the overlay
# - Main menu
# - Storefront?
# - Library menu
# - Home menu

# Near term:
# - Manage bluetooth
# - Audio?

# Far future
# - Friends/Chat?
# - GamepadUI Input Manager
# - Cloud saves

# Shortcuts .osf
#  shortcutId: 123
#  name: Fortnite
#  command: steam
#  args: []
#  provider: steam
#  providerAppId: 1234
#  tags: []
#  categories: []

# Store Plugin Interface
#  get_available()
#  get_installed()
#  install(game)
#  uninstall(game)

# Store Plugin
#  - Steam
#		manager.add_shortcut()
#  - Heroic
#  - Flatpak
#  - Local - look for .desktop files


# Called when the node enters the scene tree for the first time.
# gamescope --xwayland-count 2 -- build/opengamepad-ui.x86_64
func _ready() -> void:
	# Set bg to transparent
	get_tree().get_root().transparent_bg = true
	$AnimationPlayer.play("bounce")

# Look in XDG_APP_PATH for .desktop files
func _discover_apps() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	#print(event)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
