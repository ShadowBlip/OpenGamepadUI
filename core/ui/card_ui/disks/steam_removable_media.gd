extends ScrollContainer

var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager

const drive_card_scene: PackedScene = preload("res://core/ui/components/drive_card.tscn")


var logger := Log.get_logger("SteamRemovableMedia", Log.LEVEL.INFO)

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

	# Poplulate drives
	var last_focus: FocusGroup
	for drive in devices:
		var drive_card := drive_card_scene.instantiate()
		container.add_child(drive_card)
		drive_card.setup(drive)
		drive_card.visible = true
		drive_card.format_drive.connect(_on_format_drive)
		drive_card.format_sd_card.connect(_on_format_sd_card)
		drive_card.init_partition.connect(_on_init_partition)
		var drive_focus: FocusGroup = drive_card.drive_focus_group
		if last_focus:
			last_focus.focus_neighbor_bottom = drive_focus
			drive_focus.focus_neighbor_top = last_focus
		last_focus = drive_focus


func _on_format_drive(device: BlockDevice) -> void:
	if steam_disks.block_operations:
		return
	steam_disks.block_operations = true
	steam_disks.format_drive(device)


func _on_format_sd_card(device: BlockDevice) -> void:
	if steam_disks.block_operations:
		return
	steam_disks.block_operations = true
	steam_disks.format_sd_card()


func _on_init_partition(device: PartitionDevice) -> void:
	if steam_disks.block_operations:
		return
	steam_disks.block_operations = true
	steam_disks.init_steam_lib(device)
