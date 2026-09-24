extends GutTest

func _check_dialog(path: String) -> void:
	var packed := load(path) as PackedScene
	assert_not_null(packed)
	var dialog := packed.instantiate() as Control
	add_child_autofree(dialog)
	await wait_frames(2)
	assert_eq(dialog.scroll_maximum_size, Vector2i(0, 600), "Keep the existing scroll growth limit")
	var container: ScrollContainer = dialog.scroll_container
	var child: Control = container.get_child(0)
	child.custom_minimum_size.y = 1000
	await wait_frames(3)
	dialog._recalculate_minimum_size()
	assert_eq(container.custom_minimum_size.y, 600.0)

func test_install_location_scroll_growth_limit() -> void:
	await _check_dialog("res://core/ui/components/install_location_dialog.tscn")

func test_install_options_scroll_growth_limit() -> void:
	await _check_dialog("res://core/ui/components/install_options_dialog.tscn")
