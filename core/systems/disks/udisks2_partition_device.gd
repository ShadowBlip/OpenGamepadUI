extends BlockDevice
class_name PartitionDevice

## Methods and properties of a UDisks2 Block Device's Partition and Filesystem 
## dbus interface.
##
## The PartitionDevice class is responsible for handling dbus messages to and
## from the UDisks2 daemon for filesystems and partition BLock devices.

var has_filesystem: bool = false

# Partition
#func partition_delete() -> void: #a{sv}
	#pass

#func partition_resize_partition() -> void: #ta{sv}
	#pass

#func partition_set_flags() -> void: #ta{sv}
	#pass

#func partition_set_partition_name() -> void: #sa{sv} .SetName, set_name is a reserved Godot method
	#pass

#func partition_set_type() -> void: #sa{sv}
	#pass

#func partition_set_partition_uuid() -> void: #sa{sv}
	#pass


var partition_flags: int: #t
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Flags")
		if not property is int:
			return -1
		return property

var partition_is_contained: bool:
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "IsContained")
		if not property is bool:
			return false
		return property

var partition_is_container: bool:
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "IsContainer")
		if not property is bool:
			return false
		return property

var partition_name: String: #s
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Name")
		if not property is String:
			return ""
		return property

var partition_number: int: #u
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Number")
		if not property is int:
			return -1
		return property

var partition_offset: int: #t
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Offset")
		if not property is int:
			return -1
		return property 

var partition_size: int: #t
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Size")
		if not property is int:
			return -1
		return property 

var partition_table: String: #o
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Table")
		if not property is String:
			return ""
		return property

var partition_type: String: #s
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "Type")
		if not property is String:
			return ""
		return property

var partition_uuid: String: #s
	get:
		var property = _proxy.get_property(IFACE_PARTITION, "UUID")
		if not property is String:
			return ""
		return property

# Filesystem
#func fs_check() -> void: #a{sv} -> b
	#pass

#func fs_mount() -> void: #a{sv} -> s
	#pass

#func fs_repair() -> void: #a{sv} -> b
	#pass

#func fs_resize_filesystem() -> void: #ta{sv}
	#pass

#func fs_set_label() -> void: #sa{sv} 
	#pass

#func fs_set_filesystem_uuid() -> void: #sa{sv} 
	#pass

#func fs_take_ownership() -> void: #a{sv}
	#pass

#func fs_unmount() -> void: #a{sv}
	#pass

var fs_mount_points: PackedStringArray: #aay
	get:
		if not has_filesystem:
			return []

		var mount_points: PackedStringArray = []
		var property = _proxy.get_property(IFACE_FILESYSTEM, "MountPoints")

		if not property is Array:
			return []

		for raw_array in property:
			var char_array: PackedByteArray = []
			char_array.append_array(raw_array as PackedByteArray)
			var mount_point = char_array.get_string_from_ascii()
			mount_points.append(mount_point as String)

		return mount_points

var fs_size: int: #t
	get:
		if not has_filesystem:
			return -1
		var property = _proxy.get_property(IFACE_FILESYSTEM, "Size")
		if not property is int:
			return -1
		return property

var fs_symlinks: PackedStringArray: #aay
	get:
		if not has_filesystem:
			return []

		var symlinks: PackedStringArray = []
		var property = _proxy.get_property(IFACE_FILESYSTEM, "MountPoints")

		if not property is Array:
			return []

		for raw_array in property:
			var char_array: PackedByteArray = []
			char_array.append_array(raw_array as PackedByteArray)
			var symlink = char_array.get_string_from_ascii()
			symlinks.append(symlink as String)

		return symlinks
