#ifndef PYTHONSCRIPT_CLASS_H
#define PYTHONSCRIPT_CLASS_H

#include "godot_cpp/variant/array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/node.hpp>

#include <godot_cpp/core/binder_common.hpp>

using namespace godot;

class PythonScript : public Object {
  GDCLASS(PythonScript, Object);

protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  PythonScript();
  ~PythonScript();

  // Static functions
  static void run_script(String code, Array output);
  static int run_file(const String path);
};

#endif // PYTHONSCRIPT_CLASS_H
