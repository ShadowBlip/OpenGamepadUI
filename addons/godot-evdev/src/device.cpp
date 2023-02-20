#include "device.h"
#include "event.h"
#include "virtual_device.h"

#include <fcntl.h>
#include <iostream>
#include <libevdev/libevdev-uinput.h>
#include <libevdev/libevdev.h>
#include <linux/input-event-codes.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <stdio.h>
#include <sys/ioctl.h>
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
using godot::ClassDB;
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
  fd = ::open(device.ascii().get_data(), O_RDWR | O_NONBLOCK);
  if (fd < 0) {
    godot::UtilityFunctions::push_warning("Unable to open input device as RW: ",
                                          device);
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
  int code = 0;
  if (fd > 0) {
    code = ::close(fd);
  }
  if (code < 0) {
    return godot::ERR_CANT_OPEN;
  }
  fd = -1;
  libevdev_free(dev);
  return code;
};

VirtualInputDevice *InputDevice::duplicate() {
  if (!is_open()) {
    return nullptr;
  }

  // Open uinput
  struct libevdev_uinput *uidev;
  int uifd = ::open("/dev/uinput", O_RDWR | O_NONBLOCK);
  if (uifd < 0) {
    return nullptr;
  }

  // Add extra capabilities to emulate mouse (and maybe kb?)
  libevdev_enable_event_type(dev, EV_REL);
  libevdev_enable_event_code(dev, EV_REL, REL_X, NULL);
  libevdev_enable_event_code(dev, EV_REL, REL_Y, NULL);
  libevdev_enable_event_code(dev, EV_REL, REL_WHEEL, NULL);
  libevdev_enable_event_type(dev, EV_KEY);
  libevdev_enable_event_code(dev, EV_KEY, BTN_LEFT, NULL);
  libevdev_enable_event_code(dev, EV_KEY, BTN_MIDDLE, NULL);
  libevdev_enable_event_code(dev, EV_KEY, BTN_RIGHT, NULL);
  libevdev_enable_property(dev, INPUT_PROP_POINTER);

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

int InputDevice::enable_event_type(unsigned int event_type) {
  return libevdev_enable_event_type(dev, event_type);
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
    if (events.size() > 1000) {
      godot::UtilityFunctions::push_warning("Large event processing loop: ",
                                            events.size());
    }
  } while (rc >= 0);

  return events;
}

// Write the given event to the device
int InputDevice::write_event(int type, int code, int value) {
  if (!is_open()) {
    return -1;
  }
  struct input_event ev;
  struct timeval tval;
  memset(&ev, 0, sizeof(ev));
  gettimeofday(&tval, 0);
  ev.input_event_usec = tval.tv_usec;
  ev.input_event_sec = tval.tv_sec;
  ev.type = type;
  ev.code = code;
  ev.value = value;

  return ::write(fd, &ev, sizeof(ev));
}

// Uploads the given force feedback effect to the device
int InputDevice::upload_effect(ForceFeedbackEffect *effect) {
  return ioctl(fd, EVIOCSFF, &(effect->effect));
}

// Erases the effect with the given id from the device
int InputDevice::erase_effect(int effect_id) {
  return ioctl(fd, EVIOCRMFF, effect_id);
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
  ClassDB::bind_method(D_METHOD("open", "dev"), &InputDevice::open);
  ClassDB::bind_method(D_METHOD("close"), &InputDevice::close);
  ClassDB::bind_method(D_METHOD("duplicate"), &InputDevice::duplicate);
  ClassDB::bind_method(D_METHOD("grab", "mode"), &InputDevice::grab);
  ClassDB::bind_method(D_METHOD("get_fd"), &InputDevice::get_fd);
  ClassDB::bind_method(D_METHOD("get_path"), &InputDevice::get_path);
  ClassDB::bind_method(D_METHOD("get_name"), &InputDevice::get_name);
  ClassDB::bind_method(D_METHOD("get_bustype"), &InputDevice::get_bustype);
  ClassDB::bind_method(D_METHOD("get_vendor"), &InputDevice::get_vendor);
  ClassDB::bind_method(D_METHOD("get_product"), &InputDevice::get_product);
  ClassDB::bind_method(D_METHOD("get_version"), &InputDevice::get_version);
  ClassDB::bind_method(D_METHOD("get_phys"), &InputDevice::get_phys);
  ClassDB::bind_method(D_METHOD("enable_event_type", "event_type"),
                       &InputDevice::enable_event_type);
  ClassDB::bind_method(D_METHOD("has_event_type", "event_type"),
                       &InputDevice::has_event_type);
  ClassDB::bind_method(D_METHOD("has_event_code", "event_type", "event_code"),
                       &InputDevice::has_event_code);
  ClassDB::bind_method(D_METHOD("get_events"), &InputDevice::get_events);
  ClassDB::bind_method(D_METHOD("write_event", "type", "code", "value"),
                       &InputDevice::write_event);
  ClassDB::bind_method(D_METHOD("upload_effect", "effect"),
                       &InputDevice::upload_effect);
  ClassDB::bind_method(D_METHOD("erase_effect", "effect_id"),
                       &InputDevice::erase_effect);
  ClassDB::bind_method(D_METHOD("is_open"), &InputDevice::is_open);
  ClassDB::bind_method(D_METHOD("is_grabbed"), &InputDevice::is_grabbed);
  ClassDB::bind_method(D_METHOD("get_abs_min"), &InputDevice::get_abs_min);
  ClassDB::bind_method(D_METHOD("get_abs_max"), &InputDevice::get_abs_max);
  ClassDB::bind_method(D_METHOD("get_abs_fuzz"), &InputDevice::get_abs_fuzz);
  ClassDB::bind_method(D_METHOD("get_abs_flat"), &InputDevice::get_abs_flat);
  ClassDB::bind_method(D_METHOD("get_abs_resolution"),
                       &InputDevice::get_abs_resolution);

  // Static methods

  // Constants
};
} // namespace evdev
