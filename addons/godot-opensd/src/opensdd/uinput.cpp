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
#include "uinput.hpp"
#include "../common/log.hpp"
#include <sys/stat.h>
#include <sys/uio.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <cstring>
#include <cmath>


int Uinput::Device::Open( std::string deviceName )
{
    int                     result;
    struct stat             stat_data;
    std::string             uinput_path;
   
    gLog.Write( Log::DEBUG, FUNC_NAME, "Opening uinput device:  " + deviceName );
    
    // Find uinput path
    gLog.Write( Log::DEBUG, FUNC_NAME, "Searching for uinput path..." );
    for (auto p : UINPUT_PATH_LIST)
    {
        result = stat( p.c_str(), &stat_data );
        if (result >= 0)
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Found uinput path at " + p );
            uinput_path = p;
            break;
        }
    }

    if (uinput_path.length() < 5)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to find a uinput device node." );
        return Err::NOT_FOUND;
    }

    // Check if uinput can be opened
    mFd = open( uinput_path.c_str(), O_RDWR | O_NONBLOCK );
    if (mFd < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "errno: " + Err::GetErrnoString(e) );
        gLog.Write( Log::ERROR, "Failed to open uinput.  Make sure this user has R/W permissions for " + uinput_path );
        mFd = 0;
        return Err::NO_PERMISSION;
    }
    
    mDeviceName = deviceName;

    return Err::OK;
}



void Uinput::Device::Close()
{
    if (IsOpen())
    {
        ioctl( mFd, UI_DEV_DESTROY);
        close( mFd );
        gLog.Write( Log::DEBUG, FUNC_NAME, "Closing uinput device '" + mDeviceName + "'." );
    }

    mFd = 0;
}



bool Uinput::Device::IsOpen()
{
    if (mFd > 0)
        if (fcntl( mFd, F_GETFD) >= 0)
            return true;

    return false;
}



int Uinput::Device::EnableKey( uint16_t code )
{
    int             result;
    
    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "uinput device is not open for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable key (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::NOT_OPEN;
    }
    
    // Make sure key code is within range
    if (code >= KEY_MAX)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Key code out of range for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable key (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::OUT_OF_RANGE;
    }
    
    // Enable key events for this device if not already enabled
    if (mEvBuff.key.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Enabling key events for '" + mDeviceName + "'." );
        result = ioctl( mFd, UI_SET_EVBIT, EV_KEY );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::ERROR, "Failed to enable key events for '" + mDeviceName + "'." );
            return Err::WRITE_FAILED;
        }
    }
    
    // Enable key through uinput
    result = ioctl( mFd, UI_SET_KEYBIT, code );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable key (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::WRITE_FAILED;
    }
    
    // Everything okay, lets add a new key buffer
    EventInfo           evinfo = {};
    evinfo.ev.type      = EV_KEY;
    evinfo.ev.code      = code;
    evinfo.ev.value     = 0;
    evinfo.max          = 1;
    evinfo.min          = 0;
    mEvBuff.key[code]   = evinfo;

    return Err::OK;
}



int Uinput::Device::EnableAbs( uint16_t code, int32_t min, int32_t max, int32_t fuzz, int32_t res )
{
    int                 result;
    uinput_abs_setup    axis_info;
    
    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "uinput device is not open for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable absolute axis (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::NOT_OPEN;
    }
    
    // Make sure abs code is within range
    if (code >= ABS_MAX)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Abs code out of range for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable absolute axis (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::OUT_OF_RANGE;
    }
    
    // Enable abs events for this device if not already enabled
    if (mEvBuff.abs.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Enabling abs events for '" + mDeviceName + "'." );
        result = ioctl( mFd, UI_SET_EVBIT, EV_ABS );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::ERROR, "Failed to enable absolute axis events for '" + mDeviceName + "'." );
            return Err::WRITE_FAILED;
        }
    }
    
    // Define and enable axis through uinput
    axis_info.code                  = code;
    axis_info.absinfo.value         = 0;
    axis_info.absinfo.minimum       = min;
    axis_info.absinfo.maximum       = max;
    axis_info.absinfo.fuzz          = fuzz;
    axis_info.absinfo.flat          = 0;
    axis_info.absinfo.resolution    = res;

    result = ioctl( mFd, UI_ABS_SETUP, &axis_info );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable absolute axis (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::WRITE_FAILED;
    }
    
    // Everything okay, lets add a new event buffer
    EventInfo           evinfo = {};
    evinfo.ev.type      = EV_ABS;
    evinfo.ev.code      = code;
    evinfo.ev.value     = 0;
    evinfo.min          = min;
    evinfo.max          = max;
    mEvBuff.abs[code]   = evinfo;

    return Err::OK;
}



int Uinput::Device::EnableRel( uint16_t code )
{
    int                 result;
    
    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "uinput device is not open for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable relative axis (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::NOT_OPEN;
    }
    
    // Make sure rel code is within range
    if ((code >= ABS_MAX) || (code == REL_RESERVED))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Rel code out of range for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable relative axis (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::OUT_OF_RANGE;
    }
    
    // Enable rel events for this device if not already enabled
    if (mEvBuff.rel.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Enabling rel events for '" + mDeviceName + "'." );
        result = ioctl( mFd, UI_SET_EVBIT, EV_REL );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::ERROR, "Failed to enable relative axis events for '" + mDeviceName + "'." );
            return Err::WRITE_FAILED;
        }
    }
    
    // Enable relative axis through uinput
    result = ioctl( mFd, UI_SET_RELBIT, code );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable relative axis (" + std::to_string(code) + ") for '" + mDeviceName + "'." );
        return Err::WRITE_FAILED;
    }
    
    // Everything okay, lets add a new event buffer
    EventInfo           evinfo = {};
    evinfo.ev.type      = EV_REL;
    evinfo.ev.code      = code;
    evinfo.ev.value     = 0;
    evinfo.max          = 0;
    evinfo.min          = 0;
    mEvBuff.rel[code]   = evinfo;

    return Err::OK;
}



int Uinput::Device::EnableFF()
{
    int             result;
    
    // Enable FF for device
    gLog.Write( Log::DEBUG, FUNC_NAME, "Enabling force feedback events for '" + mDeviceName + "'." );
    result = ioctl( mFd, UI_SET_EVBIT, EV_FF );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to enable force feedback for '" + mDeviceName + "'." );
        return Err::WRITE_FAILED;
    }
    
    // Enable Event types
    result = ioctl( mFd, UI_SET_FFBIT, FF_RUMBLE );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_RUMBLE effect for '" + mDeviceName + "'." );
    }
    
    // TODO: Enable full FF support
    /*
    result = ioctl( mFd, UI_SET_FFBIT, FF_CONSTANT );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_CONSTANT effect for '" + mDeviceName + "'." );
    }
    
    result = ioctl( mFd, UI_SET_FFBIT, FF_PERIODIC );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_PERIODIC effect for '" + mDeviceName + "'." );
    }
    else
    {
        result = ioctl( mFd, UI_SET_FFBIT, FF_SQUARE );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_SQUARE effect for '" + mDeviceName + "'." );
        }

        result = ioctl( mFd, UI_SET_FFBIT, FF_TRIANGLE );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_TRIANGLE effect for '" + mDeviceName + "'." );
        }

        result = ioctl( mFd, UI_SET_FFBIT, FF_SINE );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_SINE effect for '" + mDeviceName + "'." );
        }
        
        result = ioctl( mFd, UI_SET_FFBIT, FF_SAW_UP );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_SAW_UP effect for '" + mDeviceName + "'." );
        }
        
        result = ioctl( mFd, UI_SET_FFBIT, FF_SAW_DOWN );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_SAW_DOWN effect for '" + mDeviceName + "'." );
        }

        result = ioctl( mFd, UI_SET_FFBIT, FF_CUSTOM );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
            gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_CUSTOM effect for '" + mDeviceName + "'." );
        }
    }
    
    result = ioctl( mFd, UI_SET_FFBIT, FF_RAMP );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_RAMP effect for '" + mDeviceName + "'." );
    }

    result = ioctl( mFd, UI_SET_FFBIT, FF_SPRING );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_SPRING effect for '" + mDeviceName + "'." );
    }

    result = ioctl( mFd, UI_SET_FFBIT, FF_FRICTION );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_SPRING effect for '" + mDeviceName + "'." );
    }

    result = ioctl( mFd, UI_SET_FFBIT, FF_GAIN );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl error: " + Err::GetErrnoString(e) + " for '" + mDeviceName + "'." );
        gLog.Write( Log::WARN, FUNC_NAME, "Failed to enable FF_GAIN effect for '" + mDeviceName + "'." );
    }
    */

    return Err::OK;
}



int Uinput::Device::Create( std::string deviceName, uint16_t vid, uint16_t pid, uint16_t ver )
{
    int                         result;
    struct uinput_setup         dev_info = {};

    if (deviceName.empty())
        deviceName = "Unknown device";

    gLog.Write( Log::DEBUG, FUNC_NAME, "Creating uinput device '" + mDeviceName + "'." );
        
    strncpy( dev_info.name, deviceName.c_str(), deviceName.length() );
    dev_info.id.bustype     = BUS_VIRTUAL;
    dev_info.id.vendor      = vid;
    dev_info.id.product     = pid;
    dev_info.id.version     = ver;
    if (mFFEnabled)
        dev_info.ff_effects_max = 16;
    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "uinput device is not open for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to set uinput device information for '" + mDeviceName + "'." );
        return Err::NOT_OPEN;
    }

    // Upload device info block
    result = ioctl( mFd, UI_DEV_SETUP, &dev_info );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "UI_DEV_SETUP ioctl error (" + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        gLog.Write( Log::ERROR, "Failed to set uinput device information." );
        Close();
        return Err::WRITE_FAILED;
    }

    // Create the uinput device
    result = ioctl( mFd, UI_DEV_CREATE );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "UI_DEV_CREATE ioctl error (" + std::to_string(e) + "): " + Err::GetErrnoString(e) );
        gLog.Write( Log::ERROR, "Failed to create uinput device." );
        Close();
        return Err::WRITE_FAILED;
    }

    mDeviceName = deviceName;

    gLog.Write( Log::DEBUG, FUNC_NAME, "Successfully created uinput device '" + mDeviceName + "'." );

    return Err::OK;
}



int Uinput::Device::UpdateKey( uint16_t code, bool value )
{
    if (!mEvBuff.key.count(code))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Key code (" + std::to_string(code) + ") is not mapped to buffer. " );
        gLog.Write( Log::WARN, "Attemped to update unmapped key for '" + mDeviceName + "'." );
        return Err::NOT_FOUND;
    }
    
    // Values are already zeroed after being written and in the event of multiple
    // buttons being bound to the same key event, we use OR logic
    if (!value)
        return Err::OK;
    else
        mEvBuff.key[code].ev.value = 1;
    
    return Err::OK;
}



int Uinput::Device::UpdateAbs( uint16_t code, double value )
{
    if (!mEvBuff.abs.count(code))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Abs code (" + std::to_string(code) + ") is not mapped to buffer. " );
        gLog.Write( Log::WARN, "Attemped to update unmapped absolute axis for '" + mDeviceName + "'." );
        return Err::NOT_FOUND;
    }
    
    // Values are already zeroed after being written and in the event of multiple
    // axes being bound to the same abs event, we use the first non-zero value 
    // written to the buffer.  This is implemented for split axis mapping.
    if ((!value) || (mEvBuff.key[code].ev.value != 0))
        return Err::OK;
    
    // Clamp float
    if (value < -1.0)
        value = -1.0;
    
    if (value > 1.0)
        value = 1.0;
        
    // Multiply normalized value to what was defined in uinput
    if (value > 0)
        mEvBuff.abs[code].ev.value = fabs(value) * mEvBuff.abs[code].max;
    else
        mEvBuff.abs[code].ev.value = fabs(value) * mEvBuff.abs[code].min;
    
    return Err::OK;
}



int Uinput::Device::UpdateRel( uint16_t code, int32_t value )
{
    if (!mEvBuff.rel.count(code))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Rel code (" + std::to_string(code) + ") is not mapped to buffer. " );
        gLog.Write( Log::WARN, "Attemped to update unmapped relative axis for '" + mDeviceName + "'." );
        return Err::NOT_FOUND;
    }
    
    // Values are already zeroed after being written and in the event of multiple
    // axes being bound to the same rel event, use use the first non-zero value
    // that gets sent to the buffer
    if (!value)
        return Err::OK;
    
    if (mEvBuff.rel[code].ev.value)
        return Err::OK;
        
    mEvBuff.rel[code].ev.value = value;
    
    // TODO:  There's no way this will work well
    
    return Err::OK;
}



int Uinput::Device::Configure( const Uinput::DeviceConfig& rCfg )
{
    int                         result;
    unsigned int                error_count = 0;

    gLog.Write( Log::VERB, "Configuring uinput device for '" + mDeviceName + "'." );

    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "uinput device is not open." );
        gLog.Write( Log::ERROR, "Failed to configure uinput device for '" + mDeviceName + "': Device is not open." );
        return Err::NOT_OPEN;
    }
    
    // Enable each key / button event
    if (rCfg.features.enable_keys)
    {
        for (auto&& i : rCfg.key_list)
        {
            if (EnableKey( i ) != Err::OK)
                ++error_count;
        }
    }
    
    // Enable each absolute axis
    if (rCfg.features.enable_abs)
    {
        for (auto&& i : rCfg.abs_list)
        {
            if (EnableAbs( i.code, i.min, i.max, i.fuzz, i.res ) != Err::OK)
                ++error_count;
        }
    }
    
    // Enable each relative axis
    if (rCfg.features.enable_rel)
    {
        for (auto&& i : rCfg.rel_list)
        {
            if (EnableRel( i ) != Err::OK)
                ++error_count;
        }
    }
    
    // Enable force feedback
    if (rCfg.features.enable_ff)
    {
        result = EnableFF();
        if (result == Err::OK)
            mFFEnabled = true;
    }
        
    result = Create( rCfg.deviceinfo.name, rCfg.deviceinfo.vid, rCfg.deviceinfo.pid, rCfg.deviceinfo.ver );
    if (result != Err::OK)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to create device" );
        gLog.Write( Log::ERROR, "Failed to configure uinput device for '" + mDeviceName + "': Failed to create device." );
        return Err::CANNOT_CREATE;
    }
    
    if (error_count)
    {
        gLog.Write( Log::WARN, "Uinput device configured successfully for '" + mDeviceName + "', but with errors." );
        if (rCfg.features.enable_keys)
            gLog.Write( Log::INFO, "    " + std::to_string(mEvBuff.key.size()) + "/" + std::to_string(rCfg.key_list.size()) + " keys/buttons configured." );

        if (rCfg.features.enable_abs)
            gLog.Write( Log::INFO, "    " + std::to_string(mEvBuff.abs.size()) + "/" + std::to_string(rCfg.abs_list.size()) + " absolute axes configured." );

        if (rCfg.features.enable_rel)
            gLog.Write( Log::INFO, "    " + std::to_string(mEvBuff.rel.size()) + "/" + std::to_string(rCfg.rel_list.size()) + " relative axes configured." );
    }
    else
    {
        gLog.Write( Log::INFO, "Uinput device configured successfully for '" + mDeviceName + "'." );
        if (rCfg.features.enable_keys)
            gLog.Write( Log::INFO, "    " + std::to_string(mEvBuff.key.size()) + " keys/buttons configured." );
            
        if (rCfg.features.enable_abs)
            gLog.Write( Log::INFO, "    " + std::to_string(mEvBuff.abs.size()) + " absolute axes configured." );
            
        if (rCfg.features.enable_rel)
            gLog.Write( Log::INFO, "    " + std::to_string(mEvBuff.rel.size()) + " relative axes configured." );
    }

    return Err::OK;
}



int Uinput::Device::Flush()
{
    int                         result;
    std::vector<iovec>          iov;
    iovec                       iov_data;
    

    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open for '" + mDeviceName + "'." );
        gLog.Write( Log::ERROR, "Failed to write uinput: Device not open." );
        return Err::NOT_OPEN;
    }

    iov_data.iov_len = sizeof(input_event);

    // loop through lists of events and add them to an iovector to write out
    for (auto&& i : mEvBuff.key )
    {
        iov_data.iov_base = &i.second.ev;
        iov.push_back(iov_data);
    }
    for (auto&& i : mEvBuff.abs )
    {
        iov_data.iov_base = &i.second.ev;
        iov.push_back(iov_data);
    }
    for (auto&& i : mEvBuff.rel )
    {
        iov_data.iov_base = &i.second.ev;
        iov.push_back(iov_data);
    }

    // Sync events
    input_event     ev = {};
    ev.type = EV_SYN;
    ev.code = SYN_REPORT;
    iov_data.iov_base = &ev;
    iov.push_back(iov_data);

    // Write out event vector
    result = writev( mFd, iov.data(), iov.size() );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "write error: " + Err::GetErrnoString(e) );
        gLog.Write( Log::ERROR, "Failed to write uinput: I/O error for '" +mDeviceName + "'." );
        return Err::WRITE_FAILED;
    }

    // Clear written values to flag them for updates
    for (auto&& i : mEvBuff.key )
    {
        i.second.ev.value = 0;
    }
    for (auto&& i : mEvBuff.abs )
    {
        i.second.ev.value = 0;
    }
    for (auto&& i : mEvBuff.rel )
    {
        i.second.ev.value = 0;
    }
    
    return Err::OK;
}



int Uinput::Device::Read( input_event& rEvent )
{
    int             result;
    
    rEvent = {};
    
    result = read( mFd, &rEvent, sizeof(rEvent) );
    if (result < 0)
    {
        int e = errno;
        if (e != EAGAIN)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Error reading uinput device '" + mDeviceName + "': " + Err::GetErrnoString(e) );
        return Err::READ_FAILED;
    }
    
    if (result == sizeof(rEvent))
        return Err::OK;
    
    return Err::READ_FAILED;
}



bool Uinput::Device::IsFFEnabled()
{
    return mFFEnabled;
}



int Uinput::Device::GetFFEffect( int32_t id, uinput_ff_upload& rData )
{
    uinput_ff_upload    ff_data = {};
    int                 result;

    ff_data.request_id = id;

    // Signal start of transfer
    result = ioctl( mFd, UI_BEGIN_FF_UPLOAD, &ff_data );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl UI_BEGIN_FF_UPLOAD failed: " + Err::GetErrnoString(e) );
        return Err::WRITE_FAILED;
    }
    
    // Return a copy of data as a reference parameter
    rData = ff_data;
    
    // Signal end of transfer
    ff_data.retval = 0;
    result = ioctl( mFd, UI_END_FF_UPLOAD, &ff_data );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl UI_END_FF_UPLOAD failed: " + Err::GetErrnoString(e) );
        return Err::WRITE_FAILED;
    }
    
    return Err::OK;
}



int Uinput::Device::EraseFFEffect( int32_t id, uinput_ff_erase& rData )
{
    uinput_ff_erase     ff_data = {};
    int                 result;
    
    ff_data.request_id = id;
    
    // Signal start of transfer
    result = ioctl( mFd, UI_BEGIN_FF_ERASE, &ff_data );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl UI_BEGIN_FF_ERASE failed: " + Err::GetErrnoString(e) );
        return Err::WRITE_FAILED;
    }
    
    // Return a copy of data as a reference parameter
    rData = ff_data;
    
    // Signal end of transfer
    ff_data.retval = 0;
    result = ioctl( mFd, UI_END_FF_ERASE, &ff_data );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "ioctl UI_END_FF_ERASE failed: " + Err::GetErrnoString(e) );
        return Err::WRITE_FAILED;
    }

    return Err::OK;
}



Uinput::Device::Device( const Uinput::DeviceConfig& rCfg )
{
    int     result;
    
    mFd = 0;
    mDeviceName = rCfg.deviceinfo.name;
    mFFEnabled = false;
    
    result = Open( mDeviceName );
    if (result != Err::OK)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to open uinput for r/w." );
        gLog.Write( Log::ERROR, "Failed to create uinput object for '" + mDeviceName + "'." );
        throw -1;
    }
    
    result = Configure( rCfg );
    if (result != Err::OK)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to configure uinput device." );
        gLog.Write( Log::ERROR, "Failed to create uinput object for '" + mDeviceName + "'." );
        throw -1;
    }
}



Uinput::Device::~Device()
{
    Close();
}





