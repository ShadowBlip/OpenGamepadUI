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
#include "hidraw.hpp"
#include "../common/log.hpp"
#include "../common/string_funcs.hpp"
// Linux
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/hidraw.h>
#include <linux/input.h>
#include <poll.h>


bool MatchHidrawInfo( std::filesystem::path path, uint16_t vid, uint16_t pid, uint16_t iFaceNum )
{
    int             fd;
    int             result;
    
    fd = open( path.c_str(), O_RDONLY | O_NONBLOCK );
    if (fd < 0)
    {
        // Cannot open device to read info
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to open '" + path.string() + "': " + Err::GetErrnoString( e ) );
        return false;
    }
    else
    {
        // Device open, now read hidraw info
        char                buffer[1024] = {};
        hidraw_devinfo      dev_info = {};
        std::string         dev_name;
        
        // Get hidraw device info
        result = ioctl( fd, HIDIOCGRAWINFO, &dev_info );
        if (result < 0)
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get hidraw device info from '" + path.string() + 
                        "': " + Err::GetErrnoString( e ) );
        }
        else
        {
            // Got device info, check it against bus type and vid/pid
            if ((dev_info.bustype == BUS_USB) && (dev_info.product == pid) && (dev_info.vendor == vid))
            {
                // VID / PID match, now check interface
                result = ioctl( fd, HIDIOCGRAWPHYS(sizeof(buffer)), buffer );
                if (result < 0)
                {
                    int e = errno;
                    gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get hidraw physical location from '" + path.string() + 
                                "': " + Err::GetErrnoString( e ) );
                }
                else
                {
                    // Compare interface name
                    std::string         iface_name = "input" + std::to_string(iFaceNum);
                    std::string         buff_str( buffer );
                    
                    if (buff_str.ends_with( iface_name ))
                    {
                        // Got a match
                        gLog.Write( Log::VERB, FUNC_NAME, "Device at '" + path.string() + "' matches search params." );
                        close( fd );
                        return true;
                    }
                }
            }
        }
    }

    gLog.Write( Log::VERB, FUNC_NAME, "Device at '" + path.string() + "' did not match search params." );
    if (fd >= 0)
        close( fd );
    return false;
}



std::filesystem::path Hidraw::FindDevNode( uint16_t vid, uint16_t pid, uint16_t iFaceNum )
{
    namespace           fs = std::filesystem;
    
    fs::path            dev_path = "/dev/";
    fs::path            hidraw_path;
    std::string         search_name = Str::Uint16ToHex(vid) + ":" + Str::Uint16ToHex(pid) + ":" + std::to_string(iFaceNum);
        
    gLog.Write( Log::DEBUG, FUNC_NAME, "Scanning hidraw nodes..." );
    for (auto const& i : fs::directory_iterator( dev_path ))
    {
        // Look for character files in /dev/ that begin with "hidraw"
        if ((i.path().filename().string().starts_with( "hidraw" )) && (fs::is_character_file( i.path() )))
        {
            gLog.Write( Log::VERB, "Checking '" + i.path().string() + "' for matching device info..." );
            if (MatchHidrawInfo( i.path(), vid, pid, iFaceNum ))
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "Found device matching '" + search_name + "' at '" + i.path().string() + "'" );
                return i.path();
            }
        }
    }
        
    // No luck.  Return empty string on failure.
    gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to find any hidraw device matching '" + search_name + "'." );
    return "";
}



int Hidraw::Open( std::filesystem::path hidrawPath )
{
    namespace fs = std::filesystem;
    
    if (!fs::exists( hidrawPath ))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "hidraw path '" + hidrawPath.string() + " does not exist." );
        return Err::INVALID_PARAMETER;
    }

    if (!fs::is_character_file( hidrawPath ))
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "hidraw path '" + hidrawPath.string() + " is not a character file." );
        return Err::INVALID_PARAMETER;
    }

    if (IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Hidraw object already has an open fd." );
        return Err::ALREADY_OPEN;
    }
    
    gLog.Write( Log::VERB, FUNC_NAME, "Opening hidraw device on '" + hidrawPath.string() + "'." );

    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );
    
    mFd = open( hidrawPath.c_str(), O_RDWR );
    if (mFd < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to open device on '" + hidrawPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        Close();
        return Err::CANNOT_OPEN;
    }

    gLog.Write( Log::VERB, FUNC_NAME, "Successfully opened hidraw device on '" + hidrawPath.string() + "'." );
    mPath = hidrawPath;
    
    return Err::OK;
}



bool Hidraw::IsOpen()
{
    if (mFd > 0)
        if (fcntl( mFd, F_GETFD) >= 0)
            return true;
            
    return false;
}



void Hidraw::Close()
{
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    if (IsOpen())
    {
        gLog.Write( Log::VERB, FUNC_NAME, "Closing device '" + mPath.string() + "'." );
        close( mFd );
        mFd = -1;
    }
    mPath.clear();
}



int Hidraw::Read( std::vector<uint8_t>& rData )
{
    int             result;
    uint8_t         buff[64];
    pollfd          pfd = { .fd = mFd, .events = POLLIN, .revents = 0 };

    // Make sure our return vector is empty
    rData.clear();

    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }

    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = poll( &pfd, 1, mReadTimeout );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Error while waiting for device: " + Err::GetErrnoString( e ) );
        return Err::READ_FAILED;
    }
    else
    {
        if (result == 0)
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Device timeout." );
            ++mTimeoutCount;
            
            if (mTimeoutCount > mMaxTimeouts)
            {
                gLog.Write( Log::ERROR, "Maximum timout count exceeded for hidraw device." );
                Close();
                return Err::DEVICE_LOST;
            }
        }
        else
        {
            mTimeoutCount = 0;
            result = read( mFd, buff, sizeof(buff) );
            if (result < 0)
            {
                int e = errno;
                gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to read '" + mPath.string() + "': error " + 
                            std::to_string(e) + ": " + Err::GetErrnoString(e) );
                return Err::READ_FAILED;
            }
            
            if (result != sizeof(buff))
            {
                gLog.Write( Log::DEBUG, FUNC_NAME, "Read " + std::to_string(result) + " bytes, but expected to read " + 
                            std::to_string(sizeof(buff)) + " bytes." );
                return Err::READ_FAILED;
            }
            
            rData.assign( buff, buff + result );
        }
    }
    
    return Err::OK;
}



int Hidraw::Write( const std::vector<uint8_t>& rData )
{
    int                 result;

    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = write( mFd, rData.data(), rData.size() );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write '" + mPath.string() + " with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return Err::WRITE_FAILED;
    }

    //gLog.Write( Log::VERB, FUNC_NAME, "Successfully wrote " + std::to_string(result) + " bytes to '" + mPath.string() );
    
    return Err::OK;
}



int Hidraw::GetReportDescriptor( hidraw_report_descriptor& rDesc )
{
    hidraw_report_descriptor    temp_desc = {};
    int                         result;
    int                         desc_size = 0;


    // Clear descriptor parameter
    rDesc = temp_desc;
    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = ioctl( mFd, HIDIOCGRDESCSIZE, &desc_size );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get report descriptor size on '" + mPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return Err::READ_FAILED;
    }
    
    temp_desc.size = desc_size;
    result = ioctl( mFd, HIDIOCGRDESC, &temp_desc);
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get report descriptor on '" + mPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return Err::READ_FAILED;
    }
    
    // Return filled out descriptor if successfull
    rDesc = temp_desc;
    
    return Err::OK;
}



std::string Hidraw::GetName()
{
    int             result;
    char            buff[256] = {0};
    

    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return "";
    }
    
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = ioctl( mFd, HIDIOCGRAWNAME(sizeof(buff)), buff );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to read '" + mPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return "";
    }
    
    return buff;
}



std::string Hidraw::GetPhysLocation()
{
    int             result;
    char            buff[256] = {0};
    

    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return "";
    }
    
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = ioctl( mFd, HIDIOCGRAWPHYS(sizeof(buff)), buff );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to read '" + mPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return "";
    }
    
    return buff;
}



int Hidraw::GetInfo( hidraw_devinfo& rInfo )
{
    hidraw_devinfo              temp_info = {};
    int                         result;


    // Clear info parameter
    rInfo = temp_info;
    
    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = ioctl( mFd, HIDIOCGRAWINFO, &temp_info);
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get report descriptor on '" + mPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return Err::READ_FAILED;
    }
    
    // Return filled out info if successfull
    rInfo = temp_info;
    
    return Err::OK;
}



int Hidraw::GetFeatureReport( std::vector<uint8_t>& rData )
{
    int             result;
    

    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    if (rData.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "No report number specified in first byte. " );
        return Err::INVALID_PARAMETER;
    }

    // Trim off everything after the report number and resize
    rData.resize( 1 );
    rData.resize( 256, 0 );

    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );
    
    result = ioctl( mFd, HIDIOCGFEATURE(rData.size()), rData.data() );
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to read feature report on '" + mPath.string() + " with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return Err::READ_FAILED;
    }
    
    rData.resize( result );
    
    return Err::OK;
}



int Hidraw::GetFeatureReport( uint8_t reportId, std::vector<uint8_t>& rData )
{
    rData.insert( rData.begin(), reportId );
    
    return GetFeatureReport( rData );
}



int Hidraw::SetFeatureReport( const std::vector<uint8_t>& rData )
{
    int             result;


    if (!IsOpen())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Device is not open." );
        return Err::NOT_OPEN;
    }
    
    if (rData.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Report is empty." );
        return Err::INVALID_PARAMETER;
    }
    
    // Multithreaded access guard
    std::lock_guard<std::mutex>     lock( mMutex );

    result = ioctl( mFd, HIDIOCSFEATURE(rData.size()), rData.data() ); 
    if (result < 0)
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get report descriptor on '" + mPath.string() + "' with error " + std::to_string(e) + ": " + Err::GetErrnoString(e) );
        return Err::READ_FAILED;
    }
    
    return Err::OK;
}



int Hidraw::SetFeatureReport( uint8_t reportId, const std::vector<uint8_t>& rData )
{
    std::vector<uint8_t>    vec_copy = rData;
    
    vec_copy.insert( rData.begin(), reportId );
    
    return SetFeatureReport( vec_copy );
}



Hidraw::Hidraw()
{
    mFd = -1;
    mReadTimeout = 1000; // in ms
    mTimeoutCount = 0;
    mMaxTimeouts = 5;
    mPath.clear();
}



Hidraw::~Hidraw()
{
    Close();
    mPath.clear();
}
