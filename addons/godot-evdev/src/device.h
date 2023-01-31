#ifndef INPUT_DEVICE_CLASS_H
#define INPUT_DEVICE_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/core/binder_common.hpp>

namespace evdev {
// Maybe inherit from Resource?
class InputDevice : public godot::Object {
  GDCLASS(InputDevice, Object);

private:
  int fd;
  godot::String path;

protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  InputDevice();
  ~InputDevice();

  // Properties
  godot::String get_path();

  // Member functions
  int open(godot::String dev);

  // Static functions
};
} // namespace evdev
#endif // INPUT_DEVICE_CLASS_H
