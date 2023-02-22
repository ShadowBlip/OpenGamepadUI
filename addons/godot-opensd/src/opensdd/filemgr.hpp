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
#ifndef __FILEMGR_HPP__
#define __FILEMGR_HPP__

#include "../common/errors.hpp"
#include <filesystem>
#include <vector>
#include <string>


class FileMgr
{
private:
    std::filesystem::path       mDataDir;
    std::filesystem::path       mConfigDir;
    std::filesystem::path       mProfileDir;
    bool                        mIsConfigDirWritable;
    bool                        mIsProfileDirWritable;
    
    bool                        IsInstalled();
    bool                        IsLocalBuild();
    bool                        HasUserHome();
    bool                        HasSystemConfig();
    int                         CreateUserConfigDir();
    int                         CopyUserConfigFile();
    int                         CreateUserProfileDir();
    int                         CopyUserProfileFiles();
    
public:
    int                         Init();
    
    std::filesystem::path       GetConfigFilePath();
    std::vector<std::string>    GetProfileList();
    std::filesystem::path       GetProfileFilePath( std::string fileName );
};


#endif // __FILEMGR_HPP__
