# ThemeUtils

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)


## Methods

| Returns | Signature |
| ------- | --------- |
| [Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html) | [get_effective_theme](./#get_effective_theme)(node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html)) |


------------------

## Method Descriptions

### `get_effective_theme()`


[Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html) **get_effective_theme**(node: [Control](https://docs.godotengine.org/en/stable/classes/class_control.html))


Returns the effective theme of the node. This will visit each parent node until it finds a theme and returns it. If no theme is found, null will be returned.
