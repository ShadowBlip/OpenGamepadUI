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
#ifndef __DRIVER_BASE_HPP__
#define __DRIVER_BASE_HPP__

// Needed for error codes
#include "../../common/errors.hpp"
// C++
#include <atomic>
#include <thread>
#include <string>
#include <queue>


namespace Drivers
{
    constexpr unsigned int                  MAX_DRIVER_MESSAGES = 20;
    
    enum class MsgType
    {
        NONE,
        PROFILE
    };
    
    struct Message
    {
        MsgType                             type;
        std::string                         msg;
        double                              val;
    };
    
    // Threaded driver base class
    class DrvBase
    {
    private:
        std::thread                         mThread;
        std::queue<Message>                 mMsgQueue;
        std::mutex                          mMsgMutex;

    protected:
        std::atomic<bool>                   mRunning;
        virtual void                        Run(){ mRunning = false; };
        void                                PushMessage( const Message& msg )
        {
            std::lock_guard<std::mutex>     lock( mMsgMutex );
            if (mMsgQueue.size() >= MAX_DRIVER_MESSAGES)
                return;
            mMsgQueue.push( msg );
        }

    public:
        // Public driver functions
        void                                Start()
        {
            mThread = std::thread( &DrvBase::Run, this );
        }

        void                                Stop()
        {
            mRunning = false;
            mThread.join();
        }

        bool                                IsRunning()
        {
            return mRunning;
        }
        
        bool                                HasMessage()
        {
            std::lock_guard<std::mutex>     lock( mMsgMutex );
            return !mMsgQueue.empty();
        }
        
        Message                             PopMessage()
        {
            std::lock_guard<std::mutex> lock( mMsgMutex );
            Message         msg = { .type = MsgType::NONE, .msg = "", .val = 0 };
            if (mMsgQueue.empty())
                return msg;
            msg = mMsgQueue.front();
            mMsgQueue.pop();
            return msg;
        }
        
        // Non-virtual constructor
        DrvBase(): mThread(), mRunning(false) {};

        // Destructor
        virtual ~DrvBase()
        {
            try { Stop(); } catch(...) { /*??*/ };
        }
    };

} // namespace Drivers


#endif // __DRIVER_BASE_HPP__
