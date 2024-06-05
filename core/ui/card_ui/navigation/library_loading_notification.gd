extends Control

signal refresh_started
signal refresh_completed

var library_refresh := load("res://core/ui/card_ui/library/library_refresh_state.tres") as LibraryRefreshState


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Use the shared library refresh resource to listen for when the library
	# menu is refreshing.
	var on_refresh := func():
		refresh_started.emit()
	library_refresh.refresh_started.connect(on_refresh)

	# Use the shared library refresh resource to listen when the library menu
	# finishes refreshing.
	var on_completed := func():
		refresh_completed.emit()
	library_refresh.refresh_completed.connect(on_completed)

	visible = library_refresh.is_refreshing
