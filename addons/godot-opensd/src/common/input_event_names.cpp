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
#include "input_event_names.hpp"
#include "log.hpp"
#include "string_funcs.hpp"


int EvName::GetEvType( std::string codeName )
{
    if (codeName.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Empty string paramater. " );
        return -1;
    }
    
    // Derive the event type from the prefix
    codeName = Str::Uppercase( codeName.substr( 0, 4 ) );
    if ((codeName == "KEY_") || (codeName == "BTN_"))
        return EV_KEY;
    else
        if (codeName == "ABS_")
            return EV_ABS;
        else
            if (codeName == "REL_")
                return EV_REL;

    gLog.Write( Log::DEBUG, FUNC_NAME, "Unknown or unsupported event type. " );
    return -1;
}



int EvName::GetEvCode( std::string codeName )
{
    int             result;
    bool            has_offset = false;
    int             code_val;
    int             offset = 0;
    std::string     pfx;
    std::string     sfx;
    
       
    result = EvName::GetEvType( codeName );
    if (result < 0)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get event type. " );
        return -1;
    }
    
    // Check for offset value (i.e. ABS_X+13)
    for (auto& c : codeName)
    {
        if (c == '+')
            has_offset = true;
        else
            if (has_offset)
                sfx += c;
            else
                pfx += c;
    }

    if ((has_offset) && (sfx.size()))
    {
        try 
        { 
            offset = std::stoi( sfx ); 
        } 
        catch (...)
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Invalid event code offset value." );
            return -1;
        }
    }

    // Switch on detected event type
    switch (result)
    {
        case EV_KEY:
            // Make sure key name exists in map
            if (!KEY_MAP.count( codeName ))
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "Invalid or unknown KEY name specified." );
                return -1;
            }
            
            // Add offset and check max event code
            code_val = KEY_MAP.at( codeName ) + offset;
            if (code_val >= KEY_MAX)
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "KEY event code out of range." );
                return -1;
            }
            return code_val;
        break;
        
        case EV_ABS:
            // Make sure absolute axis name exists in map
            if (!ABS_MAP.count( codeName ))
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "Invalid or unknown ABS name specified." );
                return -1;
            }
            
            // Add offset and check max event code
            code_val = ABS_MAP.at( codeName ) + offset;
            if (code_val >= ABS_MAX)
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "ABS event code out of range." );
                return -1;
            }
            return code_val;
        break;
        
        case EV_REL:
            // Make sure relative axis name exists in map
            if (!REL_MAP.count( codeName ))
                return -1;
            
            // Add offset and check max event code
            code_val = REL_MAP.at( codeName ) + offset;
            if (code_val >= REL_MAX)
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "REL event code out of range." );
                return -1;
            }
            return code_val;
        break;
        
        default:
            gLog.Write( Log::DEBUG, FUNC_NAME, "Invalid type specified." );
            return -1;
        break;
    }
}
