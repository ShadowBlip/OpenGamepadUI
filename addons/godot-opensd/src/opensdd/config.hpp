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
#ifndef __CONFIG_HPP__
#define __CONFIG_HPP__

#include "../common/ini.hpp"
#include "../common/errors.hpp"
#include <cstdint>
#include <string>
#include <filesystem>


class Config
{
private:
    Ini::IniFile        mIni;

public:
    bool                mAllowClients;
    uint16_t            mPort;
    std::string         mProfileName;

    int                 Load( std::filesystem::path configFile );
    int                 Save( std::filesystem::path configFile );
    
    Config();
    ~Config();
};


#endif // __CONFIG_HPP__