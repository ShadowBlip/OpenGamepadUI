@icon("res://assets/editor-icons/overlay_control.svg")
extends Container
class_name OverlayContainer

## Manages the layout for multiple [OverlayProvider] nodes.
##
## The [OverlayContainer] is meant to be added to the main UI scene to provide
## a place to add an arbitrary number of [OverlayProvider] nodes and manage 
## their layout and ordering.

## Dictionary of {provider_id: <[OverlayProvider]>}.
var overlays := {}
var logger := Log.get_logger("OverlayContainer")


func _init() -> void:
	if not "overlay" in get_groups():
		add_to_group("overlay")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_exiting_tree.connect(_on_child_exiting_tree)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Add the given overlay to the overlay container
func add_overlay(overlay: OverlayProvider) -> void:
	logger.debug("Adding overlay: " + overlay.provider_id)
	overlays[overlay.provider_id] = overlay
	add_child(overlay)


## Remove the given overlay from the overlay container.
func remove_overlay(overlay: OverlayProvider) -> void:
	logger.debug("Removing overlay: " + overlay.provider_id)
	if not overlay.provider_id in overlays:
		logger.debug("Overlay was already removed previously: " + overlay.provider_id)
		return
	if overlay in get_children():
		remove_child(overlay)
		overlay.queue_free()
	overlays.erase(overlay.provider_id)


func _on_child_exiting_tree(node: Node) -> void:
	if not node is OverlayProvider:
		return
	var overlay := node as OverlayProvider
	remove_overlay(overlay)
