@icon("res://assets/editor-icons/visible.svg")
extends Node
class_name VisibilityManager

## Update visibility based on [State] changes to a [StateMachine]
##
## DEPRECATED in favor of [StateWatcher] with a child [Effect].
## The [VisibilityManager] manages the visibility of its parent node based on
## the current [State] of a [StateMachine]. This enables nodes to be visible or
## invisible only during the correct state(s), allowing menus to hide themselves
## or become visible depending on the state. Optionally, [Transition] nodes
## can be added as a child to [VisibilityManager] to play an animation to
## show or hide the node.

signal transition_started
signal transition_finished
signal entered
signal exited

## The state machine instance to use for managing state changes
@export var state_machine: StateMachine = preload(
	"res://assets/state/state_machines/global_state_machine.tres"
)
## Toggles visibility when this state is entered
@export var state: State
## Toggles visibility when any of these states are entered, but the main state
## exists in the state stack
@export var visible_during: Array[Resource] = []

var _transitions: Array[Transition] = []
var logger := Log.get_logger("VisibilityManager", Log.LEVEL.INFO)
@onready var _parent := get_parent() as CanvasItem


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.state_changed.connect(_on_state_changed)
	
	# Handle visibility transitions
	var children := get_children()
	for child in children:
		if not child is Transition:
			continue
			
		var transition := child as Transition
		if not transition.has_animation(transition.enter_animation):
			logger.warn("Transition {0} doesn't have enter animation {1}".format([transition.name, transition.enter_animation]))
			continue
		if not transition.has_animation(transition.exit_animation):
			logger.warn("Transition {0} doesn't have exit animation {1}".format([transition.name, transition.exit_animation]))
			continue
			
		_transitions.append(transition)
		transition.root_node = "../.."


func _on_state_changed(_from: State, to: State) -> void:
	# Transition if this is the state being looked for
	if to == state:
		_transition(true)
		return

	# Loop through the state stack to see if visibility should be maintained.
	var stack := state_machine.stack()
	stack.reverse()
	for s in stack:
		# If the target state is found before reaching the end of the stack, this
		# node should be visible.
		if s == state:
			_transition(true)
			return
		# If the state in the stack is one that this node should be visible during,
		# keep searching for the target state. 
		elif s in visible_during:
			continue
		# If the target state is not found, or a state that is not in the "visible_during"
		# list, then this node should not be visible.
		else:
			break

	_transition(false)


func _transition(visibility: bool) -> void:
	# Set our z-index based on where we are in the state stack
	_parent.z_index = state_machine.stack().find(state)

	# If the parent doesn't have any transitions, flip visibility
	if not has_transitions():
		_parent.visible = visibility
		if visibility:
			entered.emit()
		else:
			exited.emit()
		return

	# Prefer transitions that are children of visibilitymanager
	if _transitions.size() > 0:
		if visibility:
			enter()
			return
		exit()
		return

	# Use transition containers if they exist
	var transition := _parent.get_node("TransitionContainer") as TransitionContainer
	if visibility:
		transition.enter()
		return
	transition.exit()


func has_transitions() -> bool:
	if _transitions.size() > 0 or _parent.has_node("TransitionContainer"):
		return true
	return false


func enter() -> void:
	for transition in _transitions:
		transition.play(transition.enter_animation)
	transition_started.emit()
	
	for transition in _transitions:
		var anim = await transition.animation_finished
		logger.debug("Finished playing: " + anim)
	transition_finished.emit()
	entered.emit()


func exit() -> void:
	for transition in _transitions:
		transition.play(transition.exit_animation)
	transition_started.emit()
	
	for transition in _transitions:
		var anim = await transition.animation_finished
		logger.debug("Finished playing: " + anim)
	transition_finished.emit()
	exited.emit()
