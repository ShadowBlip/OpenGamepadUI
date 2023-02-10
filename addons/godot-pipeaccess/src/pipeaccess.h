#ifndef PIPEACCESS_CLASS_H
#define PIPEACCESS_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>

#include <godot_cpp/core/binder_common.hpp>

class PipeAccess : public godot::RefCounted {
  GDCLASS(PipeAccess, godot::RefCounted);

protected:
  static void _bind_methods();

public:
  int fd;
  FILE *stream = NULL;

  // Constants
  enum {
    READ = 0,
    WRITE = 1,
  };

  // Constructor/deconstructor
  PipeAccess();
  ~PipeAccess();

  // Member functions
  godot::String get_buffer(int size_bytes);
  int close();
  bool is_open();
  void write(godot::String data);

  // Static Functions
  static PipeAccess *open(godot::String path, int mode);
};

#endif // PIPEACCESS_CLASS_H
