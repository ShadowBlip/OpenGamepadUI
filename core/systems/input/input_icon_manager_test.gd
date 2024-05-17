extends GutTest

var icons_manager := load("res://core/systems/input/input_icon_manager.tres") as InputIconManager


func test_input_icons() -> void:
	var icons_processor := InputIconProcessor.new()
	add_child_autoqfree(icons_processor)
	
	var container := HFlowContainer.new()
	
	var input_icon := InputIcon.new()
	input_icon.text = "Gamepad South"
	input_icon.path = "joypad/a"
	container.add_child(input_icon)

	var input_icon2 := InputIcon.new()
	input_icon2.text = "Gamepad East"
	input_icon2.path = "joypad/b"
	container.add_child(input_icon2)

	var input_icon3 := InputIcon.new()
	input_icon3.text = "Quick Bar Input Action"
	input_icon3.path = "ogui_qb"
	container.add_child(input_icon3)

	add_child_autoqfree(container)


func test_get_input_icon_from_mapping() -> void:
	var icons_processor := InputIconProcessor.new()
	add_child_autoqfree(icons_processor)
	
	# Should return the input icon from the XBox 360 icon mapping
	var textures := icons_manager.parse_path("joypad/start", "XBox 360")
	assert_eq(textures.size(), 1, "Failed to get input icon")

	# Should return the fallback icon
	textures = icons_manager.parse_path("joypad/a", "IDONTEXIST")
	assert_eq(textures.size(), 1, "Failed to get fallback input icon")

	# Should return nothing
	textures = icons_manager.parse_path("joypad/idontexist", "IDONTEXIST")
	assert_eq(textures.size(), 0, "Unexpectedly got input icon from non-existent path")
