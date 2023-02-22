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
#ifndef __PROFILE_INI_HPP__
#define __PROFILE_INI_HPP__

#include "drivers/gamepad/profile.hpp"
#include "../common/ini.hpp"
#include "../common/errors.hpp"
// C++
#include <filesystem>


// Class for loading gamepad profiles
class ProfileIni
{
private:
    Drivers::Gamepad::Profile   mProf;
    Ini::IniFile                mIni;

    // Loading helper methods
    void                        AddKeyEvent( Drivers::Gamepad::BindType bindType, uint16_t code );
    void                        AddAbsEvent( Drivers::Gamepad::BindType bindType, uint16_t code, int32_t min, int32_t max, int32_t fuzz = 0, int32_t res = 0 );
    void                        AddRelEvent( Drivers::Gamepad::BindType bindType, uint16_t code );
    void                        GetFeatEnable( std::string key, bool& rValue );
    void                        GetDeviceInfo( std::string key, uint16_t& rVid, uint16_t& rPid, uint16_t& rVer, std::string& rName );
    void                        GetDeadzone( std::string key, double& rValue );
    void                        GetAxisRange( std::string section, std::string key, int32_t& rMin, int32_t& rMax, int32_t& rFuzz, int32_t& rRes );
    void                        GetEventBinding( std::string key, Drivers::Gamepad::Binding& rBind );
    void                        GetCommandBinding( std::string key, Drivers::Gamepad::Binding& rBind );
    void                        GetProfileBinding( std::string key, Drivers::Gamepad::Binding& rBind );
    void                        GetBinding( std::string key, Drivers::Gamepad::Binding& rBind );
    
public:
    int                         Load( std::filesystem::path filePath, Drivers::Gamepad::Profile& rProf );
    
    ProfileIni();
    ~ProfileIni();
};


#endif // __PROFILE_INI_HPP__
