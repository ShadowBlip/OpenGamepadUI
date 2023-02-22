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
#include "config.hpp"
#include "../common/log.hpp"


int Config::Load( std::filesystem::path configFile )
{
    int             result;
    Ini::ValVec     val;
    
    // Load user config file
    result = mIni.LoadFile( configFile );
    if (result != Err::OK)
    {
        std::string     temp_str;
        switch (result)
        {
            case Err::FILE_NOT_FOUND:
                temp_str = "File not found.";
            break;
            
            case Err::CANNOT_OPEN:
                temp_str = "Cannot open file.  Check your permissions.";
            break;
            
            case Err::INVALID_FORMAT:
                temp_str = "File has errors.";
            break;
            
            default:
                temp_str = "An unhandled error occurred.";
                result = Err::UNKNOWN;
            break;
        }
        gLog.Write( Log::ERROR, "Failed to load config file '" + configFile.string() + "': " + temp_str );
        return result;
    }
    
    // Check for correct file
    if (!mIni.DoesSectionExist( "Daemon" ))
    {
        gLog.Write( Log::ERROR, "Config file is missing '[Daemon]' section." );
        return Err::INVALID_FORMAT;
    }
    
    // Read values
    val = mIni.GetVal( "Daemon", "Profile" );
    if (!val.Count())
    {
        gLog.Write( Log::ERROR, "Config file is missing 'Profile' key." );
        return Err::INVALID_FORMAT;
    }
    mProfileName = val.FullString();
    
    val = mIni.GetVal( "Daemon", "AllowClients" );
    if (!val.Count())
    {
        gLog.Write( Log::WARN, "Config file is missing 'AllowClients' key.  Using default value 'false'." );
        mAllowClients = false;
    }
    else
        mAllowClients = val.Bool();
    
    val = mIni.GetVal( "Daemon", "Port" );
    if (!val.Count())
    {
        gLog.Write( Log::WARN, "Config file is missing 'Port' key.  Using default value of '4040'." );
        mPort = 4040;
    }
    else
        mPort = val.Int();

    
    return Err::OK;
}



int Config::Save( std::filesystem::path configFile )
{
    int             result;
    
    // Update keys
    mIni.SetStringVal( "Daemon", "Profile", mProfileName );
    mIni.SetBoolVal( "Daemon", "AllowClients", mAllowClients );
    mIni.SetIntVal( "Daemon", "Port", mPort );
    
    // Write file
    result = mIni.SaveFile( configFile );
    if (result != Err::OK)
    {
        std::string     temp_str;
        
        switch (result)
        {
            case Err::EMPTY:
                temp_str = "Nothing to write.";
            break;
            
            case Err::CANNOT_CREATE:
                temp_str = "Cannot create file.  Check your permissions and make sure OpenSD config directory exists.";
            break;
            
            case Err::CANNOT_OPEN:
                temp_str = "Cannot open file for writing.  Check your permissions.";
            break;
            
            case Err::WRITE_FAILED:
                temp_str = "Cannot write file.  Check your permissions and make sure there is available space on the storage device.";
            break;
            
            default:
                result = Err::UNKNOWN;
                temp_str = "An unhandled error occurred.";
            break;
        }
        gLog.Write( Log::ERROR, "Failed to save config file '" + configFile.string() + "': " + temp_str );
        return result;
    }
    
    return Err::OK;
}



Config::Config()
{
    mAllowClients   = false;
    mPort           = 0;
}



Config::~Config()
{
    mAllowClients   = false;
    mPort           = 0;
}