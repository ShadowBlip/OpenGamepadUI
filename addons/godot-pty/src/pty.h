#ifndef PTY_CLASS_H
#define PTY_CLASS_H

#include "godot_cpp/variant/packed_byte_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>

#include <godot_cpp/core/binder_common.hpp>

class PTY : public godot::RefCounted {
  GDCLASS(PTY, godot::RefCounted);

protected:
  static void _bind_methods();

private:
  int fdm = -1;
  int fds = -1;
  char input[150];
  pid_t pid;

public:
  // Constructor/deconstructor
  PTY();
  ~PTY();

  // Member functions
  int open();
  int close();
  int create_process(godot::String path, godot::PackedStringArray args);
  godot::PackedByteArray read(int size);
  int write(godot::PackedByteArray data);
  int get_pid();
  godot::String get_path();
};

#endif // PTY_CLASS_H
