extends Control

@onready var max_recent_slider := $%MaxRecentAppsSlider as HSlider
@onready var max_recent_value := $%MaxRecentAppsValue as Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var max_recent := SettingsManager.get_value("general.home", "max_home_items", 10)
	max_recent_slider.value = max_recent
	max_recent_value.text = str(max_recent)
	max_recent_slider.value_changed.connect(_on_max_recent_changed)


func _on_max_recent_changed(value: float) -> void:
	max_recent_value.text = str(value)
	SettingsManager.set_value("general.home", "max_home_items", int(value))
