#include "xlib.h"

#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <X11/X.h>
#include <cstring>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

using namespace godot;

Xlib::Xlib(){};
Xlib::~Xlib(){};

// Returns the root window id of the given display.
int Xlib::get_root_window_id(String display) {
  // Open a connection with the server
  Display *dpy;
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")
  if (dpy == NULL) {
    UtilityFunctions::push_error("Unable to open display!");
    return ERR_X_DISPLAY_NOT_FOUND;
  }

  // Return the root window id
  Window root = DefaultRootWindow(dpy);
  XCloseDisplay(dpy);
  return root;
};

// Returns the children of the given window.
PackedInt32Array Xlib::get_window_children(String display, int window_id) {
  Window window = (Window)window_id;
  // Open a connection with the server
  Display *dpy;
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")
  if (dpy == NULL) {
    UtilityFunctions::push_error("Unable to open display!");
    return PackedInt32Array();
  }

  // Variables to store the return results
  Window parent, root, *children;
  unsigned int nchildren;
  XWindowAttributes attributes;

  // Query the tree
  // https://cpp.hotexamples.com/examples/-/-/XQueryTree/cpp-xquerytree-function-examples.html
  Status status =
      XQueryTree(dpy, window, &root, &parent, &children, &nchildren);
  if (!status) {
    UtilityFunctions::push_error("Unable to query X tree for window: ",
                                 window_id);
    XCloseDisplay(dpy);
    return PackedInt32Array();
  }

  // Loop through all the children and add them to our int array
  PackedInt32Array results = PackedInt32Array();
  while (nchildren--) {
    Window child = children[nchildren];
    results.append((int64_t)child);
  }

  // Let the children be free!
  if (children)
    XFree(children);

  XCloseDisplay(dpy);
  return results;
};

// Sets the given x window property value on the given window. Returns 0 if
// successful.
int Xlib::set_xprop(String display, int window_id, String key, int value) {
  Window window = (Window)window_id;

  // Open a connection with the server
  Display *dpy;
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")?
  if (dpy == NULL) {
    UtilityFunctions::push_error("Unable to open display!");
    return ERR_X_DISPLAY_NOT_FOUND;
  }

  // Build the atom to set
  Atom atom = XInternAtom(dpy, key.ascii().get_data(), false);
  if (atom == None) {
    UtilityFunctions::push_error("Failed to create atom with name: ", key);
    return BadAtom;
  }

  // Fetch the actual property
  Atom actual;
  int format;
  unsigned long n, left;
  unsigned char *data;
  int result = XChangeProperty(dpy, window, atom, XA_CARDINAL, 32,
                               PropModeReplace, (unsigned char *)&value, 1);
  XCloseDisplay(dpy);
  if (result > 1) {
    return result;
  }

  return 0;
};

// Returns the value of the given x property on the given window. Returns -255
// if no value was found.
int Xlib::get_xprop(String display, int window_id, String key) {
  Window window = (Window)window_id;

  // Open a connection with the server
  Display *dpy;
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")?
  if (dpy == NULL) {
    UtilityFunctions::push_error("Unable to open display!");
    return ERR_XPROP_NOT_FOUND;
  }

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
    XCloseDisplay(dpy);
    return i;
  }

  // Close the connection to the x server
  UtilityFunctions::push_error("Property ", key,
                               " not found on window: ", window_id);
  XCloseDisplay(dpy);
  return ERR_XPROP_NOT_FOUND;
};

// Returns the values of the given x property on the given window.
PackedInt32Array Xlib::get_xprop_array(String display, int window_id,
                                       String key) {
  Window window = (Window)window_id;
  PackedInt32Array results = PackedInt32Array();

  // Open a connection with the server
  Display *dpy;
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")?
  if (dpy == NULL) {
    UtilityFunctions::push_error("Unable to open display!");
    return results;
  }

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
    XCloseDisplay(dpy);
    return results;
  }

  // Close the connection to the x server
  UtilityFunctions::push_error("Property ", key,
                               " not found on window: ", window_id);
  XCloseDisplay(dpy);
  return results;
}

// Returns true if the given property exists on the given window.
bool Xlib::has_xprop(String display, int window_id, String key) {
  int value = Xlib::get_xprop(display, window_id, key);
  if (value == ERR_XPROP_NOT_FOUND) {
    return false;
  }
  return true;
};

// Returns the value of the given x property on the given window. Returns -255
// if no value was found.
String Xlib::get_window_name(String display, int window_id) {
  Window window = (Window)window_id;

  // Open a connection with the server
  Display *dpy;
  dpy = XOpenDisplay(display.ascii().get_data()); // XOpenDisplay(":0")?
  if (dpy == NULL) {
    UtilityFunctions::push_error("Unable to open display!");
    return String();
  }

  // Build the atom to get
  Atom atom = XInternAtom(dpy, "WM_NAME", false);

  // Fetch the actual property
  XTextProperty property;
  XGetTextProperty(dpy, window, &property, atom);
  const char *text = strndup((char *)property.value, property.nitems);

  // Close the connection to the x server
  XCloseDisplay(dpy);
  return String(text);
};

// Register the methods with Godot
void Xlib::_bind_methods() {
  // Static methods
  ClassDB::bind_static_method("Xlib", D_METHOD("get_root_window_id", "display"),
                              &Xlib::get_root_window_id);
  ClassDB::bind_static_method(
      "Xlib", D_METHOD("get_window_children", "display", "window_id"),
      &Xlib::get_window_children);
  ClassDB::bind_static_method(
      "Xlib", D_METHOD("set_xprop", "display", "window_id", "key", "value"),
      &Xlib::set_xprop);
  ClassDB::bind_static_method(
      "Xlib", D_METHOD("get_xprop", "display", "window_id", "key"),
      &Xlib::get_xprop);
  ClassDB::bind_static_method(
      "Xlib", D_METHOD("get_xprop_array", "display", "window_id", "key"),
      &Xlib::get_xprop_array);
  ClassDB::bind_static_method(
      "Xlib", D_METHOD("has_xprop", "display", "window_id", "key"),
      &Xlib::has_xprop);
  ClassDB::bind_static_method(
      "Xlib", D_METHOD("get_window_name", "display", "window_id"),
      &Xlib::get_window_name);

  // Constants
  BIND_CONSTANT(ERR_XPROP_NOT_FOUND);
  BIND_CONSTANT(ERR_X_DISPLAY_NOT_FOUND);
};
