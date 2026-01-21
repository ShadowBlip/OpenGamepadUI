# BehaviorNode

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Base class for defining signal-based behavior
## Description

A [BehaviorNode](../BehaviorNode) is a node that follows a signaling pattern. These nodes can be added as a child of any node and can be configured to listen for and react to signals from its parent. This can allow developers to attach behaviors to nodes in the scene tree from the editor in a compositional way.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [on_signal](./#on_signal) |  |



------------------

## Property Descriptions

### `on_signal`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) on_signal


The signal to connect to on this behavior's parent node. This behavior will execute whenever this signal is fired.

