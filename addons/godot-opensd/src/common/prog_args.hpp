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
#ifndef __PROGARGS_HPP__
#define __PROGARGS_HPP__

#include <vector>
#include <string>


class ProgArgs
{
private:
    std::vector<std::string>    mArgList;
    int                         mErrorCount;
    
public:
    int                         HasOpt( std::string shortOpt, std::string longOpt );
    std::string                 GetOptParam( std::string shortOpt, std::string longOpt );
    int                         GetErrorCount();
    
    ProgArgs( std::vector<std::string> argList );
    ~ProgArgs();
};


#endif // __PROGARGS_HPP__
