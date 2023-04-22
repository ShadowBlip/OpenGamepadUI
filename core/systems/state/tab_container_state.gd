extends Resource
class_name TabContainerState

## Shared resource for the state of a tab container
##
## Resource used to watch and manipulate the state of a tab container regardless
## of where UI components are in the scene tree.

signal tab_button_pressed(tab: int)
signal tab_changed(tab: int)
signal tab_selected(tab: int)

var current_tab := 0:
	set(v):
		current_tab = v
		tab_changed.emit(v)

@export var tabs_text: PackedStringArray
