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
#ifndef __GAMEPAD__DEVICE_STATE_HPP__
#define __GAMEPAD__DEVICE_STATE_HPP__


namespace Drivers::Gamepad
{

    // POD structure to contain the normalized device state.
    // This struct is populated from the input report.
    struct DeviceState
    {
        struct _dpad
        {
            bool            up;
            bool            down;
            bool            left;
            bool            right;
        } dpad;

        struct _btn
        {
            bool            a;
            bool            b;
            bool            x;
            bool            y;
            bool            l1;
            bool            l2;
            bool            l3;
            bool            l4;
            bool            l5;
            bool            r1;
            bool            r2;
            bool            r3;
            bool            r4;
            bool            r5;
            bool            menu;
            bool            options;
            bool            steam;
            bool            quick_access;
        } btn;

        struct _trigg
        {
            // Sensor
            double          z;
            // Configuration
            double          deadzone;
            double          scale;
        };
        
        struct _triggs
        {
            _trigg          l;
            _trigg          r;
        } trigg;

        // Reusable scoped struct
        struct _stick
        {
            // Sensors
            double          x;
            double          y;
            bool            touch;
            double          force;
            // Configuration
            double          deadzone;
            double          scale;
        };

        struct _sticks
        {
            _stick          l;
            _stick          r;
            bool            filtered;
        } stick;

        struct _touchpad
        {
            // Sensors
            double          x;
            double          y;
            double          sx;
            double          sy;
            double          dx;
            double          dy;
            bool            touch;
            bool            press;
            double          force;
            // Directional "button" input
            bool            btn_quad_up;
            bool            btn_quad_down;
            bool            btn_quad_left;
            bool            btn_quad_right;
            bool            btn_orth_up;
            bool            btn_orth_down;
            bool            btn_orth_left;
            bool            btn_orth_right;
            bool            btn_2x2_1;
            bool            btn_2x2_2;
            bool            btn_2x2_3;
            bool            btn_2x2_4;
            bool            btn_3x3_1;
            bool            btn_3x3_2;
            bool            btn_3x3_3;
            bool            btn_3x3_4;
            bool            btn_3x3_5;
            bool            btn_3x3_6;
            bool            btn_3x3_7;
            bool            btn_3x3_8;
            bool            btn_3x3_9;
            // Configuration
            double          deadzone;
            double          scale;
        };

        struct _touchpads
        {
            _touchpad       l;
            _touchpad       r;
            bool            filtered;
        } pad;

        struct _accel
        {
            double          x;
            double          y;
            double          z;
        } accel;

        struct _attitude
        {
            double          roll;
            double          pitch;
            double          yaw;
        } att;
    };

} // namespace Drivers::Gamepad


#endif // __GAMEPAD__DEVICE_STATE_HPP__
