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
#include "driver.hpp"
#include "compat.hpp"
#include "filter_axes.hpp"
#include "../../../common/log.hpp"
#include "../../../common/string_funcs.hpp"
#include "../../runner.hpp"
// Linux
#include <unistd.h>
// C++
#include <bit>
#include <bitset>
#include <cmath>
#include <iostream>
#include <chrono>


int Drivers::Gamepad::Driver::OpenHid()
{
    int                 result;
    std::string         path;
    

    // Loop throught known gamepad device list and break on first one found
    for (auto&& i : KNOWN_DEVICES)
    {
        path = mHid.FindDevNode( i.vid, i.pid, i.ifacenum );
        if (!path.empty())
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Found hidraw device on '" + path + "'." );
            result = mHid.Open( path );
            if (result != Err::OK)
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "Error opening hidraw device on '" + path + "'." );
                gLog.Write( Log::ERROR, "Failed to open gamepad hidraw device." );
                return Err::CANNOT_OPEN;
            }
            else
            {
                gLog.Write( Log::INFO, "Successfully opened Steam Deck gamepad device." );
                return Err::OK;
            }
        }
    }
    
    gLog.Write( Log::ERROR, "Failed to find any compatible gamepad devices." );
    return Err::NOT_FOUND;
}



int Drivers::Gamepad::Driver::ReadRegister( uint8_t reg, uint16_t& rValue )
{
    // TODO:  Read gamepad registers
    
    // Suppress compiler warnings in the meantime
    ++reg;
    ++rValue;
    
    return Err::OK;
}



int Drivers::Gamepad::Driver::WriteRegister( uint8_t reg, uint16_t value )
{
    std::vector<uint8_t>    buff;
    uint8_t                 length = 3;  // Function writes fixed nuber of bytes
    int                     result;
    
    if (!mHid.IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }

    using namespace v100;
    
    
    // Set the first byte of the report to the write register command
    buff.push_back( ReportType::WRITE_REGISTER );
    // Second byte is the number of bytes for registers and values
    buff.push_back( length );
    // Register is 8 bits
    buff.push_back( reg );
    // Value is 16 bits, with the low bits first
    buff.push_back( value & 0xff );
    buff.push_back( value >> 8 );

    // Fix buffer size at 64 bytes
    buff.resize(64);
    
    result = mHid.Write( buff );
    if (result != Err::OK)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write register on gamepad device. " );
        return Err::WRITE_FAILED;
    }
    
    return Err::OK;
}



int Drivers::Gamepad::Driver::HandleInputReport( const std::vector<uint8_t>& rReport )
{
    // All report descriptors are 64 bytes, so this is just to be safe
    if (rReport.size() != 64)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Invalid input report size was received from gamepad device." );
        return Err::WRONG_SIZE;
    }
    
    // Combine major + minor version numbers (I think)
    uint16_t report_ver = ((uint16_t)rReport.at(0) << 8) + (uint16_t)rReport.at(1);
    
    // Handle report versions
    switch (report_ver)
    {
        case 0x0100:  // Version 1.0 (I think)
            // Handle different report types 
            switch (rReport.at(2))
            {
                // Input data report (I think)
                case 0x09: 
                {
                    // Cast input report vector into packed report struct
                    v100::PackedInputDataReport* pir = (v100::PackedInputDataReport*)rReport.data();
                    // Update internal gamepad state
                    UpdateState( pir );
                    // Translate gamepad state into mapped events
                    Translate();
                    // Write out event buffer to uinput
                    Flush();
                }
                break;
                
                // Unhandled report types
                default:
                    gLog.Write( Log::DEBUG, FUNC_NAME, "An unhandled report type was received from the gamepad device: " + Str::Uint16ToHex(rReport.at(2)) );
                    return Err::UNHANDLED_TYPE;
                break;
            }
        break;
        
        // Unhandled report versions
        default:
            gLog.Write( Log::DEBUG, FUNC_NAME, "An unhandled report version was received from the gamepad device: " + Str::Uint16ToHex(report_ver) );
            return Err::UNSUPPORTED;
        break;
    }
    
    return Err::OK;
}



int Drivers::Gamepad::Driver::ClearRegister( uint8_t reg )
{
    std::vector<uint8_t>    buff;
    uint8_t                 length = 2;  // Function writes fixed nuber of bytes
    int                     result;
    
    if (!mHid.IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    using namespace v100;
    
    
    // Set the first byte of the report to the write register command
    buff.push_back( ReportType::CLEAR_REGISTER );
    // Second byte is the number of bytes for registers and values
    buff.push_back( length );
    // Register is 8 bits
    buff.push_back( reg );
    
    // Fix buffer size at 64 bytes
    buff.resize(64);
    
    result = mHid.Write( buff );
    if (result != Err::OK)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to clear register on gamepad device. " );
        return Err::WRITE_FAILED;
    }
    
    return Err::OK;
}



void Drivers::Gamepad::Driver::DestroyUinputDevs()
{
    if (mpGamepad != nullptr)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Destroying gamepad uinput object." );
        delete mpGamepad;
        mpGamepad = nullptr;
    }
    
    if (mpMotion != nullptr)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Destroying motion uinput object." );
        delete mpMotion;
        mpMotion = nullptr;
    }
    
    if (mpMouse != nullptr)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Destroying mouse uinput object." );
        delete mpMouse;
        mpMouse = nullptr;
    }
}



void Drivers::Gamepad::Driver::UpdateState( v100::PackedInputDataReport* pIr )
{
    using namespace     v100;
    DeviceState         old = mState;
    
    // Buttons
    mState.dpad.up              = pIr->up;
    mState.dpad.down            = pIr->down;
    mState.dpad.left            = pIr->left;
    mState.dpad.right           = pIr->right;
    mState.btn.a                = pIr->a;
    mState.btn.b                = pIr->b;
    mState.btn.x                = pIr->x;
    mState.btn.y                = pIr->y;
    mState.btn.l1               = pIr->l1;
    mState.btn.l2               = pIr->l2;
    mState.btn.l3               = pIr->l3;
    mState.btn.l4               = pIr->l4;
    mState.btn.l5               = pIr->l5;
    mState.btn.r1               = pIr->r1;
    mState.btn.r2               = pIr->r2;
    mState.btn.r3               = pIr->r3;
    mState.btn.r4               = pIr->r4;
    mState.btn.r5               = pIr->r5;
    mState.btn.menu             = pIr->menu;
    mState.btn.options          = pIr->options;
    mState.btn.steam            = pIr->steam;
    mState.btn.quick_access     = pIr->quick_access;
    // Triggers
    mState.trigg.l.z            = (double)pIr->l_trigg * TRIGG_AXIS_MULT;
    mState.trigg.r.z            = (double)pIr->r_trigg * TRIGG_AXIS_MULT;
    // Trigger deadzones
    if (mState.trigg.l.deadzone > 0)
        mState.trigg.l.z = (mState.trigg.l.z < mState.trigg.l.deadzone) ? 0 : (mState.trigg.l.z - mState.trigg.l.deadzone) * mState.trigg.l.scale;
    if (mState.trigg.r.deadzone > 0)
        mState.trigg.r.z = (mState.trigg.r.z < mState.trigg.r.deadzone) ? 0 : (mState.trigg.r.z - mState.trigg.r.deadzone) * mState.trigg.r.scale;
    // Sticks
    mState.stick.l.x            = (double)pIr->l_stick_x * STICK_X_AXIS_MULT;
    mState.stick.l.y            = (double)pIr->l_stick_y * STICK_Y_AXIS_MULT;
    mState.stick.l.touch        = pIr->l_stick_touch;
    mState.stick.l.force        = (((double)pIr->l_stick_force > STICK_FORCE_MAX) ? STICK_FORCE_MAX : (double)pIr->l_stick_force) * STICK_FORCE_MULT;
    mState.stick.r.x            = (double)pIr->r_stick_x * STICK_X_AXIS_MULT;
    mState.stick.r.y            = (double)pIr->r_stick_y * STICK_Y_AXIS_MULT;
    mState.stick.r.touch        = pIr->r_stick_touch;
    mState.stick.r.force        = (((double)pIr->r_stick_force > STICK_FORCE_MAX) ? STICK_FORCE_MAX : (double)pIr->r_stick_force) * STICK_FORCE_MULT;
    // Stick vectorization & deadzones
    if (mState.stick.filtered)
    {
        FilterStickCoords( mState.stick.l.x, mState.stick.l.y, mState.stick.l.deadzone, mState.stick.l.scale );
        FilterStickCoords( mState.stick.r.x, mState.stick.r.y, mState.stick.r.deadzone, mState.stick.r.scale );
    }
    // Pads
    mState.pad.l.x              = (double)pIr->l_pad_x * PAD_X_AXIS_MULT;
    mState.pad.l.y              = (double)pIr->l_pad_y * PAD_Y_AXIS_MULT;
    mState.pad.l.sx             = ((double)pIr->l_pad_x + PAD_X_MAX) * PAD_X_SENS_MULT;
    mState.pad.l.sy             = ((double)pIr->l_pad_y * -1.0 + PAD_Y_MIN) * PAD_Y_SENS_MULT;
    mState.pad.l.touch          = pIr->l_pad_touch;
    mState.pad.l.press          = pIr->l_pad_press;
    mState.pad.l.force          = (double)pIr->l_pad_force * PAD_FORCE_MULT;
    mState.pad.r.x              = (double)pIr->r_pad_x * PAD_X_AXIS_MULT;
    mState.pad.r.y              = (double)pIr->r_pad_y * PAD_Y_AXIS_MULT;
    mState.pad.r.sx             = ((double)pIr->r_pad_x + PAD_X_MAX) * PAD_X_SENS_MULT;
    mState.pad.r.sy             = ((double)pIr->r_pad_y * -1.0 + PAD_Y_MIN) * PAD_Y_SENS_MULT;
    mState.pad.r.touch          = pIr->r_pad_touch;
    mState.pad.r.press          = pIr->r_pad_press;
    mState.pad.r.force          = (double)pIr->r_pad_force * PAD_FORCE_MULT;
    // Left trackpad deltas
    if ((mState.pad.l.touch) && (old.pad.l.touch))
    {
        mState.pad.l.dx = ((mState.pad.l.sx - old.pad.l.sx) + old.pad.l.dx) / 2.0;
        mState.pad.l.dy = ((mState.pad.l.sy - old.pad.l.sy) + old.pad.l.dy) / 2.0;
    }
    else
    {
        // Delta decay / inertia
        // Rate of decay here is fixed to hardware polling interval, which
        // seems to be 250Hz.  If the polling rate changes, the decay will need
        // to reflect that.  For now, 5% feels pretty good.
        mState.pad.l.dx *= 0.95;
        mState.pad.l.dy *= 0.95;
    }
    // Right trackpad deltas
    if ((mState.pad.r.touch) && (old.pad.r.touch))
    {
        mState.pad.r.dx = ((mState.pad.r.sx - old.pad.r.sx) + old.pad.r.dx) / 2.0;
        mState.pad.r.dy = ((mState.pad.r.sy - old.pad.r.sy) + old.pad.r.dy) / 2.0;
    }
    else
    {
        // Delta decay / inertia
        mState.pad.r.dx *= .95;
        mState.pad.r.dy *= .95;
    }
    // Trackpad deadzones
    if (mState.pad.filtered)
    {
        FilterPadCoords( mState.pad.l.x, mState.pad.l.y, mState.pad.l.deadzone, mState.pad.l.scale );
        FilterPadCoords( mState.pad.r.x, mState.pad.r.y, mState.pad.r.deadzone, mState.pad.r.scale );
    }
    // Left trackpad directional "buttons"
    if (mState.pad.l.press)
    {
        // Triangular Quadrants
        mState.pad.l.btn_quad_up        = ((mState.pad.l.y < 0) && (fabs(mState.pad.l.y) > fabs(mState.pad.l.x)));
        mState.pad.l.btn_quad_down      = ((mState.pad.l.y > 0) && (fabs(mState.pad.l.y) > fabs(mState.pad.l.x)));
        mState.pad.l.btn_quad_left      = ((mState.pad.l.x < 0) && (fabs(mState.pad.l.x) > fabs(mState.pad.l.y)));
        mState.pad.l.btn_quad_right     = ((mState.pad.l.x > 0) && (fabs(mState.pad.l.x) > fabs(mState.pad.l.y)));
        // Orthogonal (dpad-like)
        mState.pad.l.btn_orth_up        = (mState.pad.l.y < -0.333);
        mState.pad.l.btn_orth_down      = (mState.pad.l.y > 0.333);
        mState.pad.l.btn_orth_left      = (mState.pad.l.x < -0.333);
        mState.pad.l.btn_orth_right     = (mState.pad.l.x > 0.333);
        // 2x2 Grid
        mState.pad.l.btn_2x2_1          = ((mState.pad.l.x < 0) && (mState.pad.l.y < 0));
        mState.pad.l.btn_2x2_2          = ((mState.pad.l.x > 0) && (mState.pad.l.y < 0));
        mState.pad.l.btn_2x2_3          = ((mState.pad.l.x < 0) && (mState.pad.l.y > 0));
        mState.pad.l.btn_2x2_4          = ((mState.pad.l.x > 0) && (mState.pad.l.y > 0));
        // 3x3 Grid
        int row_3x3 = (mState.pad.l.y < -0.333) ? 0 : (mState.pad.l.y < 0.333) ? 1 : 2;
        int col_3x3 = (mState.pad.l.x < -0.333) ? 0 : (mState.pad.l.x < 0.333) ? 1 : 2;
        mState.pad.l.btn_3x3_1         = ((row_3x3 == 0) && (col_3x3 == 0));
        mState.pad.l.btn_3x3_2         = ((row_3x3 == 0) && (col_3x3 == 1));
        mState.pad.l.btn_3x3_3         = ((row_3x3 == 0) && (col_3x3 == 2));
        mState.pad.l.btn_3x3_4         = ((row_3x3 == 1) && (col_3x3 == 0));
        mState.pad.l.btn_3x3_5         = ((row_3x3 == 1) && (col_3x3 == 1));
        mState.pad.l.btn_3x3_6         = ((row_3x3 == 1) && (col_3x3 == 2));
        mState.pad.l.btn_3x3_7         = ((row_3x3 == 2) && (col_3x3 == 0));
        mState.pad.l.btn_3x3_8         = ((row_3x3 == 2) && (col_3x3 == 1));
        mState.pad.l.btn_3x3_9         = ((row_3x3 == 2) && (col_3x3 == 2));
    }
    else
    {
        mState.pad.l.btn_quad_up = mState.pad.l.btn_quad_down = mState.pad.l.btn_quad_left = mState.pad.l.btn_quad_right = false;
        mState.pad.l.btn_orth_up = mState.pad.l.btn_orth_down = mState.pad.l.btn_orth_left = mState.pad.l.btn_orth_right = false;
        mState.pad.l.btn_2x2_1 = mState.pad.l.btn_2x2_2 = mState.pad.l.btn_2x2_3 = mState.pad.l.btn_2x2_4 = false;
        mState.pad.l.btn_3x3_1 = mState.pad.l.btn_3x3_2 = mState.pad.l.btn_3x3_3 = mState.pad.l.btn_3x3_4 = mState.pad.l.btn_3x3_5 = mState.pad.l.btn_3x3_6 = mState.pad.l.btn_3x3_7 = mState.pad.l.btn_3x3_8 = mState.pad.l.btn_3x3_9 = false;
    }
    // Right Trackpad directional "buttons"
    if (mState.pad.r.press)
    {
        // Triangular Quadrants
        mState.pad.r.btn_quad_up        = ((mState.pad.r.y < 0) && (fabs(mState.pad.r.y) > fabs(mState.pad.r.x)));
        mState.pad.r.btn_quad_down      = ((mState.pad.r.y > 0) && (fabs(mState.pad.r.y) > fabs(mState.pad.r.x)));
        mState.pad.r.btn_quad_left      = ((mState.pad.r.x < 0) && (fabs(mState.pad.r.x) > fabs(mState.pad.r.y)));
        mState.pad.r.btn_quad_right     = ((mState.pad.r.x > 0) && (fabs(mState.pad.r.x) > fabs(mState.pad.r.y)));
        // Orthogonal (dpad-like)
        mState.pad.r.btn_orth_up        = (mState.pad.r.y < -0.333);
        mState.pad.r.btn_orth_down      = (mState.pad.r.y > 0.333);
        mState.pad.r.btn_orth_left      = (mState.pad.r.x < -0.333);
        mState.pad.r.btn_orth_right     = (mState.pad.r.x > 0.333);
        // 2x2 Grid
        mState.pad.r.btn_2x2_1          = ((mState.pad.r.x < 0) && (mState.pad.r.y < 0));
        mState.pad.r.btn_2x2_2          = ((mState.pad.r.x > 0) && (mState.pad.r.y < 0));
        mState.pad.r.btn_2x2_3          = ((mState.pad.r.x < 0) && (mState.pad.r.y > 0));
        mState.pad.r.btn_2x2_4          = ((mState.pad.r.x > 0) && (mState.pad.r.y > 0));
        // 3x3 Grid
        int row_3x3 = (mState.pad.r.y < -0.333) ? 0 : (mState.pad.r.y < 0.333) ? 1 : 2;
        int col_3x3 = (mState.pad.r.x < -0.333) ? 0 : (mState.pad.r.x < 0.333) ? 1 : 2;
        mState.pad.r.btn_3x3_1         = ((row_3x3 == 0) && (col_3x3 == 0));
        mState.pad.r.btn_3x3_2         = ((row_3x3 == 0) && (col_3x3 == 1));
        mState.pad.r.btn_3x3_3         = ((row_3x3 == 0) && (col_3x3 == 2));
        mState.pad.r.btn_3x3_4         = ((row_3x3 == 1) && (col_3x3 == 0));
        mState.pad.r.btn_3x3_5         = ((row_3x3 == 1) && (col_3x3 == 1));
        mState.pad.r.btn_3x3_6         = ((row_3x3 == 1) && (col_3x3 == 2));
        mState.pad.r.btn_3x3_7         = ((row_3x3 == 2) && (col_3x3 == 0));
        mState.pad.r.btn_3x3_8         = ((row_3x3 == 2) && (col_3x3 == 1));
        mState.pad.r.btn_3x3_9         = ((row_3x3 == 2) && (col_3x3 == 2));
    }
    else
    {
        mState.pad.r.btn_quad_up = mState.pad.r.btn_quad_down = mState.pad.r.btn_quad_left = mState.pad.r.btn_quad_right = false;
        mState.pad.r.btn_orth_up = mState.pad.r.btn_orth_down = mState.pad.r.btn_orth_left = mState.pad.r.btn_orth_right = false;
        mState.pad.r.btn_2x2_1 = mState.pad.r.btn_2x2_2 = mState.pad.r.btn_2x2_3 = mState.pad.r.btn_2x2_4 = false;
        mState.pad.r.btn_3x3_1 = mState.pad.r.btn_3x3_2 = mState.pad.r.btn_3x3_3 = mState.pad.r.btn_3x3_4 = mState.pad.r.btn_3x3_5 = mState.pad.r.btn_3x3_6 = mState.pad.r.btn_3x3_7 = mState.pad.r.btn_3x3_8 = mState.pad.r.btn_3x3_9 = false;
    }
    
    // Accelerometers
    // TODO
    
    // Gyro
    // TODO
}



void Drivers::Gamepad::Driver::TransEvent( Binding& bind, double state, BindMode mode )
{
    Uinput::Device*     device = nullptr;
    
    
    // Select which uinput device we need to write to
    switch (bind.type)
    {
        case BindType::NONE: // No binding, do nothing
            return;
        break;
        
        case BindType::GAME:  // Gamepad device binding
            // Abort if there is no gamepad uinput device to write to
            if (mpGamepad == nullptr)
                return;
            else
                device = mpGamepad;
        break;
        
        case BindType::MOTION:  // Motion device binding
            if (mpMotion == nullptr)
                return;
            else
                device = mpMotion;
        break;
        
        case BindType::MOUSE:  // Mouse device binding
            if (mpMouse == nullptr)
                return;
            else
                device = mpMouse;
        break;
        
        case BindType::COMMAND:  // Run a command
            if (state)
            {
                if (bind.delay > 0)
                {
                    // Handle repeat-delay (in ms) if set
                    uint64_t time = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
                    if (time < bind.timestamp)
                        return;
                    bind.timestamp = time + bind.delay;
                }
                // Run command from separate thread to avoid packet loss or stopping driver
                gRunner.Exec( bind.str, bind.id );
            }
            return;
        break;
        
        case BindType::PROFILE:  // Request profile switch
            if (state)
            {
                // Enforce a timeout for profile switching when called from binding
                uint64_t time = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
                if (time < mProfSwitchTimestamp)
                    return;
                mProfSwitchTimestamp = time + mProfSwitchDelay;

                // Let the daemon know the user wants to switch profiles
                PushMessage( { .type = Drivers::MsgType::PROFILE, .msg = bind.str, .val = 0 } );
            }
            return;
        break;
        
        default:
            // Unhandled device type
            gLog.Write( Log::DEBUG, FUNC_NAME, "An unhandled device type occurred." );
            return;
        break;
    }
    
    // Switch on input trigger mode
    switch (mode)
    {
        // State is a button
        case BindMode::BUTTON:
            switch (bind.ev_type)
            {
                // Button press emits a key/button event
                case EV_KEY:
                    if (state)
                        device->UpdateKey( bind.ev_code, true );
                break;
                
                // Button press emits an absolute axis value
                case EV_ABS:
                    // If triggered, emit an maximum absolute axis value in the direction specified by
                    // the binding
                    if (state)
                        device->UpdateAbs( bind.ev_code, (bind.dir) ? 1.0 : -1.0 );
                break;
                
                // Button press emits a relative axis value
                case EV_REL:
                    // If triggered, emit a relative value in the direction specified in the binding
                    if (state) 
                        device->UpdateRel( bind.ev_code, (bind.dir) ? 1 : -1 );  // TODO: Some kind of scaling / multiplier
                break;
                
                default:
                    // Unsupported input event type
                    gLog.Write( Log::DEBUG, FUNC_NAME, "An unsupported input event type occurred." );
                    return;
                break;
            }
        break;

        // State is an normalized absolute axis with a negative value
        case BindMode::AXIS_MINUS:
            switch (bind.ev_type)
            {
                // Axis UP/LEFT emits a key/button event
                case EV_KEY:
                    if (state < 0)
                        device->UpdateKey( bind.ev_code, true );
                break;
                
                // Axis UP/LEFT emits an absolute axis event
                case EV_ABS:
                    // If triggered, emit the state as a positive or negive absolute axis
                    // value depending on the direction specified in the binding.
                    if (state < 0)
                        device->UpdateAbs( bind.ev_code, (bind.dir) ? fabs(state) : state );
                        
                break;

                // Axis UP/LEFT emits an absolute axis event
                case EV_REL:
                    // If triggered, emit the state as a positive or negative relative axis 
                    // value depending on the direction specified in the binding.
                    if (state < 0)
                        device->UpdateRel( bind.ev_code, (bind.dir) ? fabs(state) : state );  // TODO Some kind of axis scaling / multiplier
                break;
                
                default:
                    // Unsupported input event type
                    gLog.Write( Log::DEBUG, FUNC_NAME, "An unsupported input event type occurred." );
                    return;
                break;
            }
        break;
        
        // State is a normalized absolute axis with a positive value
        case BindMode::PRESSURE:
        case BindMode::AXIS_PLUS:
            switch (bind.ev_type)
            {
                // Axis DOWN/RIGHT emits a key/button event
                case EV_KEY:
                    if (state > 0)
                        device->UpdateKey( bind.ev_code, true );
                break;
                
                // Axis DOWN/RIGHT emits an absolute axis event
                case EV_ABS:
                    // If triggered, emit the state as a positive or negive absolute axis
                    // value depending on the direction specified in the binding.
                    if (state > 0)
                        device->UpdateAbs( bind.ev_code, (bind.dir) ? state : state * -1.0 );
                break;

                // Axis UP/LEFT emits an absolute axis event
                case EV_REL:
                    // If triggered, emit the state as a positive or negative relative axis 
                    // value depending on the direction specified in the binding.
                    if (state > 0)
                        device->UpdateRel( bind.ev_code, (bind.dir) ? state : state * -1.0 );  // TODO Some kind of axis scaling / multiplier
                break;
                
                // Unsupported input event type
                default:
                    gLog.Write( Log::DEBUG, FUNC_NAME, "An unsupported input event type occurred." );
                    return;
                break;
            }
        break;
        
        // Relative bindings
        case BindMode::RELATIVE:
            switch (bind.ev_type)
            {
                // TODO: handle other bind types?  Is it practical?
                
                case EV_REL:
                    device->UpdateRel( bind.ev_code, state );
                break;
                
                default:
                    // Unsupported input event type
                    gLog.Write( Log::DEBUG, FUNC_NAME, "An unsupported input event type occurred." );
                    return;
                break;
            }
        break;
        
        // Unhandled state trigger mode
        default:
            gLog.Write( Log::DEBUG, FUNC_NAME, "An unhandled state trigger occurred." );
            return;
        break;
    }
}



void Drivers::Gamepad::Driver::Translate()
{
    // Map normalized event values using the pregenerated map and write them to
    // our uinput event buffer
    
    // Dpad
    TransEvent( mMap.dpad.up,               mState.dpad.up,                 BindMode::BUTTON );
    TransEvent( mMap.dpad.down,             mState.dpad.down,               BindMode::BUTTON );
    TransEvent( mMap.dpad.left,             mState.dpad.left,               BindMode::BUTTON );
    TransEvent( mMap.dpad.right,            mState.dpad.right,              BindMode::BUTTON );
    // Buttons
    TransEvent( mMap.btn.a,                 mState.btn.a,                   BindMode::BUTTON );
    TransEvent( mMap.btn.b,                 mState.btn.b,                   BindMode::BUTTON );
    TransEvent( mMap.btn.x,                 mState.btn.x,                   BindMode::BUTTON );
    TransEvent( mMap.btn.y,                 mState.btn.y,                   BindMode::BUTTON );
    TransEvent( mMap.btn.l1,                mState.btn.l1,                  BindMode::BUTTON );
    TransEvent( mMap.btn.l2,                mState.btn.l2,                  BindMode::BUTTON );
    TransEvent( mMap.btn.l3,                mState.btn.l3,                  BindMode::BUTTON );
    TransEvent( mMap.btn.l4,                mState.btn.l4,                  BindMode::BUTTON );
    TransEvent( mMap.btn.l5,                mState.btn.l5,                  BindMode::BUTTON );
    TransEvent( mMap.btn.r1,                mState.btn.r1,                  BindMode::BUTTON );
    TransEvent( mMap.btn.r2,                mState.btn.r2,                  BindMode::BUTTON );
    TransEvent( mMap.btn.r3,                mState.btn.r3,                  BindMode::BUTTON );
    TransEvent( mMap.btn.r4,                mState.btn.r4,                  BindMode::BUTTON );
    TransEvent( mMap.btn.r5,                mState.btn.r5,                  BindMode::BUTTON );
    TransEvent( mMap.btn.menu,              mState.btn.menu,                BindMode::BUTTON );
    TransEvent( mMap.btn.options,           mState.btn.options,             BindMode::BUTTON );
    TransEvent( mMap.btn.steam,             mState.btn.steam,               BindMode::BUTTON );
    TransEvent( mMap.btn.quick_access,      mState.btn.quick_access,        BindMode::BUTTON );
    // Triggers
    TransEvent( mMap.trigg.l,               mState.trigg.l.z,               BindMode::PRESSURE );
    TransEvent( mMap.trigg.r,               mState.trigg.r.z,               BindMode::PRESSURE );
    // Sticks
    TransEvent( mMap.stick.l.up,            mState.stick.l.y,               BindMode::AXIS_MINUS );
    TransEvent( mMap.stick.l.down,          mState.stick.l.y,               BindMode::AXIS_PLUS );
    TransEvent( mMap.stick.l.left,          mState.stick.l.x,               BindMode::AXIS_MINUS );
    TransEvent( mMap.stick.l.right,         mState.stick.l.x,               BindMode::AXIS_PLUS );
    TransEvent( mMap.stick.l.touch,         mState.stick.l.touch,           BindMode::BUTTON );
    TransEvent( mMap.stick.l.force,         mState.stick.l.force,           BindMode::PRESSURE );
    TransEvent( mMap.stick.r.up,            mState.stick.r.y,               BindMode::AXIS_MINUS );
    TransEvent( mMap.stick.r.down,          mState.stick.r.y,               BindMode::AXIS_PLUS );
    TransEvent( mMap.stick.r.left,          mState.stick.r.x,               BindMode::AXIS_MINUS );
    TransEvent( mMap.stick.r.right,         mState.stick.r.x,               BindMode::AXIS_PLUS );
    TransEvent( mMap.stick.r.touch,         mState.stick.r.touch,           BindMode::BUTTON );
    TransEvent( mMap.stick.r.force,         mState.stick.r.force,           BindMode::PRESSURE );
    // Pads
    TransEvent( mMap.pad.l.up,              mState.pad.l.y,                 BindMode::AXIS_MINUS );
    TransEvent( mMap.pad.l.down,            mState.pad.l.y,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.pad.l.left,            mState.pad.l.x,                 BindMode::AXIS_MINUS );
    TransEvent( mMap.pad.l.right,           mState.pad.l.x,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.pad.l.rel_x,           mState.pad.l.dx,                BindMode::RELATIVE );
    TransEvent( mMap.pad.l.rel_y,           mState.pad.l.dy,                BindMode::RELATIVE );
    TransEvent( mMap.pad.l.touch,           mState.pad.l.touch,             BindMode::BUTTON );
    TransEvent( mMap.pad.l.press,           mState.pad.l.press,             BindMode::BUTTON );
    TransEvent( mMap.pad.l.force,           mState.pad.l.force,             BindMode::PRESSURE );
    TransEvent( mMap.pad.l.btn_quad_up,     mState.pad.l.btn_quad_up,       BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_quad_down,   mState.pad.l.btn_quad_down,     BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_quad_left,   mState.pad.l.btn_quad_left,     BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_quad_right,  mState.pad.l.btn_quad_right,    BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_orth_up,     mState.pad.l.btn_orth_up,       BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_orth_down,   mState.pad.l.btn_orth_down,     BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_orth_left,   mState.pad.l.btn_orth_left,     BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_orth_right,  mState.pad.l.btn_orth_right,    BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_2x2_1,       mState.pad.l.btn_2x2_1,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_2x2_2,       mState.pad.l.btn_2x2_2,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_2x2_3,       mState.pad.l.btn_2x2_3,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_2x2_4,       mState.pad.l.btn_2x2_4,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_1,       mState.pad.l.btn_3x3_1,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_2,       mState.pad.l.btn_3x3_2,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_3,       mState.pad.l.btn_3x3_3,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_4,       mState.pad.l.btn_3x3_4,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_5,       mState.pad.l.btn_3x3_5,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_6,       mState.pad.l.btn_3x3_6,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_7,       mState.pad.l.btn_3x3_7,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_8,       mState.pad.l.btn_3x3_8,         BindMode::BUTTON );
    TransEvent( mMap.pad.l.btn_3x3_9,       mState.pad.l.btn_3x3_9,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.up,              mState.pad.r.y,                 BindMode::AXIS_MINUS );
    TransEvent( mMap.pad.r.down,            mState.pad.r.y,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.pad.r.left,            mState.pad.r.x,                 BindMode::AXIS_MINUS );
    TransEvent( mMap.pad.r.right,           mState.pad.r.x,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.pad.r.rel_x,           mState.pad.r.dx,                BindMode::RELATIVE );
    TransEvent( mMap.pad.r.rel_y,           mState.pad.r.dy,                BindMode::RELATIVE );
    TransEvent( mMap.pad.r.touch,           mState.pad.r.touch,             BindMode::BUTTON );
    TransEvent( mMap.pad.r.press,           mState.pad.r.press,             BindMode::BUTTON );
    TransEvent( mMap.pad.r.force,           mState.pad.r.force,             BindMode::PRESSURE );
    TransEvent( mMap.pad.r.btn_quad_up,     mState.pad.r.btn_quad_up,       BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_quad_down,   mState.pad.r.btn_quad_down,     BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_quad_left,   mState.pad.r.btn_quad_left,     BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_quad_right,  mState.pad.r.btn_quad_right,    BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_orth_up,     mState.pad.r.btn_orth_up,       BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_orth_down,   mState.pad.r.btn_orth_down,     BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_orth_left,   mState.pad.r.btn_orth_left,     BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_orth_right,  mState.pad.r.btn_orth_right,    BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_2x2_1,       mState.pad.r.btn_2x2_1,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_2x2_2,       mState.pad.r.btn_2x2_2,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_2x2_3,       mState.pad.r.btn_2x2_3,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_2x2_4,       mState.pad.r.btn_2x2_4,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_1,       mState.pad.r.btn_3x3_1,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_2,       mState.pad.r.btn_3x3_2,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_3,       mState.pad.r.btn_3x3_3,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_4,       mState.pad.r.btn_3x3_4,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_5,       mState.pad.r.btn_3x3_5,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_6,       mState.pad.r.btn_3x3_6,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_7,       mState.pad.r.btn_3x3_7,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_8,       mState.pad.r.btn_3x3_8,         BindMode::BUTTON );
    TransEvent( mMap.pad.r.btn_3x3_9,       mState.pad.r.btn_3x3_9,         BindMode::BUTTON );
    // Accelerometers
    TransEvent( mMap.accel.x_plus,          mState.accel.x,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.accel.x_minus,         mState.accel.x,                 BindMode::AXIS_MINUS );
    TransEvent( mMap.accel.y_plus,          mState.accel.y,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.accel.y_minus,         mState.accel.y,                 BindMode::AXIS_MINUS );
    TransEvent( mMap.accel.z_plus,          mState.accel.z,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.accel.z_minus,         mState.accel.z,                 BindMode::AXIS_MINUS );
    // Gyros
    TransEvent( mMap.att.roll_plus,         mState.att.roll,                BindMode::AXIS_PLUS );
    TransEvent( mMap.att.roll_minus,        mState.att.roll,                BindMode::AXIS_MINUS );
    TransEvent( mMap.att.pitch_plus,        mState.att.pitch,               BindMode::AXIS_PLUS );
    TransEvent( mMap.att.pitch_minus,       mState.att.pitch,               BindMode::AXIS_MINUS );
    TransEvent( mMap.att.yaw_plus,          mState.att.yaw,                 BindMode::AXIS_PLUS );
    TransEvent( mMap.att.yaw_minus,         mState.att.yaw,                 BindMode::AXIS_MINUS );
}



void Drivers::Gamepad::Driver::Flush()
{
    if (mpGamepad != nullptr)
        mpGamepad->Flush();
    if (mpMotion != nullptr)
        mpMotion->Flush();
    if (mpMouse != nullptr)
        mpMouse->Flush();
}



int Drivers::Gamepad::Driver::SetProfile( const Drivers::Gamepad::Profile& rProf )
{
    Uinput::DeviceConfig        cfg;


    gLog.Write( Log::INFO, "Setting gamepad profile..." );

    // Lock driver so we can make changes
    std::lock_guard<std::mutex>     lock( mPollMutex );
    
    // Wait 50ms for threads to hit the mutex just to be safe
    usleep( 50000 );
    
    // Destroy any uinput objects since we need to create new ones
    DestroyUinputDevs();
    
    // Create Gamepad device
    cfg.deviceinfo.name         = rProf.dev.gamepad.name;
    cfg.deviceinfo.vid          = rProf.dev.gamepad.vid;
    cfg.deviceinfo.pid          = rProf.dev.gamepad.pid;
    cfg.deviceinfo.ver          = rProf.dev.gamepad.ver;
    cfg.features.enable_keys    = true;
    cfg.features.enable_abs     = true;
    cfg.features.enable_rel     = true;
    cfg.features.enable_ff      = rProf.features.ff;
    cfg.key_list                = rProf.dev.gamepad.key_list;
    cfg.abs_list                = rProf.dev.gamepad.abs_list;
    cfg.rel_list.clear();
    try { mpGamepad = new Uinput::Device( cfg ); } catch (...)
    {
        gLog.Write( Log::ERROR, "Failed to create gamepad uinput device." );
        DestroyUinputDevs();
        return Err::CANNOT_CREATE;
    }
    
    // Create motion device
    if (rProf.features.motion)
    {
        cfg.deviceinfo.name         = rProf.dev.motion.name;
        cfg.deviceinfo.vid          = rProf.dev.motion.vid;
        cfg.deviceinfo.pid          = rProf.dev.motion.pid;
        cfg.deviceinfo.ver          = rProf.dev.motion.ver;
        cfg.features.enable_keys    = false;
        cfg.features.enable_abs     = true;
        cfg.features.enable_rel     = false;
        cfg.features.enable_ff      = false;
        cfg.key_list.clear();
        cfg.abs_list                = rProf.dev.motion.abs_list;
        cfg.rel_list.clear();
        try { mpMotion = new Uinput::Device( cfg ); } catch (...)
        {
            gLog.Write( Log::ERROR, "Failed to create motion control uinput device." );
            DestroyUinputDevs();
            return Err::CANNOT_CREATE;
        }
    }

    // Create mouse device
    if (rProf.features.mouse)
    {
        cfg.deviceinfo.name         = rProf.dev.mouse.name;
        cfg.deviceinfo.vid          = rProf.dev.mouse.vid;
        cfg.deviceinfo.pid          = rProf.dev.mouse.pid;
        cfg.deviceinfo.ver          = rProf.dev.mouse.ver;
        cfg.features.enable_keys    = true;
        cfg.features.enable_abs     = false;
        cfg.features.enable_rel     = true;
        cfg.features.enable_ff      = false;
        cfg.key_list                = rProf.dev.mouse.key_list;
        cfg.abs_list.clear();
        cfg.rel_list                = rProf.dev.mouse.rel_list;
        try { mpMouse = new Uinput::Device( cfg ); } catch (...)
        {
            gLog.Write( Log::ERROR, "Failed to create trackpad/mouse uinput device." );
            DestroyUinputDevs();
            return Err::CANNOT_CREATE;
        }
    }
      
    // Set bindings
    mMap = rProf.map;
    
    // Set Deadzones
    SetStickFiltering( rProf.features.filter_sticks );
    SetPadFiltering( rProf.features.filter_pads );
    SetDeadzone( AxisEnum::L_STICK, rProf.dz.stick.l );
    SetDeadzone( AxisEnum::R_STICK, rProf.dz.stick.r );
    SetDeadzone( AxisEnum::L_PAD,   rProf.dz.pad.l );
    SetDeadzone( AxisEnum::R_PAD,   rProf.dz.pad.r );
    SetDeadzone( AxisEnum::L_TRIGG, rProf.dz.trigg.l );
    SetDeadzone( AxisEnum::R_TRIGG, rProf.dz.trigg.r );
    
    // Done
    return Err::OK;
}



int Drivers::Gamepad::Driver::Poll()
{
    // Use static to avoid construction costs since reports should usually
    // be the same size.  The underlying memory will stay allocated between
    // calls.
    static std::vector<uint8_t>     buff;
    int                             result;
    
    using namespace v100;
    
    // Prevent other public functions from being called while handling device input
    std::lock_guard<std::mutex>     lock( mPollMutex );

    result = mHid.Read( buff );
    if (result != Err::OK)
    {
        switch (result)
        {
            case Err::NOT_OPEN:
                gLog.Write( Log::ERROR, "Failed to read gamepad input:  Device is not open." );
                return Err::NO_DEVICE;
            break;

            case Err::READ_FAILED:
                gLog.Write( Log::ERROR, "Failed to read input from gamepad device." );
                return Err::READ_FAILED;
            break;
            
            case Err::DEVICE_LOST:
                gLog.Write( Log::ERROR, "Gamepad device has been lost.  Terminating gamepad driver." );
                mRunning = false;
                return Err::DEVICE_LOST;
            break;

            default:
                gLog.Write( Log::ERROR, "An unhandled error while occurred reading gamepad device." );
                return Err::UNKNOWN;
            break;
        }
    }
    
    if (buff.size())
        HandleInputReport( buff );
    else
        gLog.Write( Log::VERB, FUNC_NAME, "Received zero-length report from gamepad device." );
    
    // Handle incoming force-feedback events
    if (mpGamepad->IsFFEnabled())
    {
        int             result;
        input_event     ev;

        // Read event from uinput
        result = mpGamepad->Read( ev );
        if (result == Err::OK)
        {
            // Handle different event types accordingly
            switch (ev.type)
            {
                // Force-feedback event
                case EV_FF:
                    switch (ev.code)
                    {
                        // Set gain
                        case FF_GAIN:
                            // TODO: Set gain
                            //gLog.Write( Log::VERB, "FF GAIN: " + std::to_string(ev.value) );
                        break;
                        
                        default:
                            gLog.Write( Log::VERB, "Unknown FF effect:  code=" + std::to_string(ev.code) + "   val=" + std::to_string(ev.value) );
                        break;
                    }
                break;
                
                // Uinput upload events
                case EV_UINPUT:
                    switch (ev.code)
                    {
                        // Upload force-feedback program
                        case UI_FF_UPLOAD:
                        {
                            // TODO: FF uploads
                            uinput_ff_upload    data;
                            
                            gLog.Write( Log::VERB, "UI_FF_UPLOAD" );
                            
                            mpGamepad->GetFFEffect( ev.value, data );
                        }
                        break;
                        
                        // Erase force-feedback program
                        case UI_FF_ERASE:
                        {
                            // TODO: FF Erase
                            uinput_ff_erase     data;
                            
                            gLog.Write( Log::VERB, ">>> UI_FF_ERASE" );
                            
                            mpGamepad->EraseFFEffect( ev.value, data );
                        }   
                        break;
                        
                        default:
                            //gLog.Write( Log::VERB, "Unhandled EV_UINPUT code." );
                        break;
                    }
                break;
                
                // Unimplemented
                case EV_LED:
                break;
                
                default:
                    gLog.Write( Log::VERB, "Unhandled uinput type." );
                break;
            }
        }
    }
    
    return Err::OK;
}



void Drivers::Gamepad::Driver::ThreadedLizardHandler()
{
    std::vector<uint8_t>    buff;
    int                     result;

    // Strangely, the only known method to disable keyboard emulation only does
    // so for a few seconds, whereas disabling the mouse is permanent until
    // re-enabled.  This means we have to run a separate thread which wakes up
    // every couple seconds and disabled the keyboard again using the 
    // CLEAR_MAPPINGS report.  If there's a better way to do this, I'd love to
    // know about it.  Looking at you, Valve.
        
    using namespace v100;
    
    // Initialize report
    buff.resize( 64, 0 );
    buff.at(0) = ReportType::CLEAR_MAPPINGS;

    // Loop thread while driver is running
    while (mRunning)
    {
        // Sleep for a bit
        usleep( LIZARD_SLEEP_SEC * 1000000 );   // in microseconds
        
        // If lizard mode is still false, send another CLEAR_MAPPINGS report
        if (!mLizardMode)
        {
            if (!mHid.IsOpen())
                gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
            else
            {
                result = mHid.Write( buff );
                if (result != Err::OK)
                    gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write gamepad device." );
            }
        }
    }
}



void Drivers::Gamepad::Driver::Run()
{
    // Init
    mRunning    = true;
    mLizardMode = false;
    
    // Run this function as a separate thread
    mLizHandlerThread = std::thread( &Drivers::Gamepad::Driver::ThreadedLizardHandler, this );
    
    // Loop while driver is running
    gLog.Write( Log::DEBUG, FUNC_NAME, "Gamepad driver is now running..." );
    while (mRunning)
    {
        Poll();
        
        // Polling interval is about 4ms so we can sleep a little
        usleep( 250 );
    }
    
    // Rejoin threads after driver exits
    mLizHandlerThread.join();
}



int Drivers::Gamepad::Driver::SetLizardMode( bool enabled )
{
    int                     result;
    std::vector<uint8_t>    buff;

    
    using namespace v100;
        
    if (!mHid.IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    // Pause main driver thread to set mode
    std::lock_guard<std::mutex>     lock( mPollMutex );
    // Wait 10ms for drivers to hit the mutex just to be safe
    usleep( 10000 );
    
    // Initialize report
    buff.resize( 64, 0 );
    
    if (!enabled)
    {
        buff.at(0) = ReportType::CLEAR_MAPPINGS;                      // Disable keyboard emulation (for a few seconds)
        result = mHid.Write( buff );
        if (result != Err::OK)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to disable keyboard emulation." );

        result = WriteRegister( Register::RPAD_MODE, 0x07 );       // Disable mouse emulation on right pad
        if (result != Err::OK)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to disable mouse emulation." );

        result = WriteRegister( Register::RPAD_MARGIN, 0x00 );     // Disable margins on the right pad
        if (result != Err::OK)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to disable trackpad margins." );

        mLizardMode = false;
        gLog.Write( Log::DEBUG, FUNC_NAME, "'Lizard Mode' disabled." );
    }
    else
    {
        buff.at(0) = ReportType::DEFAULT_MAPPINGS;                    // Enable keyboard emulation
        result = mHid.Write( buff );
        if (result != Err::OK)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to enable keyboard emulation." );
        
        buff.at(0) = ReportType::DEFAULT_MOUSE;                       // Enable mouse emulation
        result = mHid.Write( buff );
        if (result != Err::OK)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to enable mouse emulation." );

        result = WriteRegister( Register::RPAD_MARGIN, 0x01 );     // Enable margins on the right pad
        if (result != Err::OK)
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to enable trackpad margins." );

        mLizardMode = true;
        gLog.Write( Log::DEBUG, FUNC_NAME, "'Lizard Mode' enabled." );
    }
    
    return Err::OK;
}



void Drivers::Gamepad::Driver::SetDeadzone( AxisEnum ax, double dz )
{
    dz = (dz < 0) ? 0 : dz;
    dz = (dz > 0.9) ? 0.9 : dz;
    
    switch (ax)
    {
        case AxisEnum::L_STICK:
            mState.stick.l.deadzone = dz;
            mState.stick.l.scale = (1.0 / (1.0 - dz));
        break;
        
        case AxisEnum::R_STICK:
            mState.stick.r.deadzone = dz;
            mState.stick.r.scale = (1.0 / (1.0 - dz));
        break;

        case AxisEnum::L_PAD:
            mState.pad.l.deadzone = dz;
            mState.pad.l.scale = (1.0 / (1.0 - dz));
        break;
        
        case AxisEnum::R_PAD:
            mState.pad.r.deadzone = dz;
            mState.pad.r.scale = (1.0 / (1.0 - dz));
        break;

        case AxisEnum::L_TRIGG:
            mState.trigg.l.deadzone = dz;
            mState.trigg.l.scale = (1.0 / (1.0 - dz));
        break;
        
        case AxisEnum::R_TRIGG:
            mState.trigg.r.deadzone = dz;
            mState.trigg.r.scale = (1.0 / (1.0 - dz));
        break;
    }
}



void Drivers::Gamepad::Driver::SetStickFiltering( bool enabled )
{
    mState.stick.filtered = enabled;
}



void Drivers::Gamepad::Driver::SetPadFiltering( bool enabled )
{
    mState.pad.filtered = enabled;
}



Drivers::Gamepad::Driver::Driver()
{
    int             result;
    DeviceState     initstate = {};
   
    mpGamepad               = nullptr;
    mpMotion                = nullptr;
    mpMouse                 = nullptr;
    mState                  = initstate;
    mProfSwitchDelay        = 2000;         //  Default: 2 seconds
    mProfSwitchTimestamp    = 0;
    
    result = OpenHid();
    if (result != Err::OK)
        throw -1;
        
    SetLizardMode( false );
}



Drivers::Gamepad::Driver::~Driver()
{
    SetLizardMode( true );
    
    DestroyUinputDevs();
        
    mHid.Close();
}
