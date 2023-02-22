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
#ifndef __ERRORS_HPP__
#define __ERRORS_HPP__

#include <string>
#include <errno.h>


namespace Err
{
    enum
    {
        // Success
        OK = 0,

        // Generic
        UNKNOWN,
        EMPTY,
        UNSUPPORTED,
        INVALID_PARAMETER,
        INVALID_FORMAT,
        OUT_OF_RANGE,
        OUT_OF_MEMORY,
        ENVIRONMENT_ERROR,
        UNHANDLED_TYPE,
        UNTERMINATED,

        // Files
        FILE_NOT_FOUND,
        DIR_NOT_FOUND,

        // TODO: Clean up
        READ_FAILED,
        WRITE_FAILED,
        COPY_FAILED,
        CANNOT_OPEN,
        NO_PERMISSION,      
        ALREADY_OPEN,
        NOT_OPEN,
        INIT_FAILED,
        NOT_INITIALIZED,
        NOT_FOUND,
        NO_DEVICE,
        DEVICE_LOST,
        CANNOT_CREATE,
        CANNOT_SET_PROP,
        WRONG_SIZE,
    };

    std::string GetErrnoString( int e );
}


#endif // __ERRORS_HPP__
