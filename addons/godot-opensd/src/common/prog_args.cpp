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
#include "prog_args.hpp"
#include "../common/log.hpp"


int ProgArgs::HasOpt( std::string shortOpt, std::string longOpt )
{
    unsigned int    pos = 0;
    int             count = 0;
    bool            terminated = false;


    // Return 0 if there are no program arguments
    if (mArgList.size() < 2)
        return 0;

    // Return 0 if no short or long options specified
    if ((shortOpt.empty()) && (longOpt.empty()))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "No options specified." );
        ++mErrorCount;
        return 0;
    }

    // Add preceeding "-" to short option
    if (!shortOpt.empty())
        shortOpt = "-" + shortOpt;

    // Add preceeding "--" to long option
    if (!longOpt.empty())
        longOpt = "--" + longOpt;

    // Loop through arg list and look for option
    for (unsigned int i = 1; i < mArgList.size(); ++i)
    {
        if (!terminated)
        {
            if (mArgList.at(i) == "--")
                terminated = true;
            else
            {
                if (!shortOpt.empty())
                    if (mArgList.at(i) == shortOpt)
                    {
                        if (count == 0)
                            pos = i;
                        ++count;
                    }

                if (!longOpt.empty())
                    if (mArgList.at(i) == longOpt)
                    {
                        if (count == 0)
                            pos = i;
                        ++count;
                    }
            }
        }
    }

    // No matches
    if (count == 0)
        return 0;

    // Multiple matches returns error
    if (count > 1)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Multiple options definitions." );
        ++mErrorCount;
        return 0;
    }

    // If theres only 1 match, return the position
    return pos;
}



std::string ProgArgs::GetOptParam( std::string shortOpt, std::string longOpt )
{
    int             result;
    unsigned int    pos;


    result = HasOpt( shortOpt, longOpt );
    if (result < 1)
        return "";

    pos = result + 1;

    // No option after argument
    if (pos >= mArgList.size())
        return "";

    // Just to be safe
    if (mArgList.at(pos).empty())
        return "";

    // Check to see if next argument is an option
    if (mArgList.at(pos).at(0) == '-')
        return "";

    // Return non-option argument following specified option
    return mArgList.at(pos);
}



int ProgArgs::GetErrorCount()
{
    return mErrorCount;
}



ProgArgs::ProgArgs( std::vector<std::string> argList )
{
    mArgList = argList;
    mErrorCount = 0;
}



ProgArgs::~ProgArgs()
{
    mArgList.clear();
}