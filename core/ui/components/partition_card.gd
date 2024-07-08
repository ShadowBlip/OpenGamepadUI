extends MarginContainer
class_name PartitionCard

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

var logger: Logger
var log_level:= Log.LEVEL.INFO


## Performs _ready fucntionality with the given PartitionDevice
func setup(partition_device: PartitionDevice) -> void:
	# Setup UDisks2 information
	self.device = partition_device
	self.device_path = "/dev" + self.device.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)
	logger = Log.get_logger("PartitionCard|"+self.device_path, log_level)
	logger.debug("Setup card for:", self.device.dbus_path)
	name_label.text = self.device_path
	filesystem_label.text = self.device.block_id_type
	size_label.text = partition_device.get_readable_size()
	_populate_mounts()

	# Setup SteamRemovableMedia interfaces
	if steam_disks.init_capable:
		init_button.pressed.connect(_srm_init_drive)
		init_button.visible = true


func _srm_init_drive() -> void:
	var dialog := get_tree().get_first_node_in_group("dialog") as Dialog
	var msg := "INFO: Adding " + device_path + " as a steam path will NOT cause data loss. " + \
		"The drive will be made available to Steam for installing games. Do you wish to continue?"
	dialog.open(msg, "Cancel", "Continue")
	var cancel := await dialog.choice_selected as bool
	if cancel:
		return

	if steam_disks.block_operations:
		logger.debug("Init operation blocked.")
		return

	logger.debug("Init Partition", device_path)
	_clear_mounts()
	var note := Notification.new("Started Initializing Steam Library on " + self.device_path)
	notification_manager.show(note)
	init_button.text = "Adding to Steam..."
	note.text = "Initializing Complete: " + self.device_path
	if await steam_disks.init_steam_lib(device) != OK:
		note.text = "Failed to add drive to steam: " + self.device_path

	logger.debug("Init Complete", device_path)
	init_button.text = "Add to Steam"
	notification_manager.show(note)
	_populate_mounts()


## Clears the mount grid of items
func _clear_mounts() -> void:
	for child in mounts_container.get_children():
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
