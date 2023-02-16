#include "register_types.h"

#include <gdextension_interface.h>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "pty.h"

void initialize_pty_module(godot::ModuleInitializationLevel p_level) {
  if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }

  godot::ClassDB::register_class<PTY>();
}

void uninitialize_pty_module(godot::ModuleInitializationLevel p_level) {
  if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }
}

extern "C" {
// Initialization
GDExtensionBool GDE_EXPORT
pty_library_init(const GDExtensionInterface *p_interface,
                 const GDExtensionClassLibraryPtr p_library,
                 GDExtensionInitialization *r_initialization) {

  godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library,
                                                 r_initialization);

  // Set the initializer to use and its initialization level. This controls
  // when to register and construct objects at different points of Godot's
  // initialization.
  init_obj.register_initializer(initialize_pty_module);
  init_obj.register_terminator(uninitialize_pty_module);
  init_obj.set_minimum_library_initialization_level(
      godot::MODULE_INITIALIZATION_LEVEL_SCENE);

  return init_obj.init();
}
}
