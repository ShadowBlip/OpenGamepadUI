extends Control

const system_thread := preload("res://core/systems/threading/system_thread.tres")

var bluetooth_manager := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager
var connecting := false
var discovered_devices: Array[BluetoothManager.BluetoothDevice] = []
var discovered_controllers: Array[BluetoothManager.ControllerDevice] = []
var scan_enabled = false

@onready var no_net_label := $%NoBluetoothLabel
@onready var bt_tree := $%BluetoothDeviceTree as Tree
@onready var autoconnect_toggle := $%AutoconnectToggle
@onready var enable_toggle := $%EnableToggle
@onready var scan_toggle := $%ScanToggle

var logger := Log.get_logger("BluetoothSettings", Log.LEVEL.DEBUG)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var result = await bluetooth_manager.start(enable_toggle.button_pressed)
	if not bluetooth_manager.supports_bluetooth():
		no_net_label.visible = true
		return
	visibility_changed.connect(_on_visible_changed)
	bt_tree.item_activated.connect(_on_bt_selected)
	bt_tree.create_item()
	bluetooth_manager.devices_updated.connect(_on_refresh_devices)
	bluetooth_manager.controllers_updated.connect(_on_refresh_controllers)
	bluetooth_manager.scan_completed.connect(_on_scan_completed)
	scan_toggle.toggled.connect(_on_toggle_scan)
	enable_toggle.toggled.connect(_on_toggle_enabled)
	_set_bt_tree_titles()
	_on_visible_changed()
	if autoconnect_toggle.button_pressed:
		_connect_known_devices()


func _on_scan_completed() -> void:
	logger.info("Scan complete! Should we do this again? " + str(scan_enabled))
	if scan_enabled:
		logger.info("Scanning still enabled. Starting another scan.")
		_on_toggle_scan(scan_enabled)


func _set_bt_tree_titles() -> void:
	bt_tree.set_column_title(0, "MAC Address")
	bt_tree.set_column_title(1, "Name")
	bt_tree.set_column_title(2, "Paired")
	bt_tree.set_column_title(3, "Connected")
	bt_tree.set_column_title(4, "Signal Strength")


func _connect_known_devices() -> void:
	logger.info("_connect_known_devices")


func _on_visible_changed() -> void:
	logger.info("_on_visible_changed")
	for device in discovered_devices:
		logger.info(str(device.mac_address) + " | " + str(device.name) + " | " + str(device.signal_strength) + " | " + str(device.connected) + " | " + str(device.paired))


# Do a popup for pair/unpair connect/disconnect
func _on_bt_selected() -> void:
	logger.info("_on_bt_selected")


func _on_toggle_enabled(_pressed: bool) -> void:
	logger.info("_on_toggle_enabled")


func _on_refresh_devices(devices: Array[BluetoothManager.BluetoothDevice]) -> void:
	logger.info("_on_discovered_devices")
	discovered_devices = devices
	for device in discovered_devices:
		logger.info(str(device.mac_address) + " | " + str(device.name) + " | " + str(device.signal_strength) + " | " + str(device.connected) + " | " + str(device.paired))


	# Fetch all the available access points from NetworkManager
	var tree := bt_tree as Tree
	var root := tree.get_root()

	# Look at the current tree items to see if any need to be removed
	var tree_macs := {}
	for item in root.get_children():
		var mac := item.get_metadata(0) as String
		if mac in tree_macs:
			tree_macs[mac] = item
			continue
		root.remove_child(item)

	# Look at the current APs to see if any tree items need to be created
	# or updated
	for device in devices:
		var item: TreeItem

		if device.mac_address in tree_macs:
			item = tree_macs[device.mac_address]
		else:
			item = tree.create_item(root)
		item.set_metadata(0, device.mac_address)
		item.set_text(0, device.mac_address)
		item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text(1, device.name)
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text(2, str(device.paired))
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text(3, str(device.connected))
		item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)
		item.set_text(4, str(device.signal_strength))
		item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)


func _on_refresh_controllers(devices: Array[BluetoothManager.ControllerDevice]) -> void:
	logger.info("_on_discovered_controllers")
	discovered_controllers = devices
	for device in discovered_controllers:
		logger.info(str(device.mac_address) + " | " + str(device.name) + " | " + str(device.powered) + " | " + str(device.pairable) + " | " + str(device.discoverable))


func _on_toggle_scan(pressed: bool) -> void:
	logger.info("Scan enabled " + str(pressed))
	scan_enabled = pressed
	if scan_enabled == false:
		return
	bluetooth_manager.scan_devices()
