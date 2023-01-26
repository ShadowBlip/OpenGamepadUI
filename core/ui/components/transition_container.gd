extends Node
class_name TransitionContainer

signal transition_started
signal transition_finished
signal entered
signal exited

var _transitions: Array[Transition] = []
var logger := Log.get_logger("TransitionContainer")


func _ready() -> void:
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
