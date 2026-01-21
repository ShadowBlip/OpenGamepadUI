# TextSetter

**Inherits:** [BehaviorNode](../BehaviorNode)

Set text on the target [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) node in reaction to a parent signal
## Description

This [BehaviorNode](../BehaviorNode) can be added as a child to any node and configured to listen for a signal. When the parent signal fires, this behavior will set the text on the given target [Label](https://docs.godotengine.org/en/stable/classes/class_label.html).
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) | [target](./#target) |  |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [text](./#text) | "" |



------------------

## Property Descriptions

### `target`


[Label](https://docs.godotengine.org/en/stable/classes/class_label.html) target


The target [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) to update with the given text when a parent signal fires
### `text`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) text = <span style="color: red;">""</span>


The text to set on the target label

