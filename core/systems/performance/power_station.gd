extends Resource
class_name PowerStation

## Proxy interface to PowerStation over DBus
##
## Provides wrapper classes and methods for interacting with PowerStation over
## DBus to control CPU and GPU performance.

const POWERSTATION_BUS := "org.shadowblip.PowerStation"
const PERFORMANCE_PATH := "/org/shadowblip/Performance"
const CPU_PATH := "/org/shadowblip/Performance/CPU"
const GPU_PATH := "/org/shadowblip/Performance/GPU"
const IFACE_CPU := "org.shadowblip.CPU"
const IFACE_CPU_CORE := "org.shadowblip.CPU.Core"
const IFACE_GPU := "org.shadowblip.GPU"
const IFACE_GPU_CARD := "org.shadowblip.GPU.Card"
const IFACE_GPU_TDP := "org.shadowblip.GPU.Card.TDP"
const IFACE_GPU_CONNECTOR := "org.shadowblip.GPU.Card.Connector"

var dbus := load("res://core/global/dbus_system.tres") as DBusManager
var cpu := CPUBus.new(dbus.create_proxy(POWERSTATION_BUS, CPU_PATH))
var gpu := GPUBus.new(dbus.create_proxy(POWERSTATION_BUS, GPU_PATH))


## Returns true if PowerStation can be used on this system
func supports_power_station() -> bool:
	return dbus.bus_exists(POWERSTATION_BUS)


## CPUBus provides a DBus connection to the CPU bus for CPU controls
class CPUBus extends Resource:
	signal properties_changed
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	## Returns a list of DBus object paths to every detected core
	func enumerate_cores() -> PackedStringArray:
		var result := _proxy.call_method(IFACE_CPU, "EnumerateCores")
		if not result:
			return []
		var args := result.get_args()
		if args.size() != 1:
			return []
		if not args[0] is Array:
			return []
		return args[0]

	## Returns true if the CPU has the given feature
	func has_feature(feature: String) -> bool:
		var result := _proxy.call_method(IFACE_CPU, "HasFeature", [feature], "s")
		if not result:
			return false
		var args := result.get_args()
		if args.size() != 1:
			return false
		if not args[0] is bool:
			return false
		return args[0]

	var boost_enabled: bool:
		set(v):
			_proxy.set_property(IFACE_CPU, "BoostEnabled", v)
		get:
			var property = _proxy.get_property(IFACE_CPU, "BoostEnabled")
			if not property is bool:
				return false
			return property

	var cores_count: int:
		get:
			var property = _proxy.get_property(IFACE_CPU, "CoresCount")
			if not property is int:
				return -1
			return property

	var cores_enabled: int:
		set(v):
			_proxy.set_property(IFACE_CPU, "CoresEnabled", DBus.uint32(v))
		get:
			var property = _proxy.get_property(IFACE_CPU, "CoresEnabled")
			if not property is int:
				return -1
			return property

	var features: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_CPU, "Features")
			if not property is Array:
				return []
			return property

	var smt_enabled: bool:
		set(v):
			_proxy.set_property(IFACE_CPU, "SmtEnabled", v)
		get:
			var property = _proxy.get_property(IFACE_CPU, "SmtEnabled")
			if not property is bool:
				return false
			return property


## Provides an interface to enumerate all detected GPU cards
class GPUBus extends Resource:
	signal properties_changed
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	## Returns a list of DBus object paths to every detected GPU card
	func enumerate_cards() -> PackedStringArray:
		var result := _proxy.call_method(IFACE_GPU, "EnumerateCards")
		if not result:
			return []
		var args := result.get_args()
		if args.size() != 1:
			return []
		if not args[0] is Array:
			return []
		return args[0]

	## Returns a list of all GPUCard objects
	func get_cards() -> Array[GPUCard]:
		var dbus := load("res://core/global/dbus_system.tres") as DBusManager
		var cards: Array[GPUCard] = []
		var paths := self.enumerate_cards()
		for path in paths:
			var card = GPUCard.new(dbus.create_proxy(POWERSTATION_BUS, path))
			cards.append(card)
		
		return cards


## GPUCard provides a DBus connection to the GPU for GPU control
class GPUCard extends Resource:
	signal properties_changed
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	## Returns true if the card supports TDP control
	func supports_tdp() -> bool:
		return self.tdp > 1

	## Returns a list of DBus object paths to every detected GPU connector
	func enumerate_connectors() -> PackedStringArray:
		var result := _proxy.call_method(IFACE_GPU_CARD, "EnumerateConnectors")
		if not result:
			return []
		var args := result.get_args()
		if args.size() != 1:
			return []
		if not args[0] is Array:
			return []
		return args[0]

	## Returns a list of all GPUConnector objects
	func get_connectors() -> Array[GPUConnector]:
		var dbus := load("res://core/global/dbus_system.tres") as DBusManager
		var connectors: Array[GPUConnector] = []
		var paths := self.enumerate_connectors()
		for path in paths:
			var card = GPUConnector.new(dbus.create_proxy(POWERSTATION_BUS, path))
			connectors.append(card)
		
		return connectors

	var class_type: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "Class")
			if not property is String:
				return ""
			return property

	var class_id: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "ClassId")
			if not property is String:
				return ""
			return property

	var clock_limit_mhz_max: float:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "ClockLimitMhzMax")
			if not property is float:
				return -1
			return property

	var clock_limit_mhz_min: float:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "ClockLimitMhzMin")
			if not property is float:
				return -1
			return property

	var clock_value_mhz_max: float:
		set(v):
			_proxy.set_property(IFACE_GPU_CARD, "ClockValueMhzMax", float(v))
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "ClockValueMhzMax")
			if not property is float:
				return -1
			return property

	var clock_value_mhz_min: float:
		set(v):
			_proxy.set_property(IFACE_GPU_CARD, "ClockValueMhzMin", float(v))
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "ClockValueMhzMin")
			if not property is float:
				return -1
			return property

	var device: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "Device")
			if not property is String:
				return ""
			return property

	var device_id: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "DeviceId")
			if not property is String:
				return ""
			return property

	var manual_clock: bool:
		set(v):
			_proxy.set_property(IFACE_GPU_CARD, "ManualClock", v)
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "ManualClock")
			if not property is bool:
				return false
			return property

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "Name")
			if not property is String:
				return ""
			return property

	var path: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "Path")
			if not property is String:
				return ""
			return property

	var revision_id: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "RevisionId")
			if not property is String:
				return ""
			return property

	var subdevice: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "Subdevice")
			if not property is String:
				return ""
			return property

	var subdevice_id: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "SubdeviceId")
			if not property is String:
				return ""
			return property

	var subvendor_id: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "SubvendorId")
			if not property is String:
				return ""
			return property

	var vendor: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "Vendor")
			if not property is String:
				return ""
			return property

	var vendor_id: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CARD, "VendorId")
			if not property is String:
				return ""
			return property

	var boost: float:
		set(v):
			_proxy.set_property(IFACE_GPU_TDP, "Boost", float(v))
		get:
			var property = _proxy.get_property(IFACE_GPU_TDP, "Boost")
			if not property is float:
				return -1
			return property

	var power_profile: String:
		set(v):
			_proxy.set_property(IFACE_GPU_TDP, "PowerProfile", v)
		get:
			var property = _proxy.get_property(IFACE_GPU_TDP, "PowerProfile")
			if not property is String:
				return ""
			return property

	var tdp: float:
		set(v):
			_proxy.set_property(IFACE_GPU_TDP, "TDP", float(v))
		get:
			var property = _proxy.get_property(IFACE_GPU_TDP, "TDP")
			if not property is float:
				return -1
			return property

	var thermal_throttle_limit_c: float:
		set(v):
			_proxy.set_property(IFACE_GPU_TDP, "ThermalThrottleLimitC", float(v))
		get:
			var property = _proxy.get_property(IFACE_GPU_TDP, "ThermalThrottleLimitC")
			if not property is float:
				return -1
			return property


## GPUConnector provides a DBus connection to a GPU connector
class GPUConnector extends Resource:
	signal properties_changed
	signal updated
	var _proxy: DBusManager.Proxy

	func _init(proxy: DBusManager.Proxy) -> void:
		_proxy = proxy
		_proxy.properties_changed.connect(_on_properties_changed)

	func _on_properties_changed(iface: String, props: Dictionary) -> void:
		updated.emit()

	var dpms: bool:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "DPMS")
			if not property is bool:
				return false
			return property

	var enabled: bool:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "Enabled")
			if not property is bool:
				return false
			return property

	var id: int:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "Id")
			if not property is int:
				return -1
			return property

	var modes: PackedStringArray:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "Modes")
			if not property is Array:
				return []
			return property

	var name: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "Name")
			if not property is String:
				return ""
			return property

	var path: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "Path")
			if not property is String:
				return ""
			return property

	var status: String:
		get:
			var property = _proxy.get_property(IFACE_GPU_CONNECTOR, "Status")
			if not property is String:
				return ""
			return property
