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
#ifndef __GAMEPAD__COMPAT_HPP__
#define __GAMEPAD__COMPAT_HPP__

#include <vector>
#include <cstdint>


namespace Drivers::Gamepad
{
    struct UsbHidInterface
    {
        uint16_t      vid;
        uint16_t      pid;
        uint16_t      ifacenum;
    };

    // List of USB interfaces for "gamepad" portion of the Steam Deck since
    // firmware or hardware revisions might cause this to change.
    const std::vector<UsbHidInterface>  KNOWN_DEVICES = 
    { 
        // Gamepad device interface (v1)
        // Should be able to look these up with lsusb
        { 
            .vid        = 0x28de,           // IdVendor
            .pid        = 0x1205,           // IdProduct
            .ifacenum   = 2                 // bInterfaceNumber
        } 
    };

} // namespace Driver::Gamepad


#endif // __GAMEPAD__COMPAT_HPP__
