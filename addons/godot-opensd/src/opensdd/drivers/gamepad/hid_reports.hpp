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
#ifndef __GAMEPAD__HID_REPORTS_HPP__
#define __GAMEPAD__HID_REPORTS_HPP__

#include <cstdint>


namespace Drivers::Gamepad
{
    // Version 1.00 namespace
    // We use versioning here for future-proofing against possible firmware 
    // updates or hardware revisions that might affect HID reports.  Hopefully
    // This might allow us to keep the driver code the same, while only swapping
    // out some structures and stuff.
    namespace v100
    {
        // Input report axis ranges
        const double    STICK_X_MIN         = -32767.0;
        const double    STICK_X_MAX         = 32767.0;
        const double    STICK_Y_MIN         = 32767.0;                  // Hardware uses an inverted y axis
        const double    STICK_Y_MAX         = -32767.0;
        const double    STICK_FORCE_MAX     = 112.0;                    // Weird number
        const double    PAD_X_MIN           = -32767.0;
        const double    PAD_X_MAX           = 32767.0;
        const double    PAD_Y_MIN           = 32767.0;
        const double    PAD_Y_MAX           = -32767.0;
        const double    PAD_FORCE_MAX       = 32767.0;
        const double    TRIGG_MIN           = 0;
        const double    TRIGG_MAX           = 32767.0;
        
        // Precalculated axis multipliers
        const double    STICK_X_AXIS_MULT   = 1.0 / STICK_X_MAX;
        const double    STICK_Y_AXIS_MULT   = 1.0 / STICK_Y_MAX;
        const double    STICK_FORCE_MULT    = 1.0 / STICK_FORCE_MAX;
        const double    PAD_X_AXIS_MULT     = 1.0 / PAD_X_MAX;
        const double    PAD_Y_AXIS_MULT     = 1.0 / PAD_Y_MAX;
        const double    PAD_X_SENS_MULT     = 1.0 / 128.0;
        const double    PAD_Y_SENS_MULT     = 1.0 / 128.0;
        const double    PAD_FORCE_MULT      = 1.0 / PAD_FORCE_MAX;
        const double    TRIGG_AXIS_MULT     = 1.0 / TRIGG_MAX;
        
        // Lengh of time for the thread to sleep before keyboard emulation 
        // has to be disabled again with a CLEAR_MAPPINGS report.
        const double    LIZARD_SLEEP_SEC    = 2.0;
        
        namespace ReportType
        {
            enum
            {   
                INPUT_DATA                  = 0x09,
                SET_MAPPINGS                = 0x80,
                CLEAR_MAPPINGS              = 0x81,
                GET_MAPPINGS                = 0x82,
                GET_ATTRIB                  = 0x83,
                GET_ATTRIB_LABEL            = 0x84,
                DEFAULT_MAPPINGS            = 0x85,
                FACTORY_RESET               = 0x86,
                WRITE_REGISTER              = 0x87,
                CLEAR_REGISTER              = 0x88,
                READ_REGISTER               = 0x89,
                GET_REGISTER_LABEL          = 0x8a,
                GET_REGISTER_MAX            = 0x8b,
                GET_REGISTER_DEFAULT        = 0x8c,
                SET_MODE                    = 0x8d,
                DEFAULT_MOUSE               = 0x8e,
                FORCE_FEEDBACK              = 0x8f,
                REQUEST_COMM_STATUS         = 0xb4,
                GET_SERIAL                  = 0xae,
                HAPTIC_PULSE                = 0xea
            };
        }
    
        namespace Register
        {
            enum
            {
                LPAD_MODE                   = 0x07,
                RPAD_MODE                   = 0x08,
                RPAD_MARGIN                 = 0x18,
                GYRO_MODE                   = 0x30
            };
        }

        // This structure maps the input
        struct __attribute__((__packed__)) PackedInputDataReport
        {
            //              Field           Bits    Byte #      Description
            //-----------------------------------------------------------------------------------------------------------------
            uint8_t         major_ver       : 8;    // 0        Major version?  Always 0x01
            uint8_t         minor_ver       : 8;    // 1        Minor version?  Always 0x00
            uint8_t         report_type     : 8;    // 2        Report type?    Always 0x09
            uint8_t         report_size     : 8;    // 3        Actual data length of report in bytes.  Always 64 for input reports.
            // byte 4-7
            uint32_t        frame           : 32;   // 4        Input frame counter?
            // byte 8
            bool            r2              : 1;    // 8.0      Binary sensor for analogue triggers
            bool            l2              : 1;    // 8.1    
            bool            r1              : 1;    // 8.2      Shoulder buttons
            bool            l1              : 1;    // 8.3
            bool            y               : 1;    // 8.4      Button cluster
            bool            b               : 1;    // 8.5
            bool            x               : 1;    // 8.6
            bool            a               : 1;    // 8.7
            // byte 9
            bool            up              : 1;    // 9.0      Directional Pad buttons
            bool            right           : 1;    // 9.1
            bool            left            : 1;    // 9.2
            bool            down            : 1;    // 9.3
            bool            options         : 1;    // 9.4      Overlapping square ⧉  button located above left stick
            bool            steam           : 1;    // 9.5      STEAM button below left trackpad
            bool            menu            : 1;    // 9.6      Hamburger (☰) button located above right stick
            bool            l5              : 1;    // 9.7      L5 & R5 on the back of the deck
            // byte 10
            bool            r5              : 1;    // 10.0       
            bool            l_pad_press     : 1;    // 10.1     Binary "press" sensor for trackpads
            bool            r_pad_press     : 1;    // 10.2
            bool            l_pad_touch     : 1;    // 10.3     Binary "touch" sensor for trackpads
            bool            r_pad_touch     : 1;    // 10.4
            bool            _unk3           : 1;    // 10.5
            bool            l3              : 1;    // 10.6     Z-axis button on the left stick
            bool            _unk4           : 1;    // 10.7
            // byte 11
            bool            _unk5           : 1;    // 11.0
            bool            _unk6           : 1;    // 11.1
            bool            r3              : 1;    // 11.2     Z-axis button on the right stick
            bool            _unk7           : 1;    // 11.3
            bool            _unk8           : 1;    // 11.4
            bool            _unk9           : 1;    // 11.5
            bool            _unk10          : 1;    // 11.6
            bool            _unk11          : 1;    // 11.7
            // byte 12
            bool            _unk12          : 1;    // 12.0     No readings on any of these.
            bool            _unk13          : 1;    // 12.1 
            bool            _unk14          : 1;    // 12.2 
            bool            _unk15          : 1;    // 12.3
            bool            _unk16          : 1;    // 12.4
            bool            _unk17          : 1;    // 12.5
            bool            _unk18          : 1;    // 12.6
            bool            _unk19          : 1;    // 12.7
            // byte 13
            bool            _unk20          : 1;    // 13.0   
            bool            l4              : 1;    // 13.1     L4 & R4 on the back of the deck
            bool            r4              : 1;    // 13.2
            bool            _unk21          : 1;    // 13.3
            bool            _unk22          : 1;    // 13.4
            bool            _unk23          : 1;    // 13.5
            bool            l_stick_touch   : 1;    // 13.6     Binary touch sensors on the stick controls
            bool            r_stick_touch   : 1;    // 13.7
            // byte 14
            bool            _unk24          : 1;    // 14.0
            bool            _unk25          : 1;    // 14.1
            bool            quick_access    : 1;    // 14.2     Quick Access (...) button below right trackpad
            bool            _unk26          : 1;    // 14.3
            bool            _unk27          : 1;    // 14.4
            bool            _unk28          : 1;    // 14.5
            bool            _unk29          : 1;    // 14.6
            bool            _unk30          : 1;    // 14.7
            // byte 15
            uint8_t         _unk31          : 8;    // 15       Not sure, maybe padding or just unused
            // byte 16-23 
            int16_t         l_pad_x         : 16;   // 16       Trackpad touch coordinates
            int16_t         l_pad_y         : 16;   // 18     
            int16_t         r_pad_x         : 16;   // 20
            int16_t         r_pad_y         : 16;   // 22    
            // byte 24-29
            int16_t         accel_x         : 16;   // 24       Accelerometers I think.  Needs more testing.
            int16_t         accel_y         : 16;   // 26
            int16_t         accel_z         : 16;   // 28
            // byte 30-35
            int16_t         pitch           : 16;   // 30       Attitude (?)  Needs more testing
            int16_t         yaw             : 16;   // 32
            int16_t         roll            : 16;   // 34
            // byte 36-43
            int16_t         _gyro0          : 16;   // 36       Not sure what these are...
            int16_t         _gyro1          : 16;   // 38       Seems like they might be additional gyros for extra precision (?)
            int16_t         _gyro2          : 16;   // 40
            int16_t         _gyro3          : 16;   // 42
            // byte 44-47
            uint16_t        l_trigg         : 16;   // 44       Pressure sensors for L2 & R2 triggers
            uint16_t        r_trigg         : 16;   // 46    
            // byte 48-55
            int16_t         l_stick_x       : 16;   // 48       Analogue thumbsticks
            int16_t         l_stick_y       : 16;   // 50
            int16_t         r_stick_x       : 16;   // 52
            int16_t         r_stick_y       : 16;   // 54
            // byte 56-59 
            uint16_t        l_pad_force     : 16;   // 56       Touchpad pressure sensors
            uint16_t        r_pad_force     : 16;   // 58
            // byte 60-63
            uint16_t        l_stick_force   : 16;   // 60       Thumbstick capacitive sensors
            uint16_t        r_stick_force   : 16;   // 62
            // 64 Bytes total
        };
        
        struct __attribute__((__packed__)) PackedFeedbackReport
        {
            uint8_t         report_id       : 8;
            uint8_t         report_size     : 8;
            uint8_t         side            : 8;
            uint16_t        amplitude       : 16;
            uint16_t        period          : 16;
            uint16_t        count           : 16;
        };
        
    } // namespace v1

} // namespace Driver::Gamepad


#endif // __GAMEPAD__HID_REPORTS_HPP__
