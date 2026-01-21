# NotificationManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Resource API for displaying arbitrary notifications
## Description

The NotificationManager is responsible for providing an API to display arbitrary notifications to the user and maintain a history of those notifications. It also manages a queue of notifications so only one notification shows at a time.


```gdscript

    const NotificationManager := preload("res://core/global/notification_manager.tres")
    ...
    var notify := Notification.new("Hello world!")
    notify.icon = load("res://assets/icons/critical.png")
    NotificationManager.show(notify)

```


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [SettingsManager](../SettingsManager) | [settings_manager](./#settings_manager) | <unknown> |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [ready](./#ready) | false |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [show](./#show)(notify: [Notification](../Notification)) |
| [Notification[]](../Notification) | [get_notification_history](./#get_notification_history)() |
| void | [show_notification](./#show_notification)(text: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), icon: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) = null, timeout_sec: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 5.0) |
| [bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) | [has_next](./#has_next)() |
| [Notification](../Notification) | [next](./#next)() |


------------------

## Property Descriptions

### `settings_manager`


[SettingsManager](../SettingsManager) settings_manager


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `ready`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) ready = <span style="color: red;">false</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `show()`


void **show**(notify: [Notification](../Notification))


Queues the given notification to be shown
### `get_notification_history()`


[Notification[]](../Notification) **get_notification_history**()


Returns a list of notifications
### `show_notification()`


void **show_notification**(text: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), icon: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) = null, timeout_sec: [float](https://docs.godotengine.org/en/stable/classes/class_float.html) = 5.0)


!!! note
    There is currently no description for this method. Please help us by contributing one!

### `has_next()`


[bool](https://docs.godotengine.org/en/stable/classes/class_bool.html) **has_next**()


Returns whether there are notifiations waiting in the queue
### `next()`


[Notification](../Notification) **next**()


Returns the next notifiation waiting in the queue
