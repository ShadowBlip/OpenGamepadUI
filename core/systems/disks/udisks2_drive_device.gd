extends UDisks2
class_name DriveDevice 

## Methods and properties of a UDisks2 Drive Device dbus interface.
##
## The DriveDevice class is responsible for handling dbus messages to and
## from the UDisks2 daemon for drive device management, including drive
## controllers.

signal updated

var _proxy: DBusManager.Proxy
var dbus_path: String
var interface_type:= INTERFACE_TYPE.UNKNOWN

enum INTERFACE_TYPE {
	UNKNOWN,
	HDD,
	NVME,
	SD,
	SSD,
	USB,
}


func _init(proxy: DBusManager.Proxy) -> void:
	var dbus := load("res://core/global/dbus_system.tres") as DBusManager
	_proxy = proxy
	_proxy.properties_changed.connect(_on_properties_changed)
	dbus_path = _proxy.path

func _on_properties_changed(_iface: String, props: Dictionary) -> void:
	updated.emit()

# Drive
#func eject() -> void: #a{sv}
	#pass

#func power_off() -> void: #a{sv}
	#pass

#func set_configuration() -> void: #a{sv}a{sv}
	#pass

var can_power_off: bool: 
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Ejectable")
		if not property is bool:
			return false
		return property

var configuration: Array: #a{sv}
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Configuration")
		if not property is Array:
			return []
		return property

var connection_bus: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "ConnectionBus")
		if not property is String:
			return ""
		return property

var ejectable: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Ejectable")
		if not property is bool:
			return false
		return property

var id: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Id")
		if not property is String:
			return ""
		return property

var media: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Media")
		if not property is String:
			return ""
		return property

var media_available: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "MediaAvailable")
		if not property is bool:
			return false
		return property

var media_change_detected: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "MediaChangeDetected")
		if not property is bool:
			return false
		return property

var media_compatibility: PackedStringArray: #as
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "MediaCompatibility")
		if not property is PackedStringArray:
			return []
		return property

var media_removable: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "MediaRemovable")
		if not property is bool:
			return false
		return property

var model: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Model")
		if not property is String:
			return ""
		return property

var optical: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Optical")
		if not property is bool:
			return false
		return property

var optical_blank: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "OpticalBlank")
		if not property is bool:
			return false
		return property

var optical_num_audio_tracks: int: #u
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "OpticalNumAudioTracks")
		if not property is int:
			return -1
		return property

var optical_num_data_tracks: int: #u
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "OpticalNumDataTracks")
		if not property is int:
			return -1
		return property

var optical_num_sessions: int: #u
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "OpticalNumSessions")
		if not property is int:
			return -1
		return property

var optical_num_tracks: int: #u
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "OpticalNumTracks")
		if not property is int:
			return -1
		return property

var removable: bool:
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Removable")
		if not property is bool:
			return false
		return property

var revision: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Revision")
		if not property is String:
			return ""
		return property

var rotation_rate: int: #i
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "RotationRate")
		if not property is int:
			return -1
		return property 

var seat: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Seat")
		if not property is String:
			return ""
		return property

var serial: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Serial")
		if not property is String:
			return ""
		return property

var sibling_id: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "SiblingId")
		if not property is String:
			return ""
		return property

var size: int: #t
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Size")
		if not property is int:
			return -1
		return property 

var sort_key: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "SortKey")
		if not property is String:
			return ""
		return property

var time_detected: int: #t
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "TimeDetected")
		if not property is int:
			return -1
		return property 

var time_media_detected: int: #t
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "TimeMediaDetected")
		if not property is int:
			return -1
		return property 

var vendor: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "Vendor")
		if not property is String:
			return ""
		return property

var wwn: String: #s
	get:
		var property = _proxy.get_property(IFACE_DRIVE, "WWN")
		if not property is String:
			return ""
		return property

# NVME Controller
#func sanitize_start() -> void: #sa{sv}
	#pass

#func smart_get_attributes() -> void: #a{sv} -> a{sv}
	#pass

#func smart_selftest_abort() -> void: #a{sv}
	#pass

#func smart_selftest_start() -> void: #sa{sv}
	#pass

#func smart_update() -> void: #a{sv}
	#pass

#var controller_id: int: #q
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "ControllerID")
		#if not property is int:
			#return -1
		#return property  #uint16

#var fguid: String: #s
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "FGUID")
		#if not property is String:
			#return ""
		#return property

#var nvme_revision: String: #s
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "NVMERevision")
		#if not property is String:
			#return ""
		#return property

#var sanitize_percent_remaining: int: #i
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SanitizePercentRemaining")
		#if not property is int:
			#return -1
		#return property 

#var sanitize_status: String: #s
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SanitizeStatus")
		#if not property is String:
			#return ""
		#return property

#var smart_critical_warning: PackedStringArray: #as
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SmartCriticalWarning")
		#if not property is PackedStringArray:
			#return []
		#return property 

#var smart_power_on_hours: int: #t
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SmartPowerOnHours")
		#if not property is int:
			#return -1
		#return property

#var smart_selftest_percent_remaining: int: #i
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SmartSelftestPercentRemaining")
		#if not property is int:
			#return -1
		#return property 

#var smart_selftest_status: String: #s
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SmartSelftestStatus")
		#if not property is String:
			#return ""
		#return property

#var smart_temperature: int: #q
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SmartTemperature")
		#if not property is int:
			#return -1
		#return property

#var smart_updated: int: #t
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SmartUpdated")
		#if not property is int:
			#return -1
		#return property

#var state: String: #s
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "State")
		#if not property is String:
			#return ""
		#return property

#var subsystem_nqn: String: #ay
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "SubsystemNQN")
		#if not property is String:
			#return ""
		#return property

#var unallocated_capacity: int: #t
	#get:
		#var property = _proxy.get_property(IFACE_NVME_CONTROLLER, "unallocatedCapacity")
		#if not property is int:
			#return -1
		#return property
