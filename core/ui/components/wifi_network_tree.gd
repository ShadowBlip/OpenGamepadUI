extends Tree

const thread := preload("res://core/systems/threading/thread_pool.tres")

## Emitted when a password is needed to connect. The given callable should be
## invoked by a listener with the password. E.g. callback.call(password)
signal challenge_required(callback: Callable)
signal refresh_started
signal refresh_completed

var connecting := false
var logger := Log.get_logger("WifiNetworkTree")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not NetworkManager.supports_network():
		logger.warn("Network management not supported")
		return

	thread.start()
	visibility_changed.connect(refresh_networks)
	item_activated.connect(_on_wifi_selected)
	create_item()
	refresh_networks()


func _on_wifi_selected() -> void:
	var item := get_selected()
	var ssid := item.get_text(1)
	network_connect("", ssid)


## Connect to the given wireless network
func network_connect(password: String, ssid: String) -> void:
	if connecting:
		logger.info("Already trying to connect")
		return
	logger.info("Connecting to SSID: " + ssid)
	connecting = true

	var item := get_selected()
	var connect_ap := func() -> int:
		return NetworkManager.connect_access_point(ssid)
	item.set_text(4, "Connecting")
	var code := await thread.exec(connect_ap) as int

	connecting = false
	if code == OK:
		logger.info("Successfully connected to " + ssid)
		refresh_networks()
		return

	# If we fail to connect, open a wifi challenge
	logger.info("Wifi challenge required")
	item.set_text(4, "Unable to connect")
	challenge_required.emit(network_connect.bind(ssid))


## Refreshes the available wifi networks
func refresh_networks() -> void:
	logger.info("Refreshing wifi networks")
	refresh_started.emit()
	# Fetch all the available access points from NetworkManager
	var tree := self as Tree
	var root := tree.get_root()
	var access_points: Array[NetworkManager.WifiAP]
	var get_aps := func() -> Array[NetworkManager.WifiAP]:
		return NetworkManager.get_access_points()
	access_points = await thread.exec(get_aps)

	# Create an array of BSSIDs from our access points
	var bssids := []
	for ap in access_points:
		bssids.append(ap.bssid)

	# Look at the current tree items to see if any need to be removed
	var tree_bssids := {}
	for item in root.get_children():
		var bssid := item.get_metadata(0) as String
		if bssid in bssids:
			tree_bssids[bssid] = item
			continue
		root.remove_child(item)

	# Look at the current APs to see if any tree items need to be created
	# or updated
	for ap in access_points:
		var item: TreeItem
		if ap.bssid in tree_bssids:
			item = tree_bssids[ap.bssid]
		else:
			item = tree.create_item(root)
		item.set_metadata(0, ap.bssid)
		item.set_icon(0, NetworkManager.get_strength_texture(ap.strength))
		item.set_text(1, ap.ssid)
		item.set_text(2, ap.security)
		item.set_text(3, ap.rate)
		if ap.in_use:
			item.set_text(4, "Connected")
		else:
			item.set_text(4, "")
	
	logger.info("Refresh completed")
	refresh_completed.emit()
