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
#ifndef __GAMEPAD__BINDINGS_HPP__
#define __GAMEPAD__BINDINGS_HPP__

// Linux
#include <linux/input.h>
// C++ 
#include <cstdint>
#include <string>


namespace Drivers::Gamepad
{
    // Shorthand enums
    enum class BindType
    {
        // Devices
        NONE,
        GAME,
        MOTION,
        MOUSE,
        COMMAND,
        PROFILE
    };

    // Input binding
    struct Binding
    {
        BindType                type;           // Determines how binding is handled / what uinput device to emit from
        uint16_t                ev_type;        // Input event type
        uint16_t                ev_code;        // Input event code
        bool                    dir;            // Axis direction.  true = Axis+, false = Axis-
        std::string             str;            // If dev is COMMAND, this string will be executed in a shell environment
                                                // If dev is PROFILE, this holds the filename of the profile ini to load
        uint32_t                id;             // Unique binding ID for commands, or zero to disable wait_for_exit
        uint64_t                delay;          // Minimum delay between repeated commands
        uint64_t                timestamp;      // Timestamp of binding execution in ms
        
        Binding():
            type(BindType::NONE), ev_type(0), ev_code(0), dir(false), str(""), id(0), delay(0), timestamp(0) {};
            
        Binding( BindType bindType, uint16_t eventType, uint16_t eventCode, bool direction ):
            type(bindType), ev_type(eventType), ev_code(eventCode), dir(direction), str(""), id(0), delay(0), timestamp(0) {};
            
        Binding( std::string commandStr, uint32_t uniqueId, uint64_t repeatDelay ): 
            type(BindType::COMMAND), ev_type(0), ev_code(0), str(commandStr), id(uniqueId), delay(repeatDelay), timestamp(0) {};
    };

    // List of all gamepad input bindings are defined here
    struct BindMap
    {
        struct _dpad
        {
            Binding             up;
            Binding             down;
            Binding             left;
            Binding             right;
        } dpad;

        struct _btn
        {
            Binding             a;
            Binding             b;
            Binding             x;
            Binding             y;
            Binding             l1;
            Binding             l2;
            Binding             l3;
            Binding             l4;
            Binding             l5;
            Binding             r1;
            Binding             r2;
            Binding             r3;
            Binding             r4;
            Binding             r5;
            Binding             menu;
            Binding             options;
            Binding             steam;
            Binding             quick_access;
        } btn;

        struct _trigg
        {
            Binding             l;
            Binding             r;
        } trigg;

        struct _stick
        {
            // Absolute axes
            Binding             up;
            Binding             down;
            Binding             left;
            Binding             right;
            // Thumbstick touch sensors
            Binding             touch;
            Binding             force;
        };

        struct _sticks
        {
            _stick              l;
            _stick              r;
        } stick;

        struct _touchpad
        {
            // Absolute axes
            Binding             up;
            Binding             down;
            Binding             left;
            Binding             right;
            // Relative axes
            Binding             rel_x;
            Binding             rel_y;
            // Force sensor
            Binding             touch;
            Binding             press;
            Binding             force;
            // Triangular quadrant "buttons"
            Binding             btn_quad_up;
            Binding             btn_quad_down;
            Binding             btn_quad_left;
            Binding             btn_quad_right;
            // Orthogonal directional "buttons" (dpad-like)
            Binding             btn_orth_up;
            Binding             btn_orth_down;
            Binding             btn_orth_left;
            Binding             btn_orth_right;
            // 2x2 "button" grid
            Binding             btn_2x2_1;
            Binding             btn_2x2_2;
            Binding             btn_2x2_3;
            Binding             btn_2x2_4;
            // 3x3 "button" grid
            Binding             btn_3x3_1;
            Binding             btn_3x3_2;
            Binding             btn_3x3_3;
            Binding             btn_3x3_4;
            Binding             btn_3x3_5;
            Binding             btn_3x3_6;
            Binding             btn_3x3_7;
            Binding             btn_3x3_8;
            Binding             btn_3x3_9;
        };

        struct _touchpads
        {
            _touchpad           l;
            _touchpad           r;
        } pad;

        struct _accel
        {
            Binding             x_plus;
            Binding             x_minus;
            Binding             y_plus;
            Binding             y_minus;
            Binding             z_plus;
            Binding             z_minus;
        } accel;

        struct _attitude
        {
            Binding             roll_plus;
            Binding             roll_minus;
            Binding             pitch_plus;
            Binding             pitch_minus;
            Binding             yaw_plus;
            Binding             yaw_minus;
        } att;
    };

} // namespace Drivers::Gamepad


#endif // __GAMEPAD__BINDINGS_HPP__
