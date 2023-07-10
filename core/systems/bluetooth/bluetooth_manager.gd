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
	return dbus.bus_exists(BLUEZ_BUS)


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
	signal updated
	var _proxy: DBusManager.Proxy
	var address: String:
		get:
			var property = _proxy.get_property(IFACE_ADAPTER, "Address")
			if not property is String:
				return ""
			return property
	var name: String:
		get:
			var property = _proxy.get_property(IFACE_ADAPTER, "Name")
			if not property is String:
				return ""
			return property
	var powered: bool:
		set(v):
			_proxy.set_property(IFACE_ADAPTER, "Powered", v)
		get:
			var property = _proxy.get_property(IFACE_ADAPTER, "Powered")
			if not property is bool:
				return false
			return property
	var discovering: bool:
		get:
			var property = _proxy.get_property(IFACE_ADAPTER, "Discovering")
			if not property is bool:
				return false
			return property

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	func start_discovery() -> void:
		_proxy.call_method(IFACE_ADAPTER, "StartDiscovery")
	
	func stop_discovery() -> void:
		_proxy.call_method(IFACE_ADAPTER, "StopDiscovery")


## Container for a bluetooth device
## https://github.com/luetzel/bluez/blob/master/doc/device-api.txt
class Device:
	signal connection_changed(is_connected: bool)
	signal paired_changed(is_paired: bool)
	signal updated
	var _proxy: DBusManager.Proxy
	var adapter: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Adapter")
			if not property is String:
				return ""
			return property
	var address: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Address")
			if not property is String:
				return ""
			return property
	var alias: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Alias")
			if not property is String:
				return ""
			return property
	var name: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Name")
			if not property is String:
				return ""
			return property
	var icon: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Icon")
			if not property is String:
				return ""
			return property
	var paired: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Paired")
			if not property is bool:
				return false
			return property
	var connected: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Connected")
			if not property is bool:
				return false
			return property
	var trusted: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Trusted")
			if not property is bool:
				return false
			return property
	var blocked: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Blocked")
			if not property is bool:
				return false
			return property

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()
		if "Connected" in props:
			connection_changed.emit(props["Connected"])
		if "Paired" in props:
			paired_changed.emit(props["Paired"])

	func connect_to() -> void:
		_proxy.call_method(IFACE_DEVICE, "Connect")
	
	func disconnect_from() -> void:
		_proxy.call_method(IFACE_DEVICE, "Disconnect")

	func connect_profile(uuid: String) -> void:
		_proxy.call_method(IFACE_DEVICE, "ConnectProfile", [uuid], "s")

	func disconnect_profile(uuid: String) -> void:
		_proxy.call_method(IFACE_DEVICE, "DisconnectProfile", [uuid], "s")

	func pair() -> void:
		_proxy.call_method(IFACE_DEVICE, "Pair")

	func cancel_pairing() -> void:
		_proxy.call_method(IFACE_DEVICE, "CancelPairing")
