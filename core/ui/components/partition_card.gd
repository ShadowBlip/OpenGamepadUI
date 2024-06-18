extends MarginContainer

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager

var device: PartitionDevice
var device_path: String

signal init_partition(device: PartitionDevice)

@onready var name_label: Label = $%NameLabel
@onready var filesystem_label: Label = $%FilesystemLabel
@onready var size_label: Label = $%SizeLabel
@onready var init_button: CardButton = $%InstantiateButton
@onready var mounts_container: HBoxContainer = $%MountLabelsContainer
@onready var focus_group: FocusGroup = $%FocusGroup

var logger: Logger
var log_level:= Log.LEVEL.INFO


## Performs _ready fucntionality with the given PartitionDevice
func setup(partition_device: PartitionDevice) -> void:
	self.device = partition_device
	self.device_path = "/dev" + self.device.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)
	logger = Log.get_logger("PartitionCard|"+self.device_path, log_level)

	logger.debug("Setup card for:", self.device.dbus_path)

	name_label.text = self.device_path
	filesystem_label.text = self.device.block_id_type
	size_label.text = _get_readable_size(device.partition_size)

	init_button.visible = steam_disks.init_capable
	init_button.pressed.connect(_on_init_drive)

	_populate_mounts()


func _on_init_drive() -> void:
	if steam_disks.block_operations:
		return
	logger.debug("Init Partition", device_path)
	_clear_mounts()
	var note := Notification.new("Started Initializing Steam Library on " + self.device_path)
	notification_manager.show(note)
	device.init_complete.connect(_on_init_complete, CONNECT_ONE_SHOT)
	init_button.text = "Adding to Steam..."
	init_partition.emit(device)


func _on_init_complete(_status: bool) -> void:
	logger.debug("Init Complete", device_path)
	init_button.text = "Add to Steam"
	steam_disks.block_operations = false
	var note := Notification.new("Initializing Complete: " + self.device_path)
	notification_manager.show(note)
	_populate_mounts()


# Returns the human reasable string equivalent of the given number of bytes.
func _get_readable_size(block_size: int) -> String:
	
	if block_size <= 0:
		return "0 B"
	var block_size_f: float = float(block_size)
	var length = str(block_size).length()
	var size_simple: float
	match length:
	
		1, 2, 3:
			return str(block_size) + " B"
		4, 5, 6:
			size_simple = block_size_f/1024.0
			if size_simple < 1:
				size_simple *= 1000
				return str(snappedf(size_simple, 0.01)) + " B"
			return str(snappedf(size_simple, 0.01)) + " KB"
		7, 8, 9:
			size_simple = block_size_f/1024.0/1024.0
			if size_simple < 1:
				size_simple *= 1000
				return str(snappedf(size_simple, 0.01)) + " KB"
			return str(snappedf(size_simple, 0.01)) + " MB"
		10, 11, 12:
			size_simple = block_size_f/1024.0/1024.0/1024.0
			if size_simple < 1:
				size_simple *= 1000
				return str(snappedf(size_simple, 0.01)) + " MB"
			return str(snappedf(size_simple, 0.01)) + " GB"
		13, 14, 15:
			size_simple = block_size_f/1024.0/1024.0/1024.0/1024.0
			if size_simple < 1:
				size_simple *= 1000
				return str(snappedf(size_simple, 0.01)) + " GB"
			return str(snappedf(size_simple, 0.01)) + " TB"
		16, 17, 18:
			size_simple = block_size_f/1024.0/1024.0/1024.0/1024.0/1024.0
			if size_simple < 1:
				size_simple *= 1000
				return str(snappedf(size_simple, 0.01)) + " TB"
			return str(snappedf(size_simple, 0.01)) + " PB"
		_:
			return "Undefined"

## Clears the mount grid of items
func _clear_mounts() -> void:
	var keep_nodes := [focus_group]
	for child in mounts_container.get_children():
		if child in keep_nodes:
			continue
		mounts_container.remove_child(child)
		child.queue_free()


## Populates the mount grid with an item for every mount point on this PartitionDevice
func _populate_mounts() -> void:
	_clear_mounts()
	logger.debug("Mounts:", str(self.device.fs_mount_points))
	for mount in self.device.fs_mount_points:
		var fs_label := Label.new()
		fs_label.text = mount
		mounts_container.add_child(fs_label)
		fs_label.visible = true
