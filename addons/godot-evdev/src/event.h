#ifndef INPUT_DEVICE_EVENT_CLASS_H
#define INPUT_DEVICE_EVENT_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/core/binder_common.hpp>

namespace evdev {
// Maybe inherit from Resource?
class InputDeviceEvent : public godot::Object {
  GDCLASS(InputDeviceEvent, Object);

private:
  int rc;

protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  InputDeviceEvent();
  ~InputDeviceEvent();

  // Properties
  unsigned short type;
  unsigned short code;
  int value;

  // Methods
  unsigned short get_type();
  godot::String get_type_name();
  unsigned short get_code();
  godot::String get_code_name();
  int get_value();

  // Static functions
};
} // namespace evdev
#endif // INPUT_DEVICE_EVENT_CLASS_H
