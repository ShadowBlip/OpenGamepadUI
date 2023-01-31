#include "device.h"

#include <fcntl.h>
#include <iostream>
#include <libevdev/libevdev-uinput.h>
#include <libevdev/libevdev.h>
#include <stdio.h>
#include <unistd.h>

#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/variant/utility_functions.hpp>

// References:
// https://github.com/ShadowBlip/HandyGCCS/blob/main/usr/share/handygccs/scripts/handycon.py
// https://github.com/gvalkov/python-evdev/blob/2dd6ce6364bb67eedb209f6aa0bace0c18a3a40a/evdev/device.py#L1

namespace evdev {
using godot::String;

InputDevice::InputDevice(){};
InputDevice::~InputDevice() {
  // Close our file descriptors
  if (fd > 0) {
    ::close(fd);
  }
};

// Opens the given device
int InputDevice::open(String dev) {
  // Certain operations are only possible when opened in read-write mode
  fd = ::open(dev.ascii().get_data(), O_RDWR | O_NONBLOCK);
  if (fd < 0) {
    godot::UtilityFunctions::push_error("Unable to open input device");
    return godot::ERR_CANT_OPEN;
  }
  path = dev;

  return godot::OK;
};

// Return path
godot::String InputDevice::get_path() { return path; };

// Register the methods with Godot
void InputDevice::_bind_methods() {
  // Properties
  godot::ClassDB::bind_method(godot::D_METHOD("get_path"),
                              &InputDevice::get_path);

  // Methods
  godot::ClassDB::bind_method(godot::D_METHOD("open", "dev"),
                              &InputDevice::open);

  // Static methods
};
} // namespace evdev
