extends Test


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var client := GitHubClient.new()
	var on_ready := func():
		var releases = await client.get_releases("ShadowBlip/OpenGamepadUI", 1)
		if releases == null:
			logger.info("Failed to fetch releases")
			finish()
			return
		print(releases)
		assert_true(releases is Array)
		finish()
	client.ready.connect(on_ready)
	add_child(client)
