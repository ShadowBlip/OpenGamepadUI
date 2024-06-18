extends MarginContainer

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager

var device: PartitionDevice

signal init_partition(device: PartitionDevice)

@onready var name_label: Label = $%NameLabel
@onready var filesystem_label: Label = $%FilesystemLabel
@onready var size_label: Label = $%SizeLabel
@onready var init_button: CardButton = $%InstantiateButton
@onready var mounts_container: HBoxContainer = $%MountLabelsContainer
@onready var focus_group: FocusGroup = $%FocusGroup

var logger := Log.get_logger("PartitionCard", Log.LEVEL.DEBUG)

func _ready() -> void:
	logger.debug("I'm ready!")
	init_button.pressed.connect(_on_init_drive)


func setup(partition_device: PartitionDevice) -> void:
	device = partition_device
	logger.debug("Setup card for:", device.dbus_path)
	var partition = "/dev" + device.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)
	name_label.text = partition
	filesystem_label.text = device.block_id_type
	size_label.text = _get_readable_size(device.partition_size)

	init_button.visible = steam_disks.init_capable

	# Clear the current grid of items
	var keep_nodes := [focus_group]
	for child in mounts_container.get_children():
		if child in keep_nodes:
			continue
		mounts_container.remove_child(child)
		child.queue_free()

	_populate_mounts()


func _on_init_drive() -> void:
	init_partition.emit(device)


# Returns the human reasable string equivalent of the given number of bytes.
func _get_readable_size(partition_size: int) -> String:
	var length = str(partition_size).length()
	match length:
	
		1, 2, 3:
			return str(partition_size) + " B"
		4, 5, 6:
			return str(partition_size/1000) + " KB"
		7, 8, 9:
			return str(partition_size/1000000) + " MB"
		10, 11, 12:
			return str(partition_size/1000000000) + " GB"
		13, 14, 15:
			return str(partition_size/1000000000000) + " TB"
		16, 17, 18:
			return str(partition_size/1000000000000000) + " PB"
		_:
			return "0 B"


func _populate_mounts() -> void:
	for mount in self.device.fs_mount_points:
		var fs_label := Label.new()
		fs_label.text = mount
		mounts_container.add_child(fs_label)
		fs_label.visible = true
