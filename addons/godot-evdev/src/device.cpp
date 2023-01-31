#include "device.h"

#include <fcntl.h>
#include <iostream>
#include <libevdev/libevdev-uinput.h>
#include <libevdev/libevdev.h>
#include <linux/input.h>
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
using godot::D_METHOD;
using godot::ERR_CANT_OPEN;
using godot::String;

InputDevice::InputDevice(){};
InputDevice::~InputDevice() {
  // Close our file descriptors
  close();
};

// Opens the given device
int InputDevice::open(String device) {
  // Certain operations are only possible when opened in read-write mode
  fd = ::open(device.ascii().get_data(), O_RDWR | O_NONBLOCK);
  if (fd < 0) {
    godot::UtilityFunctions::push_error("Unable to open input device: ",
                                        device);
    return ERR_CANT_OPEN;
  }
  int code = libevdev_new_from_fd(fd, &dev);
  if (code < 0) {
    ::close(fd);
    godot::UtilityFunctions::push_error("Failed to init libevdev: ", device);
    return ERR_CANT_OPEN;
  }
  path = device;

  return godot::OK;
};

// Close the device
int InputDevice::close() {
  int code = 0;
  if (fd > 0) {
    code = ::close(fd);
  }
  if (code < 0) {
    return godot::ERR_CANT_OPEN;
  }
  fd = 0;
  return code;
};

// Gets the device name
String InputDevice::get_name() {
  const char *name_str = libevdev_get_name(dev);
  return String(name_str);
}

// Return path
String InputDevice::get_path() { return path; };

// Device info functions
int InputDevice::get_bustype() { return libevdev_get_id_bustype(dev); }
int InputDevice::get_vendor() { return libevdev_get_id_vendor(dev); }
int InputDevice::get_product() { return libevdev_get_id_product(dev); }
int InputDevice::get_version() { return libevdev_get_id_version(dev); }

// Returns whether the device is currently open
bool InputDevice::is_open() { return fd > 0; };

// Register the methods with Godot
void InputDevice::_bind_methods() {
  // Properties

  // Methods
  godot::ClassDB::bind_method(D_METHOD("open", "dev"), &InputDevice::open);
  godot::ClassDB::bind_method(D_METHOD("close"), &InputDevice::close);
  godot::ClassDB::bind_method(D_METHOD("get_path"), &InputDevice::get_path);
  godot::ClassDB::bind_method(D_METHOD("get_name"), &InputDevice::get_name);
  godot::ClassDB::bind_method(D_METHOD("get_bustype"),
                              &InputDevice::get_bustype);
  godot::ClassDB::bind_method(D_METHOD("get_vendor"), &InputDevice::get_vendor);
  godot::ClassDB::bind_method(D_METHOD("get_product"),
                              &InputDevice::get_product);
  godot::ClassDB::bind_method(D_METHOD("get_version"),
                              &InputDevice::get_version);
  godot::ClassDB::bind_method(D_METHOD("is_open"), &InputDevice::is_open);

  // Static methods

  // Constants
  BIND_CONSTANT(EV_VERSION);
  BIND_CONSTANT(EV_SYN);
};
} // namespace evdev
