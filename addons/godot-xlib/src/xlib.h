#ifndef XLIB_CLASS_H
#define XLIB_CLASS_H

#include <godot_cpp/classes/node.hpp>

#include <godot_cpp/core/binder_common.hpp>

using namespace godot;

class Xlib : public Node {
  GDCLASS(Xlib, Node);

protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  Xlib();
  ~Xlib();

  // Static Functions
  static void test_static();
};

#endif // XLIB_CLASS_H
