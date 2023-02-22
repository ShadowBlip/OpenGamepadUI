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
#ifndef __UINPUT_HPP__
#define __UINPUT_HPP__

#include "uinput_device_config.hpp"
#include "../common/errors.hpp"
#include <linux/input.h>
#include <linux/uinput.h>
#include <cstdint>
#include <string>
#include <vector>
#include <unordered_map>


namespace Uinput
{
    // Define list of known uinput device nodes
    const std::vector<std::string>  UINPUT_PATH_LIST = { "/dev/uinput", "/dev/uinput/uninput", "/dev/misc/uinput" };
    //const input_event               SYN_EVENT = { .type   = EV_SYN, .code   = SYN_REPORT, .value  = 0, .time = 0 };

    struct EventInfo
    {
        input_event             ev;
        double                  min;
        double                  max;
    };
    
    struct EventBuffer
    {
        std::unordered_map<uint16_t, EventInfo>   key;
        std::unordered_map<uint16_t, EventInfo>   abs;
        std::unordered_map<uint16_t, EventInfo>   rel;
    };

    class Device
    {
    private:
        std::string             mDeviceName;
        int                     mFd;
        EventBuffer             mEvBuff;
        bool                    mFFEnabled;

        int                     Open( std::string deviceName );
        void                    Close();
        bool                    IsOpen();
        int                     EnableKey( uint16_t code );
        int                     EnableAbs( uint16_t code, int32_t min, int32_t max, int32_t fuzz = 0, int32_t res = 0 );
        int                     EnableRel( uint16_t code );
        int                     EnableFF();
        int                     Create( std::string deviceName, uint16_t vid, uint16_t pid, uint16_t ver );
        int                     Configure( const Uinput::DeviceConfig& rCfg );
        
    public:
        int                     UpdateKey( uint16_t code, bool value );
        int                     UpdateAbs( uint16_t code, double value );
        int                     UpdateRel( uint16_t code, int32_t value );
        int                     Flush();
        int                     Read( input_event& rEvent );
        // Force-feedback methods
        bool                    IsFFEnabled();
        int                     GetFFEffect( int32_t id, uinput_ff_upload& rData );
        int                     EraseFFEffect( int32_t id, uinput_ff_erase& rData );


        Device( const Uinput::DeviceConfig& rCfg );
        ~Device();
    };

} // namespace Uinput


#endif // __UINPUT_HPP__
