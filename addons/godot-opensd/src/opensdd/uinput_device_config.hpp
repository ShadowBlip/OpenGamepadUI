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
#ifndef __UINPUT__DEVICE_CONFIG_HPP__
#define __UINPUT__DEVICE_CONFIG_HPP__

#include <cstdint>
#include <vector>
#include <string>


namespace Uinput
{
    
    // Structure for absolute axis event registration
    struct AbsAxisInfo
    {
        uint16_t            code;       // Axis event code / number
        int32_t             min;        // Minimum range of axis
        int32_t             max;        // Maximum range of axis
        int32_t             fuzz;       // Axis value fuzziness
        int32_t             res;        // Axis resolution in units/mm or units/radian
    };
    
    struct DeviceConfig
    {
        // USB Device information
        struct _devinfo
        {
            std::string             name;
            uint16_t                vid;
            uint16_t                pid;
            uint16_t                ver;
        } deviceinfo;

        // Features to enable for this uinput device
        struct _features
        {
            bool                    enable_keys;    // This enables both key and js button events
            bool                    enable_abs;     // Absolute axes, like a joystick uses
            bool                    enable_rel;     // Relative axes, like a mouse uses
            bool                    enable_ff;      // Enable ForceFeedback / haptic feedback
        } features;
        
        // List of key/button codes that will be enabled
        std::vector<uint16_t>       key_list;
        
        // List of absolute axes to be enabled and their respective ranges 
        std::vector<AbsAxisInfo>    abs_list;
        
        // List of relative axes to be enabled
        std::vector<uint16_t>       rel_list;
    };
    
}   // namespace Uinput


#endif // __UINPUT__DEVICE_CONFIG_HPP__