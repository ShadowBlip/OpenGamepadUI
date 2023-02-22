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

#include "filter_axes.hpp"
#include <cmath>


void FilterStickCoords( double& rX, double& rY, double deadzone, double scale )
{
    double mag = sqrt( rX * rX + rY * rY );
    double ang = atan2( rY, rX );

    // Check if vector magnitude is inside deadzone
    if (mag < deadzone)
    {
        // Clip low input inside deadzone
        rX = 0;
        rY = 0;
    }
    else
    {
        // Rescale stick outside deadzone
        mag = (mag - deadzone) * scale;
        // Clip magnitude to unit vector
        mag = (mag > 1.0) ? 1.0 : mag;
        // Translate polar coordinates back to cartesian
        rX = mag * cos(ang);
        rY = mag * sin(ang);
    }
}



void FilterPadCoords( double& rX, double& rY, double deadzone, double scale )
{
    double mag = sqrt( rX * rX + rY * rY );
    double ang = atan2( rY, rX );

    // Check if vector magnitude is inside deadzone
    if (mag < deadzone)
    {
        // Clip low input inside deadzone
        rX = 0;
        rY = 0;
    }
    else
    {
        // Rescale stick outside deadzone
        mag = (mag - deadzone) * scale;
        // Translate polar coordinates back to cartesian
        rX = mag * cos(ang);
        rY = mag * sin(ang);
    }
}
