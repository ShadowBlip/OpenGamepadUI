extends PanelContainer

var library_tween: Tween
var search_tween: Tween
var library_state := load("res://assets/state/states/library.tres") as State
var default_size := Vector2(custom_minimum_size.x, custom_minimum_size.y)

@export var animate_time := 0.2

@onready var tabs_container := $%LibraryTabsContainer
@onready var search_bar := $%SearchBar
@onready var search_button := $%SearchButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tabs_container.visible = false
	tabs_container.modulate = Color(1, 1, 1, 0)
	library_state.state_entered.connect(_on_library_entered)
	library_state.state_exited.connect(_on_library_exited)
	
	# Show/hide the search bar when the search button is pressed
	var on_search_pressed := func():
		if search_bar.visible:
			_hide_search_bar()
			return
		_show_search_bar()
	search_button.pressed.connect(on_search_pressed)


func _on_library_entered(_from: State) -> void:
	_show_library_tabs()
	_hide_search_bar()


func _on_library_exited(_to: State) -> void:
	_hide_library_tabs()
	_show_search_bar()


func _show_search_bar() -> void:
	if search_tween:
		search_tween.kill()
	search_tween = get_tree().create_tween()
	search_tween.tween_property(self, "custom_minimum_size", Vector2(default_size.x + search_bar.size.x, default_size.y), animate_time)
	search_tween.tween_property(search_bar, "visible", true, 0)
	search_tween.tween_property(search_bar, "modulate", Color(1, 1, 1, 1), animate_time)


func _hide_search_bar() -> void:
	if search_tween:
		search_tween.kill()
	search_tween = get_tree().create_tween()
	search_tween.tween_property(search_bar, "modulate", Color(1, 1, 1, 0), animate_time)
	search_tween.tween_property(search_bar, "visible", false, 0)
	search_tween.tween_property(self, "custom_minimum_size", Vector2(default_size.x - search_bar.size.x, default_size.y), animate_time)


func _show_library_tabs() -> void:
	if library_tween:
		library_tween.kill()
	library_tween = get_tree().create_tween()
	library_tween.tween_property(self, "custom_minimum_size", Vector2(default_size.x + tabs_container.size.x, default_size.y), animate_time)
	library_tween.tween_property(tabs_container, "visible", true, 0)
	library_tween.tween_property(tabs_container, "modulate", Color(1, 1, 1, 1), animate_time)


func _hide_library_tabs() -> void:
	if library_tween:
		library_tween.kill()
	library_tween = get_tree().create_tween()
	library_tween.tween_property(tabs_container, "modulate", Color(1, 1, 1, 0), animate_time)
	library_tween.tween_property(tabs_container, "visible", false, 0)
	library_tween.tween_property(self, "custom_minimum_size", Vector2(default_size.x - tabs_container.size.x, default_size.y), animate_time)

