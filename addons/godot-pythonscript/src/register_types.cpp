#include "register_types.h"

#include <godot/gdnative_interface.h>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "pythonscript.h"

using namespace godot;

void initialize_pythonscript_module(ModuleInitializationLevel p_level) {
  if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }

  ClassDB::register_class<PythonScript>();
}

void uninitialize_pythonscript_module(ModuleInitializationLevel p_level) {
  if (p_level != godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }
}

extern "C" {
// Initialization
GDNativeBool GDN_EXPORT
pythonscript_library_init(const GDNativeInterface *p_interface,
                          const GDNativeExtensionClassLibraryPtr p_library,
                          GDNativeInitialization *r_initialization) {

  godot::GDExtensionBinding::InitObject init_obj(p_interface, p_library,
                                                 r_initialization);

  // Set the initializer to use and its initialization level. This controls
  // when to register and construct objects at different points of Godot's
  // initialization.
  init_obj.register_initializer(initialize_pythonscript_module);
  init_obj.register_terminator(uninitialize_pythonscript_module);
  init_obj.set_minimum_library_initialization_level(
      MODULE_INITIALIZATION_LEVEL_SCENE);

  return init_obj.init();
}
}
