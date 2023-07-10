extends Control

var bluetooth := load("res://core/systems/bluetooth/bluetooth_manager.tres") as BluetoothManager
var adapter := bluetooth.get_adapter() # TODO: allow choosing adapter
var tree_items := {}
var logger := Log.get_logger("BluetoothMenu")

@onready var timer := $%DiscoverTimer as Timer
@onready var enabled_toggle := $%EnableToggle as Toggle
@onready var discover_toggle := $%DiscoverToggle as Toggle
@onready var tree := $%Tree as Tree
@onready var container_avail := $%AvailableContainer as Control
@onready var container_unavail := $%UnavailableContainer as Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the initial toggled states
	enabled_toggle.button_pressed = adapter.powered
	discover_toggle.button_pressed = adapter.discovering
	
	# Connect signals
	visibility_changed.connect(_on_visibility_changed)
	enabled_toggle.toggled.connect(_on_enable)
	discover_toggle.toggled.connect(_on_discover)
	timer.timeout.connect(_on_timer_timeout)
	tree.item_activated.connect(_on_item_activated)
	
	# Configure the tree
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


## Invoked when the menu becomes visible
func _on_visibility_changed():
	if not is_visible_in_tree():
		# Disable discovery if not visible
		if discover_toggle.button_pressed:
			adapter.stop_discovery()
		return
	
	# Show/hide parts of the menu if bluetooth is available
	var supports_bluetooth := bluetooth.supports_bluetooth()
	container_unavail.visible = not supports_bluetooth
	container_avail.visible = supports_bluetooth
	if not supports_bluetooth:
		return

	_on_timer_timeout()
	enabled_toggle.button_pressed = adapter.powered
	discover_toggle.button_pressed = adapter.discovering


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
	
	# Disconnect if already connected
	if device.connected:
		device.disconnect_from()
		return
	
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
		var paired := device.paired
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


func _on_device_updated(item: TreeItem) -> void:
	var device := item.get_metadata(0) as BluetoothManager.Device
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
