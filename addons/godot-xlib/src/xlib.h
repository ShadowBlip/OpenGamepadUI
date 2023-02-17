#ifndef XLIB_CLASS_H
#define XLIB_CLASS_H

#include <X11/Xutil.h>

#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>

#include <godot_cpp/core/binder_common.hpp>

using godot::String;

class Xlib : public godot::RefCounted {
  GDCLASS(Xlib, godot::RefCounted);

protected:
  static void _bind_methods();

private:
  Display *dpy = NULL;
  String name = String();

public:
  // Constants
  enum {
    ERR_XPROP_NOT_FOUND = -255,
    ERR_X_DISPLAY_NOT_FOUND = -1,
  };

  // Constructor/deconstructor
  Xlib();
  ~Xlib();

  // Methods
  int open(String display);
  int close();
  String get_name();
  int get_root_window_id();
  godot::PackedInt32Array get_window_children(int window_id);
  int set_xprop(int window_id, String key, int value);
  int get_xprop(int window_id, String key);
  godot::PackedStringArray list_xprops(int window_id);
  godot::PackedInt32Array get_xprop_array(int window_id, String key);
  bool has_xprop(int window_id, String key);
  int remove_xprop(int window_id, String key);
  String get_window_name(int window_id);
  int get_window_pid(int window_id);
  int set_input_focus(int window_id);
  int set_wm_hints(int window_id);
};

#endif // XLIB_CLASS_H
