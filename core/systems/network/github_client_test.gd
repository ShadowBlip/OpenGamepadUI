extends GutTest

var client := GitHubClient.new()


func test_get_releases() -> void:
	add_child_autoqfree(client)
	
	var releases = await client.get_releases("ShadowBlip/OpenGamepadUI", 1)
	assert_not_null(releases, "should find at least one release")
	if not releases:
		return
	gut.p(releases)
	assert_true(releases is Array, "should return an array")
	assert_eq(releases.size(), 1, "should return 1 result")
	if releases.size() > 0:
		var release = releases[0]
		assert_has(release, "url", "should have 'url' in the result")
