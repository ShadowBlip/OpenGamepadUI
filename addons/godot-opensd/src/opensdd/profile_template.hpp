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
#ifndef __PROFILE_TEMPLATE_HPP__
#define __PROFILE_TEMPLATE_HPP__

#include "drivers/gamepad/profile.hpp"
// Event codes
#include <linux/input.h>


// This is the template that the profile ini gets loaded on top of.
// We do this because there are things we want to default to if not
// specified in the config.  There are also some things we want to 
// pass on to the initialization, but aren't worth the time or errors
// to leave to the user to configure.
const Drivers::Gamepad::Profile PROFILE_TEMPLATE =
{
    .profile_name                   = "Basic profile template",
    .profile_desc                   = "The default profile template description.",
    .features
    {
        .ff                         = false,
        .motion                     = false,
        .mouse                      = true,
        .lizard                     = false,
        .filter_sticks              = true,
        .filter_pads                = true
    },
    .dz
    {
        // Initialize all deadzones at 0%
        .stick
        {
            .l                      = 0.00,
            .r                      = 0.00
        },
        .pad
        {
            .l                      = 0.00,
            .r                      = 0.00
        },
        .trigg
        {
            .l                      = 0.00,
            .r                      = 0.00
        }
    },
    .dev
    {
        .gamepad
        {
            .name                   = "OpenSD Gamepad Device",
            .vid                    = 0xDEAD,
            .pid                    = 0xBEEF,
            .ver                    = 0x0001,
            .key_list
            {
                // No keys or buttons are defined by default here.
                // This section will be filled in by ProfileIni::Load()
            },
            .abs_list
            {
                // No absolute axes are defined by default here.
                // This section will be filled in by ProfileIni::Load()
            },
            .rel_list
            {
                // No relative axes are defined by default here.
                // This section will be filled in by ProfileIni::Load()
            }
        },
        .motion
        {
            .name                   = "OpenSD Motion Control Device",
            .vid                    = 0xDEAD,
            .pid                    = 0xBEEF,
            .ver                    = 0x0001,
            .key_list
            {
                // No keys defined
            },
            .abs_list
            {
                // No absolute axes defined
            },
            .rel_list
            {
                // No relative axes defined
            }
        },
        .mouse
        {
            .name                   = "OpenSD Trackpad/Mouse Device",
            .vid                    = 0xDEAD,
            .pid                    = 0xF00D,
            .ver                    = 0x0001,
            .key_list
            {
                // Mouse devices should have at least BTN_LEFT defined, but
                // we'll go ahead and define all the standard mouse buttons
                BTN_LEFT,
                BTN_RIGHT,
                BTN_MIDDLE,
                BTN_SIDE,
                BTN_EXTRA,
                BTN_FORWARD,
                BTN_BACK,
                BTN_TASK,
            },
            .abs_list
            {
                // No absolute axes for touchpad / mouse
            },
            .rel_list
            {
                // Define the standard relative axes for mice by default
                REL_X,
                REL_Y,
                REL_WHEEL,
                REL_HWHEEL
            }
        }
    },
    .map
    {
        // Initialize using Binding constructors.  
        // No bindings are defined here by default.
        .dpad
        {
            .up                     = {},
            .down                   = {},
            .left                   = {},
            .right                  = {}
        },
        .btn
        {
            .a                      = {},
            .b                      = {},
            .x                      = {},
            .y                      = {},
            .l1                     = {},
            .l2                     = {},
            .l3                     = {},
            .l4                     = {},
            .l5                     = {},
            .r1                     = {},
            .r2                     = {},
            .r3                     = {},
            .r4                     = {},
            .r5                     = {},
            .menu                   = {},
            .options                = {},
            .steam                  = {},
            .quick_access           = {}
        },
        .trigg
        {
            .l                      = {},
            .r                      = {}
        },
        .stick
        {
            .l
            {
                .up                 = {},
                .down               = {},
                .left               = {},
                .right              = {},
                .touch              = {},
                .force              = {}
            },
            .r
            {
                .up                 = {},
                .down               = {},
                .left               = {},
                .right              = {},
                .touch              = {},
                .force              = {}
            },
        },
        .pad
        {
            .l
            {
                .up                 = {},
                .down               = {},
                .left               = {},
                .right              = {},
                .rel_x              = {},
                .rel_y              = {},
                .touch              = {},
                .press              = {},
                .force              = {},
                .btn_quad_up        = {},
                .btn_quad_down      = {},
                .btn_quad_left      = {},
                .btn_quad_right     = {},
                .btn_orth_up        = {},
                .btn_orth_down      = {},
                .btn_orth_left      = {},
                .btn_orth_right     = {},
                .btn_2x2_1          = {},
                .btn_2x2_2          = {},
                .btn_2x2_3          = {},
                .btn_2x2_4          = {},
                .btn_3x3_1          = {},
                .btn_3x3_2          = {},
                .btn_3x3_3          = {},
                .btn_3x3_4          = {},
                .btn_3x3_5          = {},
                .btn_3x3_6          = {},
                .btn_3x3_7          = {},
                .btn_3x3_8          = {},
                .btn_3x3_9          = {}
            },
            .r
            {
                .up                 = {},
                .down               = {},
                .left               = {},
                .right              = {},
                .rel_x              = {},
                .rel_y              = {},
                .touch              = {},
                .press              = {},
                .force              = {},
                .btn_quad_up        = {},
                .btn_quad_down      = {},
                .btn_quad_left      = {},
                .btn_quad_right     = {},
                .btn_orth_up        = {},
                .btn_orth_down      = {},
                .btn_orth_left      = {},
                .btn_orth_right     = {},
                .btn_2x2_1          = {},
                .btn_2x2_2          = {},
                .btn_2x2_3          = {},
                .btn_2x2_4          = {},
                .btn_3x3_1          = {},
                .btn_3x3_2          = {},
                .btn_3x3_3          = {},
                .btn_3x3_4          = {},
                .btn_3x3_5          = {},
                .btn_3x3_6          = {},
                .btn_3x3_7          = {},
                .btn_3x3_8          = {},
                .btn_3x3_9          = {}
            },
        },
        .accel
        {
            .x_plus                 = {},
            .x_minus                = {},
            .y_plus                 = {},
            .y_minus                = {},
            .z_plus                 = {},
            .z_minus                = {}
        },
        .att
        {
            .roll_plus              = {},
            .roll_minus             = {},
            .pitch_plus             = {},
            .pitch_minus            = {},
            .yaw_plus               = {},
            .yaw_minus              = {}
        }
    }
}; // end profile


#endif // __PROFILE_TEMPLATE_HPP__
