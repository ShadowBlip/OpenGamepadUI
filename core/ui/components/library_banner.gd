extends Control

var library := load("res://core/global/library_manager.tres") as LibraryManager
var boxart := load("res://core/global/boxart_manager.tres") as BoxArtManager

var logger := Log.get_logger("LibraryBanner")

@onready var container := $%HFlowContainer
@onready var timer := $%Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ready.connect(queue_refresh)
	var on_item_added := func(_item: LibraryItem):
		if not timer.is_stopped():
			return
		queue_refresh()
		timer.start()
	library.library_item_added.connect(on_item_added)


func queue_refresh():
	logger.debug("Queuing banner refresh")
	refresh.call_deferred()


func refresh() -> void:
	var library_items := library.get_library_items()
	if library_items.size() == 0:
		return
	randomize()
	
	for child in container.get_children():
		var item := library_items[randi() % library_items.size()]
		var texture := await boxart.get_boxart_or_placeholder(item, BoxArtProvider.LAYOUT.GRID_LANDSCAPE)
		var texture_rect := child as TextureRect
		texture_rect.texture = texture
