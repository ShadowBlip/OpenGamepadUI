# LogManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) | [loggers_by_name](./#loggers_by_name) | {} |
| [Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) | [mutex](./#mutex) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [register](./#register)(logger: [CustomLogger](../CustomLogger)) |
| void | [set_global_log_level](./#set_global_log_level)(level: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [set_log_level](./#set_log_level)(name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), level: [int](https://docs.godotengine.org/en/stable/classes/class_int.html)) |
| void | [set_log_level_from_env](./#set_log_level_from_env)(logger: [CustomLogger](../CustomLogger), env_var: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_available_loggers](./#get_available_loggers)() |


------------------

## Property Descriptions

### `loggers_by_name`


[Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html) loggers_by_name = <span style="color: red;">{}</span>


Mapping of loggers by their name. This is in the form of {"<logger name>": [<logger>, ...](https://docs.godotengine.org/en/stable/classes/class_<logger>, ....html)}
### `mutex`


[Mutex](https://docs.godotengine.org/en/stable/classes/class_mutex.html) mutex


Mutex to allow register/unregister through threads



------------------

## Method Descriptions

### `register()`


void **register**(logger: [CustomLogger](../CustomLogger))


Register the given logger with the LogManager
### `set_global_log_level()`


void **set_global_log_level**(level: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Set the given log level on all loggers
### `set_log_level()`


void **set_log_level**(name: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), level: [int](https://docs.godotengine.org/en/stable/classes/class_int.html))


Sets the log level on loggers with the given name to the given level.
### `set_log_level_from_env()`


void **set_log_level_from_env**(logger: [CustomLogger](../CustomLogger), env_var: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Looks up the given environment variable and sets the log level on the given logger if the variable exists.
### `get_available_loggers()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_available_loggers**()


Return a list of loggers that are currently registered
