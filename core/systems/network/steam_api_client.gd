extends HTTPAPIClient
class_name SteamAPIClient


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_url = "https://store.steampowered.com"


## Returns the app details as a Dictionary with the given app id.
## E.g.
## {
##   "367520": {
##     "success": true,
##     "data": {
##       "type": "game",
##       "name": "Hollow Knight",
##       "steam_appid": 367520,
##   ...
func get_app_details(app_id: String) -> Variant:
	var url := "/api/appdetails?appids={0}".format([app_id])
	var response := await request(url)
	if response.code != 200:
		return null
	return response.get_json()
