extends Control

# Plugin "mods"
# https://blog.cy.md/2022/05/27/modding-for-godot/
# We can load plugins from user://plugins
# This normally resolves to: ~/.local/share/godot/app_userdata/Open Gamepad UI/plugins

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
#  images:
#	poster: foo.png

# Storage Manager
#  Lets plugins determine where to install things

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
	
	# Subscribe to state changes
	var state_manager: StateManager = $StateManager
	state_manager.state_changed.connect(_on_state_changed)

# Handle state changes
func _on_state_changed(from: int, to: int):
	# Hide all menus when in-game
	if to == StateManager.State.IN_GAME:
		for child in $UIContainer.get_children():
			child.visible = false
		return
	
	# Display all menus?
	for child in $UIContainer.get_children():
		child.visible = true
	return

# Look in XDG_APP_PATH for .desktop files
func _discover_apps() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
