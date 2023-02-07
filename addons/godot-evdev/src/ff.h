#ifndef FORCE_FEEDBACK_EFFECT_CLASS_H
#define FORCE_FEEDBACK_EFFECT_CLASS_H

#include "godot_cpp/variant/string.hpp"
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <libevdev/libevdev.h>
#include <linux/input.h>
#include <linux/uinput.h>

namespace evdev {

class ForceFeedbackEffect : public godot::RefCounted {
  GDCLASS(ForceFeedbackEffect, RefCounted);

private:
protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  ForceFeedbackEffect();
  ~ForceFeedbackEffect();

  // Properties
  struct ff_effect effect;

  // Methods

  // Static functions
};

class ForceFeedbackUpload : public godot::RefCounted {
  GDCLASS(ForceFeedbackUpload, RefCounted);

private:
protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  ForceFeedbackUpload();
  ~ForceFeedbackUpload();

  // Properties
  struct uinput_ff_upload upload;

  // Methods
  int get_retval();
  void set_retval(int value);
  ForceFeedbackEffect *get_effect();

  // Static functions
};

class ForceFeedbackErase : public godot::RefCounted {
  GDCLASS(ForceFeedbackErase, RefCounted);

private:
protected:
  static void _bind_methods();

public:
  // Constructor/deconstructor
  ForceFeedbackErase();
  ~ForceFeedbackErase();

  // Properties
  struct uinput_ff_erase erase;

  // Methods
  int get_retval();
  void set_retval(int value);
  int get_effect_id();

  // Static functions
};

} // namespace evdev
#endif // FORCE_FEEDBACK_EFFECT_CLASS_H
