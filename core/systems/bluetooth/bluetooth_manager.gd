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


## Start discovering bluetooth devices using the given bluetooth adapter
func start_discovery(adapter_name: String = "hci0") -> int:
	var device_path := "/".join([BLUES_PREFIX, adapter_name])
	var adapter := dbus.create_proxy(BLUEZ_BUS, device_path)
	
	var result := adapter.call_method(IFACE_ADAPTER, "StartDiscovery", [])
	if not result:
		return -1
	
	return OK


## Stop discovering bluetooth devices using the given bluetooth adapter
func stop_discovery(adapter_name: String = "hci0") -> int:
	var device_path := "/".join([BLUES_PREFIX, adapter_name])
	var adapter := dbus.create_proxy(BLUEZ_BUS, device_path)
	
	var result := adapter.call_method(IFACE_ADAPTER, "StopDiscovery", [])
	if not result:
		return -1
	
	return OK


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
	


## Container for a bluetooth device
## https://github.com/luetzel/bluez/blob/master/doc/device-api.txt
class Device:
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
	var name: String:
		get:
			var properties := _proxy.get_properties(IFACE_DEVICE)
			if "Name" in properties:
				return properties["Name"]
			return ""

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
	
	func connect_to() -> void:
		_proxy.call_method(IFACE_DEVICE, "Connect")
	
	func disconnect_from() -> void:
		_proxy.call_method(IFACE_DEVICE, "Disconnect")
