# GitHubClient

**Inherits:** [HTTPAPIClient](../HTTPAPIClient)


## Methods

| Returns | Signature |
| ------- | --------- |
| [Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) | [get_releases](./#get_releases)(project: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), per_page: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 30, page: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 1) |


------------------

## Method Descriptions

### `get_releases()`


[Variant](https://docs.godotengine.org/en/stable/classes/class_variant.html) **get_releases**(project: [String](https://docs.godotengine.org/en/stable/classes/class_string.html), per_page: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 30, page: [int](https://docs.godotengine.org/en/stable/classes/class_int.html) = 1)


Returns the releases for the given project. E.g. "ShadowBlip/OpenGamepadUI" Refer to the GitHub API for data layout: https://api.github.com/repos/ShadowBlip/OpenGamepadUI/releases
