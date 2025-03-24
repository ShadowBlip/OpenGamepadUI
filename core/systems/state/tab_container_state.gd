extends Resource
class_name TabContainerState

## Shared resource for the state of a tab container
##
## Resource used to watch and manipulate the state of a tab container regardless
## of where UI components are in the scene tree.

signal tab_button_pressed(tab: int)
signal tab_changed(tab: int)
signal tab_selected(tab: int)
signal tab_added(tab_text: String, node: ScrollContainer)
signal tab_removed(tab_text: String)

var current_tab := 0:
	set(v):
		current_tab = v
		tab_changed.emit(v)

@export var tabs_text: PackedStringArray


## Add the given tab
func add_tab(tab_text: String, node: ScrollContainer) -> void:
	tabs_text.append(tab_text)
	tab_added.emit(tab_text, node)


## Remove the given tab
func remove_tab(tab_text: String) -> void:
	var idx := tabs_text.find(tab_text)
	if idx < 0:
		return
	tabs_text.remove_at(idx)
	if tabs_text.size() > current_tab:
		current_tab = tabs_text.size() - 1
	tab_removed.emit(tab_text)
