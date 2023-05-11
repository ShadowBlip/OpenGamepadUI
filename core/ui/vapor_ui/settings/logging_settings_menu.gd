extends ScrollContainer

const toggle_scene := preload("res://core/ui/components/toggle.tscn")

var logger_map := {}
var log_manager := preload("res://core/global/log_manager.tres")

@onready var container := $%VBoxContainer
@onready var focus_group := $%FocusGroup
@onready var global_dropdown := $%GlobalDropdown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Populate the global log levels
	global_dropdown.clear()
	global_dropdown.add_item("debug")
	global_dropdown.add_item("info")
	global_dropdown.add_item("warn")
	global_dropdown.add_item("error")
	global_dropdown.select(1)
	var on_item_selected := func(idx: int):
		if idx == 0:
			log_manager.set_global_log_level(Log.LEVEL.INFO)
			for toggle in logger_map.values():
				toggle.button_pressed = true
		if idx == 1:
			log_manager.set_global_log_level(Log.LEVEL.INFO)
		if idx == 2:
			log_manager.set_global_log_level(Log.LEVEL.WARN)
		if idx == 3:
			log_manager.set_global_log_level(Log.LEVEL.ERROR)
		if idx > 0:
			for toggle in logger_map.values():
				toggle.button_pressed = false
	global_dropdown.item_selected.connect(on_item_selected)

	# Populate the menu with loggers we can enable debug on
	log_manager.loggers_changed.connect(_populate_loggers)
	_populate_loggers()


func _populate_loggers() -> void:
	var loggers := Array(log_manager.get_available_loggers())
	loggers.sort()
	
	# Add any loggers not yet in the menu
	for logger_name in loggers:
		if logger_name in logger_map:
			continue
		_create_logger_toggle(logger_name)
	
	# Delete any loggers that don't exist anymore
	for logger_name in logger_map.keys():
		if logger_name in loggers:
			continue
		logger_map[logger_name].queue_free()
		logger_map.erase(logger_name)
		
	focus_group.recalculate_focus()


func _create_logger_toggle(logger_name: String) -> void:
	var toggle := toggle_scene.instantiate()
	toggle.name = logger_name
	toggle.text = logger_name
	toggle.separator_visible = false
	toggle.button_pressed = false
	var on_toggled := func(on: bool):
		if on:
			log_manager.set_log_level(logger_name, Log.LEVEL.INFO)
			return
		log_manager.set_log_level(logger_name, Log.LEVEL.INFO)
	toggle.toggled.connect(on_toggled)
		
	container.add_child(toggle)
	logger_map[logger_name] = toggle
