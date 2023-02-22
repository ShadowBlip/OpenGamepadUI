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
#ifndef __GAMEPAD__PROFILE_HPP__
#define __GAMEPAD__PROFILE_HPP__

#include "bindings.hpp"
#include "../../uinput_device_config.hpp"
// C++
#include <filesystem>


namespace Drivers::Gamepad
{
    struct Profile
    {
        std::string                             profile_name;
        std::string                             profile_desc;
        
        // List of features gamepad driver will enable
        struct _features
        {
            bool                                ff;
            bool                                motion;
            bool                                mouse;
            bool                                lizard;
            bool                                filter_sticks;
            bool                                filter_pads;
        } features;

        // Stick deazone profiles
        // Values are percentage of total stick precision, represented as 
        // floating point numbers (0 - 1.0)
        struct _deadzone
        {
            struct _dzlr
            {
                double                          l;
                double                          r;
            };
            
            _dzlr                               stick;
            _dzlr                               pad;
            _dzlr                               trigg;
        } dz;

        struct _devinfo
        {
            std::string                         name;
            uint16_t                            vid;
            uint16_t                            pid;
            uint16_t                            ver;
            std::vector<uint16_t>               key_list;
            std::vector<Uinput::AbsAxisInfo>    abs_list;
            std::vector<uint16_t>               rel_list;
        };
        
        // List of events each uinput device created by gamepad driver will
        // support.  Each event must first be enabled in order to bind to it.
        struct _devices
        {
            _devinfo                            gamepad;
            _devinfo                            motion;
            _devinfo                            mouse;
        } dev;
        
        // Map of each physical input to their respective uinput device events
        BindMap                                 map;
    };
    
}   // namespace Driver::Gamepad


#endif // __GAMEPAD__PROFILE_HPP__