extends RefCounted
class_name NetworkManager

## Manage and interact with the system network settings
##
## Allows network management through nmcli
## Reference: https://developer-old.gnome.org/NetworkManager/stable/nmcli.html

const bar_0 := preload("res://assets/ui/icons/wifi-none.svg")
const bar_1 := preload("res://assets/ui/icons/wifi-low.svg")
const bar_2 := preload("res://assets/ui/icons/wifi-medium.svg")
const bar_3 := preload("res://assets/ui/icons/wifi-high.svg")

const common_args := ["--terse", "--color", "no"]


## Wireless Access Point
class WifiAP:
	var in_use: bool
	var bssid: String
	var ssid: String
	var mode: String
	var channel: int
	var rate: String
	var strength: int
	var security: String


## Network device
class NetworkDevice:
	var device: String
	var type: String
	var state: String
	var connection: String


## Returns true if the system has network controls we support
static func supports_network() -> bool:
	var code := OS.execute("which", ["nmcli"])
	return code == 0


## Returns a list of network devices
#$nmcli --terse --color no device
#enp5s0:ethernet:connected:Wired connection 1
#wlp4s0:wifi:connected:Chonenberg
#lo:loopback:connected (externally):lo
#p2p-dev-wlp4s0:wifi-p2p:disconnected:
static func get_devices() -> Array[NetworkDevice]:
	var result: Array[NetworkDevice] = []
	var output := _run_nmcli(["device"])
	for line in output:
		var device := NetworkDevice.new()
		device.device = line[0]
		device.type = line[1]
		device.state = line[2]
		device.connection = line[3]
		result.append(device)

	return result


## Returns a list of available wifi access points
#$ nmcli --terse --color no dev wifi
# :AA\:BB\:CC\:83\:82\:FF:Chronenberg 5GHz:Infra:120:405 Mbit/s:94:▂▄▆█:WPA2
#*:AA\:BB\:CC\:83\:82\:FB:Chonenberg:Infra:11:195 Mbit/s:83:▂▄▆█:WPA2
static func get_access_points() -> Array[WifiAP]:
	var result: Array[WifiAP] = []
	var output := _run_nmcli(["dev", "wifi"])
	for line in output:
		var ap := WifiAP.new()
		ap.in_use = line[0] == "*"
		ap.bssid = line[1]
		ap.ssid = line[2]
		ap.mode = line[3]
		ap.channel = line[4].to_int()
		ap.rate = line[5]
		ap.strength = line[6].to_int()
		ap.security = line[8]
		result.append(ap)

	return result


## Returns the currently connected access point
static func get_current_access_point() -> WifiAP:
	var access_points := get_access_points()
	for ap in access_points:
		if ap.in_use:
			return ap
	return null


## Connect to the given wifi access point
static func connect_access_point(ssid: String, password: String = "") -> int:
	var args := ["dev", "wifi", "connect", ssid]
	if password != "":
		args.append_array(["password", password])
	var output := []
	var code := OS.execute("nmcli", args, output)
	if code != OK:
		push_warning("Unable to connect to ", ssid, ": ", output[0])
	return code


## Returns the texture reflecting the given wifi strength
static func get_strength_texture(strength: int) -> Texture2D:
	if strength >= 80:
		return bar_3
	if strength >= 60:
		return bar_2
	if strength >= 40:
		return bar_1
	return bar_0


# Run nmcli with the given arguments. Returns the parsed output.
static func _run_nmcli(args: PackedStringArray) -> Array[PackedStringArray]:
	var output := []
	var cmd_args := common_args.duplicate()
	cmd_args.append_array(args)
	var code := OS.execute("nmcli", cmd_args, output)
	if code != OK:
		return []

	return _parse_nmcli(output[0])


# Parses the terse output of nmcli, which is separated by ':'
#$ nmcli --terse --color no dev wifi
# :AA\:BB\:CC\:83\:82\:FF:Chronenberg 5GHz:Infra:120:405 Mbit/s:94:▂▄▆█:WPA2
#*:AA\:BB\:CC\:83\:82\:FB:Chonenberg:Infra:11:195 Mbit/s:83:▂▄▆█:WPA2
static func _parse_nmcli(output: String) -> Array[PackedStringArray]:
	var parsed: Array[PackedStringArray] = []
	var lines := output.split("\n")
	for line in lines:
		var parsed_line := PackedStringArray()
		if line == "":
			continue
		line = line.replace("\\:", "%COLON%")
		var columns := line.split(":")
		for column in columns:
			column = column.replace("%COLON%", ":")
			parsed_line.append(column)
		parsed.append(parsed_line)

	return parsed
