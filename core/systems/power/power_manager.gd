extends Resource
class_name PowerManager

const POWER_BUS := "org.freedesktop.UPower"
const UPOWER_PATH := "/org/freedesktop/UPower"
const POWER_PREFIX := "/org/freedesktop/UPower/devices"
const IFACE_UPOWER := "org.freedesktop.UPower"
const IFACE_DEVICE := "org.freedesktop.UPower.Device"

enum DEVICE_TYPE {
	UNKNOWN,
	LINE_POWER,
	BATTERY,
	UPS,
	MONITOR,
	MOUSE,
	KEYBOARD,
	PDA,
	PHONE,
}

enum DEVICE_STATE {
	UNKNOWN,
	CHARGING,
	DISCHARGING,
	EMPTY,
	FULLY_CHARGED,
	PENDING_CHARGE,
	PENDING_DISCHARGE,
}

enum DEVICE_WARNING_LEVEL {
	UNKNOWN,
	NONE,
	DISCHARGING,
	LOW,
	CRITICAL,
	ACTION,
}

enum DEVICE_BATTERY_LEVEL {
	UNKNOWN,
	NONE,
	LOW,
	CRITICAL,
	NORMAL,
	HIGH,
	FULL,Z
}

enum DEVICE_TECHNOLOGY {
	UNKNOWN,
	LITHIUM_ION,
	LITHIUM_POLYMER,
	LITHIUM_IRON_PHOSPHATE,
	LEAD_ACID,
	NICKLE_CADMIUM,
	NICKLE_METAL_HYDRIDE,
}

var dbus := load("res://core/global/dbus_system.tres") as DBusManager
var upower := UPower.new(dbus.create_proxy(POWER_BUS, UPOWER_PATH))


func get_devices() -> Array[Device]:
	var devices: Array[Device] = []
	var device_paths := upower.enumerate_devices()

	# Loop through all objects on the bus
	for path in device_paths:
		# Create a power Device from this object
		var proxy := dbus.create_proxy(POWER_BUS, path)
		var device := Device.new(proxy)
		
		devices.append(device)

	return devices


func get_devices_by_type(type: DEVICE_TYPE) -> Array[Device]:
	var all_devices := get_devices()
	var type_devices : Array[Device]
	for device in all_devices:
		if device.type == type:
			type_devices.append(device)
	return type_devices


func get_device(device_name: String) -> Device:
	var device_path := "/".join([POWER_PREFIX, device_name])
	var proxy := dbus.create_proxy(POWER_BUS, device_path)
	var device := Device.new(proxy)

	return device


## Returns true if bluetooth can be used on this system
func supports_power() -> bool:
	return dbus.bus_exists(POWER_BUS)


class UPower extends Resource:
	signal updated
	var _proxy: DBusManager.Proxy
	var on_battery: bool:
		get:
			var property = _proxy.get_property(IFACE_UPOWER, "OnBattery")
			if not property is bool:
				return false
			return property

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()
	
	func enumerate_devices() -> Array:
		var result := _proxy.call_method(IFACE_UPOWER, "EnumerateDevices")
		var args := result.get_args()
		if args.size() != 1:
			return []
		if not args[0] is Array:
			return []
		return args[0]
	

class Device extends Resource:
	signal porperties_changed
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	func refresh() -> void:
		_proxy.call_method(IFACE_DEVICE, "Refresh")

	var native_path: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "NativePath")
			if not property is String:
				return ""
			return property

	var vendor: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Vendor")
			if not property is String:
				return ""
			return property

	var model: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Model")
			if not property is String:
				return ""
			return property

	var serial: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Serial")
			if not property is String:
				return ""
			return property

	var update_time: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "UpdateTime")
			if not property is int:
				return 0
			return property

	var type: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Type")
			if not property is int:
				return 0
			return property

	var power_supply: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "PowerSupply")
			if not property is bool:
				return false
			return property

	var has_history: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "HasHistory")
			if not property is bool:
				return false
			return property

	var has_statistics: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "HasStatisics")
			if not property is bool:
				return false
			return property

	var online: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Online")
			if not property is bool:
				return false
			return property

	var energy: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Energy")
			if not property is float:
				return 0.0
			return property

	var energy_empty: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "EnergyEmpty")
			if not property is float:
				return 0.0
			return property

	var energy_full: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "EnergyFull")
			if not property is float:
				return 0.0
			return property

	var energy_full_design: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "EnergyFullDesign")
			if not property is float:
				return 0.0
			return property

	var energy_rate: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "EnergyRate")
			if not property is float:
				return 0.0
			return property

	var voltage: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Voltage")
			if not property is float:
				return 0.0
			return property

	var charge_cycles: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "ChargeCycles")
			if not property is int:
				return 0
			return property

	var luminosity: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Luminosity")
			if not property is float:
				return 0.0
			return property

	var time_to_empty: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "TimeToEmpty")
			if not property is int:
				return 0
			return property

	var time_to_full: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "TimeToFull")
			if not property is int:
				return 0
			return property

	var percentage: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Percentage")
			if not property is float:
				return 0.0
			return property

	var temperature: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Temperature")
			if not property is float:
				return 0.0
			return property

	var is_present: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "IsPresent")
			if not property is bool:
				return false
			return property

	var state: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "State")
			if not property is int:
				return 0
			return property

	var is_rechargable: bool:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "IsRechargeable")
			if not property is bool:
				return false
			return property
			
	var capacity: float:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Capacity")
			if not property is float:
				return 0.0
			return property

	var technology: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "Technology")
			if not property is int:
				return 0
			return property

	var warning_level: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "WarningLevel")
			if not property is int:
				return 0
			return property

	var battery_level: int:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "BatteryLevel")
			if not property is int:
				return 0
			return property

	var icon_name: String:
		get:
			var property = _proxy.get_property(IFACE_DEVICE, "IconName")
			if not property is String:
				return ""
			return property
