@icon("res://assets/editor-icons/bluetooth.svg")
extends Resource
class_name BluetoothManager

## BluetoothManager interfaces with the bluetooth system
##
## This class uses [DBusManager] to communicate with the bluetooth service
## over DBus.

const BLUEZ_BUS := "org.bluez"
const BLUES_PREFIX := "/org/bluez"

const IFACE_ADAPTER := "org.bluez.Adapter1"
const IFACE_DEVICE := "org.bluez.Device1"

var dbus := load("res://core/global/dbus_system.tres") as DBusManager


## Returns true if bluetooth can be used on this system
func supports_bluetooth() -> bool:
	return true


## Returns the bluetooth adapter with the given name.
func get_adapter(adapter_name: String = "hci0") -> Adapter:
	var adapter_path := "/".join([BLUES_PREFIX, adapter_name])
	var proxy := dbus.create_proxy(BLUEZ_BUS, adapter_path)
	var adapter := Adapter.new(proxy)

	return adapter


## Return a list of currently discovered devices
func get_discovered_devices() -> Array[Device]:
	var devices: Array[Device] = []
	var objects := dbus.get_managed_objects(BLUEZ_BUS, "/")
	
	# Loop through all objects on the bus
	for obj in objects:
		# Skip any DBus objects that aren't devices
		if not obj.has_interface_attr(IFACE_DEVICE, "Address"):
			continue
		
		# Create a bluetooth Device from this object
		var proxy := dbus.create_proxy(BLUEZ_BUS, obj.path)
		var device := Device.new(proxy)
		
		devices.append(device)
	
	return devices


## Container for a bluetooth adapter
## https://github.com/luetzel/bluez/blob/master/doc/adapter-api.txt
class Adapter:
	var _proxy: DBusManager.Proxy
	var address: String:
		get:
			var properties := _proxy.get_properties(IFACE_ADAPTER)
			if "Address" in properties:
				return properties["Address"]
			return ""
	var name: String:
		get:
			var properties := _proxy.get_properties(IFACE_ADAPTER)
			if "Name" in properties:
				return properties["Name"]
			return ""
	var powered: bool:
		set(v):
			_proxy.set_property(IFACE_ADAPTER, "Powered", v)
		get:
			var properties := _proxy.get_properties(IFACE_ADAPTER)
			if "Powered" in properties:
				return properties["Powered"]
			return false
	var discovering: bool:
		get:
			var properties := _proxy.get_properties(IFACE_ADAPTER)
			if "Discovering" in properties:
				return properties["Discovering"]
			return false

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
	
	func start_discovery() -> void:
		_proxy.call_method(IFACE_ADAPTER, "StartDiscovery")
	
	func stop_discovery() -> void:
		_proxy.call_method(IFACE_ADAPTER, "StopDiscovery")


## Container for a bluetooth device
## https://github.com/luetzel/bluez/blob/master/doc/device-api.txt
class Device:
	signal connection_changed(is_connected: bool)
	signal paired_changed(is_paired: bool)
	var _proxy: DBusManager.Proxy
	var adapter: String:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Adapter" in properties:
				return properties["Adapter"]
			return ""
	var address: String:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Address" in properties:
				return properties["Address"]
			return ""
	var alias: String:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Alias" in properties:
				return properties["Alias"]
			return ""
	var name: String:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Name" in properties:
				return properties["Name"]
			return ""
	var icon: String:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Icon" in properties:
				return properties["Icon"]
			return ""
	var paired: bool:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Paired" in properties:
				return properties["Paired"]
			return false
	var connected: bool:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Connected" in properties:
				return properties["Connected"]
			return false
	var trusted: bool:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Trusted" in properties:
				return properties["Trusted"]
			return false
	var blocked: bool:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Blocked" in properties:
				return properties["Blocked"]
			return false

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		if "Connected" in props:
			connection_changed.emit(props["Connected"])
		if "Paired" in props:
			paired_changed.emit(props["Paired"])

	func connect_to() -> void:
		_proxy.call_method(IFACE_DEVICE, "Connect")
	
	func disconnect_from() -> void:
		_proxy.call_method(IFACE_DEVICE, "Disconnect")

	func connect_profile(uuid: String) -> void:
		_proxy.call_method(IFACE_DEVICE, "ConnectProfile", [uuid])

	func disconnect_profile(uuid: String) -> void:
		_proxy.call_method(IFACE_DEVICE, "DisconnectProfile", [uuid])

	func pair() -> void:
		_proxy.call_method(IFACE_DEVICE, "Pair")

	func cancel_pairing() -> void:
		_proxy.call_method(IFACE_DEVICE, "CancelPairing")
