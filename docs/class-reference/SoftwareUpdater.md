# SoftwareUpdater

**Inherits:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html)


## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [Version](../Version) | [Version](./#Version) | <Object> |
| [PackageVerifier](../PackageVerifier) | [PackageVerifier](./#PackageVerifier) | <Object> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [update_pack_url](./#update_pack_url) | "" |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [github_project](./#github_project) | "ShadowBlip/OpenGamepadUI" |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [update_filename](./#update_filename) | "update.zip" |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [update_hash_filename](./#update_hash_filename) | "update.zip.sha256.txt" |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [update_folder](./#update_folder) | "user://updates" |
| [GitHubClient](../GitHubClient) | [github_client](./#github_client) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| void | [check_for_updates](./#check_for_updates)() |
| void | [install_update](./#install_update)(download_url: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |


------------------

## Property Descriptions

### `Version`


[Version](../Version) Version


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `PackageVerifier`


[PackageVerifier](../PackageVerifier) PackageVerifier


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `update_pack_url`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) update_pack_url = <span style="color: red;">""</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `github_project`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) github_project = <span style="color: red;">"ShadowBlip/OpenGamepadUI"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `update_filename`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) update_filename = <span style="color: red;">"update.zip"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `update_hash_filename`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) update_hash_filename = <span style="color: red;">"update.zip.sha256.txt"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `update_folder`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) update_folder = <span style="color: red;">"user://updates"</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `github_client`


[GitHubClient](../GitHubClient) github_client


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `check_for_updates()`


void **check_for_updates**()


Checks to see if there is a newer version of OpenGamepadUI available.
### `install_update()`


void **install_update**(download_url: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Downloads and installs the given update
