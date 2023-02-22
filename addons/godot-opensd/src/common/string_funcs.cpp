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
#include "string_funcs.hpp"
#include <sstream>
#include <ios>
#include <iomanip>


std::string Str::Uint16ToHex( uint16_t value )
{
    std::stringstream ss;
    
    ss << std::uppercase << std::setfill ('0') << std::setw( sizeof(value) * 2 ) << std::hex << value;
    
    return ss.str();
}



std::string Str::Uppercase( std::string s )
{
    for (auto& c : s)
        c = std::toupper(c);

    return s;
}



std::string Str::Lowercase( std::string s )
{
    for (auto& c : s)
        c = std::tolower(c);
        
    return s;
}



bool Str::CIComp( std::string s1, std::string s2 )
{
    for (auto& c : s1)
        c = std::tolower(c);

    for (auto& c : s2)
        c = std::tolower(c);

    return (s1 == s2);
}