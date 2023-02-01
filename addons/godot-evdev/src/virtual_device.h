#ifndef VIRTUAL_INPUT_DEVICE_CLASS_H
#define VIRTUAL_INPUT_DEVICE_CLASS_H

#include "event.h"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>

#include <libevdev/libevdev-uinput.h>
#include <libevdev/libevdev.h>

namespace evdev {
// Maybe inherit from Resource?
class VirtualInputDevice : public godot::RefCounted {
  GDCLASS(VirtualInputDevice, godot::RefCounted);

private:
protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  VirtualInputDevice();
  ~VirtualInputDevice();

  // Properties
  int uifd;
  struct libevdev_uinput *uidev = NULL;

  // Methods
  int write_event(InputDeviceEvent *event);
  bool is_open();
  int close();

  // Static functions
};
} // namespace evdev
#endif // VIRTUAL_INPUT_DEVICE_CLASS_H
