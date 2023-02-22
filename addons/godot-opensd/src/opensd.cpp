#include "godot_cpp/classes/global_constants.hpp"
#include "godot_cpp/variant/packed_byte_array.hpp"
#include "godot_cpp/variant/packed_string_array.hpp"
#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "common/log.hpp"
#include "opensdd/daemon.hpp"

#include "opensd.h"

OpenSD::OpenSD(){};
OpenSD::~OpenSD(){};

// Creates and opens a new OpenSD
int OpenSD::run() {
  Daemon opensdd;
  gLog.SetFilterLevel(Log::DEBUG);
  try {
    return opensdd.Run();
  } catch (int code) {
    // Failed to run
    godot::UtilityFunctions::push_error("OpenSD exited with code: ", code);
    return godot::ERR_CANT_OPEN;
  }
}

// Register the methods with Godot
void OpenSD::_bind_methods() {
  // Methods
  godot::ClassDB::bind_method(godot::D_METHOD("run"), &OpenSD::run);
};
