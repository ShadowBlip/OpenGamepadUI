extends HTTPAPIClient
class_name GitHubClient



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	logger.set_name("GitHubClient")
	base_url = "https://api.github.com"


## Returns the releases for the given project. E.g. "ShadowBlip/OpenGamepadUI"
## Refer to the GitHub API for data layout:
## https://api.github.com/repos/ShadowBlip/OpenGamepadUI/releases
func get_releases(project: String, per_page: int = 30, page: int = 1) -> Variant:
	var url := "/repos/{0}/releases?per_page={1}&page={2}".format([project, per_page, page])
	var response := await request(url, Cache.FLAGS.NONE)
	if response.code != 200:
		return null
	return response.get_json()
