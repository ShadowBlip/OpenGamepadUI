extends Control

var SettingsManager := load("res://core/global/settings_manager.tres") as SettingsManager
var NotificationManager := load("res://core/global/notification_manager.tres") as NotificationManager
var Version := load("res://core/global/version.tres") as Version
var Platform := load("res://core/global/platform.tres") as Platform
var update_available := false
var update_installed := false
var logger := Log.get_logger("GeneralSettings")

@onready var updater := $SoftwareUpdater as SoftwareUpdater
@onready var update_timer := $UpdateTimer as Timer
@onready var auto_update_toggle := $%AutoUpdateToggle
@onready var check_update_button := $%CheckUpdateButton
@onready var update_button := $%UpdateButton
@onready var max_recent_slider := $%MaxRecentAppsSlider
@onready var client_version_text := $%ClientVersionText
@onready var os_text := $%OSText
@onready var product_text := $%ProductText
@onready var vendor_text := $%VendorText


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set system info text
	client_version_text.text = "v{0}".format([str(Version.core)])
	os_text.text = Platform.os_info.pretty_name
	product_text.text = Platform.get_product_name()
	vendor_text.text = Platform.get_vendor_name()
	
	# Configure home menu
	var max_recent := SettingsManager.get_value("general.home", "max_home_items", 10) as int
	max_recent_slider.value = max_recent

	# Configure check updates
	var on_check_updates := func():
		check_update_button.disabled = true
		updater.check_for_updates()
		var available := await updater.update_available as bool
		check_update_button.disabled = false
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
		updater.install_update(updater.update_pack_url, updater.update_pack_signature_url)
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
	updater.install_update(updater.update_pack_url, updater.update_pack_signature_url)
	var status := await updater.update_installed as int
	if status == OK:
		update_installed = true
		return
	update_button.disabled = false
