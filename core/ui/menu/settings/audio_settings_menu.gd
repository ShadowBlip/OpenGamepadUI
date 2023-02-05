extends ScrollContainer

@onready var output_volume := $%VolumeSlider
@onready var output_device := $%OutputDevice
@onready var input_volume := $%MicVolumeSlider
@onready var input_device := $%InputDevice


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not AudioManager.supports_audio():
		output_volume.visible = false
		output_device.visible = false
		input_volume.visible = false
		input_device.visible = false
		return
	var current_volume := AudioManager.get_current_volume()
	output_volume.value = current_volume * 100
	output_volume.value_changed.connect(_on_output_volume_changed)
	output_device.item_selected.connect(_on_output_device_changed)

	# Populate the dropdown with available output devices
	_update_output_devices()


# Updates the list of output devices
func _update_output_devices() -> void:
	var current_device := AudioManager.get_current_output_device()
	var output_devices := AudioManager.get_output_devices()
	output_device.clear()

	var selected := 0
	var i := 0
	for device in output_devices:
		output_device.add_item(device)
		if device == current_device:
			selected = i
		i += 1

	output_device.select(selected)


func _on_output_device_changed(idx: int) -> void:
	var output_devices := AudioManager.get_output_devices()
	var device := output_devices[idx]
	AudioManager.set_output_device(device)


func _on_output_volume_changed(value: float) -> void:
	var percent := value * 0.01
	AudioManager.set_volume(percent)
