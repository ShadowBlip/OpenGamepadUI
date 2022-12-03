#ifndef XLIB_CLASS_H
#define XLIB_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/node.hpp>

#include <godot_cpp/core/binder_common.hpp>

using namespace godot;

class Xlib : public Object {
  GDCLASS(Xlib, Object);

protected:
  static void _bind_methods();

public:
  // Constants
  enum {
    XPROP_NOT_FOUND = -255,
  };

  // Constructor/deconstructor
  Xlib();
  ~Xlib();

  // Static Functions
  static int get_xprop(String display, int window_id, String key);
  static bool has_xprop(String display, int window_id, String key);
  static void test_static();
};

#endif // XLIB_CLASS_H
