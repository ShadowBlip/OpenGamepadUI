# TabSetter

**Inherits:** [BehaviorNode](../BehaviorNode)

Set the current tab on a [TabContainer](https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html) in reaction to a parent signal
## Description

This [BehaviorNode](../BehaviorNode) can be added as a child to any node and configured to listen for a signal. When the parent signal fires, this behavior will set the current tab on the given target [TabContainer](https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html).
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [TabContainer](https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html) | [target](./#target) |  |
| [int](https://docs.godotengine.org/en/stable/classes/class_int.html) | [tab_number](./#tab_number) | 0 |



------------------

## Property Descriptions

### `target`


[TabContainer](https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html) target


The target [TabContainer](https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html) to update the current tab in response to a signal
### `tab_number`


[int](https://docs.godotengine.org/en/stable/classes/class_int.html) tab_number = <span style="color: red;">0</span>


The current tab number to switch to

