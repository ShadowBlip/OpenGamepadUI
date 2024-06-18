extends MarginContainer

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager

const partition_card_scene: PackedScene = preload("res://core/ui/components/partition_card.tscn")
const hdd_icon = preload("res://assets/icons/interface-hdd.svg")
const nvme_icon = preload("res://assets/icons/interface-nvme.svg")
const sd_icon= preload("res://assets/icons/interface-sd.svg")
const ssd_icon= preload("res://assets/icons/interface-ssd.svg")
const usb_icon= preload("res://assets/icons/interface-usb.svg")

var device: BlockDevice
var device_path: String
var highlight_tween: Tween

signal format_drive(device: BlockDevice)
signal format_sd_card
signal init_partition(device: PartitionDevice)

@onready var drive_name_label: Label = $%DriveName
@onready var drive_size_label: Label = $%DriveSize
@onready var drive_icon: TextureRect = $%IconTextureRect
@onready var drive_focus_group: FocusGroup = $%DriveFocusGroup
@onready var format_button: CardButton = $%FormatButton
@onready var partitions_container: VBoxContainer = $%PartitionsVBox
@onready var partitions_focus_group: FocusGroup = $%PartitionsFocusGroup

var logger: Logger
var log_level:= Log.LEVEL.INFO


## Performs _ready fucntionality with the given BlockDevice
func setup(device: BlockDevice) -> void:
	self.device = device
	self.device_path = "/dev" + self.device.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)
	logger = Log.get_logger("DriveCard|"+self.device_path, log_level)

	logger.debug("Setup Drive Card")
	drive_name_label.text = self.device_path
	drive_size_label.text = _get_readable_size(self.device.block_size)

	format_button.visible = steam_disks.format_capable
	format_button.pressed.connect(_on_format_drive)
	if not steam_disks.format_capable && steam_disks.format_sd_capable && self.device_path == steam_disks.SDCARD_PATH:
		format_button.pressed.connect(_on_format_sd_card)
		format_button.pressed.disconnect(_on_format_drive)
		format_button.visible = true
	_set_icon()
	_populate_partitions()


func _on_format_drive() -> void:
	if steam_disks.block_operations:
		return
	logger.debug("Format Drive", device_path)
	_clear_partitions()
	_on_format_started()
	format_drive.emit(self.device)


func _on_format_sd_card() -> void:
	if steam_disks.block_operations:
		return
	logger.debug("Format SD Card", device_path)
	_clear_partitions()
	_on_format_started()
	format_sd_card.emit()


func _on_format_started() -> void:
	logger.debug("Start formatting", device_path)
	var note := Notification.new("Started Formatting " + self.device_path)
	notification_manager.show(note)
	device.format_complete.connect(_on_format_complete, CONNECT_ONE_SHOT)
	format_button.text = "Formating..."


func _on_format_complete(_status: bool) -> void:
	logger.debug("Done formatting", device_path)
	format_button.text = "Format Drive"
	steam_disks.block_operations = false
	var note := Notification.new("Format Complete: " + self.device_path)
	notification_manager.show(note)
	_populate_partitions()



func _on_init_drive(partition: PartitionDevice) -> void:
	logger.debug("Init Partition", "/dev" + partition.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX))
	init_partition.emit(partition)


# Returns the human readable string equivalent of the given number of bytes.
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


func _clear_partitions() -> void:
	# Clear the current grid of items
	var keep_nodes := [partitions_focus_group]
	for child in partitions_container.get_children():
		if child in keep_nodes:
			continue
		partitions_container.remove_child(child)
		child.queue_free()


func _set_icon() -> void:
	match device.drive.interface_type:
		DriveDevice.INTERFACE_TYPE.HDD:
			drive_icon.texture = hdd_icon
		DriveDevice.INTERFACE_TYPE.NVME:
			drive_icon.texture = nvme_icon
		DriveDevice.INTERFACE_TYPE.SD:
			drive_icon.texture = sd_icon
		DriveDevice.INTERFACE_TYPE.SSD:
			drive_icon.texture = ssd_icon
		DriveDevice.INTERFACE_TYPE.USB:
			drive_icon.texture = usb_icon


## Populates the partition grid with an item for every PartitionDevice on this BlockDevice
func _populate_partitions() -> void:
	_clear_partitions()
	var last_focus: FocusGroup
	for partition in self.device.partitions:
		logger.debug("Drive has partition to set up:", partition.dbus_path)
		var partition_card := partition_card_scene.instantiate()
		partitions_container.add_child(partition_card)
		partition_card.setup(partition)
		partition_card.visible = true
		partition_card.init_partition.connect(_on_init_drive)

		var partition_focus: FocusGroup = partition_card.drive_focus_group
		if last_focus:
			last_focus.focus_neighbor_bottom = partition_focus
			partition_focus.focus_neighbor_top = last_focus
		last_focus = partition_focus
