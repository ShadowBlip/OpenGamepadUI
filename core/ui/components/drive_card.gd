extends MarginContainer
class_name DriveCard

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager
var notification_manager := load("res://core/global/notification_manager.tres") as NotificationManager

const partition_card_scene: PackedScene = preload("res://core/ui/components/partition_card.tscn")
const hdd_icon = preload("res://assets/icons/interface-hdd.svg")
const nvme_icon = preload("res://assets/icons/interface-nvme.svg")
const sd_icon = preload("res://assets/icons/interface-sd.svg")
const ssd_icon = preload("res://assets/icons/interface-ssd.svg")
const usb_icon = preload("res://assets/icons/interface-usb.svg")

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
	# Setup UDisks2 information
	self.device = device
	self.device_path = "/dev" + self.device.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)
	logger = Log.get_logger("DriveCard|"+self.device_path, log_level)
	logger.debug("Setup Drive Card")
	drive_name_label.text = self.device_path
	drive_size_label.text = device.get_readable_size()
	_set_icon()
	_populate_partitions()

	# Setup SteamRemovableMedia interfaces
	if steam_disks.format_capable:
		format_button.pressed.connect(_srm_format_drive)
		format_button.visible = true
	if not steam_disks.format_capable && steam_disks.format_sd_capable && self.device_path == steam_disks.SDCARD_PATH:
		format_button.pressed.connect(_srm_format_sd_card)
		format_button.pressed.disconnect(_srm_format_drive)
		format_button.visible = true


func _srm_format_drive() -> void:
	var dialog := get_tree().get_first_node_in_group("dialog") as Dialog
	var msg := "WARNING: All data on " + device_path + " device will be wiped. " + \
		"This action cannot be undone. Do you wish to continue?"
	dialog.open(msg, "Cancel", "Continue Format")
	var cancel := await dialog.choice_selected as bool
	if cancel:
		return

	if steam_disks.block_operations:
		logger.debug("Format operation blocked.")
		return

	logger.debug("Format Drive", device_path)
	_clear_partitions()
	_on_format_started()
	var note := Notification.new("Format Complete: " + self.device_path)
	if await steam_disks.format_drive(device) != OK:
		note.text = "Failed to format " + self.device_path
	_on_format_complete(note)


func _srm_format_sd_card() -> void:
	var dialog := get_tree().get_first_node_in_group("dialog") as Dialog
	var msg := "WARNING: All data on " + device_path + " device will be wiped. " + \
		"This action cannot be undone. Do you wish to continue?"
	dialog.open(msg, "Cancel", "Continue Format")
	var cancel := await dialog.choice_selected as bool
	if cancel:
		return

	if steam_disks.block_operations:
		logger.debug("Format operation blocked.")
		return

	logger.debug("Format SD Card", device_path)
	_clear_partitions()
	_on_format_started()
	var note := Notification.new("Format Complete: " + self.device_path)
	if await steam_disks.format_sd_card() != OK:
		note.text = "Failed to format " + self.device_path
	_on_format_complete(note)


func _on_format_started() -> void:
	logger.debug("Start formatting", device_path)
	var note := Notification.new("Started Formatting " + self.device_path)
	notification_manager.show(note)
	format_button.text = "Formating..."


func _on_format_complete(note: Notification) -> void:
	logger.debug("Done formatting", device_path)
	format_button.text = "Format Drive"
	notification_manager.show(note)
	_populate_partitions()


func _srm_init_drive(partition: PartitionDevice) -> void:
	logger.debug("Init Partition", "/dev" + partition.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX))
	init_partition.emit(partition)



func _clear_partitions() -> void:
	# Clear the current grid of items
	var keep_nodes := [partitions_focus_group]
	for child in partitions_container.get_children():
		if child in keep_nodes:
			continue
		partitions_container.remove_child(child)
		child.queue_free()


func _set_icon() -> void:
	if not device or not device.drive:
		logger.warn("Unable to detect drive to set icon for:", device)
		drive_icon.texture = hdd_icon
		return
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
		var partition_card := partition_card_scene.instantiate() as PartitionCard
		partitions_container.add_child(partition_card)
		partition_card.setup(partition)
		partition_card.visible = true
		partition_card.init_partition.connect(_srm_init_drive)
