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
#ifndef __LOG_HPP__
#define __LOG_HPP__

#include <string>
#include <mutex>


// Trim unwanted stuff off of __PRETTY_FUNCTION__ at compile time 
consteval std::string_view ShortenPrettyFunction( const char* prettyString )
{
    std::string_view    sv(prettyString);
    
    unsigned int    end     = sv.rfind( "(" );
    unsigned int    start   = sv.rfind( " ", end ) + 1;
    unsigned int    len     = end - start;
    
    return sv.substr( start, len );
}

// Macro to get clean function/method names for Log::Write
#define FUNC_NAME ShortenPrettyFunction(__PRETTY_FUNCTION__)


// Simple thread-safe global logger
class Log
{
private:
    int             mFilter;
    int             mMethod;
    std::mutex      mMutex;

public:
    enum            Level { VERB, DEBUG, INFO, WARN, ERROR };
    enum            Method { NONE, STDOUT, STDERR, SYSLOG };    

    void            SetFilterLevel( Log::Level logLevel );
    void            SetOutputMethod( Log::Method  method );
    void            Write( Log::Level logLevel, std::string_view funcName, std::string msg );
    void            Write( Log::Level logLevel, std::string msg ) { Write( logLevel, "", msg ); }

    Log();
    ~Log();
};

// Global instance
extern Log     gLog;


#endif // __LOG_HPP__
