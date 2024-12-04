extends RefCounted
class_name AppLifecycleHook

## Base class for executing callbacks at certain points of an app's lifecycle.
##
## This class provides an interface for executing arbitrary callbacks at certain
## points of an application's lifecycle. This can allow [Library] implementations
## the ability to execute actions when apps are about to start, have started,
## or have exited.

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


## Executes whenever an app from this library reaches the stage in its lifecycle
## designated by the hook type. E.g. a `PRE_LAUNCH` hook will have this method
## called whenever an app is about to launch.
func execute(item: LibraryLaunchItem) -> void:
	pass


## Returns the hook type, which designates where in the application's lifecycle
## the hook should be executed.
func get_type() -> TYPE:
	return _hook_type
