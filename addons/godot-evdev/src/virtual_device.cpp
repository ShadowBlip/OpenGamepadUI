#include "virtual_device.h"
#include "device.h"
#include "event.h"

#include <cerrno>
#include <fcntl.h>
#include <iostream>
#include <libevdev/libevdev-uinput.h>
#include <libevdev/libevdev.h>
#include <linux/input.h>
#include <linux/uinput.h>
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
using godot::Array;
using godot::D_METHOD;
using godot::String;

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
int VirtualInputDevice::write_event(int type, int code, int value) {
  int err = 0;
  err = libevdev_uinput_write_event(uidev, type, code, value);
  return err;
}

// Read events from the virtual device. This should be UINPUT events
Array VirtualInputDevice::get_events() {
  Array events = Array();

  struct input_event event_arr[64];
  size_t event_size = sizeof(struct input_event);
  ssize_t nread = read(uifd, event_arr, event_size * 64);

  // No events to read
  if (nread < 0) {
    return events;
  }

  // Loop through all read events
  for (unsigned i = 0; i < nread / event_size; i++) {
    InputDeviceEvent *event = memnew(InputDeviceEvent());
    memcpy(&(event->ev), &event_arr[i], sizeof(event_arr[i]));
    events.append(event);
  }

  return events;
}

String VirtualInputDevice::get_syspath() {
  if (!is_open()) {
    return String();
  }
  return String(libevdev_uinput_get_syspath(uidev));
}

String VirtualInputDevice::get_devnode() {
  if (!is_open()) {
    return String();
  }
  return String(libevdev_uinput_get_devnode(uidev));
}

// Register the methods with Godot
void VirtualInputDevice::_bind_methods() {
  // Properties

  // Methods
  godot::ClassDB::bind_method(D_METHOD("close"), &VirtualInputDevice::close);
  godot::ClassDB::bind_method(D_METHOD("get_events"),
                              &VirtualInputDevice::get_events);
  godot::ClassDB::bind_method(D_METHOD("is_open"),
                              &VirtualInputDevice::is_open);
  godot::ClassDB::bind_method(D_METHOD("write_event", "event"),
                              &VirtualInputDevice::write_event);
  godot::ClassDB::bind_method(D_METHOD("get_syspath"),
                              &VirtualInputDevice::get_syspath);
  godot::ClassDB::bind_method(D_METHOD("get_devnode"),
                              &VirtualInputDevice::get_devnode);
  // Static methods

  // Constants
};

} // namespace evdev
