extends MarginContainer

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager

const partition_card_scene: PackedScene = preload("res://core/ui/components/partition_card.tscn")

var device: BlockDevice

signal format_drive(device: BlockDevice)
signal format_sd_card
signal init_partition(device: PartitionDevice)

@onready var drives_name_label: Label = $%DriveName
@onready var drives_size_label: Label = $%DriveSize
@onready var format_button: CardButton = $%FormatButton
@onready var partitions_container: VBoxContainer = $%PartitionsVBox
@onready var partitions_focus_group: FocusGroup = $%PartitionsFocusGroup

var logger := Log.get_logger("DriveCard", Log.LEVEL.DEBUG)

func _ready() -> void:
	logger.debug("I'm ready!")
	format_button.pressed.connect(_on_format_drive)


func setup(device: BlockDevice) -> void:
	logger.debug("Setup card for :", device.dbus_path)
	self.device = device
	var drive = "/dev" + device.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)
	drives_name_label.text = drive
	drives_size_label.text = _get_readable_size(device.block_size)

	format_button.visible = steam_disks.format_capable
	if not steam_disks.format_capable && steam_disks.format_sd_capable && drive == steam_disks.SDCARD_PATH:
		format_button.pressed.connect(_on_format_sd_card)
		format_button.pressed.disconnect(_on_format_drive)
		format_button.visible = true

	# Clear the current grid of items
	var keep_nodes := [partitions_focus_group]
	for child in partitions_container.get_children():
		if child in keep_nodes:
			continue
		partitions_container.remove_child(child)
		child.queue_free()

	_populate_partitions()


func _on_format_drive() -> void:
	format_drive.emit(device)


func _on_format_sd_card() -> void:
	format_sd_card.emit()


func _on_init_drive(partition: PartitionDevice) -> void:
	init_partition.emit(partition)


# Returns the human reasable string equivalent of the given number of bytes.
func _get_readable_size(block_size: int) -> String:
	var length = str(block_size).length()
	match length:
	
		1, 2, 3:
			return str(block_size) + " B"
		4, 5, 6:
			return str(block_size/1000) + " KB"
		7, 8, 9:
			return str(block_size/1000000) + " MB"
		10, 11, 12:
			return str(block_size/1000000000) + " GB"
		13, 14, 15:
			return str(block_size/1000000000000) + " TB"
		16, 17, 18:
			return str(block_size/1000000000000000) + " PB"
		_:
			return "0 B"


func _populate_partitions() -> void:
	for partition in self.device.partitions:
		logger.debug("Drive has partition to set up:", partition.dbus_path)
		var partition_card := partition_card_scene.instantiate()
		partitions_container.add_child(partition_card)
		partition_card.setup(partition)
		partition_card.visible = true
		partition_card.init_partition.connect(_on_init_drive)
