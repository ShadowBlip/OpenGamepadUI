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
#include <sys/ioctl.h>
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
using godot::ClassDB;
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
  uifd = -1;

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

// Uploads the given FF event value to the device. The FF effect will
// be populated in the return object.
ForceFeedbackUpload *VirtualInputDevice::begin_upload(int value) {
  struct uinput_ff_upload upload;
  upload.request_id = value;

  int code = ioctl(uifd, UI_BEGIN_FF_UPLOAD, &upload);
  if (code != 0) {
    return nullptr;
  }

  ForceFeedbackUpload *ff_upload = memnew(ForceFeedbackUpload());
  ff_upload->upload = upload;

  return ff_upload;
}

// Finished the upload of the given FF event. The return code must be set.
int VirtualInputDevice::end_upload(ForceFeedbackUpload *upload) {
  return ioctl(uifd, UI_END_FF_UPLOAD, &(upload->upload));
}

// Starts the FF erase operation on the given device
ForceFeedbackErase *VirtualInputDevice::begin_erase(int value) {
  struct uinput_ff_erase erase;
  erase.request_id = value;

  int code = ioctl(uifd, UI_BEGIN_FF_ERASE, &erase);
  if (code != 0) {
    return nullptr;
  }

  ForceFeedbackErase *ff_erase = memnew(ForceFeedbackErase());
  ff_erase->erase = erase;

  return ff_erase;
}

// Finishes the erase operation of a FF event. Return code must be set.
int VirtualInputDevice::end_erase(ForceFeedbackErase *erase) {
  struct uinput_ff_erase ers = erase->erase;
  return ioctl(uifd, UI_END_FF_ERASE, &ers);
}

// Begin upload of a force feedback effect
int VirtualInputDevice::blackhole_upload(int value) {
  // 2. Allocate a uinput_ff_upload struct, fill in request_id with
  //    the 'value' from the EV_UINPUT event.
  struct uinput_ff_upload upload;
  upload.request_id = value;

  //   3. Issue a UI_BEGIN_FF_UPLOAD ioctl, giving it the
  //      uinput_ff_upload struct. It will be filled in with the
  //      ff_effects passed to upload_effect().
  int code = ioctl(uifd, UI_BEGIN_FF_UPLOAD, &upload);
  if (code != 0) {
    return code;
  }

  //   4. Perform the effect upload, and place a return code back into
  //      the uinput_ff_upload struct.
  upload.retval = 0;

  //   5. Issue a UI_END_FF_UPLOAD ioctl, also giving it the
  //      uinput_ff_upload_effect struct. This will complete execution
  //      of our upload_effect() handler.
  return ioctl(uifd, UI_END_FF_UPLOAD, &upload);
}

int VirtualInputDevice::blackhole_erase(int value) {
  //   1. Wait for an event with type == EV_UINPUT and code == UI_FF_ERASE.
  //      A request ID will be given in 'value'.
  //   2. Allocate a uinput_ff_erase struct, fill in request_id with
  //      the 'value' from the EV_UINPUT event.
  struct uinput_ff_erase erase;
  erase.request_id = value;
  //   3. Issue a UI_BEGIN_FF_ERASE ioctl, giving it the
  //      uinput_ff_erase struct. It will be filled in with the
  //      effect ID passed to erase_effect().
  int code = ioctl(uifd, UI_BEGIN_FF_ERASE, &erase);
  if (code != 0) {
    return code;
  }
  //   4. Perform the effect erasure, and place a return code back
  //      into the uinput_ff_erase struct.
  erase.retval = 0;
  //   5. Issue a UI_END_FF_ERASE ioctl, also giving it the
  //      uinput_ff_erase_effect struct. This will complete execution
  //      of our erase_effect() handler.
  return ioctl(uifd, UI_END_FF_ERASE, &erase);
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
  ClassDB::bind_method(D_METHOD("close"), &VirtualInputDevice::close);
  ClassDB::bind_method(D_METHOD("get_events"), &VirtualInputDevice::get_events);
  ClassDB::bind_method(D_METHOD("blackhole_upload", "value"),
                       &VirtualInputDevice::blackhole_upload);
  ClassDB::bind_method(D_METHOD("blackhole_erase", "value"),
                       &VirtualInputDevice::blackhole_erase);
  ClassDB::bind_method(D_METHOD("begin_upload", "value"),
                       &VirtualInputDevice::begin_upload);
  ClassDB::bind_method(D_METHOD("end_upload", "upload"),
                       &VirtualInputDevice::end_upload);
  ClassDB::bind_method(D_METHOD("begin_erase", "value"),
                       &VirtualInputDevice::begin_erase);
  ClassDB::bind_method(D_METHOD("end_erase", "erase"),
                       &VirtualInputDevice::end_erase);
  ClassDB::bind_method(D_METHOD("is_open"), &VirtualInputDevice::is_open);
  ClassDB::bind_method(D_METHOD("write_event", "event"),
                       &VirtualInputDevice::write_event);
  ClassDB::bind_method(D_METHOD("get_syspath"),
                       &VirtualInputDevice::get_syspath);
  ClassDB::bind_method(D_METHOD("get_devnode"),
                       &VirtualInputDevice::get_devnode);
  // Static methods

  // Constants
};

} // namespace evdev
