extends Resource
class_name DBusManager

## DBusManager is a helper class for using DBus
##
## Use this class to interface with DBus.

enum BUS_TYPE {
	SYSTEM =  dbus.DBUS_BUS_SYSTEM,
	SESSION = dbus.DBUS_BUS_SESSION,
	STARTER = dbus.DBUS_BUS_STARTER,
}

const DBUS_BUS := "org.freedesktop.DBus"
const DBUS_PATH := "/org/freedesktop/DBus"

const IFACE_DBUS := "org.freedesktop.DBus"
const IFACE_PROPERTIES := "org.freedesktop.DBus.Properties"
const IFACE_OBJECT_MANAGER := "org.freedesktop.DBus.ObjectManager"

## Type of bus to connect to
@export var bus_type := BUS_TYPE.SYSTEM
## Shared thread to process DBus messages on
@export var thread: SharedThread = load("res://core/systems/threading/system_thread.tres")

var logger := Log.get_logger("DBusManager", Log.LEVEL.DEBUG)
var well_known_names := []
var dbus := DBus.new()
var dbus_proxy := DBusProxy.new(create_proxy(DBUS_BUS, DBUS_PATH))


func _init() -> void:
	if dbus.connect(bus_type) != OK:
		logger.warn("Unable to connect to dbus")
		return
	thread.add_process(process)
	thread.start()


## Process messages on the bus that are being watched and dispatch them.
func process(_delta: float):
	var msg := dbus.pop_message()
	if not msg:
		return
	logger.debug("Received DBus message on " + msg.get_sender() + " from " + msg.get_path() + ": " + str(msg.get_args()))
	
	# Try looking up the well-known name of the message sender
	var known_names := get_names_for_owner(msg.get_sender())
	
	# Try constructing the resource path to the proxy and see if it exists
	for known_name in known_names:
		var res_path := "dbus://" + known_name + msg.get_path()
		if not ResourceLoader.exists(res_path):
			logger.debug("No proxy resource found to send message to at: " + res_path)
			continue
		logger.debug("Found proxy to send message signal to at: " + res_path)
		var proxy := load(res_path) as Proxy
		var send_signal := func(message: DBusMessage):
			proxy.message_received.emit(message)
		send_signal.call_deferred(msg)
		break


## Creates a reference to a DBus object on the given bus at the given path.
## E.g. create_proxy("org.bluez", "/org/bluez/hci0")
func create_proxy(bus: String, path: String) -> Proxy:
	# Try to load the proxy if it already exists
	var res_path := "dbus://" + bus + path
	logger.debug("Creating proxy with resource path: " + res_path)
	var proxy: Proxy
	if ResourceLoader.exists(res_path):
		logger.debug("Resource already exists. Returning existing instance.")
		proxy = load(res_path)
		return proxy

	proxy = Proxy.new(dbus, bus, path)
	proxy.take_over_path(res_path)
	
	# Keep track of bus names so they can be referenced later
	if not bus in well_known_names:
		well_known_names.append(bus)

	return proxy


## Returns a dictionary of manages objects for the given bus and path
func get_managed_objects(bus: String, path: String) -> Array[ManagedObject]:
	var obj := create_proxy(bus, path)
	var result := obj.call_method(IFACE_OBJECT_MANAGER, "GetManagedObjects", [])
	if not result:
		return []
	var args := result.get_args()
	if args.size() != 1:
		return []
	if not args[0] is Dictionary:
		return []
	
	var objs_dict := args[0] as Dictionary
	var objects: Array[ManagedObject] = []
	
	# Convert the objects dictionary into an array of objects
	for obj_path in objs_dict.keys():
		var obj_data := objs_dict[obj_path] as Dictionary
		var object := ManagedObject.new(obj_path, obj_data)
		objects.append(object)
	
	return objects


## Tries to resolve well-known names (e.g. "org.bluez") from the given owner (e.g. ":1.5").
## This will return an array of well-known names.
func get_names_for_owner(owner: String) -> PackedStringArray:
	var names := PackedStringArray()
	for name in well_known_names:
		var name_owner := dbus_proxy.get_name_owner(name)
		if name_owner == owner:
			names.append(name)
	
	return names


## A Proxy provides an interface to call methods on a DBus object.
class Proxy extends Resource:
	signal message_received(msg: DBusMessage)
	signal properties_changed(iface: String, props: Dictionary)
	var _dbus: DBus
	var bus_name: String
	var path: String
	var rules := PackedStringArray()
	var logger := Log.get_logger("DBusProxy")
	
	func _init(conn: DBus, bus: String, obj_path: String) -> void:
		_dbus = conn
		bus_name = bus
		path = obj_path
		message_received.connect(_on_property_changed)
		if watch(IFACE_PROPERTIES, "PropertiesChanged") != OK:
			logger.warn("Unable to watch " + obj_path)

	func _on_property_changed(msg: DBusMessage) -> void:
		if not msg:
			return
		if msg.get_member() != "PropertiesChanged":
			return
		var args := msg.get_args()
		if args.size() < 2:
			return
		properties_changed.emit(args[0], args[1])

	func _notification(what: int) -> void:
		if what != NOTIFICATION_PREDELETE:
			return
		for rule in rules:
			logger.debug("Removing watch rule: " + rule)
			_dbus.remove_match(rule)

	## Call the given method
	func call_method(iface: String, method: String, args: Array = []) -> DBusMessage:
		logger.debug("Calling method: " + iface + "::" + method + "(" + str(args) + ")")
		return _dbus.send_with_reply_and_block(bus_name, path, iface, method, args)

	## Get the given property
	func get_property(iface: String, property: String) -> Variant:
		var response := call_method(IFACE_PROPERTIES, "Get", [iface, property])
		if not response:
			return null
		var args := response.get_args()
		if args.size() == 0:
			return null
		
		return args[0]
	
	## Get all properties for the given interface
	func get_properties(iface: String) -> Dictionary:
		var response := call_method(IFACE_PROPERTIES, "GetAll", [iface])
		if not response:
			return {}
		var args := response.get_args()
		if args.size() == 0:
			return {}
		
		return args[0]

	## Watch the bus for particular signals
	func watch(iface: String, member: String = "PropertiesChanged") -> int:
		var rule := "type='signal',interface='{0}',path='{1}',member='{2}'".format(
			[iface, path, member]
		)
		rules.append(rule)
		logger.debug("Adding watch rule: " + rule)
		return _dbus.add_match(rule)


## A ManagedObject is a simple structure used with GetManagedObjects
class ManagedObject:
	var path: String
	var data: Dictionary

	func _init(obj_path: String, obj_data: Dictionary) -> void:
		path = obj_path
		data = obj_data
	
	func has_interface(name: String) -> bool:
		return name in data
	
	func has_interface_attr(iface: String, name: String) -> bool:
		if not iface in data:
			return false
		if not name in data[iface]:
			return false
		return true


## Proxy to manage /org/freedesktop/DBus on the org.freedesktop.DBus bus.
class DBusProxy:
	var _proxy: Proxy

	func _init(proxy: Proxy) -> void:
		_proxy = proxy

	## Return the connection name (e.g. ":1.1270") from the given well-known name
	func get_name_owner(name: String) -> String:
		var msg := _proxy.call_method(IFACE_DBUS, "GetNameOwner", [name])
		if not msg:
			return ""
		var args := msg.get_args()
		if args.size() != 1:
			return ""
		
		return args[0]
