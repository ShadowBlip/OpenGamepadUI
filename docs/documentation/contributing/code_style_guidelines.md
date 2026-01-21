# Code Style Guidelines

In general, OpenGamepadUI tries to conform to using the official
GDScript style guide from Godot:

<https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/gdscript_styleguide.html>

Some additional guidelines to try and follow are:

- Always use type annotations. Knowing our types is half the battle

Good

``` gdscript
func do_something(button: Button) -> void:
    var button_name := button.name
```

Bad

``` gdscript
func do_something(button):
    var button_name = button.name
```
