#ifndef OPENSD_CLASS_H
#define OPENSD_CLASS_H

#include "godot_cpp/variant/packed_byte_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>

#include <godot_cpp/core/binder_common.hpp>

class OpenSD : public godot::RefCounted {
  GDCLASS(OpenSD, godot::RefCounted);

protected:
  static void _bind_methods();

private:
public:
  // Constructor/deconstructor
  OpenSD();
  ~OpenSD();

  // Member functions
  int run();
};

#endif // OPENSD_CLASS_H
