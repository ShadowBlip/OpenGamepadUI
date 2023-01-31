#ifndef INPUT_DEVICE_CLASS_H
#define INPUT_DEVICE_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/core/binder_common.hpp>

#include <libevdev/libevdev.h>

namespace evdev {
// Maybe inherit from Resource?
class InputDevice : public godot::Object {
  GDCLASS(InputDevice, Object);

private:
  int fd;
  struct libevdev *dev = NULL;

  godot::String path;

protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  InputDevice();
  ~InputDevice();

  // Properties

  // Methods
  int open(godot::String dev);
  int close();
  bool is_open();
  godot::String get_path();
  godot::String get_name();
  int get_bustype();
  int get_vendor();
  int get_product();
  int get_version();

  // Static functions
};
} // namespace evdev
#endif // INPUT_DEVICE_CLASS_H
