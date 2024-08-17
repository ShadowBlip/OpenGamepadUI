extends RefCounted
class_name ThemeUtils


## Returns the effective theme of the node. This will visit each parent node
## until it finds a theme and returns it. If no theme is found, null will be
## returned.
static func get_effective_theme(node: Control) -> Theme:
	if not node:
		return null
	var parent := node.get_parent()
	if not parent is Control:
		return null

	var parent_control := parent as Control
	if parent_control.theme:
		return parent_control.theme

	return get_effective_theme(parent_control)
