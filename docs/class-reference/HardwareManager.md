# HardwareManager

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

Discover and queries different aspects of the hardware
## Description

HardwareManager is responsible for providing a way to discover and query different aspects of the current hardware.
## Properties

| Type | Name | Default |
| ---- | ---- | ------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [pci_ids_path](./#pci_ids_path) | <unknown> |
| [APUDatabase](../APUDatabase) | [amd_apu_database](./#amd_apu_database) | <unknown> |
| [APUDatabase](../APUDatabase) | [intel_apu_database](./#intel_apu_database) | <unknown> |
| [APUDatabase](../APUDatabase) | [dmi_overrides_apu_database](./#dmi_overrides_apu_database) | <unknown> |
| [CustomLogger](../CustomLogger) | [logger](./#logger) | <unknown> |
| [DRMCardInfo[]](../DRMCardInfo) | [cards](./#cards) | get_gpu_cards() |
| [DRMCardPort[]](../DRMCardPort) | [card_ports](./#card_ports) |  |
| [CPU](../CPU) | [cpu](./#cpu) | get_cpu() |
| [HardwareManager.GPUInfo](../HardwareManager.GPUInfo) | [gpu](./#gpu) | get_gpu_info() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [bios](./#bios) | get_bios_version() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [kernel](./#kernel) | get_kernel_version() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [product_name](./#product_name) | get_product_name() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [vendor_name](./#vendor_name) | get_vendor_name() |
| [SharedThread](../SharedThread) | [thread](./#thread) | <unknown> |

## Methods

| Returns | Signature |
| ------- | --------- |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_bios_version](./#get_bios_version)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_product_name](./#get_product_name)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_vendor_name](./#get_vendor_name)() |
| [CPU](../CPU) | [get_cpu](./#get_cpu)() |
| [HardwareManager.GPUInfo](../HardwareManager.GPUInfo) | [get_gpu_info](./#get_gpu_info)() |
| [String](https://docs.godotengine.org/en/stable/classes/class_string.html) | [get_kernel_version](./#get_kernel_version)() |
| [DRMCardInfo](../DRMCardInfo) | [get_gpu_card](./#get_gpu_card)(card_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html)) |
| [DRMCardInfo[]](../DRMCardInfo) | [get_gpu_cards](./#get_gpu_cards)() |
| [DRMCardInfo](../DRMCardInfo) | [get_active_gpu_card](./#get_active_gpu_card)() |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [get_active_gpu_device](./#get_active_gpu_device)() |
| void | [start_gpu_watch](./#start_gpu_watch)() |


------------------

## Property Descriptions

### `pci_ids_path`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) pci_ids_path


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `amd_apu_database`


[APUDatabase](../APUDatabase) amd_apu_database


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `intel_apu_database`


[APUDatabase](../APUDatabase) intel_apu_database


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `dmi_overrides_apu_database`


[APUDatabase](../APUDatabase) dmi_overrides_apu_database


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `logger`


[CustomLogger](../CustomLogger) logger


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `cards`


[DRMCardInfo[]](../DRMCardInfo) cards = <span style="color: red;">get_gpu_cards()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `card_ports`


[DRMCardPort[]](../DRMCardPort) card_ports


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `cpu`


[CPU](../CPU) cpu = <span style="color: red;">get_cpu()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `gpu`


[HardwareManager.GPUInfo](../HardwareManager.GPUInfo) gpu = <span style="color: red;">get_gpu_info()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `bios`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) bios = <span style="color: red;">get_bios_version()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `kernel`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) kernel = <span style="color: red;">get_kernel_version()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `product_name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) product_name = <span style="color: red;">get_product_name()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `vendor_name`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) vendor_name = <span style="color: red;">get_vendor_name()</span>


!!! note
    There is currently no description for this property. Please help us by contributing one!

### `thread`


[SharedThread](../SharedThread) thread


!!! note
    There is currently no description for this property. Please help us by contributing one!




------------------

## Method Descriptions

### `get_bios_version()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_bios_version**()


Queries /sys/class for BIOS information
### `get_product_name()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_product_name**()


Returns the hardware product name
### `get_vendor_name()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_vendor_name**()


Returns the hardware vendor name
### `get_cpu()`


[CPU](../CPU) **get_cpu**()


Provides info on the CPU vendor, model, and capabilities.
### `get_gpu_info()`


[HardwareManager.GPUInfo](../HardwareManager.GPUInfo) **get_gpu_info**()


Returns the GPUInfo
### `get_kernel_version()`


[String](https://docs.godotengine.org/en/stable/classes/class_string.html) **get_kernel_version**()


Returns the kernel version
### `get_gpu_card()`


[DRMCardInfo](../DRMCardInfo) **get_gpu_card**(card_dir: [String](https://docs.godotengine.org/en/stable/classes/class_string.html))


Returns GPU card info for the given card directory in /sys/class/drm (e.g. get_gpu_card("card1"))
### `get_gpu_cards()`


[DRMCardInfo[]](../DRMCardInfo) **get_gpu_cards**()


Returns an array of CardInfo resources derived from /sys/class/drm
### `get_active_gpu_card()`


[DRMCardInfo](../DRMCardInfo) **get_active_gpu_card**()


Returns the currently active GPU card
### `get_active_gpu_device()`


[PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) **get_active_gpu_device**()


Returns the string of the currently active GPU
### `start_gpu_watch()`


void **start_gpu_watch**()


Starts watching for GPU connector port state changes in a separate thread, updating the properties of [DRMCardPort](../DRMCardPort) objects and emitting signals when their state changes.
