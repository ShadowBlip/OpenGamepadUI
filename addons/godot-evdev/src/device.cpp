#include "device.h"
#include "event.h"
#include "virtual_device.h"

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

// References:
// https://github.com/ShadowBlip/HandyGCCS/blob/main/usr/share/handygccs/scripts/handycon.py
// https://github.com/gvalkov/python-evdev/blob/2dd6ce6364bb67eedb209f6aa0bace0c18a3a40a/evdev/device.py#L1

namespace evdev {
using godot::Array;
using godot::D_METHOD;
using godot::ERR_CANT_OPEN;
using godot::ERR_DOES_NOT_EXIST;
using godot::String;

InputDevice::InputDevice(){};
InputDevice::~InputDevice() {
  // Close our file descriptors
  close();
};

// Opens the given device
int InputDevice::open(String device) {
  // Certain operations are only possible when opened in read-write mode
  int fd;
  fd = ::open(device.ascii().get_data(), O_RDWR | O_NONBLOCK);
  if (fd < 0) {
    fd = ::open(device.ascii().get_data(), O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
      godot::UtilityFunctions::push_error("Unable to open input device: ",
                                          device);
      return ERR_CANT_OPEN;
    }
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
  int fd = get_fd();
  int code = 0;
  if (fd > 0) {
    code = ::close(fd);
  }
  if (code < 0) {
    return godot::ERR_CANT_OPEN;
  }
  libevdev_free(dev);
  return code;
};

VirtualInputDevice *InputDevice::duplicate() {
  if (!is_open()) {
    return nullptr;
  }

  // Open uinput
  struct libevdev_uinput *uidev;
  int uifd = ::open("/dev/uinput", O_RDWR);
  if (uifd < 0) {
    return nullptr;
  }

  // Try to create a new uinput device from the evdev device
  int err = libevdev_uinput_create_from_device(dev, uifd, &uidev);
  if (err != 0)
    return nullptr;

  // Create a virtual uinput device
  VirtualInputDevice *virt_dev = memnew(VirtualInputDevice());
  virt_dev->uifd = uifd;
  virt_dev->uidev = uidev;

  return virt_dev;
}

// Return the file descriptor of the given device
int InputDevice::get_fd() {
  if (dev == NULL) {
    return 0;
  }
  return libevdev_get_fd(dev);
}

// Grabs the device for exclusive access
int InputDevice::grab(bool mode) {
  if (!is_open()) {
    return ERR_DOES_NOT_EXIST;
  }
  int code = 0;
  if (mode) {
    code = libevdev_grab(dev, LIBEVDEV_GRAB);
    if (code == 0) {
      grabbed = true;
    }
  } else {
    code = libevdev_grab(dev, LIBEVDEV_UNGRAB);
    if (code == 0) {
      grabbed = false;
    }
    grabbed = false;
  }
  return code;
}

// Gets the device name
String InputDevice::get_name() {
  if (!is_open()) {
    return "";
  }
  const char *name_str = libevdev_get_name(dev);
  return String(name_str);
}

// Return path
String InputDevice::get_path() { return path; };

// Device info functions
int InputDevice::get_bustype() {
  if (!is_open()) {
    return ERR_DOES_NOT_EXIST;
  }
  return libevdev_get_id_bustype(dev);
}

int InputDevice::get_vendor() {
  if (!is_open()) {
    return ERR_DOES_NOT_EXIST;
  }
  return libevdev_get_id_vendor(dev);
}

int InputDevice::get_product() {
  if (!is_open()) {
    return ERR_DOES_NOT_EXIST;
  }
  return libevdev_get_id_product(dev);
}

int InputDevice::get_version() {
  if (!is_open()) {
    return ERR_DOES_NOT_EXIST;
  }
  return libevdev_get_id_version(dev);
}

String InputDevice::get_phys() {
  if (!is_open()) {
    return "";
  }
  const char *phys = libevdev_get_phys(dev);
  return String(phys);
}

bool InputDevice::has_event_type(unsigned int event_type) {
  if (!is_open()) {
    return false;
  }
  return libevdev_has_event_type(dev, event_type);
}

bool InputDevice::has_event_code(unsigned int event_type,
                                 unsigned int event_code) {
  if (!is_open()) {
    return false;
  }

  return libevdev_has_event_code(dev, event_type, event_code);
}

// Get the next event from the device
// https://www.freedesktop.org/software/libevdev/doc/latest/group__events.html#gabb96c864e836c0b98788f4ab771c3a76
Array InputDevice::get_events() {
  Array events = Array();
  if (!is_open()) {
    return events;
  }

  struct input_event ev;
  int rc = LIBEVDEV_READ_STATUS_SUCCESS;
  do {
    if (rc == LIBEVDEV_READ_STATUS_SYNC) {
      rc = libevdev_next_event(dev, LIBEVDEV_READ_FLAG_SYNC, &ev);
    } else {
      rc = libevdev_next_event(dev, LIBEVDEV_READ_FLAG_NORMAL, &ev);
      InputDeviceEvent *event = memnew(InputDeviceEvent());
      memcpy(&(event->ev), &ev, sizeof(ev));
      events.append(event);
    }
  } while (rc >= 0);

  return events;
}

// Returns whether the device is currently open
bool InputDevice::is_open() { return libevdev_get_fd(dev) > 0; };
bool InputDevice::is_grabbed() { return grabbed; };

// ABS info
int InputDevice::get_abs_min(unsigned int event_code) {
  return libevdev_get_abs_minimum(dev, event_code);
};

int InputDevice::get_abs_max(unsigned int event_code) {
  return libevdev_get_abs_maximum(dev, event_code);
};

int InputDevice::get_abs_fuzz(unsigned int event_code) {
  return libevdev_get_abs_fuzz(dev, event_code);
};

int InputDevice::get_abs_flat(unsigned int event_code) {
  return libevdev_get_abs_flat(dev, event_code);
};

int InputDevice::get_abs_resolution(unsigned int event_code) {
  return libevdev_get_abs_resolution(dev, event_code);
};

// Register the methods with Godot
void InputDevice::_bind_methods() {
  // Properties

  // Methods
  godot::ClassDB::bind_method(D_METHOD("open", "dev"), &InputDevice::open);
  godot::ClassDB::bind_method(D_METHOD("close"), &InputDevice::close);
  godot::ClassDB::bind_method(D_METHOD("duplicate"), &InputDevice::duplicate);
  godot::ClassDB::bind_method(D_METHOD("grab", "mode"), &InputDevice::grab);
  godot::ClassDB::bind_method(D_METHOD("get_fd"), &InputDevice::get_fd);
  godot::ClassDB::bind_method(D_METHOD("get_path"), &InputDevice::get_path);
  godot::ClassDB::bind_method(D_METHOD("get_name"), &InputDevice::get_name);
  godot::ClassDB::bind_method(D_METHOD("get_bustype"),
                              &InputDevice::get_bustype);
  godot::ClassDB::bind_method(D_METHOD("get_vendor"), &InputDevice::get_vendor);
  godot::ClassDB::bind_method(D_METHOD("get_product"),
                              &InputDevice::get_product);
  godot::ClassDB::bind_method(D_METHOD("get_version"),
                              &InputDevice::get_version);
  godot::ClassDB::bind_method(D_METHOD("get_phys"), &InputDevice::get_phys);
  godot::ClassDB::bind_method(D_METHOD("has_event_type", "event_type"),
                              &InputDevice::has_event_type);
  godot::ClassDB::bind_method(
      D_METHOD("has_event_code", "event_type", "event_code"),
      &InputDevice::has_event_code);
  godot::ClassDB::bind_method(D_METHOD("get_events"), &InputDevice::get_events);
  godot::ClassDB::bind_method(D_METHOD("is_open"), &InputDevice::is_open);
  godot::ClassDB::bind_method(D_METHOD("is_grabbed"), &InputDevice::is_grabbed);
  godot::ClassDB::bind_method(D_METHOD("get_abs_min"),
                              &InputDevice::get_abs_min);
  godot::ClassDB::bind_method(D_METHOD("get_abs_max"),
                              &InputDevice::get_abs_max);
  godot::ClassDB::bind_method(D_METHOD("get_abs_fuzz"),
                              &InputDevice::get_abs_fuzz);
  godot::ClassDB::bind_method(D_METHOD("get_abs_flat"),
                              &InputDevice::get_abs_flat);
  godot::ClassDB::bind_method(D_METHOD("get_abs_resolution"),
                              &InputDevice::get_abs_resolution);

  // Static methods

  // Constants
};
} // namespace evdev
