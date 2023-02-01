#ifndef INPUT_DEVICE_EVENT_CLASS_H
#define INPUT_DEVICE_EVENT_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <libevdev/libevdev.h>

namespace evdev {
// Maybe inherit from Resource?
class InputDeviceEvent : public godot::RefCounted {
  GDCLASS(InputDeviceEvent, RefCounted);

private:
protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  InputDeviceEvent();
  ~InputDeviceEvent();

  // Properties
  struct input_event ev;

  // Methods
  unsigned short get_type();
  void set_type(int type);
  godot::String get_type_name();
  unsigned short get_code();
  void set_code(int code);
  godot::String get_code_name();
  int get_value();
  void set_value(int value);

  // Static functions
};
} // namespace evdev
#endif // INPUT_DEVICE_EVENT_CLASS_H
