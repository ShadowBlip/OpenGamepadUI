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
#include "log.hpp"
#include <iostream>
#include <ctime>


// Global logger object
Log gLog;



Log::Log()
{
    mFilter = Log::WARN;
    mMethod = Log::STDOUT;
}



Log::~Log()
{
    // Nothing to close
}



void Log::SetOutputMethod( Log::Method method )
{
    if (method < Log::NONE)
        method = Log::NONE;

    if (method > Log::SYSLOG)
        method = Log::SYSLOG;

    mMethod = method;
}



void Log::SetFilterLevel( Log::Level logLevel )
{
    if (logLevel < Log::VERB)
        logLevel = Log::VERB;

    if (logLevel > Log::ERROR)
        logLevel = Log::VERB;

    mFilter = logLevel;
}



void Log::Write( Log::Level logLevel, std::string_view funcName, std::string msg )
{
    std::string     pfx;

    if (mMethod == Log::NONE)
        return;
        
    if (!msg.length())
        return;

    if (logLevel < mFilter)
        return;
        
    if (logLevel < Log::VERB)
        logLevel = Log::VERB;
    if (logLevel > Log::ERROR)
        logLevel = Log::ERROR;
    
    // A bit hacky, but it works and keeps consteval macro simple
    if (!funcName.empty())
        msg = "(): " + msg;

    switch (logLevel)
    {
        case Log::DEBUG:
            pfx = "DEBUG";
        break;

        case Log::INFO:   
            pfx = "INFO"; 
        break;

        case Log::WARN:
            pfx = "WARN"; 
        break;

        case Log::ERROR:
            pfx = "ERROR"; 
        break;
        
        case Log::VERB:   
        default:
            pfx = "VERB"; 
        break;
    }

    switch (mMethod)
    {
        case Log::STDOUT:
        {
            std::lock_guard<std::mutex> write_lock( mMutex );
            std::cout << "[" << pfx << "]  " << funcName << msg << "\n";
        }
        break;

        case Log::STDERR:
        {
            std::lock_guard<std::mutex> write_lock( mMutex );
            std::cerr << "[" << pfx << "]  " << funcName << msg << "\n";
        }
        break;

        case Log::SYSLOG:
            // TODO
        break;

        default:
            return;
        break;
    }

    return;
}

