# FeatureFlags

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Registry of feature flags
## Description

FeatureFlags parses command-line arguments and environment variables to turn features on or off, and allows features to be toggled at runtime by plugins and platform classes. Signals are emitted when a feature changes so the UI can react.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Feature[]](../Feature) | [features](./#features) | [] |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [register_feature](./#register_feature)(feature: [Feature](../Feature)) |
| [Feature](../Feature) | [get_feature](./#get_feature)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [Feature[]](../Feature) | [get_features](./#get_features)() |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [is_enabled](./#is_enabled)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [set_feature](./#set_feature)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), enabled: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html)) |
| void | [enable](./#enable)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [disable](./#disable)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [toggle](./#toggle)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [reset](./#reset)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [get_source](./#get_source)(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [clear_sources](./#clear_sources)() |
| void | [parse_args](./#parse_args)(args: [String[]](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| void | [parse_env](./#parse_env)(env: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html)) |
| void | [load_from_os](./#load_from_os)() |


------------------

## Property Descriptions

### `features`


[Feature[]](../Feature) features = <span style="color: red;">[]</span>


The registered features.
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `register_feature()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **register_feature**(feature: [Feature](../Feature))


Registers a feature. Returns OK if the feature was newly registered.
### `get_feature()`


[Feature](../Feature) **get_feature**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns the registered feature with the given id, or null if it is not registered.
### `get_features()`


[Feature[]](../Feature) **get_features**()


Returns all registered features.
### `is_enabled()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **is_enabled**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns whether the given feature is enabled. Unknown features return false.
### `set_feature()`


void **set_feature**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), enabled: [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html))


Sets a feature at runtime. The runtime value takes precedence over all sources.
### `enable()`


void **enable**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `disable()`


void **disable**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `toggle()`


void **toggle**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `reset()`


void **reset**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Clears the runtime override so the feature resolves from its sources again.
### `get_source()`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) **get_source**(id: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns which source produced the current value of the given feature.
### `clear_sources()`


void **clear_sources**()


Clears all parsed values so the sources can be applied again.
### `parse_args()`


void **parse_args**(args: [String[]](https://docs.godotengine.org/en/stable/classes/class_string.html))


Applies the given command-line arguments. Testable entrypoint.
### `parse_env()`


void **parse_env**(env: [Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html))


Applies the given environment variables. Testable entrypoint.
### `load_from_os()`


void **load_from_os**()


Parses the process command-line arguments and environment.
