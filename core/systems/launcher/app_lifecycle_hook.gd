extends RefCounted
class_name AppLifecycleHook

## Base class for executing callbacks at certain points of an app's lifecycle.
##
## This class provides an interface for executing arbitrary callbacks at certain
## points of an application's lifecycle. This can allow [Library] implementations
## the ability to execute actions when apps are about to start, have started,
## or have exited.

## Emit this signal if you want to indicate progression of the hook.
signal progressed(percent: float)
## Emit this signal whenever you want custom text to be displayed
signal notified(text: String)

## The type of hook determines where in the application's lifecycle this hook
## should be executed.
enum TYPE {
	## Executes right before an app is launched
	PRE_LAUNCH,
	## Executes right after an app is launched
	LAUNCH,
	## Executed after app exit
	EXIT,
}

var _hook_type: TYPE


func _init(hook_type: TYPE) -> void:
	_hook_type = hook_type


## Name of the lifecycle hook
func get_name() -> String:
	return ""


## Executes whenever an app from this library reaches the stage in its lifecycle
## designated by the hook type. E.g. a `PRE_LAUNCH` hook will have this method
## called whenever an app is about to launch.
func execute(item: LibraryLaunchItem) -> void:
	pass


## Returns the hook type, which designates where in the application's lifecycle
## the hook should be executed.
func get_type() -> TYPE:
	return _hook_type


func _to_string() -> String:
	var kind: String
	match self.get_type():
		TYPE.PRE_LAUNCH:
			kind = "PreLaunch"
		TYPE.LAUNCH:
			kind = "Launch"
		TYPE.EXIT:
			kind = "Exit"
	var name := self.get_name()
	if name.is_empty():
		name = "Anonymous"

	return "<AppLifecycleHook.{0}-{1}>".format([kind, name])
