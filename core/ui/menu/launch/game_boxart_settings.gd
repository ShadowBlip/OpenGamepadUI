extends ScrollContainer

const BoxArtManager := preload("res://core/global/boxart_manager.tres")
const SettingsManager := preload("res://core/global/settings_manager.tres")

var game_settings_state := preload("res://assets/state/states/game_settings.tres") as State
var library_item: LibraryItem

@onready var provider_dropdown := $%BoxartProviderDropdown
@onready var banner_texture := $%BannerTexture
@onready var logo_texture := $%LogoTexture
@onready var portrait_texture := $%PortraitTexture
@onready var landscape_texture := $%LandscapeTexture


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_settings_state.state_entered.connect(_on_game_settings_entered)
	provider_dropdown.item_selected.connect(_on_provider_selected)


func _on_game_settings_entered(_from: State) -> void:
	if not "item" in game_settings_state.data:
		return
	library_item = game_settings_state.data["item"] as LibraryItem

	# Get the provider used for this game
	var selected_provider = (
		SettingsManager.get_library_value(library_item, "boxart_provider", "") as String
	)

	# Get the available boxart providers
	var provider_ids := BoxArtManager.get_provider_ids()

	# Populate the boxart providers this game can use
	provider_dropdown.clear()
	provider_dropdown.add_item("any")
	var provider_idx := 0
	var i := 1
	for provider_id in provider_ids:
		if provider_id == selected_provider:
			provider_idx = i
		provider_dropdown.add_item(provider_id)
		i += 1

	# Select the provider from the user's settings
	provider_dropdown.select(provider_idx)
	_on_provider_selected(provider_idx)


# Update the menu whenever a boxart provider changes.
func _on_provider_selected(idx: int) -> void:
	if not library_item:
		return

	# Write the provider used to the user's settings for this game
	if idx == 0:
		SettingsManager.erase_library_key(library_item, "boxart_provider")
	else:
		# Get the text of the selected item
		var provider_ids := BoxArtManager.get_provider_ids()
		var provider_id := provider_ids[idx - 1] as String
		SettingsManager.set_library_value(library_item, "boxart_provider", provider_id)

	# Display loading animations
	banner_texture.get_child(0).visible = true
	logo_texture.get_child(0).visible = true
	portrait_texture.get_child(0).visible = true
	landscape_texture.get_child(0).visible = true

	# Update the boxart in the menu
	banner_texture.texture = await (
		BoxArtManager . get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.BANNER)
	)
	banner_texture.get_child(0).visible = false
	logo_texture.texture = await (
		BoxArtManager . get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.LOGO)
	)
	logo_texture.get_child(0).visible = false
	portrait_texture.texture = await (
		BoxArtManager . get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.GRID_PORTRAIT)
	)
	portrait_texture.get_child(0).visible = false
	landscape_texture.texture = await (
		BoxArtManager
		. get_boxart_or_placeholder(library_item, BoxArtProvider.LAYOUT.GRID_LANDSCAPE)
	)
	landscape_texture.get_child(0).visible = false
