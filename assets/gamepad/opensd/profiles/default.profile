# OpenSD profile file: default
#
# Please see the online OpenSD users manual at https://open-sd.gitlab.io/opensd-docs
# for detailed explanations of each setting in this file. Or use the offline
# documentation that came with installation, usually in /usr/local/share/opensd.
# An offline manpage is also available by typing: man opensdd
#
# This is file is included with OpenSD and meant as a template.  It's recommended
# to make a copy of this file, rather than edit it directly.


[Profile]
# Name
# The profile name as it will appear in the GUI and through the CLI query.
# Should be unique for each profile to avoid confusion.
#   Value: Any unique name.  Should be enclosed in quotes to preserve spaces.
Name            = "Default OpenSD Profile"

# Description
# The profile description as it will appear in the GUI and through the CLI query.
#   Value: A brief description.  Should be enclosed in quotes "" to preserve spaces.
Description     = "A basic configuration that should work for most games and provide a few extras."


[Features]
# Force Feedback
# Enable haptic feedback / rumble function.
#   Values:  true, false
ForceFeedback   = true

# Motion Device
# If this is set to true, an additional input device will be created which
# will report motion control data.  Motion axes still need to have thier
# bindings defined.  If this is disabled, any "Motion" bindings will be
# ignored.
#   Values:  true, false
MotionDevice    = true

# Mouse Device
# If this is set to true, an additional input device will be created which
# will be used to send mouse / trackpad events.  Mouse events still need to
# have thier bindings defined.  If this is disabled, any "Mouse" bindings
# will be ignored.
#   Values:  true, false
MouseDevice     = true

# Lizard Mode
# The Steam Controller and the Steam Deck both have a kind of fallback BIOS
# mode which emulates some keyboard and mouse events.  Valve refers to this
# as 'Lizard Mode'.  This mode cannot be redefined.  It sends events
# IN ADDITION to the gamepad events created by the OpenSD driver, so it
# should always be disabled. When OpenSD exits, Lizard Mode is re-enabled.
#   Values:  true, false  (recommended: false)
LizardMode      = false

# Stick Filtering
# The thumbsticks on the Steam Deck have a circular range but return square-ish
# data, which makes it feel odd and complicated to apply radial deadzones to.
# Because of this, OpenSD vectorizes the stick position and returns "cleaner",
# round stick ranges, as well as being able to create clean deadzone rescaling.
# If you disable this setting, axis ranges are still internally normalized and
# rescaled to the the uinput device, but no vectorization will be applied and
# any deadzones will be ignored.
#   Values:  true, false (recommended: true)
StickFiltering  = true

# Trackpad Filtering
# Similar to above, but matches the square shape of the trackpad.  Filtering is
# only applied to absolute values.  This setting must be enabled to apply
# deadzones to the trackpad absolute axes.  Relative values (rel_x and rel_y)
# are unaffected, therefore deadzones do not affect mouse movement with the pads.
#   Values:  true, false (recommended: true)
TrackpadFiltering  = true


[DeviceInfo]
# This section allows you to set the name and USB identity of the individual
# input devices created by the gamepad driver.  This can be useful to mimic the
# appearance of a specific controller in order to get a very poorly written game
# to recognise and support it.
#
# These are optional and will use defaults if undefined.  If the respective
# device is not first enabled in the Feature section, these values will be
# ignored.
#
# Format:
#   <device> = <vid> <pid> <ver> <name string>
#
#   device:  Which device to define.  Can be:  <Gamepad | Motion | Mouse>
#   vid:     Vendor ID.  16-bit hex value starting with "0x"
#   pid:     Product ID.  16-bit hex value starting with "0x"
#   vid:     Version.  16-bit hex value starting with "0x"
#   name:    The name string of the device
#
# Examples:
#   Gamepad = 0xDEAD 0xBEEF 0x001 "OpenSD Gamepad Device"
#   Motion = 0xDEAD 0xBEEF 0x001 "OpenSD Motion Control Device"
#   Mouse = 0xDEAD 0xF00D 0x001 "OpenSD Mouse Device"


[Deadzones]
# Axis deadzones
# Values are floating point and represent the percentage of the total range to
# ignore.  A value of 0.05 would be a 5% deadzone.  Deadzones are capped at
# 90% (0.9).  A value of 0 is considered disabled.
# If StickFiltering is disabled, LStick and RStick deadzones will be ignored.
# If TrackpadFiltering is disabled, LPad and RPad deadzones will be ignored.
#   Supported inputs:  LeftStick, RightStick, LeftPad, RightPad, LeftTrigg, RightTrigg
#   Values: 0.000 to 0.900
LStick      = 0.1
RStick      = 0.1
LPad        = 0
RPad        = 0
LTrigg      = 0
RTrigg      = 0


[GamepadAxes]
# Gamepad absolute axes must have a defined range or they will not be created.
# Any 'Gamepad' ABS_ events which are configured in the [Bindings] section must be
# defined here first, or they will be ignored.
ABS_HAT0X       = -1        1
ABS_HAT0Y       = -1        1
ABS_X           = -32767    32767
ABS_Y           = -32767    32767
ABS_RX          = -32767    32767
ABS_RY          = -32767    32767
ABS_Z           = 0         32767
ABS_RZ          = 0         32767


[MotionAxes]
# Motion control absolute axes must have a defined range or they will not be created.
# Any 'Motion' ABS_ events which are configured in the [Bindings] section must be
# defined here first, or they will be ignored.
ABS_X           = -32767    32767
ABS_Y           = -32767    32767
ABS_Z           = -32767    32767
ABS_RX          = -32767    32767
ABS_RY          = -32767    32767
ABS_RZ          = -32767    32767


[Bindings]
# Gamepad input bindings
#
# This should be a list of all the physical gamepad buttons/sticks/pads/motion
# inputs you want to bind to a virtual input event or command.  Anything not
# specified here will be considered 'unbound' and not register any event.
#
# Input:
#   Input names reflect the action of the user.  Like pressing a button or
#   pushing a thumbstick to the left.  Button bindings are pretty self-explanatory.
#   While axes are broken into directional actions (i.e. LeftStickUp). This way
#   you can make an axis send a keypress if you wanted to, and the inverse is
#   also possible.
#
# BindType:
#   There are two categories of bindings:  Event bindings and Command Bindings.
#
#   Event Bindings:
#     Since OpenSD manages up to 3 separate virtual input devices, you will need
#     to specify which device will send a particular event.
#     These devices are "Gamepad", "Motion and "Mouse".
#
#     Gamepad: This  device is for buttons and axes input.  This device is always
#     enabled.
#
#     Motion: This is a separate input device specifically for motion-sensors
#     like accelerometers and gyroscopes.  This device must be enabled in the
#     [Features] section.
#
#     Mouse: This is a virtual mouse device which uses relative axes (REL) and
#     buttons / keys.  This device must be enabled in the [Features] section.
#
#     Each binding must be mapped to a Linux input event code.  A complete list
#     can be found in <linux/input-event-codes.h> and the supported codes can be
#     found in the OpenSD documentation.
#     Most KEY_*, BTN_*, ABS_* and REL_* codes should be usable.
#
#     Event type is derived from the code prefix (i.e. KEY_* is a key event,
#     ABS_* is an absolute axis event.)
#
#     Axis event bindings MUST specify the direction of the axis.  This allows
#     buttons to send axis events or allows an axis to be inverted at a driver
#     level.
#
#     Event binding format:
#       Input = <Gamepad | Motion | Mouse> <input_event_code> [ + | - ]
#
#     Example:
#       DPadUp = Gamepad ABS_HAT0Y -
#
#     The above line will bind the up direction on the physical dpad to the negative
#     (up/left) direction of an absolute axis on the gamepad device.
#
#     There are also some standard meanings for these with regard to device
#     types and it is possible to configure this section which can cause very
#     strange behaviour.
#
#     Please see the documentation for a more detailed explanation about event
#     bindings.
#
#   Command Bindings:
#     The "Command" binding allows you to execute external programs or scripts
#     by forking them off as a child process.
#
#     Format:
#       Input = Command <wait_for_exit> <repeat_delay_ms> <command_to_execute>
#
#     wait_for_exit: <true | false> value which specifies if the command should
#     complete before the binding can be triggered again.
#
#     repeat_delay_ms: The amount of time in milliseconds that must elapse before
#     the binding can be triggered again.  The timer starts when the binding is
#     successfully triggered.
#
#     Example:
#       QuickAccess = Command true 0 rofi -show run
#
#   Profile Bindings:
#     This binding type allows you to switch to a different profile using just
#     the gamepad input.  Profiles are loaded from the user profile directory.
#
#     Format:
#       Input = Profile <profile_name>
#
#     profile_name: Filename of the profile ini you want to load.  Path is fixed
#     to the user profile directory, so only specify the filename itself.
#
#     Example:
#       L5 = Profile left_hand_mouse.profile
#
#
#   Valid binding types are:  Gamepad, Mouse, Motion, Command, Profile
#
#
# Input             BindType    Mapping     +/-
#---------------------------------------------
# Directional Pad
DpadUp              = Gamepad   ABS_HAT0Y   -
DpadDown            = Gamepad   ABS_HAT0Y   +
DpadLeft            = Gamepad   ABS_HAT0X   -
DpadRight           = Gamepad   ABS_HAT0X   +
# Buttons
A                   = Gamepad   BTN_SOUTH
B                   = Gamepad   BTN_EAST
X                   = Gamepad   BTN_NORTH
Y                   = Gamepad   BTN_WEST
L1                  = Gamepad   BTN_TL
R1                  = Gamepad   BTN_TR
L2                  = Gamepad   None
R2                  = Gamepad   None
L3                  = Gamepad   BTN_THUMBL
R3                  = Gamepad   BTN_THUMBR
L4                  = None
R4                  = None
L5                  = None
R5                  = None
Menu                = Gamepad   BTN_START
Options             = Gamepad   BTN_SELECT
Steam               = Gamepad   BTN_MODE
QuickAccess         = Gamepad   KEY_F20
# Triggers
LTrigg              = Gamepad   ABS_Z       +
RTrigg              = Gamepad   ABS_RZ      +
# Left Stick
LStickUp            = Gamepad   ABS_Y       -
LStickDown          = Gamepad   ABS_Y       +
LStickLeft          = Gamepad   ABS_X       -
LStickRight         = Gamepad   ABS_X       +
LStickTouch         = None
LStickForce         = None
# Right Stick
RStickUp            = Gamepad   ABS_RY      -
RStickDown          = Gamepad   ABS_RY      +
RStickLeft          = Gamepad   ABS_RX      -
RStickRight         = Gamepad   ABS_RX      +
RStickTouch         = None
RStickForce         = None
# Left Trackpad
LPadUp              = None
LPadDown            = None
LPadLeft            = None
LPadRight           = None
LPadTouch           = None
LPadRelX            = None
LPadRelY            = None
LPadTouch           = None
LPadPress           = None
LPadForce           = None
LPadPressQuadUp     = None
LPadPressQuadDown   = None
LPadPressQuadLeft   = None
LPadPressQuadRight  = None
LPadPressOrthUp     = None
LPadPressOrthDown   = None
LPadPressOrthLeft   = None
LPadPressOrthRight  = None
LPadPressGrid2x2_1  = None
LPadPressGrid2x2_2  = None
LPadPressGrid2x2_3  = None
LPadPressGrid2x2_4  = None
LPadPressGrid3x3_1  = None
LPadPressGrid3x3_2  = None
LPadPressGrid3x3_3  = None
LPadPressGrid3x3_4  = None
LPadPressGrid3x3_5  = None
LPadPressGrid3x3_6  = None
LPadPressGrid3x3_7  = None
LPadPressGrid3x3_8  = None
LPadPressGrid3x3_9  = None
# Right Trackpad
RPadUp              = None
RPadDown            = None
RPadLeft            = None
RPadRight           = None
RPadTouch           = None
RPadRelX            = Mouse     REL_X
RPadRelY            = Mouse     REL_Y
RPadTouch           = None
RPadPress           = Mouse     BTN_LEFT
RPadForce           = None
RPadPressQuadUp     = None
RPadPressQuadDown   = None
RPadPressQuadLeft   = None
RPadPressQuadRight  = None
RPadPressOrthUp     = None
RPadPressOrthDown   = None
RPadPressOrthLeft   = None
RPadPressOrthRight  = None
RPadPressGrid2x2_1  = None
RPadPressGrid2x2_2  = None
RPadPressGrid2x2_3  = None
RPadPressGrid2x2_4  = None
RPadPressGrid3x3_1  = None
RPadPressGrid3x3_2  = None
RPadPressGrid3x3_3  = None
RPadPressGrid3x3_4  = None
RPadPressGrid3x3_5  = None
RPadPressGrid3x3_6  = None
RPadPressGrid3x3_7  = None
RPadPressGrid3x3_8  = None
RPadPressGrid3x3_9  = None
# Accelerometers
AccelXPlus          = Motion    ABS_RX      +
AccelXMinus         = Motion    ABS_RX      -
AccelYPlus          = Motion    ABS_RY      +
AccelYMinus         = Motion    ABS_RY      -
AccelZPlus          = Motion    ABS_RZ      +
AccelZMinus         = Motion    ABS_RZ      -
# Gyro / Attitude
RollPlus            = Motion    ABS_X       +
RollMinus           = Motion    ABS_X       -
PitchPlus           = Motion    ABS_Y       +
PitchMinus          = Motion    ABS_Y       -
YawPlus             = Motion    ABS_Z       +
YawMinus            = Motion    ABS_Z       -

