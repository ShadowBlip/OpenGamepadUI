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
#ifndef __INI_HPP__
#define __INI_HPP__

#include "errors.hpp"
// C++
#include <string>
#include <vector>
#include <utility>
#include <filesystem>


namespace Ini
{
    class IniFile
    {
    private:
        struct Key
        {
            std::string                 name;
            std::vector<std::string>    values;
            bool                        comment;
        };
        struct Section
        {
            std::string                 name;
            std::vector<Key>            keys;
        };
        std::vector<Section>            mData;
        
    public:
        int                             LoadFile( std::filesystem::path filePath );
        int                             SaveFile( std::filesystem::path filePath );
        
        std::vector<std::string>        GetSectionList();
        std::vector<std::string>        GetKeyList( std::string section );
        
        std::vector<std::string>        GetVal( std::string section, std::string key );
        int                             SetVal( std::string section, std::string key, std::vector<std::string> vals );
        
        int                             SetStringVal( std::string section, std::string key, std::string val );
        int                             SetIntVal( std::string section, std::string key, int val );
        int                             SetDoubleVal( std::string section, std::string key, double val );
        int                             SetBoolVal( std::string section, std::string key, bool val );

        bool                            DoesSectionExist( std::string section );
        bool                            DoesKeyExist( std::string section, std::string key );
        
        void                            Clear();
        
        IniFile();
        ~IniFile();
    };

    // Helper class to use in place of string vector for IniFile function 
    // return values
    class ValVec : public std::vector<std::string>
    {
    public:
        // Public access to underlying data
        std::vector<std::string>    mData;
        
        // Assign this class like you would a string or a vector of strings
        void                        operator=( std::vector<std::string> v ) { mData = v; };
        void                        operator=( std::string& s ) { mData.clear(); mData.push_back(s); };
        
        // Return number of contained values
        unsigned int                Count();
        
        // Return a single selected string.  
        // Defaults to first string if no parameter is supplied.
        std::string                 String( unsigned int index = 0 );
        
        // Converts the selected string to an integer and returns it.
        // Defaults to first string if no parameter is supplied.
        int                         Int( unsigned int index = 0 );
        
        // Converts the selected string to a floating point number and returns it.
        // Defaults to first string if no parameter is supplied.
        double                      Double( unsigned int index = 0 );
        
        // Convers the selected string to a boolean value and returns it.
        // Recognized values are zero/non-zero, true/false, yes/no;
        // Defaults to first string if no parameter is supplied.
        bool                        Bool( unsigned int index = 0 );
        
        // Returns all values as a single string separated by spaces.
        // Used for text lines
        std::string                 FullString( unsigned int index = 0 );
        
        ValVec(){};
        ~ValVec(){};
    };

} // namespace Ini


#endif // __INI_HPP__

