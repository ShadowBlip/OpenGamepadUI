extends SceneTree
const Fixtures := preload("res://core/systems/input/lighting_model_test.gd")
const Scene := preload("res://core/ui/common/quick_bar/lighting_panel.tscn")
var model: LightingModel
var source: Fixtures.FakeSource

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	print("LED_RENDER_START")
	OS.low_processor_usage_mode = false
	Engine.max_fps = 60
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(480, 800)
	model = LightingModel.new()
	source = Fixtures.FakeSource.new()
	source.state.config.effect = "breathing"
	source.state.config.color = [80, 160, 255]
	source.state.config.brightness = 30
	model.set_sources([source])
	root.size = Vector2i(480, 800)
	var background := ColorRect.new()
	background.color = Color("#17191f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 20)
	scroll.size = Vector2(440, 760)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var panel := Scene.instantiate()
	panel.model = model
	panel.connect_backend = false
	panel.theme = load("res://assets/themes/card_ui-dracula.tres")
	scroll.add_child(panel)
	for i in 5:
		await process_frame
	RenderingServer.force_draw()
	var image := root.get_texture().get_image()
	var result := image.save_png("/work/artifacts/ogui-lighting-breathing.png")
	assert(result == OK)
	model.edit("effect", "cycle")
	for i in 4:
		await process_frame
	panel.effect.option_button.grab_focus()
	RenderingServer.force_draw()
	result = root.get_texture().get_image().save_png("/work/artifacts/ogui-lighting-cycle.png")
	assert(result == OK)
	panel.queue_free()
	scroll.queue_free()
	background.queue_free()
	model.set_sources([])
	await process_frame
	model = null
	source = null
	print("LED_RENDER_OK: breathing and cycle panels at 480x800")
	quit(0)
