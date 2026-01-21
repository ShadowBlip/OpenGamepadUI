# PlatformProvider

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Base class that defines a particular platform
## Description

A "platform" can be a particular set of hardware (i.e. a handheld PC), an OS platform, etc. Anything that requires special consideration for OpenGamepadUI to run correctly.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [name](./#name) |  |
| [PlatformAction[]](../PlatformAction) | [startup_actions](./#startup_actions) |  |
| [PlatformAction[]](../PlatformAction) | [shutdown_actions](./#shutdown_actions) |  |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [ready](./#ready)(root: [Window](https://docs.godotengine.org/en/stable/classes/class_window.html)) |


------------------

## Property Descriptions

### `name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) name


Name of the platform
### `startup_actions`


[PlatformAction[]](../PlatformAction) startup_actions


Actions to take upon startup
### `shutdown_actions`


[PlatformAction[]](../PlatformAction) shutdown_actions


Actions to take upon shutdown
### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `ready()`


void **ready**(root: [Window](https://docs.godotengine.org/en/stable/classes/class_window.html))


Ready will be called after the scene tree has initialized. This should be overridden in the child class if the platform wants to make changes to the scene tree.
