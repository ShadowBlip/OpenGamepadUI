#include "ff.h"

#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/string.hpp"
#include <libevdev/libevdev.h>
#include <linux/uinput.h>

namespace evdev {
using godot::ClassDB;
using godot::D_METHOD;
using godot::PropertyInfo;

/************* ForceFeedbackEffect **************/
ForceFeedbackEffect::ForceFeedbackEffect(){};
ForceFeedbackEffect::~ForceFeedbackEffect(){};

int ForceFeedbackEffect::get_effect_id() { return effect.id; }
void ForceFeedbackEffect::set_effect_id(int id) { effect.id = id; }

// Register the methods with Godot
void ForceFeedbackEffect::_bind_methods() {
  ClassDB::bind_method(D_METHOD("get_effect_id"),
                       &ForceFeedbackEffect::get_effect_id);
  ClassDB::bind_method(D_METHOD("set_effect_id", "id"),
                       &ForceFeedbackEffect::set_effect_id);

  // Properties
  ADD_PROPERTY(PropertyInfo(godot::Variant::INT, "effect_id"), "set_effect_id",
               "get_effect_id");
};

/************* ForceFeedbackUpload **************/
ForceFeedbackUpload::ForceFeedbackUpload(){};
ForceFeedbackUpload::~ForceFeedbackUpload(){};

int ForceFeedbackUpload::get_retval() { return upload.retval; }
void ForceFeedbackUpload::set_retval(int value) { upload.retval = value; }

ForceFeedbackEffect *ForceFeedbackUpload::get_effect() {
  ForceFeedbackEffect *effect = memnew(ForceFeedbackEffect());
  effect->effect = upload.effect;
  return effect;
}

// Register the methods with Godot
void ForceFeedbackUpload::_bind_methods() {
  // Methods
  ClassDB::bind_method(D_METHOD("get_retval"),
                       &ForceFeedbackUpload::get_retval);
  ClassDB::bind_method(D_METHOD("set_retval", "code"),
                       &ForceFeedbackUpload::set_retval);
  ClassDB::bind_method(D_METHOD("get_effect"),
                       &ForceFeedbackUpload::get_effect);

  // Properties
  ADD_PROPERTY(PropertyInfo(godot::Variant::INT, "retval"), "set_retval",
               "get_retval");
};

/************* ForceFeedbackErase **************/
ForceFeedbackErase::ForceFeedbackErase(){};
ForceFeedbackErase::~ForceFeedbackErase(){};

int ForceFeedbackErase::get_retval() { return erase.retval; }
void ForceFeedbackErase::set_retval(int value) { erase.retval = value; }
int ForceFeedbackErase::get_effect_id() { return erase.effect_id; }

// Register the methods with Godot
void ForceFeedbackErase::_bind_methods() {
  // Methods
  ClassDB::bind_method(D_METHOD("get_retval"), &ForceFeedbackErase::get_retval);
  ClassDB::bind_method(D_METHOD("set_retval", "code"),
                       &ForceFeedbackErase::set_retval);
  ClassDB::bind_method(D_METHOD("get_effect_id"),
                       &ForceFeedbackErase::get_effect_id);

  // Properties
  ADD_PROPERTY(PropertyInfo(godot::Variant::INT, "retval"), "set_retval",
               "get_retval");
};

} // namespace evdev
