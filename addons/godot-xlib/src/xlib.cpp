#include "xlib.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <X11/Xlib.h>

using namespace godot;

Xlib::Xlib(){};
Xlib::~Xlib(){};

void Xlib::test_static() {
  UtilityFunctions::print("  Simple static func called!");
};

void Xlib::_bind_methods() {
  // Static methods
  ClassDB::bind_static_method("Xlib", D_METHOD("test_static"),
                              &Xlib::test_static);
};
