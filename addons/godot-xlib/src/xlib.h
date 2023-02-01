#ifndef XLIB_CLASS_H
#define XLIB_CLASS_H

#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/packed_int32_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/node.hpp>

#include <godot_cpp/core/binder_common.hpp>

class Xlib : public godot::Object {
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
  static int get_root_window_id(godot::String display);
  static godot::PackedInt32Array get_window_children(godot::String display,
                                                     int window_id);
  static int set_xprop(godot::String display, int window_id, godot::String key,
                       int value);
  static int get_xprop(godot::String display, int window_id, godot::String key);
  static godot::PackedStringArray list_xprops(godot::String display,
                                              int window_id);
  static godot::PackedInt32Array
  get_xprop_array(godot::String display, int window_id, godot::String key);
  static bool has_xprop(godot::String display, int window_id,
                        godot::String key);
  static int remove_xprop(godot::String display, int window_id,
                          godot::String key);
  static godot::String get_window_name(godot::String display, int window_id);
  static int get_window_pid(godot::String display, int window_id);
  static int set_input_focus(godot::String display, int window_id);
  static int set_wm_hints(godot::String display, int window_id);
};

#endif // XLIB_CLASS_H
