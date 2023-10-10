extends GutTest

var scene := load("res://core/systems/input/focus_group_test.tscn") as PackedScene
var node: Node


func before_each() -> void:
	node = add_child_autofree(scene.instantiate())
	await wait_frames(1, "wait one frame")


func test_focus() -> void:
	var focus_group := node.get_node("MarginContainer/VBoxContainer/FocusGroup") as FocusGroup
	focus_group.grab_focus()
	assert_true(focus_group.is_focused(), "focus group is focused")
