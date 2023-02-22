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
#ifndef __RUNNER_HPP__
#define __RUNNER_HPP__

#include "../common/errors.hpp"
// C++
#include <thread>
#include <string>
#include <cstdint>
#include <vector>


class Runner
{
private:
    struct ProcInfo
    {
        int                 pid;    // Process ID
        uint32_t            bid;    // binding ID
    };
    
    std::atomic<bool>       mIsRunning;
    std::thread             mThread;
    std::mutex              mCmdMutex;
    std::vector<ProcInfo>   mProcList;
    
    void                    Daemon();
    
public:
    int                 Exec( std::string command, uint32_t bindingId );
    
    Runner();
    ~Runner();
};

// Global instance
extern Runner gRunner;



#endif // __RUNNER_HPP__
