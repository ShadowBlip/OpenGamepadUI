extends Control

const user_themes_path := "user://themes"
const card_button_scene := preload("res://core/ui/components/card_button.tscn")
const theme_setter_scene := preload("res://core/systems/user_interface/theme_setter.tscn")

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager
var NotificationManager := load("res://core/global/notification_manager.tres") as NotificationManager
var Version := load("res://core/global/version.tres") as Version
var platform := load("res://core/global/platform.tres") as Platform
var hardware_manager := load("res://core/systems/hardware/hardware_manager.tres") as HardwareManager
var update_available := false
var update_installed := false
var logger := Log.get_logger("GeneralSettings")

@onready var updater := $SoftwareUpdater as SoftwareUpdater
@onready var update_timer := $UpdateTimer as Timer
@onready var auto_update_toggle := $%AutoUpdateToggle
@onready var check_update_button := $%CheckUpdateButton
@onready var update_button := $%UpdateButton
@onready var themes_container := $%ThemeButtonContainer
@onready var max_recent_slider := $%MaxRecentAppsSlider
@onready var platform_container := $%PlatformContainer
@onready var platform_image := $%PlatformImage
@onready var platform_name := $%PlatformNameLabel
@onready var client_version_text := $%ClientVersionText
@onready var os_text := $%OSText as SelectableText
@onready var product_text := $%ProductText as SelectableText
@onready var vendor_text := $%VendorText as SelectableText
@onready var cpu_text := $%CPUModelText as SelectableText
@onready var gpu_text := $%GPUModelText as SelectableText
@onready var driver_text := $%GPUDriverText as SelectableText
@onready var kernel_text := $%KernelVerText as SelectableText
@onready var bios_text := $%BIOSVerText as SelectableText


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set system info text
	client_version_text.text = "v{0}".format([str(Version.core)])
	os_text.text = platform.os_info.pretty_name
	product_text.text = hardware_manager.get_product_name()
	vendor_text.text = hardware_manager.get_vendor_name()
	if hardware_manager.cpu:
		cpu_text.text = hardware_manager.cpu.model
	if hardware_manager.gpu:
		gpu_text.text = hardware_manager.gpu.model
		driver_text.text = hardware_manager.gpu.driver
	kernel_text.text = hardware_manager.get_kernel_version()
	bios_text.text = hardware_manager.get_bios_version()
	
	# Try to detect the platform and platform image
	if product_text.text == "Jupiter" and vendor_text.text == "Valve":
		platform_image.texture = load("res://assets/images/platform/steamdeck.png")
		platform_name.text = "Steam Deck"
	else:
		platform_container.visible = false

	# Add user theme selection buttons
	_add_user_themes()

	# Configure home menu
	var max_recent := SettingsManager.get_value("general.home", "max_home_items", 10) as int
	max_recent_slider.value = max_recent

	# Configure check updates
	var on_check_updates := func():
		var check_update_text := check_update_button.text as String
		check_update_button.text = "Checking..."
		check_update_button.disabled = true
		updater.check_for_updates()
		var available := await updater.update_available as bool
		check_update_button.disabled = false
		check_update_button.text = check_update_text
		if not available:
			var notify := Notification.new("Client is already up to date")
			NotificationManager.show(notify)
			return
		var notify := Notification.new("New client update is available")
		NotificationManager.show(notify)
		update_available = true
		update_button.disabled = false
	check_update_button.pressed.connect(on_check_updates)

	# Configure install update
	var on_install_update := func():
		update_button.disabled = true
		updater.install_update(updater.update_pack_url)
		var status := await updater.update_installed as int
		if status == OK:
			var notify := Notification.new("Client update installed successfully")
			NotificationManager.show(notify)
			update_installed = true
			return
		update_button.disabled = false
		var notify := Notification.new("Failed to install client update")
		NotificationManager.show(notify)
	update_button.pressed.connect(on_install_update)

	# Configure auto updates
	var auto_update := SettingsManager.get_value("general.updates", "auto_update", false) as bool
	auto_update_toggle.button_pressed = auto_update
	var on_auto_update_toggled := func(toggled: bool):
		SettingsManager.set_value("general.updates", "auto_update", toggled)
		if toggled:
			update_timer.start()
		else:
			update_timer.stop()
	auto_update_toggle.toggled.connect(on_auto_update_toggled)
	update_timer.timeout.connect(_on_autoupdate)
	if auto_update:
		update_timer.start()


# Looks for user defined themes and creates buttons to select those themes
func _add_user_themes() -> void:
	# Do nothing if no themes directory exists
	if not DirAccess.dir_exists_absolute(user_themes_path):
		logger.debug("No user themes found in: " + user_themes_path)
		return
	
	# Discover theme resources
	var theme_files := DirAccess.get_files_at(user_themes_path)
	for filename in theme_files:
		var path := "/".join([user_themes_path, filename])
		logger.debug("Discovered possible user theme: " + path)
		
		# Load and validate the theme
		var user_theme := load(path)
		if not user_theme is Theme:
			logger.warn("Unable to load theme resource: " + path)
			continue
		var theme_name := user_theme.get_meta("name", "") as String
		if theme_name == "":
			logger.warn("Theme does not have required 'name' metadata field: " + path)
			continue
		
		# Build the theme switcher button
		var button := card_button_scene.instantiate() as CardButton
		button.text = theme_name
		button.custom_minimum_size.x = 158
		
		# Add the theme setter behavior
		var theme_setter := theme_setter_scene.instantiate() as ThemeSetter
		theme_setter.theme = user_theme
		theme_setter.on_signal = "button_up"
		button.add_child(theme_setter)

		# Add the button to the settings menu
		themes_container.add_child(button)
		logger.debug("Add user theme: " + theme_name)


func _on_autoupdate() -> void:
	logger.info("Automatically checking for updates...")
	check_update_button.disabled = true
	updater.check_for_updates()
	var available := await updater.update_available as bool
	check_update_button.disabled = false
	if not available:
		logger.info("No new updates available")
		return

	logger.info("New update was found. Trying to install it.")
	update_button.disabled = true
	updater.install_update(updater.update_pack_url)
	var status := await updater.update_installed as int
	if status == OK:
		update_installed = true
		return
	update_button.disabled = false
