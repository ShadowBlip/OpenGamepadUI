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
#include "xdg.hpp"
#include "log.hpp"
// C++
#include <cstdlib>


std::filesystem::path Xdg::UserHome()
{
    std::string         dir;

    if (getenv( "HOME" ))
        dir = getenv( "HOME" );
    else
        return "";
    
    if (dir == "/")
        dir = "";
        
    if ((dir == "/root") || (dir == "/root/"))
        gLog.Write( Log::WARN, "It appears that OpenSD is being run as root!  DO NOT RUN OPENSD AS ROOT!  YOU HAVE BEEN WARNED!" );
    
    return dir;
}



std::filesystem::path Xdg::ConfigHome()
{
    std::string         dir;
    
    if (getenv( "XDG_CONFIG_HOME" ))
        dir = getenv( "XDG_CONFIG_HOME" );
    
    if (!dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_CONFIG_HOME is set to '" + dir + "'" );
        return dir + "/";
    }
    
    dir = UserHome();
    if (dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "$HOME is not set." );
        return "";
    }
    
    dir += "/.config/";
    gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_CONFIG_HOME is not set, using default '" + dir + "'");
    
    return dir;
}



std::filesystem::path Xdg::CacheHome()
{
    std::string     dir;
    
    if (getenv( "XDG_CACHE_HOME" ))
        dir = getenv( "XDG_CACHE_HOME" );
    
    if (!dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_CACHE_HOME is set to '" + dir + "'" );
        return dir + "/";
    }
    
    dir = UserHome();
    if (dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "$HOME is not set." );
        return "";
    }

    dir += "/.cache/";
    gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_CACHE_HOME is not set, using default '" + dir + "'");

    return dir;
}



std::filesystem::path Xdg::DataHome()
{
    std::string     dir;
    
    if (getenv( "XDG_DATA_HOME" ))
        dir = getenv( "XDG_DATA_HOME" );
    
    if (!dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_DATA_HOME is set to '" + dir + "'" );
        return dir + "/";
    }
    
    dir = UserHome();
    if (dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "$HOME is not set." );
        return "";
    }
    
    dir += "/.local/share/";
    gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_DATA_HOME is not set, using default '" + dir + "'");
    
    return dir;
}



std::filesystem::path Xdg::StateHome()
{
    std::string     dir;

    if (getenv( "XDG_STATE_HOME" ))
        dir = getenv( "XDG_STATE_HOME" );
    
    if (!dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_STATE_HOME is set to '" + dir + "'" );
        return dir + "/";
    }
    
    dir = UserHome();
    if (dir.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "$HOME is not set." );
        return "";
    }
    
    dir += "/.local/state/";
    gLog.Write( Log::DEBUG, FUNC_NAME, "XDG_STATE_HOME is not set, using default '" + dir + "'");
    
    return dir;
}



std::filesystem::path Xdg::SysConfigDir()
{
    return "/etc/";
}



std::filesystem::path Xdg::SysDataDir()
{
    std::string     dir = "/usr/local/share/";

    // TODO: Use cmake settings
    
    return dir;
}