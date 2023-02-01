#include "event.h"

#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/string.hpp"
#include <libevdev/libevdev.h>

namespace evdev {
using godot::D_METHOD;
using godot::String;

InputDeviceEvent::InputDeviceEvent(){};
InputDeviceEvent::~InputDeviceEvent(){};

unsigned short InputDeviceEvent::get_type() { return type; }
godot::String InputDeviceEvent::get_type_name() {
  return String(libevdev_event_type_get_name(type));
}

unsigned short InputDeviceEvent::get_code() { return code; }
godot::String InputDeviceEvent::get_code_name() {
  return String(libevdev_event_code_get_name(type, code));
}
int InputDeviceEvent::get_value() { return value; }

// Register the methods with Godot
void InputDeviceEvent::_bind_methods() {
  // Properties

  // Methods
  godot::ClassDB::bind_method(D_METHOD("get_type"),
                              &InputDeviceEvent::get_type);
  godot::ClassDB::bind_method(D_METHOD("get_type_name"),
                              &InputDeviceEvent::get_type_name);
  godot::ClassDB::bind_method(D_METHOD("get_code"),
                              &InputDeviceEvent::get_code);
  godot::ClassDB::bind_method(D_METHOD("get_code_name"),
                              &InputDeviceEvent::get_code_name);
  godot::ClassDB::bind_method(D_METHOD("get_value"),
                              &InputDeviceEvent::get_value);

  // Static methods

  // Constants
};
} // namespace evdev
