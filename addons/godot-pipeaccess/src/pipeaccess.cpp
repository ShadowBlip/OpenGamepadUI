#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <unistd.h>

#include "godot_cpp/variant/packed_byte_array.hpp"
#include "pipeaccess.h"

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

// References
// https://www.geeksforgeeks.org/named-pipe-fifo-example-c-program/
// https://stackoverflow.com/questions/40740914/using-istream-to-read-from-named-pipe

PipeAccess::PipeAccess(){};
PipeAccess::~PipeAccess() { close(); };

// Opens the given pipe
PipeAccess *PipeAccess::open(godot::String path, int mode) {
  // Build the open flags
  int flags;
  if (mode == READ) {
    flags = O_RDONLY | O_NONBLOCK;
  } else {
    flags = O_WRONLY;
  }

  int file = ::open(path.ascii().get_data(), flags);
  if (file < 0) {
    return nullptr;
  }

  // Open the pipe
  PipeAccess *pipe_access = memnew(PipeAccess());
  pipe_access->fd = file;

  // Create a stream for read/write operations
  FILE *fp;
  if (mode == READ) {
    fp = fdopen(file, "r");
  } else {
    fp = fdopen(file, "w");
  }
  pipe_access->stream = fp;

  return pipe_access;
}

// Writes the given string data to the pipe
void PipeAccess::write(godot::String data) {
  ::write(fd, data.ascii().get_data(), data.ascii().length());
  //::fprintf(stream, "%s", data.ascii().get_data());
}

bool PipeAccess::is_open() { return (fd >= 0); }

// Read a line from the pipe
godot::String PipeAccess::get_buffer(int size_bytes) {
  if (!stream) {
    return godot::String();
  }

  godot::PackedByteArray bytes;
  int bytes_read;
  char buffr[size_bytes];

  while ((bytes_read = ::read(fd, &buffr, size_bytes)) > 0) {
    for (int i = 0; i < bytes_read; i++) {
      bytes.append(buffr[i]);
    }
  }

  godot::String output = bytes.get_string_from_utf8();
  return output;
}

int PipeAccess::close() {
  int code = 0;
  if (stream) {
    code = ::fclose(stream);
    ::close(fd);
    stream = NULL;
    fd = -1;
  }
  return code;
}

// Register the methods with Godot
void PipeAccess::_bind_methods() {
  // Methods
  godot::ClassDB::bind_method(godot::D_METHOD("write", "data"),
                              &PipeAccess::write);
  godot::ClassDB::bind_method(godot::D_METHOD("is_open"), &PipeAccess::is_open);
  godot::ClassDB::bind_method(godot::D_METHOD("close"), &PipeAccess::close);
  godot::ClassDB::bind_method(godot::D_METHOD("get_buffer", "size"),
                              &PipeAccess::get_buffer);

  // Static methods
  godot::ClassDB::bind_static_method(
      "PipeAccess", godot::D_METHOD("open", "path", "mode"), &PipeAccess::open);

  // Constants
  BIND_CONSTANT(READ);
  BIND_CONSTANT(WRITE);
};
