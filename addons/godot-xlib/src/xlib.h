#ifndef XLIB_CLASS_H
#define XLIB_CLASS_H

#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
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
    ERR_XPROP_NOT_FOUND = -255,
    ERR_X_DISPLAY_NOT_FOUND = -1,
  };

  // Constructor/deconstructor
  Xlib();
  ~Xlib();

  // Static Functions
  static int get_root_window_id(String display);
  static PackedInt32Array get_window_children(String display, int window_id);
  static int set_xprop(String display, int window_id, String key, int value);
  static int get_xprop(String display, int window_id, String key);
  static bool has_xprop(String display, int window_id, String key);
};

#endif // XLIB_CLASS_H
