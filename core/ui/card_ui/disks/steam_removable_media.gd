extends ScrollContainer

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager

const drive_card_scene: PackedScene = preload("res://core/ui/components/drive_card.tscn")

var logger := Log.get_logger("SteamRemovableMedia", Log.LEVEL.DEBUG)

@onready var container: HFlowContainer = $%DriveCardContainer
@onready var focus_group: FocusGroup = $%FocusGroup

# Called when the node enters the scene tree for the first time.
func _ready():
	logger.debug("I'm ready!")
	steam_disks.drives_updated.connect(_on_drives_updated)
	steam_disks.update_drives()


func _on_drives_updated(devices: Array[BlockDevice]) -> void:
	logger.debug("Got updated drives")#, steam_disks.device_tree)

	# Clear the current grid of items
	var keep_nodes := [focus_group]
	for child in container.get_children():
		if child in keep_nodes:
			continue
		container.remove_child(child)
		child.queue_free()
	_populate_drives(devices)


func _on_format_drive(device: BlockDevice) -> void:
	steam_disks.format_drive(device)


func _on_init_partition(device: PartitionDevice) -> void:
	steam_disks.init_steam_lib(device)


# Populates the drive grid with detected drives
func _populate_drives(devices: Array[BlockDevice]):
	for drive in devices:
		var drive_card := drive_card_scene.instantiate()
		container.add_child(drive_card)
		drive_card.setup(drive)
		drive_card.visible = true
		drive_card.format_drive.connect(_on_format_drive)
		drive_card.init_partition.connect(_on_init_partition)
