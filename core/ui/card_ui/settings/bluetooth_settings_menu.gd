extends Control

var bluetooth := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager
var adapter := bluetooth.get_adapter() # TODO: allow choosing adapter
var tree_items := {}
var logger := Log.get_logger("BluetoothMenu")

@onready var timer := $%DiscoverTimer as Timer
@onready var enabled_toggle := $%EnableToggle as Toggle
@onready var discover_toggle := $%DiscoverToggle as Toggle
@onready var tree := $%Tree as Tree

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the initial toggled states
	enabled_toggle.button_pressed = adapter.powered
	discover_toggle.button_pressed = adapter.discovering
	
	# Connect signals
	enabled_toggle.toggled.connect(_on_enable)
	discover_toggle.toggled.connect(_on_discover)
	timer.timeout.connect(_on_timer_timeout)
	tree.item_activated.connect(_on_item_activated)
	
	# Configure the tree
	tree.create_item()
	tree.set_column_title(0, "Device")
	tree.set_column_title(1, "Status")


## Invoked when the enabled toggle is toggled
func _on_enable(toggled: bool) -> void:
	adapter.powered = toggled


## Invoked when the discover toggle is toggled
func _on_discover(toggled: bool) -> void:
	if toggled:
		timer.start()
		adapter.start_discovery()
		return
	timer.stop()
	adapter.stop_discovery()


## Invoked when the user selects a bluetooth device from the tree view
func _on_item_activated() -> void:
	var selected := tree.get_selected()
	var device := selected.get_metadata(0) as BluetoothManager.Device
	
	# Do nothing if already connected
	if device.connected:
		return
	
	# Update the UI when connected
	selected.set_text(1, "Connecting")
	var on_connected := func(connected: bool):
		if connected:
			selected.set_text(1, "Connected")
			return
		selected.set_text(1, "")
	device.connection_changed.connect(on_connected)
	
	# Try connecting to the device
	device.connect_to()


## Invoked when the discovery timer times out
func _on_timer_timeout() -> void:
	var discovered := bluetooth.get_discovered_devices()

	# Add tree items for each discovered device
	var addresses := []
	var root := tree.get_root()
	for device in discovered:
		var device_name := device.name
		var address := device.address
		var connected := device.connected
		addresses.append(address)
		logger.debug("Discovered device: " + address)
		
		# Skip this device if it was already discovered
		if address in tree_items:
			continue
		
		# Skip this device if it has no name
		if device_name == "":
			continue

		# Create a tree item for this device
		var item := root.create_child()
		item.set_text(0, "{0} ({1})".format([device_name, address]))
		item.set_text(1, "Connected" if connected else "")
		item.set_metadata(0, device)
		
		# Add the item
		tree_items[address] = item

	# Remove any tree items that no longer exist
	for address in tree_items.keys():
		if address in addresses:
			continue
		var item := tree_items[address] as TreeItem
		root.remove_child(item)
		tree_items.erase(address)
