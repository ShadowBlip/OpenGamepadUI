extends Tree
class_name WifiNetworkTree

var network_manager := load("res://core/systems/network/network_manager.tres") as NetworkManagerInstance

## Emitted when a password is needed to connect. The given callable should be
## invoked by a listener with the password. E.g. callback.call(password)
signal challenge_required(callback: Callable)
signal refresh_started
signal refresh_completed

var connecting := false
var logger := Log.get_logger("WifiNetworkTree")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_root = true
	columns = 5
	select_mode = SELECT_ROW
	scroll_horizontal_enabled = false
	if not network_manager.is_running():
		logger.warn("NetworkManager is not running")

	# Adjust column sizes
	set_column_expand(0, false)
	set_column_expand(2, false)

	visibility_changed.connect(refresh_networks)
	item_activated.connect(_on_wifi_selected)
	create_item()
	refresh_networks()


func _on_wifi_selected() -> void:
	var item := get_selected()
	var ssid := item.get_metadata(0) as String
	var has_security := item.get_metadata(2) as bool
	if has_security:
		challenge_required.emit(network_connect.bind(ssid))
		return
	network_connect("", ssid)


## Connect to the given wireless network
func network_connect(password: String, ssid: String) -> void:
	if connecting:
		logger.info("Already trying to connect")
		return
	logger.info("Connecting to SSID: " + ssid)
	connecting = true

	# Find the wireless device
	var devices := network_manager.get_devices()
	var wifi_devices := devices.filter(func(device: NetworkDevice): return device.wireless != null)
	if wifi_devices.is_empty():
		logger.warn("No wifi devices found")
		connecting = false
		return
	var device := wifi_devices[0] as NetworkDevice
	
	# Find the access point to connect to
	var access_points := device.wireless.access_points
	var valid_access_points := access_points.filter(func(ap: NetworkAccessPoint): return ap.ssid == ssid)
	if valid_access_points.is_empty():
		logger.warn("Unable to find access point with SSID:", ssid)
		connecting = false
		return
	var access_point := valid_access_points[0] as NetworkAccessPoint
	
	# Try to connect to the access point
	access_point.connect(device, password)
	
	# Update the tree item's status
	var item := get_selected()
	item.set_text(4, "Connecting")

	# Wait for the connection to be established
	for i in range(60):
		logger.info("Device state: " + str(device.state))
		match device.state:
			device.NM_DEVICE_STATE_ACTIVATED:
				logger.info("Successfully connected to", ssid)
				item.set_text(4, "Connected")
				connecting = false
				refresh_networks()
				return
			device.NM_DEVICE_STATE_NEED_AUTH:
				logger.info("Authentication required")
				item.set_text(4, "Authentication required")
				connecting = false
				challenge_required.emit(network_connect.bind(ssid))
				return
			device.NM_DEVICE_STATE_CONFIG:
				logger.info("Connecting...")
				item.set_text(4, "Connecting")
			device.NM_DEVICE_STATE_IP_CONFIG:
				logger.info("Acquiring IP address...")
				item.set_text(4, "Acquiring IP address")
			device.NM_DEVICE_STATE_DEACTIVATING:
				logger.info("Deactivation connection...")
				item.set_text(4, "Deactivating connection")
			device.NM_DEVICE_STATE_DISCONNECTED:
				logger.info("Disconnected")
				item.set_text(4, "Disconnected")
				connecting = false
				return
			device.NM_DEVICE_STATE_FAILED:
				logger.info("Failed to connect")
				item.set_text(4, "Failed to connect")
				connecting = false
				return
		# Use a timer to wait between tries
		await get_tree().create_timer(0.5).timeout

	connecting = false
	logger.info("Timed out waiting to connect")
	item.set_text(4, "Failed to connect")


## Refreshes the available wifi networks
func refresh_networks() -> void:
	logger.info("Refreshing wifi networks")
	refresh_started.emit()

	# Find the wireless device
	var devices := network_manager.get_devices()
	var wifi_devices := devices.filter(func(device: NetworkDevice): return device.wireless != null)
	if wifi_devices.is_empty():
		logger.warn("No wifi devices found")
		return
	var device := wifi_devices[0] as NetworkDevice
	
	# Request a scan
	device.wireless.request_scan()
	await get_tree().create_timer(0.5).timeout
	
	# Fetch all the available access points
	var tree := self as Tree
	var root := tree.get_root()
	var access_points := device.wireless.access_points

	# Create an array of BSSIDs from our access points
	var bssids := []
	for ap in access_points:
		bssids.append(ap.ssid)

	# Look at the current tree items to see if any need to be removed
	var tree_bssids := {}
	for item in root.get_children():
		var bssid := item.get_metadata(0) as String
		if bssid in bssids:
			tree_bssids[bssid] = item
			continue
		root.remove_child(item)

	var active_ap := device.wireless.active_access_point

	# Look at the current APs to see if any tree items need to be created
	# or updated
	for ap in access_points:
		await get_tree().create_timer(0.1).timeout # help spread out sync data fetching
		var item: TreeItem
		if ap.ssid in tree_bssids:
			item = tree_bssids[ap.ssid]
		else:
			item = tree.create_item(root)

		# Determine the security used for the access point
		var has_security := ap.flags > ap.NM_802_11_AP_SEC_NONE
		var security_texture: Texture2D
		if has_security:
			security_texture = load("res://assets/ui/icons/material-symbols--lock.svg")
		
		var bitrate = (ap.max_bitrate / 1024.0)
		bitrate = int(round(bitrate))

		item.set_metadata(0, ap.ssid)
		item.set_icon(0, NetworkManager.get_strength_texture(ap.strength))
		item.set_text(1, ap.ssid)
		item.set_icon(2, security_texture)
		item.set_icon_max_width(2, 16)
		item.set_expand_right(2, false)
		item.set_metadata(2, has_security)
		item.set_text(3, str(bitrate) + " Mb/s")
		if active_ap and active_ap.ssid == ap.ssid:
			item.set_text(4, "Connected")
		else:
			item.set_text(4, "")
	
	logger.info("Refresh completed")
	refresh_completed.emit()
