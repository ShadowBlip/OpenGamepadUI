////////////////////////////////////////////////////////////////////////////////////////////////////
//  OpenSD
//  An open-source userspace driver for Valve's Steam Deck hardware
//
//  Copyright 2022 seek
//  https://gitlab.com/open-sd/opensd
//  Licensed under the GNU GPLv3+
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the 
//  GNU General Public License as published by the Free Software Foundation, either version 3 of 
//  the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. 
//  If not, see <https://www.gnu.org/licenses/>.             
////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef __INPUT_EVENT_NAMES_HPP__
#define __INPUT_EVENT_NAMES_HPP__

// Event definitions
#include <linux/input.h>
// C++
#include <map>
#include <string>


// All macros are evil, especially this one.  Is there no other way...
#define EVIL(n) { #n , n },


// String/int maps of event codes as defined in linux/input-event-codes.h as
// well as some helper functions to look them up. We need this so we can 
// reference event names in our gamepad profiles.
namespace EvName
{
    // Map of key/button names
    const std::map<std::string, unsigned int> KEY_MAP = 
    {
        EVIL(KEY_ESC)
        EVIL(KEY_1)
        EVIL(KEY_2)
        EVIL(KEY_3)
        EVIL(KEY_4)
        EVIL(KEY_5)
        EVIL(KEY_6)
        EVIL(KEY_7)
        EVIL(KEY_8)
        EVIL(KEY_9)
        EVIL(KEY_0)
        EVIL(KEY_MINUS)
        EVIL(KEY_EQUAL)
        EVIL(KEY_BACKSPACE)
        EVIL(KEY_TAB)
        EVIL(KEY_Q)
        EVIL(KEY_W)
        EVIL(KEY_E)
        EVIL(KEY_R)
        EVIL(KEY_T)
        EVIL(KEY_Y)
        EVIL(KEY_U)
        EVIL(KEY_I)
        EVIL(KEY_O)
        EVIL(KEY_P)
        EVIL(KEY_LEFTBRACE)
        EVIL(KEY_RIGHTBRACE)
        EVIL(KEY_ENTER)
        EVIL(KEY_LEFTCTRL)
        EVIL(KEY_A)
        EVIL(KEY_S)
        EVIL(KEY_D)
        EVIL(KEY_F)
        EVIL(KEY_G)
        EVIL(KEY_H)
        EVIL(KEY_J)
        EVIL(KEY_K)
        EVIL(KEY_L)
        EVIL(KEY_SEMICOLON)
        EVIL(KEY_APOSTROPHE)
        EVIL(KEY_GRAVE)
        EVIL(KEY_LEFTSHIFT)
        EVIL(KEY_BACKSLASH)
        EVIL(KEY_Z)
        EVIL(KEY_X)
        EVIL(KEY_C)
        EVIL(KEY_V)
        EVIL(KEY_B)
        EVIL(KEY_N)
        EVIL(KEY_M)
        EVIL(KEY_COMMA)
        EVIL(KEY_DOT)
        EVIL(KEY_SLASH)
        EVIL(KEY_RIGHTSHIFT)
        EVIL(KEY_KPASTERISK)
        EVIL(KEY_LEFTALT)
        EVIL(KEY_SPACE)
        EVIL(KEY_CAPSLOCK)
        EVIL(KEY_F1)
        EVIL(KEY_F2)
        EVIL(KEY_F3)
        EVIL(KEY_F4)
        EVIL(KEY_F5)
        EVIL(KEY_F6)
        EVIL(KEY_F7)
        EVIL(KEY_F8)
        EVIL(KEY_F9)
        EVIL(KEY_F10)
        EVIL(KEY_NUMLOCK)
        EVIL(KEY_SCROLLLOCK)
        EVIL(KEY_KP7)
        EVIL(KEY_KP8)
        EVIL(KEY_KP9)
        EVIL(KEY_KPMINUS)
        EVIL(KEY_KP4)
        EVIL(KEY_KP5)
        EVIL(KEY_KP6)
        EVIL(KEY_KPPLUS)
        EVIL(KEY_KP1)
        EVIL(KEY_KP2)
        EVIL(KEY_KP3)
        EVIL(KEY_KP0)
        EVIL(KEY_KPDOT)

        EVIL(KEY_ZENKAKUHANKAKU)
        EVIL(KEY_102ND)
        EVIL(KEY_F11)
        EVIL(KEY_F12)
        EVIL(KEY_RO)
        EVIL(KEY_KATAKANA)
        EVIL(KEY_HIRAGANA)
        EVIL(KEY_HENKAN)
        EVIL(KEY_KATAKANAHIRAGANA)
        EVIL(KEY_MUHENKAN)
        EVIL(KEY_KPJPCOMMA)
        EVIL(KEY_KPENTER)
        EVIL(KEY_RIGHTCTRL)
        EVIL(KEY_KPSLASH)
        EVIL(KEY_SYSRQ)
        EVIL(KEY_RIGHTALT)
        EVIL(KEY_LINEFEED)
        EVIL(KEY_HOME)
        EVIL(KEY_UP)
        EVIL(KEY_PAGEUP)
        EVIL(KEY_LEFT)
        EVIL(KEY_RIGHT)
        EVIL(KEY_END)
        EVIL(KEY_DOWN)
        EVIL(KEY_PAGEDOWN)
        EVIL(KEY_INSERT)
        EVIL(KEY_DELETE)
        EVIL(KEY_MACRO)
        EVIL(KEY_MUTE)
        EVIL(KEY_VOLUMEDOWN)
        EVIL(KEY_VOLUMEUP)
        EVIL(KEY_POWER)
        EVIL(KEY_KPEQUAL)
        EVIL(KEY_KPPLUSMINUS)
        EVIL(KEY_PAUSE)
        EVIL(KEY_SCALE)

        EVIL(KEY_KPCOMMA)
        EVIL(KEY_HANGEUL)
        EVIL(KEY_HANGUEL)
        EVIL(KEY_HANJA)
        EVIL(KEY_YEN)
        EVIL(KEY_LEFTMETA)
        EVIL(KEY_RIGHTMETA)
        EVIL(KEY_COMPOSE)

        EVIL(KEY_STOP)
        EVIL(KEY_AGAIN)
        EVIL(KEY_PROPS)
        EVIL(KEY_UNDO)
        EVIL(KEY_FRONT)
        EVIL(KEY_COPY)
        EVIL(KEY_OPEN)
        EVIL(KEY_PASTE)
        EVIL(KEY_FIND)
        EVIL(KEY_CUT)
        EVIL(KEY_HELP)
        EVIL(KEY_MENU)
        EVIL(KEY_CALC)
        EVIL(KEY_SETUP)
        EVIL(KEY_SLEEP)
        EVIL(KEY_WAKEUP)
        EVIL(KEY_FILE)
        EVIL(KEY_SENDFILE)
        EVIL(KEY_DELETEFILE)
        EVIL(KEY_XFER)
        EVIL(KEY_PROG1)
        EVIL(KEY_PROG2)
        EVIL(KEY_WWW)
        EVIL(KEY_MSDOS)
        EVIL(KEY_COFFEE)
        EVIL(KEY_SCREENLOCK)
        EVIL(KEY_ROTATE_DISPLAY)
        EVIL(KEY_DIRECTION)
        EVIL(KEY_CYCLEWINDOWS)
        EVIL(KEY_MAIL)
        EVIL(KEY_BOOKMARKS)
        EVIL(KEY_COMPUTER)
        EVIL(KEY_BACK)
        EVIL(KEY_FORWARD)
        EVIL(KEY_CLOSECD)
        EVIL(KEY_EJECTCD)
        EVIL(KEY_EJECTCLOSECD)
        EVIL(KEY_NEXTSONG)
        EVIL(KEY_PLAYPAUSE)
        EVIL(KEY_PREVIOUSSONG)
        EVIL(KEY_STOPCD)
        EVIL(KEY_RECORD)
        EVIL(KEY_REWIND)
        EVIL(KEY_PHONE)
        EVIL(KEY_ISO)
        EVIL(KEY_CONFIG)
        EVIL(KEY_HOMEPAGE)
        EVIL(KEY_REFRESH)
        EVIL(KEY_EXIT)
        EVIL(KEY_MOVE)
        EVIL(KEY_EDIT)
        EVIL(KEY_SCROLLUP)
        EVIL(KEY_SCROLLDOWN)
        EVIL(KEY_KPLEFTPAREN)
        EVIL(KEY_KPRIGHTPAREN)
        EVIL(KEY_NEW)
        EVIL(KEY_REDO)

        EVIL(KEY_F13)
        EVIL(KEY_F14)
        EVIL(KEY_F15)
        EVIL(KEY_F16)
        EVIL(KEY_F17)
        EVIL(KEY_F18)
        EVIL(KEY_F19)
        EVIL(KEY_F20)
        EVIL(KEY_F21)
        EVIL(KEY_F22)
        EVIL(KEY_F23)
        EVIL(KEY_F24)

        EVIL(KEY_PLAYCD)
        EVIL(KEY_PAUSECD)
        EVIL(KEY_PROG3)
        EVIL(KEY_PROG4)
        
// 5.17
#ifdef  KEY_ALL_APPLICATIONS
        EVIL(KEY_ALL_APPLICATIONS)
#endif

#ifdef  KEY_DASHBOARD
        EVIL(KEY_DASHBOARD)
#endif

        EVIL(KEY_SUSPEND)
        EVIL(KEY_CLOSE)
        EVIL(KEY_PLAY)
        EVIL(KEY_FASTFORWARD)
        EVIL(KEY_BASSBOOST)
        EVIL(KEY_PRINT)
        EVIL(KEY_HP)
        EVIL(KEY_CAMERA)
        EVIL(KEY_SOUND)
        EVIL(KEY_QUESTION)
        EVIL(KEY_EMAIL)
        EVIL(KEY_CHAT)
        EVIL(KEY_SEARCH)
        EVIL(KEY_CONNECT)
        EVIL(KEY_FINANCE)
        EVIL(KEY_SPORT)
        EVIL(KEY_SHOP)
        EVIL(KEY_ALTERASE)
        EVIL(KEY_CANCEL)
        EVIL(KEY_BRIGHTNESSDOWN)
        EVIL(KEY_BRIGHTNESSUP)
        EVIL(KEY_MEDIA)
        EVIL(KEY_SWITCHVIDEOMODE)
        EVIL(KEY_KBDILLUMTOGGLE)
        EVIL(KEY_KBDILLUMDOWN)
        EVIL(KEY_KBDILLUMUP)
        EVIL(KEY_SEND)
        EVIL(KEY_REPLY)
        EVIL(KEY_FORWARDMAIL)
        EVIL(KEY_SAVE)
        EVIL(KEY_DOCUMENTS)
        EVIL(KEY_BATTERY)
        EVIL(KEY_BLUETOOTH)
        EVIL(KEY_WLAN)
        EVIL(KEY_UWB)
        EVIL(KEY_UNKNOWN)
        EVIL(KEY_VIDEO_NEXT)
        EVIL(KEY_VIDEO_PREV)
        EVIL(KEY_BRIGHTNESS_CYCLE)
        EVIL(KEY_BRIGHTNESS_AUTO)
        EVIL(KEY_BRIGHTNESS_ZERO)
        EVIL(KEY_DISPLAY_OFF)
        EVIL(KEY_WWAN)
        EVIL(KEY_WIMAX)
        EVIL(KEY_RFKILL)
        EVIL(KEY_MICMUTE)

        EVIL(KEY_OK)
        EVIL(KEY_SELECT)
        EVIL(KEY_GOTO)
        EVIL(KEY_CLEAR)
        EVIL(KEY_POWER2)
        EVIL(KEY_OPTION)
        EVIL(KEY_INFO)
        EVIL(KEY_TIME)
        EVIL(KEY_VENDOR)
        EVIL(KEY_ARCHIVE)
        EVIL(KEY_PROGRAM)
        EVIL(KEY_CHANNEL)
        EVIL(KEY_FAVORITES)
        EVIL(KEY_EPG)
        EVIL(KEY_PVR)
        EVIL(KEY_MHP)
        EVIL(KEY_LANGUAGE)
        EVIL(KEY_TITLE)
        EVIL(KEY_SUBTITLE)
        EVIL(KEY_ANGLE)

// 5.1
#ifdef KEY_FULL_SCREEN
        EVIL(KEY_FULL_SCREEN)
#endif

        EVIL(KEY_ZOOM)
        EVIL(KEY_MODE)
        EVIL(KEY_KEYBOARD)

// 5.1
#ifdef KEY_ASPECT_RATIO
        EVIL(KEY_ASPECT_RATIO)
#endif

        EVIL(KEY_SCREEN)
        EVIL(KEY_PC)
        EVIL(KEY_TV)
        EVIL(KEY_TV2)
        EVIL(KEY_VCR)
        EVIL(KEY_VCR2)
        EVIL(KEY_SAT)
        EVIL(KEY_SAT2)
        EVIL(KEY_CD)
        EVIL(KEY_TAPE)
        EVIL(KEY_RADIO)
        EVIL(KEY_TUNER)
        EVIL(KEY_PLAYER)
        EVIL(KEY_TEXT)
        EVIL(KEY_DVD)
        EVIL(KEY_AUX)
        EVIL(KEY_MP3)
        EVIL(KEY_AUDIO)
        EVIL(KEY_VIDEO)
        EVIL(KEY_DIRECTORY)
        EVIL(KEY_LIST)
        EVIL(KEY_MEMO)
        EVIL(KEY_CALENDAR)
        EVIL(KEY_RED)
        EVIL(KEY_GREEN)
        EVIL(KEY_YELLOW)
        EVIL(KEY_BLUE)
        EVIL(KEY_CHANNELUP)
        EVIL(KEY_CHANNELDOWN)
        EVIL(KEY_FIRST)
        EVIL(KEY_LAST)
        EVIL(KEY_AB)
        EVIL(KEY_NEXT)
        EVIL(KEY_RESTART)
        EVIL(KEY_SLOW)
        EVIL(KEY_SHUFFLE)
        EVIL(KEY_BREAK)
        EVIL(KEY_PREVIOUS)
        EVIL(KEY_DIGITS)
        EVIL(KEY_TEEN)
        EVIL(KEY_TWEN)
        EVIL(KEY_VIDEOPHONE)
        EVIL(KEY_GAMES)
        EVIL(KEY_ZOOMIN)
        EVIL(KEY_ZOOMOUT)
        EVIL(KEY_ZOOMRESET)
        EVIL(KEY_WORDPROCESSOR)
        EVIL(KEY_EDITOR)
        EVIL(KEY_SPREADSHEET)
        EVIL(KEY_GRAPHICSEDITOR)
        EVIL(KEY_PRESENTATION)
        EVIL(KEY_DATABASE)
        EVIL(KEY_NEWS)
        EVIL(KEY_VOICEMAIL)
        EVIL(KEY_ADDRESSBOOK)
        EVIL(KEY_MESSENGER)
        EVIL(KEY_DISPLAYTOGGLE)
        EVIL(KEY_BRIGHTNESS_TOGGLE)
        EVIL(KEY_SPELLCHECK)
        EVIL(KEY_LOGOFF)

        EVIL(KEY_DOLLAR)
        EVIL(KEY_EURO)

        EVIL(KEY_FRAMEBACK)
        EVIL(KEY_FRAMEFORWARD)
        EVIL(KEY_CONTEXT_MENU)
        EVIL(KEY_MEDIA_REPEAT)
        EVIL(KEY_10CHANNELSUP)
        EVIL(KEY_10CHANNELSDOWN)
        EVIL(KEY_IMAGES)

// 5.10
#ifdef KEY_NOTIFICATION_CENTER
        EVIL(KEY_NOTIFICATION_CENTER)
        EVIL(KEY_PICKUP_PHONE)
        EVIL(KEY_HANGUP_PHONE)
#endif

        EVIL(KEY_DEL_EOL)
        EVIL(KEY_DEL_EOS)
        EVIL(KEY_INS_LINE)
        EVIL(KEY_DEL_LINE)

        EVIL(KEY_FN)
        EVIL(KEY_FN_ESC)
        EVIL(KEY_FN_F1)
        EVIL(KEY_FN_F2)
        EVIL(KEY_FN_F3)
        EVIL(KEY_FN_F4)
        EVIL(KEY_FN_F5)
        EVIL(KEY_FN_F6)
        EVIL(KEY_FN_F7)
        EVIL(KEY_FN_F8)
        EVIL(KEY_FN_F9)
        EVIL(KEY_FN_F10)
        EVIL(KEY_FN_F11)
        EVIL(KEY_FN_F12)
        EVIL(KEY_FN_1)
        EVIL(KEY_FN_2)
        EVIL(KEY_FN_D)
        EVIL(KEY_FN_E)
        EVIL(KEY_FN_F)
        EVIL(KEY_FN_S)
        EVIL(KEY_FN_B)

// 5.10
#ifdef KEY_FN_RIGHT_SHIFT
        EVIL(KEY_FN_RIGHT_SHIFT)
#endif

        EVIL(KEY_BRL_DOT1)
        EVIL(KEY_BRL_DOT2)
        EVIL(KEY_BRL_DOT3)
        EVIL(KEY_BRL_DOT4)
        EVIL(KEY_BRL_DOT5)
        EVIL(KEY_BRL_DOT6)
        EVIL(KEY_BRL_DOT7)
        EVIL(KEY_BRL_DOT8)
        EVIL(KEY_BRL_DOT9)
        EVIL(KEY_BRL_DOT10)

        EVIL(KEY_NUMERIC_0)
        EVIL(KEY_NUMERIC_1)
        EVIL(KEY_NUMERIC_2)
        EVIL(KEY_NUMERIC_3)
        EVIL(KEY_NUMERIC_4)
        EVIL(KEY_NUMERIC_5)
        EVIL(KEY_NUMERIC_6)
        EVIL(KEY_NUMERIC_7)
        EVIL(KEY_NUMERIC_8)
        EVIL(KEY_NUMERIC_9)
        EVIL(KEY_NUMERIC_STAR)
        EVIL(KEY_NUMERIC_POUND)
        EVIL(KEY_NUMERIC_A)
        EVIL(KEY_NUMERIC_B)
        EVIL(KEY_NUMERIC_C)
        EVIL(KEY_NUMERIC_D)

        EVIL(KEY_CAMERA_FOCUS)
        EVIL(KEY_WPS_BUTTON)

        EVIL(KEY_TOUCHPAD_TOGGLE)
        EVIL(KEY_TOUCHPAD_ON)
        EVIL(KEY_TOUCHPAD_OFF)

        EVIL(KEY_CAMERA_ZOOMIN)
        EVIL(KEY_CAMERA_ZOOMOUT)
        EVIL(KEY_CAMERA_UP)
        EVIL(KEY_CAMERA_DOWN)
        EVIL(KEY_CAMERA_LEFT)
        EVIL(KEY_CAMERA_RIGHT)

        EVIL(KEY_ATTENDANT_ON)
        EVIL(KEY_ATTENDANT_OFF)
        EVIL(KEY_ATTENDANT_TOGGLE)
        EVIL(KEY_LIGHTS_TOGGLE)

        EVIL(KEY_ALS_TOGGLE)

// 4.16
#ifdef KEY_ROTATE_LOCK_TOGGLE
        EVIL(KEY_ROTATE_LOCK_TOGGLE)
#endif

        EVIL(KEY_BUTTONCONFIG)
        EVIL(KEY_TASKMANAGER)
        EVIL(KEY_JOURNAL)
        EVIL(KEY_CONTROLPANEL)
        EVIL(KEY_APPSELECT)
        EVIL(KEY_SCREENSAVER)
        EVIL(KEY_VOICECOMMAND)

// 4.13
#ifdef KEY_ASSISTANT
        EVIL(KEY_ASSISTANT)
#endif

// 5.2
#ifdef KEY_KBD_LAYOUT_NEXT
        EVIL(KEY_KBD_LAYOUT_NEXT)
#endif

// 5.13
#ifdef KEY_EMOJI_PICKER
        EVIL(KEY_EMOJI_PICKER)
#endif

// 5.17
#ifdef KEY_DICTATE
        EVIL(KEY_DICTATE)
#endif

        EVIL(KEY_BRIGHTNESS_MIN)
        EVIL(KEY_BRIGHTNESS_MAX)

        EVIL(KEY_KBDINPUTASSIST_PREV)
        EVIL(KEY_KBDINPUTASSIST_NEXT)
        EVIL(KEY_KBDINPUTASSIST_PREVGROUP)
        EVIL(KEY_KBDINPUTASSIST_NEXTGROUP)
        EVIL(KEY_KBDINPUTASSIST_ACCEPT)
        EVIL(KEY_KBDINPUTASSIST_CANCEL)

// 4.7
// HDMI CEC
#ifdef KEY_RIGHT_UP
        EVIL(KEY_RIGHT_UP)
        EVIL(KEY_RIGHT_DOWN)
        EVIL(KEY_LEFT_UP)
        EVIL(KEY_LEFT_DOWN)
        EVIL(KEY_ROOT_MENU)
        EVIL(KEY_MEDIA_TOP_MENU)
        EVIL(KEY_NUMERIC_11)
        EVIL(KEY_NUMERIC_12)
        EVIL(KEY_AUDIO_DESC)
        EVIL(KEY_3D_MODE)
        EVIL(KEY_NEXT_FAVORITE)
        EVIL(KEY_STOP_RECORD)
        EVIL(KEY_PAUSE_RECORD)
        EVIL(KEY_VOD)
        EVIL(KEY_UNMUTE)
        EVIL(KEY_FASTREVERSE)
        EVIL(KEY_SLOWREVERSE)
        EVIL(KEY_DATA)
#endif // HDMI CEC

// 4.12
#ifdef KEY_ONSCREEN_KEYBOARD
        EVIL(KEY_ONSCREEN_KEYBOARD)
#endif

// 5.5
#ifdef KEY_PRIVACY_SCREEN_TOGGLE
        EVIL(KEY_PRIVACY_SCREEN_TOGGLE)
#endif

// 5.6
#ifdef KEY_SELECTIVE_SCREENSHOT
        EVIL(KEY_SELECTIVE_SCREENSHOT)
#endif

// 5.18
// Marine navigation keycodes
#ifdef KEY_NEXT_ELEMENT
        EVIL(KEY_NEXT_ELEMENT)
        EVIL(KEY_PREVIOUS_ELEMENT)
        EVIL(KEY_AUTOPILOT_ENGAGE_TOGGLE)
        EVIL(KEY_MARK_WAYPOINT)
        EVIL(KEY_SOS)
        EVIL(KEY_NAV_CHART)
        EVIL(KEY_FISHING_CHART)
        EVIL(KEY_SINGLE_RANGE_RADAR)
        EVIL(KEY_DUAL_RANGE_RADAR)
        EVIL(KEY_RADAR_OVERLAY)
        EVIL(KEY_TRADITIONAL_SONAR)
        EVIL(KEY_CLEARVU_SONAR)
        EVIL(KEY_SIDEVU_SONAR)
        EVIL(KEY_NAV_INFO)
        EVIL(KEY_BRIGHTNESS_MENU)
#endif // Marine navigation keycodes

// 5.5
// Macro keyboards
#ifdef KEY_MACRO1
        EVIL(KEY_MACRO1)
        EVIL(KEY_MACRO2)
        EVIL(KEY_MACRO3)
        EVIL(KEY_MACRO4)
        EVIL(KEY_MACRO5)
        EVIL(KEY_MACRO6)
        EVIL(KEY_MACRO7)
        EVIL(KEY_MACRO8)
        EVIL(KEY_MACRO9)
        EVIL(KEY_MACRO10)
        EVIL(KEY_MACRO11)
        EVIL(KEY_MACRO12)
        EVIL(KEY_MACRO13)
        EVIL(KEY_MACRO14)
        EVIL(KEY_MACRO15)
        EVIL(KEY_MACRO16)
        EVIL(KEY_MACRO17)
        EVIL(KEY_MACRO18)
        EVIL(KEY_MACRO19)
        EVIL(KEY_MACRO20)
        EVIL(KEY_MACRO21)
        EVIL(KEY_MACRO22)
        EVIL(KEY_MACRO23)
        EVIL(KEY_MACRO24)
        EVIL(KEY_MACRO25)
        EVIL(KEY_MACRO26)
        EVIL(KEY_MACRO27)
        EVIL(KEY_MACRO28)
        EVIL(KEY_MACRO29)
        EVIL(KEY_MACRO30)

        EVIL(KEY_MACRO_RECORD_START)
        EVIL(KEY_MACRO_RECORD_STOP)
        EVIL(KEY_MACRO_PRESET_CYCLE)
        EVIL(KEY_MACRO_PRESET1)
        EVIL(KEY_MACRO_PRESET2)
        EVIL(KEY_MACRO_PRESET3)
#endif  // Macro keyboards

//5.5
// LCD panel keyboards
#ifdef KEY_KBD_LCD_MENU1
        EVIL(KEY_KBD_LCD_MENU1)
        EVIL(KEY_KBD_LCD_MENU2)
        EVIL(KEY_KBD_LCD_MENU3)
        EVIL(KEY_KBD_LCD_MENU4)
        EVIL(KEY_KBD_LCD_MENU5)
#endif

        EVIL(BTN_MISC)
        EVIL(BTN_0)
        EVIL(BTN_1)
        EVIL(BTN_2)
        EVIL(BTN_3)
        EVIL(BTN_4)
        EVIL(BTN_5)
        EVIL(BTN_6)
        EVIL(BTN_7)
        EVIL(BTN_8)
        EVIL(BTN_9)

        EVIL(BTN_MOUSE)
        EVIL(BTN_LEFT)
        EVIL(BTN_RIGHT)
        EVIL(BTN_MIDDLE)
        EVIL(BTN_SIDE)
        EVIL(BTN_EXTRA)
        EVIL(BTN_FORWARD)
        EVIL(BTN_BACK)
        EVIL(BTN_TASK)

        EVIL(BTN_JOYSTICK)
        EVIL(BTN_TRIGGER)
        EVIL(BTN_THUMB)
        EVIL(BTN_THUMB2)
        EVIL(BTN_TOP)
        EVIL(BTN_TOP2)
        EVIL(BTN_PINKIE)
        EVIL(BTN_BASE)
        EVIL(BTN_BASE2)
        EVIL(BTN_BASE3)
        EVIL(BTN_BASE4)
        EVIL(BTN_BASE5)
        EVIL(BTN_BASE6)
        EVIL(BTN_DEAD)

        EVIL(BTN_DPAD_UP)
        EVIL(BTN_DPAD_DOWN)
        EVIL(BTN_DPAD_LEFT)
        EVIL(BTN_DPAD_RIGHT)

        EVIL(BTN_GAMEPAD)
        EVIL(BTN_SOUTH)
        EVIL(BTN_A)
        EVIL(BTN_EAST)
        EVIL(BTN_B)
        EVIL(BTN_C)
        EVIL(BTN_NORTH)
        EVIL(BTN_X)
        EVIL(BTN_WEST)
        EVIL(BTN_Y)
        EVIL(BTN_Z)
        EVIL(BTN_TL)
        EVIL(BTN_TR)
        EVIL(BTN_TL2)
        EVIL(BTN_TR2)
        EVIL(BTN_SELECT)
        EVIL(BTN_START)
        EVIL(BTN_MODE)
        EVIL(BTN_THUMBL)
        EVIL(BTN_THUMBR)

        EVIL(BTN_DIGI)
        EVIL(BTN_TOOL_PEN)
        EVIL(BTN_TOOL_RUBBER)
        EVIL(BTN_TOOL_BRUSH)
        EVIL(BTN_TOOL_PENCIL)
        EVIL(BTN_TOOL_AIRBRUSH)
        EVIL(BTN_TOOL_FINGER)
        EVIL(BTN_TOOL_MOUSE)
        EVIL(BTN_TOOL_LENS)
        EVIL(BTN_TOOL_QUINTTAP)

// 4.15
#ifdef BTN_STYLUS3
        EVIL(BTN_STYLUS3)
#endif

        EVIL(BTN_TOUCH)
        EVIL(BTN_STYLUS)
        EVIL(BTN_STYLUS2)
        EVIL(BTN_TOOL_DOUBLETAP)
        EVIL(BTN_TOOL_TRIPLETAP)
        EVIL(BTN_TOOL_QUADTAP)

        EVIL(BTN_WHEEL)
        EVIL(BTN_GEAR_DOWN)
        EVIL(BTN_GEAR_UP)

        EVIL(BTN_TRIGGER_HAPPY)
        EVIL(BTN_TRIGGER_HAPPY1)
        EVIL(BTN_TRIGGER_HAPPY2)
        EVIL(BTN_TRIGGER_HAPPY3)
        EVIL(BTN_TRIGGER_HAPPY4)
        EVIL(BTN_TRIGGER_HAPPY5)
        EVIL(BTN_TRIGGER_HAPPY6)
        EVIL(BTN_TRIGGER_HAPPY7)
        EVIL(BTN_TRIGGER_HAPPY8)
        EVIL(BTN_TRIGGER_HAPPY9)
        EVIL(BTN_TRIGGER_HAPPY10)
        EVIL(BTN_TRIGGER_HAPPY11)
        EVIL(BTN_TRIGGER_HAPPY12)
        EVIL(BTN_TRIGGER_HAPPY13)
        EVIL(BTN_TRIGGER_HAPPY14)
        EVIL(BTN_TRIGGER_HAPPY15)
        EVIL(BTN_TRIGGER_HAPPY16)
        EVIL(BTN_TRIGGER_HAPPY17)
        EVIL(BTN_TRIGGER_HAPPY18)
        EVIL(BTN_TRIGGER_HAPPY19)
        EVIL(BTN_TRIGGER_HAPPY20)
        EVIL(BTN_TRIGGER_HAPPY21)
        EVIL(BTN_TRIGGER_HAPPY22)
        EVIL(BTN_TRIGGER_HAPPY23)
        EVIL(BTN_TRIGGER_HAPPY24)
        EVIL(BTN_TRIGGER_HAPPY25)
        EVIL(BTN_TRIGGER_HAPPY26)
        EVIL(BTN_TRIGGER_HAPPY27)
        EVIL(BTN_TRIGGER_HAPPY28)
        EVIL(BTN_TRIGGER_HAPPY29)
        EVIL(BTN_TRIGGER_HAPPY30)
        EVIL(BTN_TRIGGER_HAPPY31)
        EVIL(BTN_TRIGGER_HAPPY32)
        EVIL(BTN_TRIGGER_HAPPY33)
        EVIL(BTN_TRIGGER_HAPPY34)
        EVIL(BTN_TRIGGER_HAPPY35)
        EVIL(BTN_TRIGGER_HAPPY36)
        EVIL(BTN_TRIGGER_HAPPY37)
        EVIL(BTN_TRIGGER_HAPPY38)
        EVIL(BTN_TRIGGER_HAPPY39)
        EVIL(BTN_TRIGGER_HAPPY40)
    };

    // Map of all absolute axis names
    const std::map<std::string, unsigned int> ABS_MAP = 
    {
        EVIL(ABS_X)
        EVIL(ABS_Y)
        EVIL(ABS_Z)
        EVIL(ABS_RX)
        EVIL(ABS_RY)
        EVIL(ABS_RZ)
        EVIL(ABS_THROTTLE)
        EVIL(ABS_RUDDER)
        EVIL(ABS_WHEEL)
        EVIL(ABS_GAS)
        EVIL(ABS_BRAKE)
        EVIL(ABS_HAT0X)
        EVIL(ABS_HAT0Y)
        EVIL(ABS_HAT1X)
        EVIL(ABS_HAT1Y)
        EVIL(ABS_HAT2X)
        EVIL(ABS_HAT2Y)
        EVIL(ABS_HAT3X)
        EVIL(ABS_HAT3Y)
        EVIL(ABS_PRESSURE)
        EVIL(ABS_DISTANCE)
        EVIL(ABS_TILT_X)
        EVIL(ABS_TILT_Y)
        EVIL(ABS_TOOL_WIDTH)

        EVIL(ABS_VOLUME)

// 6.1
#ifdef ABS_PROFILE
        EVIL(ABS_PROFILE)
#endif

        EVIL(ABS_MISC)

        EVIL(ABS_MT_SLOT)
        EVIL(ABS_MT_TOUCH_MAJOR)
        EVIL(ABS_MT_TOUCH_MINOR)
        EVIL(ABS_MT_WIDTH_MAJOR)
        EVIL(ABS_MT_WIDTH_MINOR)
        EVIL(ABS_MT_ORIENTATION)
        EVIL(ABS_MT_POSITION_X)
        EVIL(ABS_MT_POSITION_Y)
        EVIL(ABS_MT_TOOL_TYPE)
        EVIL(ABS_MT_BLOB_ID)
        EVIL(ABS_MT_TRACKING_ID)
        EVIL(ABS_MT_PRESSURE)
        EVIL(ABS_MT_DISTANCE)
        EVIL(ABS_MT_TOOL_X)
        EVIL(ABS_MT_TOOL_Y)
    };

    // Map of all relative axis names
    const std::map<std::string, unsigned int> REL_MAP = 
    {
        EVIL(REL_X)
        EVIL(REL_Y)
        EVIL(REL_Z)
        EVIL(REL_RX)
        EVIL(REL_RY)
        EVIL(REL_RZ)
        EVIL(REL_HWHEEL)
        EVIL(REL_DIAL)
        EVIL(REL_WHEEL)
        EVIL(REL_MISC)

// 5.0
#ifdef REL_WHEEL_HI_RES
        EVIL(REL_WHEEL_HI_RES)
        EVIL(REL_HWHEEL_HI_RES)
#endif

    };
    
    // Helper functions
    
    // Get event type
    // Returns event type for the event name based on prefix (KEY_X = EV_KEY)
    int GetEvType( std::string codeName);
    
    // Get event code
    // Returns the numeric code associated with a name as defined in input-event-codes.h
    int GetEvCode( std::string codeName );
    
} // namespace EvName


#endif // __INPUT_EVENT_NAMES_HPP__