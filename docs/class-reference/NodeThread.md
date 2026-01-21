# NodeThread

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)

Node that can run _thread_process on a separate thread
## Description

Allows the extending node to use the _thread_process method to run code in a separate running thread. When emitting signals from _thread_process, be sure to use signal_name.emit.call_deferred
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [SharedThread](../SharedThread) | [thread_group](./#thread_group) |  |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [autostart](./#autostart) | true |



------------------

## Property Descriptions

### `thread_group`


[SharedThread](../SharedThread) thread_group


The [SharedThread](../SharedThread) thread that this node should run on.
### `autostart`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) autostart = <span style="color: red;">true</span>


Whether or not to automatically start the thread on ready

