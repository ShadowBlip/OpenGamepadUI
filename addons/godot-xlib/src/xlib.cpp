#include "xlib.h"

#include "godot_cpp/variant/string.hpp"
#include <cstring>
#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <X11/Xatom.h>
#include <X11/Xlib.h>

using namespace godot;

Xlib::Xlib(){};
Xlib::~Xlib(){};

void Xlib::test_static() {
  UtilityFunctions::print("  Simple static func called!");
  DisplayServer *display_server = DisplayServer::get_singleton();
  String name = display_server->get_name();
  UtilityFunctions::print(" Display name: ", name);

  // Do xwindows stuff
  Display *display;
  int screen;

  // Open a connection with the server
  display = XOpenDisplay(NULL); // XOpenDisplay(":0")?
  if (display == NULL) {
    UtilityFunctions::print("Unable to open display!");
  }

  UtilityFunctions::print(display_server->get_window_list());

  // Query the tree
  // https://cpp.hotexamples.com/examples/-/-/XQueryTree/cpp-xquerytree-function-examples.html
  Window parent, root, *children; // A 'Window' is also the window id
  unsigned int nchildren;
  XWindowAttributes attributes;

  // Get the root window
  Status status = XQueryTree(display, DefaultRootWindow(display), &root,
                             &parent, &children, &nchildren);
  if (!status) {
    UtilityFunctions::push_error("Unable to query x tree");
    return;
  }

  // Loop through all the children
  while (nchildren--) {
    Window child = children[nchildren];
    UtilityFunctions::print("Got child with id: ", child);
  }
  XFree(children);

  XGetWindowAttributes(display, DefaultRootWindow(display), &attributes);

  // Get the name
  char *window_name;
  XFetchName(display, DefaultRootWindow(display), &window_name);
  UtilityFunctions::print("Name: '", window_name, "' ",
                          DefaultRootWindow(display));

  // XGetWindowAttributes(display, root, &attributes);

  // Close connection to server
  XCloseDisplay(display);
  UtilityFunctions::print("Closed display");

  // Look for _NET_WM_PID for the process id
  Atom steamInputFocus = XInternAtom(display, "STEAM_INPUT_FOCUS", false);

  // Get a window property
  Atom actual;
  int format;
  unsigned long n, left;
  unsigned char *data;
  XGetWindowProperty(display, root, steamInputFocus, 0L, 1L, false, XA_CARDINAL,
                     &actual, &format, &n, &left, &data);
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
    return XPROP_NOT_FOUND;
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
  return XPROP_NOT_FOUND;
};

// Returns true if the given property exists on the given window.
bool Xlib::has_xprop(String display, int window_id, String key) {
  int value = Xlib::get_xprop(display, window_id, key);
  if (value == XPROP_NOT_FOUND) {
    return false;
  }
  return true;
};

// Register the methods with Godot
void Xlib::_bind_methods() {
  // Static methods
  ClassDB::bind_static_method("Xlib", D_METHOD("test_static"),
                              &Xlib::test_static);
  ClassDB::bind_static_method("Xlib", D_METHOD("get_xprop", "window_id", "key"),
                              &Xlib::get_xprop);
  ClassDB::bind_static_method("Xlib", D_METHOD("has_xprop", "window_id", "key"),
                              &Xlib::has_xprop);

  // Constants
  BIND_CONSTANT(XPROP_NOT_FOUND);
};
