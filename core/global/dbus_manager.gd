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

const IFACE_PROPERTIES := "org.freedesktop.DBus.Properties"
const IFACE_OBJECT_MANAGER := "org.freedesktop.DBus.ObjectManager"

@export var bus_type := BUS_TYPE.SYSTEM

var dbus := DBus.new()
var logger := Log.get_logger("DBusManager")


func _init() -> void:
	if dbus.connect(bus_type) != OK:
		logger.warn("Unable to connect to dbus")
		return


func _process():
	print("Process!")
	pass


## Creates a reference to a DBus object on the given bus at the given path.
## E.g. create_proxy("org.bluez", "/org/bluez/hci0")
func create_proxy(bus: String, path: String) -> Proxy:
	return Proxy.new(dbus, bus, path)


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


## A Proxy provides an interface to call methods on a DBus object.
class Proxy:
	var _dbus: DBus
	var bus_name: String
	var path: String
	
	func _init(conn: DBus, bus: String, obj_path: String) -> void:
		_dbus = conn
		bus_name = bus
		path = obj_path

	## Call the given method
	func call_method(iface: String, method: String, args: Array = []) -> DBusMessage:
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
