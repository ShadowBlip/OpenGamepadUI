#include "xlib.h"

#include <X11/X.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/XRes.h>
#include <cstring>

#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using godot::ClassDB;
using godot::D_METHOD;
using godot::String;

static int error(Display *dpy, XErrorEvent *ev) {
  // Always return, I guess?
  return 0;
}

Xlib::Xlib() { XSetErrorHandler(error); };
Xlib::~Xlib() { close(); };

// Open a connection with the given X server display. E.g. ":0"
int Xlib::open(String display) {
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")
  if (dpy == NULL) {
    return ERR_X_DISPLAY_NOT_FOUND;
  }
  name = display;

  return 0;
}

// Close the connection to the X server
int Xlib::close() {
  if (dpy == NULL) {
    return 0;
  }
  int rc = XCloseDisplay(dpy);
  dpy = NULL;
  name = String();
  return rc;
}

// Returns the name of the X server display (e.g. ":0")
String Xlib::get_name() { return name; }

// Returns the root window id of the given display.
int Xlib::get_root_window_id() {
  Window root = DefaultRootWindow(dpy);
  return root;
};

// Returns the children of the given window.
godot::PackedInt32Array Xlib::get_window_children(int window_id) {
  Window window = (Window)window_id;

  // Variables to store the return results
  Window parent, root, *children;
  unsigned int nchildren;
  XWindowAttributes attributes;

  // Query the tree
  // https://cpp.hotexamples.com/examples/-/-/XQueryTree/cpp-xquerytree-function-examples.html
  Status status =
      XQueryTree(dpy, window, &root, &parent, &children, &nchildren);
  if (!status) {
    godot::UtilityFunctions::push_error("Unable to query X tree for window: ",
                                        window_id);
    return godot::PackedInt32Array();
  }

  // Loop through all the children and add them to our int array
  godot::PackedInt32Array results = godot::PackedInt32Array();
  while (nchildren--) {
    Window child = children[nchildren];
    results.append((int64_t)child);
  }

  // Let the children be free!
  if (children)
    XFree(children);

  return results;
};

// Sets the given x window property value on the given window. Returns 0 if
// successful.
int Xlib::set_xprop(int window_id, String key, int value) {
  Window window = (Window)window_id;

  // Build the atom to set
  Atom atom = XInternAtom(dpy, key.ascii().get_data(), false);
  if (atom == None) {
    godot::UtilityFunctions::push_error("Failed to create atom with name: ",
                                        key);
    return BadAtom;
  }

  // Fetch the actual property
  Atom actual;
  int format;
  unsigned long n, left;
  unsigned char *data;
  int result = XChangeProperty(dpy, window, atom, XA_CARDINAL, 32,
                               PropModeReplace, (unsigned char *)&value, 1);
  if (result > 1) {
    return result;
  }

  return 0;
};

// Returns the value of the given x property on the given window. Returns -255
// if no value was found.
__attribute__((__no_sanitize_address__)) int Xlib::get_xprop(int window_id,
                                                             String key) {
  Window window = (Window)window_id;

  // Build the atom to get
  Atom atom = XInternAtom(dpy, key.ascii().get_data(), false);

  // Fetch the actual property
  Atom actual;
  int format;
  unsigned long n, left;
  unsigned char *data;
  int result = XGetWindowProperty(dpy, window, atom, 0L, 1L, false, XA_CARDINAL,
                                  &actual, &format, &n, &left, &data);

  // If the property exists and there is data, copy it.
  if (result == Success && data != NULL) {
    // Copy the data as an unsigned int
    unsigned int i;
    memcpy(&i, data, sizeof(unsigned int));
    XFree((void *)data);
    return i;
  }

  return ERR_XPROP_NOT_FOUND;
};

// Removes the given X property on the given window.
int Xlib::remove_xprop(int window_id, String key) {
  Window window = (Window)window_id;

  // Build the atom to remove
  Atom atom = XInternAtom(dpy, key.ascii().get_data(), false);

  // Delete the property
  int result = XDeleteProperty(dpy, window, atom);

  return result;
};

// Returns the children of the given window.
godot::PackedStringArray Xlib::list_xprops(int window_id) {
  Window window = (Window)window_id;

  // Variables to store the return results
  int nresults;

  // Query the window for properties
  godot::PackedStringArray properties = godot::PackedStringArray();
  Atom *results = XListProperties(dpy, window, &nresults);
  if (!results) {
    godot::UtilityFunctions::push_error(
        "Unable to list properties for window: ", window);
    return properties;
  }

  // Loop through the results and add them to the array
  while (nresults--) {
    Atom res = results[nresults];
    const char *name = XGetAtomName(dpy, res);
    properties.append(String(name));
  }

  // Free the results
  XFree(results);

  return properties;
};

// Returns the values of the given x property on the given window.
__attribute__((__no_sanitize_address__)) godot::PackedInt32Array
Xlib::get_xprop_array(int window_id, String key) {
  Window window = (Window)window_id;
  godot::PackedInt32Array results = godot::PackedInt32Array();

  // Build the atom to get
  Atom atom = XInternAtom(dpy, key.ascii().get_data(), false);

  // Fetch the actual property
  Atom actual;
  int format;
  unsigned long n, left;
  uint64_t *data;
  // Get up to 16 results
  int result =
      XGetWindowProperty(dpy, window, atom, 0L, 16L, false, XA_CARDINAL,
                         &actual, &format, &n, &left, (unsigned char **)&data);

  // If the property exists, loop through the result and append it to the array
  if (result == Success && data != NULL) {
    for (uint32_t i = 0; i < n; i++) {
      results.append(data[i]);
    }
    XFree((void *)data);
    return results;
  }

  return results;
}

// Returns true if the given property exists on the given window.
bool Xlib::has_xprop(int window_id, String key) {
  int value = Xlib::get_xprop(window_id, key);
  if (value == ERR_XPROP_NOT_FOUND) {
    return false;
  }
  return true;
};

// Returns the value of the given x property on the given window. Returns -255
// if no value was found.
String Xlib::get_window_name(int window_id) {
  Window window = (Window)window_id;

  // Build the atom to get
  Atom atom = XInternAtom(dpy, "WM_NAME", false);

  // Fetch the actual property
  XTextProperty property;
  XGetTextProperty(dpy, window, &property, atom);
  const char *text = strndup((char *)property.value, property.nitems);

  return String(text);
};

// Uses XRes to determine the given Window's PID
int Xlib::get_window_pid(int window_id) {
  Window window = (Window)window_id;

  // Use XRes to determine PID
  pid_t pid = -1;
  XResClientIdSpec spec = {
      .client = window,
      .mask = XRES_CLIENT_ID_PID_MASK,
  };
  long num_ids = 0;
  XResClientIdValue *client_ids = NULL;
  XResQueryClientIds(dpy, 1, &spec, &num_ids, &client_ids);

  for (long i = 0; i < num_ids; i++) {
    pid = XResGetClientPid(&client_ids[i]);
    if (pid > 0) {
      break;
    }
  }
  XResClientIdsDestroy(num_ids, client_ids);

  return pid;
};

// Set input focus on the given window
int Xlib::set_input_focus(int window_id) {
  Window window = (Window)window_id;
  int ret = XSetInputFocus(dpy, window_id, RevertToNone, CurrentTime);
  return ret;
};

// Set input focus on the given window
int Xlib::set_wm_hints(int window_id) {
  Window window = (Window)window_id;

  // allocate a WM hints structure
  XWMHints *win_hints;
  win_hints = XAllocWMHints();
  win_hints->flags = InputHint | StateHint;
  win_hints->initial_state = NormalState;
  win_hints->input = true;

  // pass the hints to the window manager.
  int ret = XSetWMHints(dpy, window, win_hints);

  // finally, we can free the WM hints structure.
  XFree(win_hints);

  return ret;
};

// Keyboard/mouse emulation
godot::Vector2 Xlib::get_mouse_position() {
  XEvent event;
  XQueryPointer(dpy, DefaultRootWindow(dpy), &event.xbutton.root,
                &event.xbutton.window, &event.xbutton.x_root,
                &event.xbutton.y_root, &event.xbutton.x, &event.xbutton.y,
                &event.xbutton.state);
  Vector2 position = Vector2();
  position.x = event.xbutton.x;
  position.y = event.xbutton.y;

  return position;
}

// Move the mouse pointer (relative)
int Xlib::move_mouse(godot::Vector2 position) {
  int rc = 1;
  rc = XWarpPointer(dpy, None, None, 0, 0, 0, 0, position.x, position.y);
  if (rc > 1) {
    return rc;
  }
  return XFlush(dpy);
}

// Move the mouse pointer (absolute)
int Xlib::move_mouse_to(Vector2 position) {
  int rc = 1;
  Vector2 current = get_mouse_position();
  rc = XWarpPointer(dpy, None, None, 0, 0, 0, 0, -current.x, -current.y);
  if (rc > 1) {
    return rc;
  }
  return move_mouse(position);
}

// Sends a mouse click of the given mouse button
int Xlib::send_mouse_click(godot::MouseButton button, bool pressed) {
  // Map godot constants to xlib constants
  int xbutton;
  if (button == godot::MOUSE_BUTTON_LEFT)
    xbutton = Button1;
  if (button == godot::MOUSE_BUTTON_MIDDLE)
    xbutton = Button2;
  if (button == godot::MOUSE_BUTTON_RIGHT)
    xbutton = Button3;
  if (button == godot::MOUSE_BUTTON_WHEEL_UP)
    xbutton = Button4;
  if (button == godot::MOUSE_BUTTON_WHEEL_DOWN)
    xbutton = Button5;

  // Create and setup the event
  XEvent event;
  memset(&event, 0, sizeof(event));
  event.xbutton.button = xbutton;
  event.xbutton.same_screen = True;
  event.xbutton.subwindow = DefaultRootWindow(dpy);
  while (event.xbutton.subwindow) {
    event.xbutton.window = event.xbutton.subwindow;
    XQueryPointer(dpy, event.xbutton.window, &event.xbutton.root,
                  &event.xbutton.subwindow, &event.xbutton.x_root,
                  &event.xbutton.y_root, &event.xbutton.x, &event.xbutton.y,
                  &event.xbutton.state);
  }

  // Send the press/release event
  long mask;
  if (pressed) {
    event.type = ButtonPress;
    mask = ButtonPressMask;
  } else {
    event.type = ButtonRelease;
    mask = ButtonReleaseMask;
  }
  int rc;
  rc = XSendEvent(dpy, PointerWindow, True, mask, &event);
  XFlush(dpy);
  if (rc == 0) {
    return -1;
  }
  return 0;
}

// Register the methods with Godot
void Xlib::_bind_methods() {
  // Methods
  ClassDB::bind_method(D_METHOD("open", "display"), &Xlib::open);
  ClassDB::bind_method(D_METHOD("close"), &Xlib::close);
  ClassDB::bind_method(D_METHOD("get_name"), &Xlib::get_name);
  ClassDB::bind_method(D_METHOD("get_root_window_id"),
                       &Xlib::get_root_window_id);
  ClassDB::bind_method(D_METHOD("get_window_children", "window_id"),
                       &Xlib::get_window_children);
  ClassDB::bind_method(D_METHOD("set_xprop", "window_id", "key", "value"),
                       &Xlib::set_xprop);
  ClassDB::bind_method(D_METHOD("remove_xprop", "window_id", "key"),
                       &Xlib::remove_xprop);
  ClassDB::bind_method(D_METHOD("get_xprop", "window_id", "key"),
                       &Xlib::get_xprop);
  ClassDB::bind_method(D_METHOD("get_xprop_array", "window_id", "key"),
                       &Xlib::get_xprop_array);
  ClassDB::bind_method(D_METHOD("has_xprop", "window_id", "key"),
                       &Xlib::has_xprop);
  ClassDB::bind_method(D_METHOD("list_xprops", "window_id"),
                       &Xlib::list_xprops);
  ClassDB::bind_method(D_METHOD("get_window_name", "window_id"),
                       &Xlib::get_window_name);
  ClassDB::bind_method(D_METHOD("get_window_pid", "window_id"),
                       &Xlib::get_window_pid);
  ClassDB::bind_method(D_METHOD("set_input_focus", "window_id"),
                       &Xlib::set_input_focus);
  ClassDB::bind_method(D_METHOD("set_wm_hints", "window_id"),
                       &Xlib::set_wm_hints);

  ClassDB::bind_method(D_METHOD("get_mouse_position"),
                       &Xlib::get_mouse_position);
  ClassDB::bind_method(D_METHOD("move_mouse", "position"), &Xlib::move_mouse);
  ClassDB::bind_method(D_METHOD("move_mouse_to", "position"),
                       &Xlib::move_mouse_to);
  ClassDB::bind_method(D_METHOD("send_mouse_click", "button", "pressed"),
                       &Xlib::send_mouse_click);
  // Constants
  BIND_CONSTANT(ERR_XPROP_NOT_FOUND);
  BIND_CONSTANT(ERR_X_DISPLAY_NOT_FOUND);
};
