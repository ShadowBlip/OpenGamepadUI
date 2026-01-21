# Xdg

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)


## Methods

| Returns | Signature |
| ------- | --------- |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_data_dirs](./#get_data_dirs)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [with_system_path](./#with_system_path)(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Method Descriptions

### `get_data_dirs()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_data_dirs**()


Return a list of system data paths in load preference order.
### `with_system_path()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **with_system_path**(path: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Return the XDG system data path with the given relative path. For example, using `Xdg.with_system_path("hwdata")` will return "/usr/share/hwdata". If XDG is unable to determine the path, the fallback prefix of "/usr/share" will be used.
