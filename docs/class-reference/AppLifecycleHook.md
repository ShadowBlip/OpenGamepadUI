# AppLifecycleHook

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Base class for executing callbacks at certain points of an app's lifecycle.
## Description

This class provides an interface for executing arbitrary callbacks at certain points of an application's lifecycle. This can allow [Library](../Library) implementations the ability to execute actions when apps are about to start, have started, or have exited.
## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_name](./#get_name)() |
| void | [execute](./#execute)(item: [LibraryLaunchItem](../LibraryLaunchItem)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_type](./#get_type)() |


------------------

## Method Descriptions

### `get_name()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_name**()


Name of the lifecycle hook
### `execute()`


void **execute**(item: [LibraryLaunchItem](../LibraryLaunchItem))


Executes whenever an app from this library reaches the stage in its lifecycle designated by the hook type. E.g. a `PRE_LAUNCH` hook will have this method called whenever an app is about to launch.
### `get_type()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_type**()


Returns the hook type, which designates where in the application's lifecycle the hook should be executed.
