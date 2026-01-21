# Best practices

## #1 Always start with an issue

Coordinating an open source project is hard. One of the most important
steps to contributing is opening an issue describing the bug or feature
you want to work on, and discussing if/how the problem should be
resolved or implemented. Maintaining a large code base is difficult and
implementation and coordination is key.

## #2 Prefer small scope pull requests

Pull requests should try to be small in scope and only address one
relevant feature or bug. Try not to include unrelated fixes or features
in the same pull request. Open a separate one for each issue you
address.

## #3 Prefer standalone, composable, decoupled solutions

When contributing code for bugs or features, try to ensure that your
solution is as independent and decoupled from other systems as possible.
This usually means taking advantage of Godot's
[signals](https://docs.godotengine.org/en/latest/getting_started/step_by_step/signals.html)
feature, [node
groups](https://docs.godotengine.org/en/latest/tutorials/scripting/groups.html),
and
[resources](https://docs.godotengine.org/en/latest/tutorials/scripting/resources.html).
Your solution should be able to run independently, even if other systems
you rely on might not be available.

## #4 Prefer solutions without external dependencies

OpenGamepadUI aims to be portable and not rely on system-installed
dependencies. In some cases not every problem has a simple solution, so
sometimes the right choice is to rely on a third-party dependency, but
try to create a self-contained solution, if possible.
