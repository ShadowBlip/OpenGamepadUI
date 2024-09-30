extends Control

## Reference to the bluetooth service instance
var bluetooth := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluezInstance
## List of discovered bluetooth adapters
var adapters := bluetooth.get_adapters() # TODO: allow choosing adapter
## Currently used bluetooth adapter
var adapter: BluetoothAdapter
## Map of DBus path of bluetooth device to its tree item.
## E.g. {"/org/bluez/dev_XX_XX_XX_XX_XX": <TreeItem>}
var tree_items := {}
var logger := Log.get_logger("BluetoothMenu")

@onready var enabled_toggle := $%EnableToggle as Toggle
@onready var discover_toggle := $%DiscoverToggle as Toggle
@onready var tree := $%Tree as Tree
@onready var container_avail := $%AvailableContainer as Control
@onready var container_unavail := $%UnavailableContainer as Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Configure the tree with a root node and column titles
	tree.create_item()
	tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)
	tree.set_column_title(1, "Name")
	tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	tree.set_column_title(2, "Address")
	tree.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
	tree.set_column_title(3, "Paired")
	tree.set_column_title_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)
	tree.set_column_title(4, "Connected")
	tree.set_column_title_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)
#	tree.set_column_title(5, "Signal Strength")
#	tree.set_column_title_alignment(5, HORIZONTAL_ALIGNMENT_CENTER)

	# Configure menu when bluetooth starts up or stops
	bluetooth.started.connect(_on_bluetooth_started)
	bluetooth.stopped.connect(_on_bluetooth_stopped)

	# Configure the initial menu state
	if _supports_bluetooth():
		_on_bluetooth_started()
	else:
		_on_bluetooth_stopped()

	# Connect signals
	visibility_changed.connect(_on_visibility_changed)
	enabled_toggle.toggled.connect(_on_enable)
	discover_toggle.toggled.connect(_on_discover)
	tree.item_activated.connect(_on_item_activated)


## Returns whether or not the bluez service is running and bluetooth adapters are found
func _supports_bluetooth() -> bool:
	if not bluetooth.is_running():
		return false
	if bluetooth.get_adapters().size() == 0:
		return false
	return true


## Invoked whenever the bluetooth service has started
func _on_bluetooth_started() -> void:
	logger.info("Bluetooth started")
	adapters = bluetooth.get_adapters()
	if not adapters.is_empty():
		adapter = adapters[0] as BluetoothAdapter

	# Listen for devices being added/removed
	bluetooth.device_added.connect(_on_device_added)
	bluetooth.device_removed.connect(_on_device_removed)

	# Set the initial toggled states
	if adapter:
		enabled_toggle.button_pressed = adapter.powered
		discover_toggle.button_pressed = adapter.discovering
	else:
		enabled_toggle.button_pressed = false
		discover_toggle.button_pressed = false

	# Perform initial device discovery
	var devices := bluetooth.get_discovered_devices()
	for device in devices:
		_on_device_added(device)

	_on_visibility_changed()


## Invoked whenever the bluetooth service has stopped
func _on_bluetooth_stopped() -> void:
	logger.info("Bluetooth stopped")
	adapters.clear()
	adapter = null
	var root := tree.get_root()
	for dbus_path in tree_items.keys():
		var item := tree_items[dbus_path] as TreeItem
		root.remove_child(item)
	tree_items.clear()

	# Disconnect signals
	if bluetooth.device_added.is_connected(_on_device_added):
		bluetooth.device_added.disconnect(_on_device_added)
	if bluetooth.device_removed.is_connected(_on_device_removed):
		bluetooth.device_removed.disconnect(_on_device_removed)

	_on_visibility_changed()


## Invoked when the menu becomes visible
func _on_visibility_changed():
	if not is_visible_in_tree():
		# Disable discovery if not visible
		if adapter and discover_toggle.button_pressed:
			adapter.stop_discovery()
		return
	
	# Show/hide parts of the menu if bluetooth is available
	var supports_bluetooth := _supports_bluetooth()
	container_unavail.visible = not supports_bluetooth
	container_avail.visible = supports_bluetooth
	if not supports_bluetooth:
		return

	if adapter:
		enabled_toggle.button_pressed = adapter.powered
		discover_toggle.button_pressed = adapter.discovering


## Invoked when the enabled toggle is toggled
func _on_enable(toggled: bool) -> void:
	if not adapter:
		return
	adapter.powered = toggled


## Invoked when the discover toggle is toggled
func _on_discover(toggled: bool) -> void:
	if not adapter:
		logger.warn("No bluetooth adapter found to start discovery")
		return
	if toggled:
		adapter.start_discovery()
		return
	adapter.stop_discovery()


## Invoked when the discovery timer times out
func _on_timer_timeout() -> void:
	var discovered := bluetooth.get_discovered_devices()

	# Add tree items for each discovered device
	var addresses := []
	var root := tree.get_root()
	for device in discovered:
		var device_name := device.name
		var address := device.address
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
		item.set_metadata(0, device)
		_on_device_updated(item)
		device.updated.connect(_on_device_updated.bind(item))
		
		# Add the item
		tree_items[address] = item

	# Remove any tree items that no longer exist
	for address in tree_items.keys():
		if address in addresses:
			continue
		var item := tree_items[address] as TreeItem
		root.remove_child(item)
		tree_items.erase(address)


func _on_device_added(device: BluetoothDevice) -> void:
	var device_name := device.name
	var address := device.address
	var dbus_path := device.dbus_path
	logger.debug("Discovered device:", address)
	
	# Skip this device if it was already discovered
	if dbus_path in tree_items:
		return
	
	# Skip this device if it has no name
	if device_name == "":
		return

	# Create a tree item for this device
	var root := tree.get_root()
	var item := root.create_child()
	item.set_metadata(0, device)
	_on_device_updated(item)
	device.updated.connect(_on_device_updated.bind(item))

	# Add the item
	tree_items[dbus_path] = item


## Invoked whenever a bluetooth device has been removed
func _on_device_removed(dbus_path: String) -> void:
	if not dbus_path in tree_items:
		return
	var item := tree_items[dbus_path] as TreeItem
	var root := tree.get_root()
	root.remove_child(item)
	tree_items.erase(dbus_path)


## Invoked whenever a bluetooth device has property changes
func _on_device_updated(item: TreeItem) -> void:
	var device := item.get_metadata(0) as BluetoothDevice
	var device_name := device.name
	var address := device.address
	var paired := device.paired
	var connected := device.connected
	var icon := device.icon
	
	item.set_text(1, device_name)
	item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text(2, address)
	item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text(3, "Yes" if paired else "No")
	item.set_text_alignment(3, HORIZONTAL_ALIGNMENT_CENTER)
	item.set_text(4, "Yes" if connected else "No")
	item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)
	#item.set_text(4, "")
	#item.set_text_alignment(4, HORIZONTAL_ALIGNMENT_CENTER)
	
	# Set the icon
	var texture: Texture2D = load("res://assets/editor-icons/bluetooth.svg")
	match icon:
		"input-gaming":
			texture = load("res://assets/ui/icons/gamepad-bold.svg")
		"audio-headphones":
			texture = load("res://assets/ui/icons/headphones.svg")
	item.set_icon(0, texture)
	item.set_icon_max_width(0, 24)
	item.set_text_alignment(0, HORIZONTAL_ALIGNMENT_CENTER)


## Invoked when the user selects a bluetooth device from the tree view
func _on_item_activated() -> void:
	var selected := tree.get_selected()
	var device := selected.get_metadata(0) as BluetoothDevice
	
	# Disconnect if already connected
	if device.connected:
		selected.set_text(4, "Disconnecting")
		device.disconnect_from()
		return
	
	# Try connecting to the device
	selected.set_text(4, "Connecting")
	device.connect_to()
