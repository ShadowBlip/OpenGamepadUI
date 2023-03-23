extends Node
class_name NodeThread

## Node that can run _thread_process on a separate thread
##
## Allows the extending node to use the _thread_process method to run code in
## a separate running thread. When emitting signals from _thread_process, be sure
## to use signal_name.emit.call_deferred

## The [SharedThread] thread that this node should run on.
@export var thread_group: SharedThread
## Whether or not to automatically start the thread on ready
@export var autostart := true


func _init() -> void:
	ready.connect(_on_ready)
	tree_exiting.connect(_on_exiting_tree)


func _on_ready() -> void:
	if thread_group == null:
		push_error("No thread group assigned to node thread!")
		assert(thread_group != null)
	thread_group.add_node(self)
	if not autostart:
		return
	thread_group.start()


func _on_exiting_tree() -> void:
	thread_group.remove_node(self)


## Should be overriden in the child class. Will get executed by the thread every
## tick.
func _thread_process(delta: float) -> void:
	pass
