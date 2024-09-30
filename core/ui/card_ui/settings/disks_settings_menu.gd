extends ScrollContainer

var udisks2 := load("res://core/systems/disks/disk_manager.tres") as UDisks2Instance
var steam_disks := load("res://core/systems/disks/steam_removable_media_manager.tres") as SteamRemovableMediaManager

const drive_card_scene: PackedScene = preload("res://core/ui/components/drive_card.tscn")

var logger := Log.get_logger("DisksMenu", Log.LEVEL.INFO)

@onready var container: VBoxContainer = $%DriveCardContainer
@onready var focus_group: FocusGroup = $%FocusGroup
@onready var no_drive_label: Label = $%NoDisksLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	if not udisks2.is_running():
		return

	udisks2.unprotected_devices_updated.connect(_on_drives_updated)
	_on_drives_updated(udisks2.get_unprotected_devices())


func _on_drives_updated(devices: Array[BlockDevice]) -> void:
	logger.debug("Got updated drives")

	# Clear the current grid of items
	var keep_nodes := [focus_group]
	for child in container.get_children():
		if child in keep_nodes:
			continue
		container.remove_child(child)
		child.queue_free()

	# Show a label if no drives are available
	if devices.size() == 0:
		no_drive_label.visible = true
		container.visible = false
		return

	no_drive_label.visible = false
	container.visible = true

	# Poplulate drives
	var last_focus: FocusGroup
	for drive in devices:
		var drive_type = drive.dbus_path.trim_prefix(steam_disks.BLOCK_PREFIX)

		# Ignore loop devices
		if drive_type.contains("loop"):
			continue

		# Create Drive Card
		var drive_card := drive_card_scene.instantiate() as DriveCard
		container.add_child(drive_card)
		drive_card.setup(drive)
		drive_card.visible = true

		# Set up focus
		var drive_focus: FocusGroup = drive_card.drive_focus_group
		if last_focus:
			last_focus.focus_neighbor_bottom = drive_focus
			drive_focus.focus_neighbor_top = last_focus
		last_focus = drive_focus
