extends Resource
class_name PlatformAction

var logger := Log.get_logger("PlatformAction")

## Executes the given platform action. This should be overriden in the child
## class implementation.
func execute() -> void:
	pass
