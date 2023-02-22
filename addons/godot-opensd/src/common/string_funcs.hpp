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
#ifndef __STRING_FUNCS_HPP__
#define __STRING_FUNCS_HPP__

#include <string>
#include <cstdint>


//  Some string helper functions
namespace Str
{
    // Convert 16-bit interger value into a hex string
    std::string     Uint16ToHex( uint16_t value );
    
    // Return uppercase copy of string
    std::string     Uppercase( std::string s );
    
    // return lowercase copy of string
    std::string     Lowercase( std::string s );
    
    // Case insensive string comparison
    bool            CIComp( std::string s1, std::string s2 );
}


#endif // __STRING_FUNCS_HPP__
