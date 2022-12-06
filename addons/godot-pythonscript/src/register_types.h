#ifndef PYTHONSCRIPT_REGISTER_TYPES_H
#define PYTHONSCRIPT_REGISTER_TYPES_H

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_pythonscript_module(ModuleInitializationLevel p_level);
void uninitialize_pythonscript_module(ModuleInitializationLevel p_level);

#endif // PYTHONSCRIPT_REGISTER_TYPES_H
