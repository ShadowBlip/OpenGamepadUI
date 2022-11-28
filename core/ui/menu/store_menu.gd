extends Control

@onready var state_manager: StateManager = get_node("/root/Main/StateManager")
@onready var store_manager: StoreManager = get_node("/root/Main/StoreManager")

var poster_scene: PackedScene = preload("res://core/ui/components/poster.tscn")
var _current_store: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Clear the template buttons
	var grid: HFlowContainer = $StoresContent/ScrollContainer/HFlowContainer
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	
	# Listen for stores that register
	store_manager.store_registered.connect(_on_store_registered)
	state_manager.state_changed.connect(_on_state_changed)
	visible = false


# When a store is registered, add an entry to the stores menu
func _on_store_registered(store: Store) -> void:
	var grid: HFlowContainer = $StoresContent/ScrollContainer/HFlowContainer
	
	# Build the poster to display
	var poster: TextureButton = poster_scene.instantiate()
	poster.layout = poster.LAYOUT_MODE.LANDSCAPE
	var img: Texture2D = load(store.store_image)
	poster.texture_normal = img
	poster.text = store.store_name
	poster.pressed.connect(_launch_store.bind(store))

	grid.add_child(poster)


func _on_state_changed(from: StateManager.State, to: StateManager.State, _data: Dictionary) -> void:
	visible = state_manager.has_state(StateManager.State.STORE)
	if not visible:
		_reset_store()
		return
	if visible and to == StateManager.State.IN_GAME:
		state_manager.remove_state(StateManager.State.STORE)
	
	if _current_store == "":
		var grid: HFlowContainer = $StoresContent/ScrollContainer/HFlowContainer
		for child in grid.get_children():
			child.grab_focus.call_deferred()
			break
	else:
		var grid: HFlowContainer = $HomeContent/ScrollContainer/HFlowContainer
		for child in grid.get_children():
			child.grab_focus.call_deferred()
			break


func _reset_store():
		_current_store = ""
		$StoresContent.visible = true 
		$HomeContent.visible = false
		var grid: HFlowContainer = $HomeContent/ScrollContainer/HFlowContainer
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()


func _launch_store(store: Store):
	# Hide the stores content and show the store
	$StoresContent.visible = false 
	$HomeContent.visible = true
	
	# Call the store's load_home method and wait for a response
	print("Launching store: ", store.store_id)
	_current_store = store.store_id
	store.home_loaded.connect(_on_home_loaded, CONNECT_ONE_SHOT)
	store.load_home()
	
	# Show the loading animation while we wait for the store home.
	$Loading01.visible = true


func _on_home_loaded(results: Array):
	# Hide the loading animation
	$Loading01.visible = false
	
	# Populate our home content grid with store items
	var grid: HFlowContainer = $HomeContent/ScrollContainer/HFlowContainer
	for i in results:
		var item: StoreItem = i

		# Build a poster for each item on the store home
		var poster: TextureButton = poster_scene.instantiate()
		poster.layout = poster.LAYOUT_MODE.PORTRAIT
		var img: Texture2D = item.texture
		poster.texture_normal = img
		poster.text = item.name
		#poster.pressed.connect(_launch_store.bind(store))
		grid.add_child(poster)

	# Focus the first item
	for child in grid.get_children():
		child.grab_focus.call_deferred()
		break
