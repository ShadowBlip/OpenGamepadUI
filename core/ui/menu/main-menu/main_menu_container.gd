extends MarginContainer

const MainMenu := preload("res://core/ui/menu/main-menu/main_menu.gd")
const InGameMenu := preload("res://core/ui/menu/main-menu/in-game_menu.gd")

var main_menu_state := preload("res://assets/state/states/main_menu.tres") as State
var in_game_menu_state := preload("res://assets/state/states/in_game_menu.tres") as State

@onready var main_menu := $%MainMenu as MainMenu
@onready var in_game_menu := $%InGameMenu as InGameMenu
@onready var main_menu_buttons := main_menu.button_container
@onready var in_game_menu_buttons := in_game_menu.button_container


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_state.state_entered.connect(_on_state_entered)
	main_menu_state.state_exited.connect(_on_state_exited)
	in_game_menu_state.state_entered.connect(_on_state_entered)
	in_game_menu_state.state_exited.connect(_on_state_exited)

	# Recalculate focus on any node changes
	_recalculate_focus(null, false)
	main_menu_buttons.child_entered_tree.connect(_recalculate_focus)
	main_menu_buttons.child_exiting_tree.connect(_recalculate_focus.bind(true))
	in_game_menu_buttons.child_entered_tree.connect(_recalculate_focus)
	in_game_menu_buttons.child_exiting_tree.connect(_recalculate_focus.bind(true))


func _on_state_entered(_from: State) -> void:
	_animate(true)


func _on_state_exited(_to: State) -> void:
	_animate(false)


func _animate(should_show: bool) -> void:
	var player: AnimationPlayer = $AnimationPlayer
	if should_show:
		player.play("show")
	else:
		player.play("hide")


# TODO: We should pull this into a generic node that can handle complex grid focus
func _recalculate_focus(node_changed: Node, exclude: bool = false) -> void:
	var button_rows: Array[Array] = []

	for node in main_menu_buttons.get_children():
		if not node is Button:
			continue
		if exclude and node == node_changed:
			continue
		button_rows.append([node])

	var i := 0
	for node in in_game_menu_buttons.get_children():
		if not node is Button:
			continue
		if exclude and node == node_changed:
			continue
		if i > button_rows.size() - 1:
			button_rows.append([])
		button_rows[i].append(node)
		i += 1

	for y in range(button_rows.size()):
		for x in range(button_rows[y].size()):
			var row := button_rows[y] as Array
			var button := button_rows[y][x] as Button

			# LEFT
			button.focus_neighbor_left = row[x - 1].get_path()

			# UP
			var row_above := button_rows[y - 1]
			var top := _nearest_neighbor(x, row.size(), row_above.size())
			button.focus_neighbor_top = row_above[top].get_path()

			# RIGHT
			var right := x + 1
			if right >= button_rows[y].size():
				right = 0
			button.focus_neighbor_right = row[right].get_path()

			# BOTTOM
			var bottom_y := y + 1
			if bottom_y >= button_rows.size():
				bottom_y = 0
			var row_below := button_rows[bottom_y]
			var bottom := _nearest_neighbor(x, row.size(), row_below.size())
			button.focus_neighbor_bottom = row_below[bottom].get_path()

			button.focus_next = button.focus_neighbor_right
			button.focus_previous = button.focus_neighbor_left


# Returns the index that closest matches how far the given index is in an array
# of the given size in comparision to the given 'to_size'.
# E.g.
#   var a := [1, 2, 3]
#   var b := [1, 2, 3, 4, 5, 6]
#   _nearest_neighbor(2, a.size(), b.size())
# Returns index in 'b' array: 4
func _nearest_neighbor(idx: int, from_size: int, to_size: int) -> int:
	var factor := float(to_size) / float(from_size)
	return int(floor(idx * factor))
