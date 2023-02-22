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
#ifndef __HIDRAW_CPP__
#define __HIDRAW_CPP__

// Needed for return codes
#include "../common/errors.hpp"
// Linux
#include <linux/hidraw.h>
#include <poll.h>
// C++
#include <cstdint>
#include <filesystem>
#include <vector>
#include <thread>


class Hidraw
{
private:
    int                     mFd;
    int                     mReadTimeout;
    int                     mTimeoutCount;
    int                     mMaxTimeouts;
    std::filesystem::path   mPath;
    std::mutex              mMutex;
    

public:
    std::filesystem::path   FindDevNode( uint16_t vid, uint16_t pid, uint16_t iFaceNum );
    int                     Open( std::filesystem::path hidrawPath );
    void                    Close();
    bool                    IsOpen();

    int                     Read( std::vector<uint8_t>& rData );
    int                     Write( const std::vector<uint8_t>& rData );

    int                     GetReportDescriptor( hidraw_report_descriptor& rDesc );
    std::string             GetName();
    std::string             GetPhysLocation();
    int                     GetInfo( hidraw_devinfo& rInfo );
    int                     GetFeatureReport( std::vector<uint8_t>& rData );
    int                     GetFeatureReport( uint8_t reportId, std::vector<uint8_t>& rData );
    int                     SetFeatureReport( const std::vector<uint8_t>& rData );
    int                     SetFeatureReport( uint8_t reportId, const std::vector<uint8_t>& rData );
    
    
    Hidraw();
    ~Hidraw();
};

#endif // __HID_CPP__
