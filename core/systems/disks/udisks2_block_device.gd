extends UDisks2
class_name BlockDevice

## Methods and properties of a UDisks2 Block Device dbus interface.
##
## The BlockDevice class is responsible for handling dbus messages to and
## from the UDisks2 daemon for block device management, including filesystems
## and partitions.

signal updated
signal format_complete(status: bool)
signal init_complete(status: bool)
signal trim_complete(status: bool)

var _proxy: DBusManager.Proxy
var dbus_path: String
var partitions: Array[PartitionDevice]


func _init(proxy: DBusManager.Proxy) -> void:
	var dbus := load("res://core/global/dbus_system.tres") as DBusManager
	_proxy = proxy
	_proxy.properties_changed.connect(_on_properties_changed)
	dbus_path = _proxy.path

func _on_properties_changed(_iface: String, _props: Dictionary) -> void:
	updated.emit()

# Block
#func block_add_configuration_item() -> void: #(sa{sv})a{sv}
	#pass

#func block_format() -> void: #sa{sv}
	#pass

#func block_get_secret_configuration() -> void: #a{sv} -> a(sa{sv})
	#pass

#func block_open_device() -> void: #sa{sv} -> h
	#pass

#func block_open_for_backup() -> void: #a{sv} -> h
	#pass

#func block_open_for_benchmark() -> void: #a{sv} -> h
	#pass

#func block_open_for_restore() -> void: #a{sv} -> h
	#pass

#func block_remove_configuration_item() -> void: #a{sv} -> a(sa{sv})
	#pass

#func block_rescan() -> void: #a{sv}
	#pass

#func block_update_configuration_item() -> void: # (sa{sv})(sa{sv})a{sv}
	#pass

var block_configuration: Dictionary: #a(sa{sv})
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "Configuration")
		if not property is Dictionary:
			return {}
		return property

var block_crypto_backing_device: String: #o 
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "CryptoBackingDevice")
		if not property is String:
			return ""
		return property

var block_device: String: #ay
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "Device")
		if not property is String:
			return ""
		return property

var block_device_number: int: #t
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "DeviceNumber")
		if not property is int:
			return -1
		return property

var drive: DriveDevice

var drive_path: String: #o
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "Drive")
		if not property is String:
			return ""
		return property

var block_hint_auto: bool:
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintAuto")
		if not property is bool:
			return false
		return property

var block_hint_icon_name: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintIconName")
		if not property is String:
			return ""
		return property

var block_hint_ignore: bool:
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintIgnore")
		if not property is bool:
			return false
		return property

var block_hint_name: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintName")
		if not property is String:
			return ""
		return property

var block_hint_partitionable: bool:
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintPartitionable")
		if not property is bool:
			return false
		return property

var block_hint_symbolic_icon_name: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintSymbolicIconName")
		if not property is String:
			return ""
		return property

var block_hint_system: bool:
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "HintSystem")
		if not property is bool:
			return false
		return property

var block_id: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "Id")
		if not property is String:
			return ""
		return property

var block_id_label: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "IdLabel")
		if not property is String:
			return ""
		return property

var block_id_type: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "IdType")
		if not property is String:
			return ""
		return property

var block_id_uuid: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "IdUUID")
		if not property is String:
			return ""
		return property

var block_id_usage: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "IdUsage")
		if not property is String:
			return ""
		return property

var block_id_version: String: #s
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "IdVersion")
		if not property is String:
			return ""
		return property

var block_md_raid: String: #o
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "MDRaid")
		if not property is String:
			return ""
		return property

var block_md_raid_member: String: #o
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "MDRaidMember")
		if not property is String:
			return ""
		return property

var block_preferred_device: String: #ay
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "PreferredDevice")
		if not property is String:
			return ""
		return property

var block_read_only: bool:
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "ReadOnly")
		if not property is bool:
			return false
		return property

var block_size: int: #t
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "Size")
		if not property is int:
			return -1
		return property

var block_userspace_mount_options: PackedStringArray: #as
	get:
		var property = _proxy.get_property(IFACE_BLOCK, "UserspaceMountOptions")
		if not property is Array:
			return []
		return property
