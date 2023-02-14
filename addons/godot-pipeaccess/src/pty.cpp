#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <termios.h>
#include <unistd.h>

#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/variant/packed_byte_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "pty.h"

// References
// http://www.rkoucha.fr/tech_corner/pty_pdip.html

PTY::PTY(){};
PTY::~PTY() { close(); };

// Creates and opens a new PTY
int PTY::open() {
  fdm = posix_openpt(O_RDWR | O_NONBLOCK);
  if (fdm < 0) {
    return godot::ERR_CANT_CREATE;
  }

  int rc;
  rc = grantpt(fdm);
  if (rc != 0) {
    return godot::ERR_CANT_CREATE;
  }

  rc = unlockpt(fdm);
  if (rc != 0) {
    return godot::ERR_CANT_CREATE;
  }

  // Open the slave side ot the PTY
  fds = ::open(ptsname(fdm), O_RDWR);

  return godot::OK;
}

// Closes the PTY
int PTY::close() {
  if (fdm >= 0) {
    ::close(fdm);
    fdm = -1;
  }
  if (fds >= 0) {
    ::close(fds);
    fds = -1;
  }
  return 0;
}

// Creates a process inside our PTY
int PTY::create_process(godot::String path, godot::PackedStringArray args) {
  pid = fork();
  if (pid < 0) {
    // Can't fork
    return -1;
  }

  // Child execution path
  if (pid == 0) {
    // Close the parent side of the PTY
    ::close(fdm);

    // Creater terminal settings
    struct termios slave_orig_term_settings; // Saved terminal settings
    struct termios new_term_settings;        // Current terminal settings

    // Save the default parameters of the child side of the PTY
    int rc = tcgetattr(fds, &slave_orig_term_settings);

    // Set RAW mode on the child side of PTY
    new_term_settings = slave_orig_term_settings;
    cfmakeraw(&new_term_settings);
    tcsetattr(fds, TCSANOW, &new_term_settings);

    // The child side of the PTY becomes the standard input and outputs of the
    // spawned process
    ::close(0); // Close standard input (current terminal)
    ::close(1); // Close standard output (current terminal)
    ::close(2); // Close standard error (current terminal)

    ::dup(fds); // PTY becomes standard input (0)
    ::dup(fds); // PTY becomes standard output (1)
    ::dup(fds); // PTY becomes standard error (2)

    // Now the original file descriptor is useless
    ::close(fds);
    fds = -1;

    // Create a new session-ID so parent won't wait for it.
    // This ensures the process won't go zombie at the end.
    setsid();

    // As the child is a session leader, set the controlling terminal to be the
    // slave side of the PTY (Mandatory for programs like the shell to make them
    // manage their outputs correctly)
    ioctl(0, TIOCSCTTY, 1);

    // Build the command line
    char *vargs[args.size() + 2];
    vargs[0] = strdup(path.utf8().get_data());
    int i;
    for (i = 0; i < args.size(); i++) {
      vargs[i + 1] = strdup(args[i].utf8().get_data());
    }
    vargs[i + 1] = NULL;

    execvp(path.utf8().get_data(), vargs);
    // The execvp() function only returns if an error occurs.
    ERR_PRINT("Could not create child process: " + path);
    return -1;
  }

  // Close the child side of the PTY
  ::close(fds);
  fds = -1;

  return pid;
}

// Read data from the PTY
godot::PackedByteArray PTY::read(int size_bytes) {
  godot::PackedByteArray bytes;
  int bytes_read;
  char buffr[size_bytes];

  while ((bytes_read = ::read(fdm, &buffr, size_bytes)) > 0) {
    for (int i = 0; i < bytes_read; i++) {
      bytes.append(buffr[i]);
    }
  }

  return bytes;
}

// Write the given data to the proess in the PTY
int PTY::write(godot::PackedByteArray data) {
  return ::write(fdm, data.ptr(), data.size());
}

// Returns the PID of the currently running process in the PTY
int PTY::get_pid() { return pid; }

// Returns the path to the PTY character device
godot::String PTY::get_path() {
  const char *name = ptsname(fdm);
  return godot::String(name);
}

// Register the methods with Godot
void PTY::_bind_methods() {
  // Methods
  godot::ClassDB::bind_method(godot::D_METHOD("open"), &PTY::open);
  godot::ClassDB::bind_method(godot::D_METHOD("close"), &PTY::close);
  godot::ClassDB::bind_method(godot::D_METHOD("create_process", "path", "args"),
                              &PTY::create_process);
  godot::ClassDB::bind_method(godot::D_METHOD("read", "size_bytes"),
                              &PTY::read);
  godot::ClassDB::bind_method(godot::D_METHOD("write", "data"), &PTY::write);
  godot::ClassDB::bind_method(godot::D_METHOD("get_pid"), &PTY::get_pid);
  godot::ClassDB::bind_method(godot::D_METHOD("get_path"), &PTY::get_path);
};
