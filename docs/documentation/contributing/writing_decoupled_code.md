# Writing decoupled code in Godot

Writing and maintaining large, complicated code bases is a big
challenge. One of the ways to combat this complexity is to try and write
systems that are modular and composable, with few or no hard
dependencies on other systems. Godot provides several patterns we can
use to help make our code simple and independent. This usually means
taking advantage of Godot's
[signals](https://docs.godotengine.org/en/latest/getting_started/step_by_step/signals.html)
feature, [node
groups](https://docs.godotengine.org/en/latest/tutorials/scripting/groups.html),
and
[resources](https://docs.godotengine.org/en/latest/tutorials/scripting/resources.html).

Some of the ideas below are largely taken from a great
[post](https://www.reddit.com/r/godot/comments/vodp2a/comment/iegv4fs/?utm_source=share&utm_medium=web2x&context=3)
about how to accomplish this in Godot, but modified with OpenGamepadUI
in mind.

Strictly speaking, the idea is to make your scenes behave like nodes.
Nodes can be instanced anywhere in the scene tree and don't care what
their parents or siblings are. Their behavior is encapsulated by the set
of methods, properties, and signals they expose. Consider this mantra:

    Every branch of your scene tree should function independently of its parents.

In other words, if you right click on any node and choose "save branch
to scene", you should be able to run that scene on its own without
getting any errors. Now, it may not actually do anything substantial,
since nothing is controlling it or listening to its signals, but it
shouldn't throw any errors or require any particular type of parent in
order to function properly.

That brings us to the point: what options do you have for preserving
branch independence?

## Export a NodePath

This is admittedly really close to breaking the rules, but it sometimes
makes sense to let your user tell the child node where to find a loose
dependency. The builtin nodes use this trick all over the place. The
`AnimationPlayer` and `AnimationTree` are a good example. The key here
is to have your script "fail safe" and check if the nodepath is unset
before trying to do anything with it.

This approach works best if...

- The external node can be any instance of a builtin class (e.g. any
  `AnimationPlayer`). This isn't a hard requirement, but for scenes and
  custom classes it can become difficult to tell if the user-provided
  dependent node is valid.
- The external node is likely to be in the same scene. You can't set
  node paths in the editor across scenes, and even setting them
  programmatically with scripts can be tricky. If you need this, see the
  next option.
- The external node's state is largely irrelevant to the functioning of
  your node and its children. In other words, your node should be able
  to do everything it needs to do with its own state, but perhaps it
  calls methods on the external node as a side effect. For example, you
  might have one node that plays different animations if you provide it
  with an `AnimationPlayer` node. If you don't give it an animation
  player, all the node's state change stuff will work, it will just skip
  over the animation stuff.

## Use a (custom) resource

The key here is leveraging the fact that resource instances are globally
unique. So if you need a bunch of nodes to share data, without being
bound to a strict hierarchy, this is a great option. Let's say you have
a UI scene that wants to show what the state is of another menu, but god
knows where in the scene tree that menu is in relation to each other.

With the resource approach, you just give the UI scene and the menu
scene access to the same MenuState resource. This resource should fire
signals whenever its various properties are changed. Both the UI and
menu scenes then connect to whichever signals are relevant to them. So,
in this instance, the UI scene might have a bunch of text labels hooked
up to every property of the MenuState, and the menu scene might hook the
signal for "menu changed" up to a method that fires an animation or
something.

Use this approach if...

- The dependency involves some kind of shared state, rather than one
  node directly controlling another.
- The dependency isn't a node.
- You want to propagate a bunch of shared state information through a
  scene tree (think: the `Style` resources that UI controls use). This
  will involve some boilerplate, but it usually scales better because
  child nodes can control themselves based on the resource state instead
  of bloating the parent with a bunch of code that just sets properties
  on the children.

## Use an autoload (or another kind of global)

This option you may already know, and has benefits and drawbacks. 90% of
the time when you want to use autoloads, you probably want to use a
resource instead. However, there are situations where an autoload makes
sense.

Use this approach only if...

- You need a node, but the requirements for the export nodepath approach
  aren't satisfied. To be clear: you only need a node if you are going
  to write a process function. If you just need a data container, or a
  place to put global signals, use a resource instead. If you need
  globally accessible helper methods, use static functions in a script
  (if you define a `class_name` in the script the UX is identical to
  autoloads).
- This node is unique.
- You keep the behavior and state encapsulated by this node to a minimum
  (one approach involves having an autoload that effectively just
  contains references to other resources and nodes).
