#include "virtual_device.h"
#include "device.h"
#include "event.h"

#include <cerrno>
#include <fcntl.h>
#include <iostream>
#include <libevdev/libevdev-uinput.h>
#include <libevdev/libevdev.h>
#include <linux/input.h>
#include <stdio.h>
#include <unistd.h>

#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/core/memory.hpp"
#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/variant/utility_functions.hpp>

// Reference:
// https://www.freedesktop.org/software/libevdev/doc/latest/group__uinput.html

namespace evdev {
using godot::D_METHOD;

VirtualInputDevice::VirtualInputDevice(){};
VirtualInputDevice::~VirtualInputDevice() { close(); };

// Close the device
int VirtualInputDevice::close() {
  if (uidev == NULL) {
    return 0;
  }
  libevdev_uinput_destroy(uidev);
  int code = ::close(uifd);
  uidev = NULL;

  return code;
};

// Returns true if the device has a valid uinput device
bool VirtualInputDevice::is_open() { return (uidev != NULL); };

// Write the given event to the virtual device
int VirtualInputDevice::write_event(InputDeviceEvent *event) {
  int err = 0;
  err = libevdev_uinput_write_event(uidev, event->get_type(), event->get_code(),
                                    event->get_value());
  return err;
}

// Register the methods with Godot
void VirtualInputDevice::_bind_methods() {
  // Properties

  // Methods
  godot::ClassDB::bind_method(D_METHOD("close"), &VirtualInputDevice::close);
  godot::ClassDB::bind_method(D_METHOD("is_open"),
                              &VirtualInputDevice::is_open);
  godot::ClassDB::bind_method(D_METHOD("write_event", "event"),
                              &VirtualInputDevice::write_event);
  // Static methods

  // Constants
};

} // namespace evdev
