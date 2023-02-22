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
#include "ini.hpp"
#include "log.hpp"
#include "string_funcs.hpp"
// C++
//#include <sstream>
#include <fstream>
#include <algorithm>
#include <cctype>


// Checks if a string contains whitespace characters
bool HasWhitespace( const std::string& rString )
{
    for (auto c : rString)
        if (std::isspace(c))
            return true; // Found whitespace char, return true
    
    // No whitespace characters found
    return false;
}


// Converts line from an ini file into a vector of strings, with respect to
// comment lines and quoted sections
int VectoriseLine( const std::string& rLineInput, std::vector<std::string>& rVecOutput )
{
    std::vector<std::string>    v;
    std::string                 s;
    bool                        q = false;
    bool                        c = false;
    
    rVecOutput.clear();
    
    // Iterate through input line
    for (auto i : rLineInput)
    {
        // Check if comment flag is set
        if (c)
        {
            // Comment flag is set, add all chars to temp string
            s += i;
        }
        else
        {
            // Check for quote characters
            if (i == '"')
            {
                // Char is a quote, set flag and discard character
                q = !q;
            }
            else  // Character is not a quote
            {
                // Check if inside a quoted block
                if (!q)
                {
                    // Not in a quoted block
                    
                    // Check if character is a comment initiator
                    if ((i == '#') || (i == ';'))
                    {
                        // Character is a comment initiator
                        // Add comment initiator to string
                        s += i;
                        // Flag the rest of the line as just a comment
                        c = true;
                    }
                    else // Character is not inside a quote or comment block
                    {
                        // Check if char is whitespace
                        if (std::isspace(i))
                        {
                            // Char is unquoted whitespace
                            
                            // If temp string is not empty then add it to the vector
                            // and clear string, otherwise ignore the whitespace
                            if (!s.empty())
                            {
                                v.push_back(s);
                                s.clear();
                            }
                        }
                        else // Char is not whitespace
                        {
                            // Add non-whitespace characters to temp string
                            s += i;
                        }
                    }
                }
                else // Character IS inside a quoted block
                {
                    // Add literal character to temp string
                    s += i;
                }
            }
        }
    }
    
    
    // Add last string to vector
    if (!s.empty())
        v.push_back(s);

    rVecOutput = v;
    
    // Unclosed quote
    if (q)
        return Err::UNTERMINATED;
        
    // Return ok
    return Err::OK;
}



int Ini::IniFile::LoadFile( std::filesystem::path filePath )
{
    namespace               fs = std::filesystem;
    std::string             line;
    std::ifstream           file;
    Section                 t_sec;
    unsigned int            line_count = 0;
    unsigned int            section_count = 0;
    unsigned int            key_count = 0;
    unsigned int            value_count = 0;
    int                     result;
    
    mData.clear();

    if (!fs::exists(filePath))
    {
        gLog.Write( Log::ERROR, FUNC_NAME, "File '" + filePath.string() + "' not found." );
        return Err::FILE_NOT_FOUND;
    }
    
    file.open( filePath );
    if (!file.is_open())
    {
        int e = errno;
        gLog.Write( Log::ERROR, FUNC_NAME, "Failed to open '" + filePath.string() + "': " + Err::GetErrnoString(e) );
        return Err::CANNOT_OPEN;
    }
    
    // Create the first/default section.
    // This section is special since it has no block and only
    // holds comments before the first block, if any are present.
    t_sec.name = "NONE";
    t_sec.keys.clear();
    mData.push_back( t_sec );

    // Read file line-by-line
    while (std::getline( file, line ))
    {
        //std::stringstream           ss(line);   // copy line into stream
        std::vector<std::string>    t_vec;
        std::string                 t_str;
        bool                        ignore = false;
        
        ++line_count;
   
        // parse line by whitespace into a vector
        result = VectoriseLine( line, t_vec );
        if (result != Err::OK)
            switch (result)
            {
                case Err::UNTERMINATED:
                    gLog.Write( Log::WARN, "Line " + std::to_string(line_count) + " of " + filePath.string() + " has an unterminated quote." );
                break;
                
                default:
                    gLog.Write( Log::DEBUG, FUNC_NAME, "An Unhandled error occurred while parsing line " + std::to_string(line_count) + " of " + filePath.string() );
                break;
            }
        

        // Check for blank line
        if (!t_vec.size())
        {
            // Push a comment key to the back of the last section
            Key             t_key;
            t_key.comment   = true;
            mData.back().keys.push_back(t_key);
        }
        else
        {
            // Make sure first string is not empty
            if (t_vec.front().size())
            {
                // Check for section change first
                // Make sure there are at least 3 characters in the first string
                // Section names must be enclose in square brackets:  [SectionName]
                if (t_vec.front().starts_with( '[' ))
                {
                    if (( t_vec.front().size() > 2) && (!t_vec.front().ends_with( ']') ))
                    {
                        // Error in section name
                        // Things could get pretty messed up if we ignore this, so we
                        // need to abort.
                        gLog.Write( Log::DEBUG, FUNC_NAME, "Error on line " + std::to_string(line_count) + 
                                    ": Unclosed section name.  Aborting." );
                        return Err::INVALID_FORMAT;
                    }
                    else
                    {
                        // Section name is properly enclosed, but we still need to
                        // make sure the string inside is alphanumeric.
                        std::string     test_str = t_vec.front().substr( 1, t_vec.front().size() - 2 );
                        
                        if (test_str == "NONE")
                        {
                            gLog.Write( Log::DEBUG, FUNC_NAME, " Error on line " + std::to_string(line_count) +
                                        ": Section name 'NONE' is reserved. " );
                            return Err::INVALID_FORMAT;
                        }
                        
                        for (auto& c : test_str)
                        {
                            if (!((std::isalnum(c)) || (c == '_')))
                            {
                                gLog.Write( Log::DEBUG, FUNC_NAME, "Error on line " + std::to_string(line_count) + 
                                            ": Section name contains invalid characters.  Aborting." );
                                return Err::INVALID_FORMAT;
                            }
                        }
                        // No problems found, so add a new section name
                        t_sec.name = test_str;
                        t_sec.keys.clear();
                        mData.push_back( t_sec );
                        ++section_count;
                    }
                }
                else
                {
                    // Check for comments
                    // Comments lines will being with # as the first non-whitespace character
                    // Check if line is a comment
                    if ((t_vec.front().at(0) == '#') || (t_vec.front().at(0) == ';'))
                    {
                        // Push whole line as the key name, but flag it as a comment
                        Key             t_key;
                        t_key.name      = line;
                        t_key.comment   = true;
                        mData.back().keys.push_back( t_key );
                    }
                    else
                    {
                        // Check for keyed lines
                        // Key lines must have at least 3 words.  They must be formatted like this:
                        //   i.e.:  KeyName = SomeValue
                        // Multivalue keys are the same with extra space-delimited values:
                        //   i.e.:  KeyName = SomeValue 1 2 3 lastValue
                        if (t_vec.size() > 2)
                        {
                            // Verify second word is '='
                            if (t_vec.at(1) != "=")
                            {
                                gLog.Write( Log::DEBUG, FUNC_NAME, "Error on line " + std::to_string(line_count) + 
                                            ": Expected key assignment, but missing '='.  Ignoring line." );
                            }
                            else
                            {
                                // Check for blank key names
                                if (t_vec.front().empty())
                                {
                                    gLog.Write( Log::DEBUG, FUNC_NAME, "Error on line "  + std::to_string(line_count) + 
                                                ": Missing or invalid key name.  Ignoring line." );
                                }
                                else
                                {
                                    // Check key name for invalid characters
                                    for (auto& c : t_vec.front())
                                    {
                                        if (!((std::isalnum(c)) || (c == '_')))
                                        {
                                            gLog.Write( Log::DEBUG, FUNC_NAME, "Error on line "  + std::to_string(line_count) + 
                                                        ": Key name contains invalid characters.  Ignoring line." );
                                            ignore = true;
                                        }
                                    }
                                    
                                    // If keyname is valid, read values
                                    if (!ignore)
                                    {
                                        Key             t_key;
                                        t_key.name      = t_vec.front();
                                        t_key.comment   = false;
                                        
                                        // Copy all the values to the temp key
                                        for (unsigned int i = 2; i < t_vec.size(); ++i)
                                        {
                                            t_key.values.push_back( t_vec.at(i) );
                                            ++value_count;
                                        }
                                        // add the temp key to the current section
                                        mData.back().keys.push_back( t_key );
                                        ++key_count;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    gLog.Write( Log::DEBUG, FUNC_NAME, "Parsed " + std::to_string(line_count) + " lines, " +
                std::to_string(section_count) + " sections, " + std::to_string(key_count) + " keys and " +
                std::to_string(value_count) + " values (total). " );
    
    return Err::OK;
}



int Ini::IniFile::SaveFile( std::filesystem::path filePath )
{
    std::ofstream       file;


    namespace fs = std::filesystem;
    
    if (mData.empty())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Nothing to save." );
        return Err::EMPTY;
    }
    
    // Make sure the directory exists
    if (!filePath.parent_path().empty())
        if (!fs::exists( filePath.parent_path() ))
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Creating directory '" + filePath.parent_path().string() + "'..." );
            // Try to create it if it doesn't
            if (!fs::create_directory( filePath.parent_path() ))
            {
                int e = errno;
                gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to create directory '" + filePath.parent_path().string() + "': " + Err::GetErrnoString(e) );
                return Err::CANNOT_CREATE;
            }
        }
    
    if (fs::exists(filePath))
        gLog.Write( Log::DEBUG, FUNC_NAME, "File '" + filePath.string() + "' exists.  File will be overwritten." );
        
    file.open( filePath, std::ios::out | std::ios::trunc );
    if (!file.is_open())
    {
        int e = errno;
        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to open '" + filePath.string() + "' for writing: " + Err::GetErrnoString(e) );
        return Err::CANNOT_OPEN;
    }
    
    // File is open, write ini data to it
    for (auto& s : mData)
    {
        // Write section name
        if (s.name != "NONE")
        {
            file << '[' << s.name << ']' << std::endl;
            if (file.fail())
            {
                int e = errno;
                gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write to '" + filePath.string() + 
                            "': " + Err::GetErrnoString(e) );
                return Err::WRITE_FAILED;
            }
                
        }
            
        // loop through keys in section
        for (auto& k : s.keys)
        {
            // Handle comments
            if (k.comment)
            {
                // Make sure comments start with # or ; if its not a blank line
                if (!k.name.empty())
                    if ((!k.name.starts_with('#')) || (!k.name.starts_with(';')))
                        k.name = "# " + k.name;
                
                file << k.name << std::endl;
                if (file.fail())
                {
                    int e = errno;
                    gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write to '" + filePath.string() + 
                                "': " + Err::GetErrnoString(e) );
                    return Err::WRITE_FAILED;
                }
            }
            else // Not a comment
            {
                // Ignore keys without values
                if (k.values.size())
                {
                    // Create key string
                    std::string     str = k.name + " =";
                    for (auto v : k.values)
                    {
                        // If value contains any whitespace, put the value in quotes
                        if (HasWhitespace(v))
                            v = "\"" + v + "\"";
                        
                        str += " " + v;
                    }
                    
                    file << str << std::endl;
                    if (file.fail())
                    {
                        int e = errno;
                        gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write to '" + filePath.string() + 
                                    "': " + Err::GetErrnoString(e) );
                        return Err::WRITE_FAILED;
                    }
                }
            }
        }
        // Add an extra line at the end of a section so it doesnt get too mushed together.
        file << std::endl;
        if (file.fail())
        {
            int e = errno;
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to write to '" + filePath.string() + 
                        "': " + Err::GetErrnoString(e) );
            return Err::WRITE_FAILED;
        }
    }
    
    return Err::OK;
}



std::vector<std::string> Ini::IniFile::GetSectionList()
{
    std::vector<std::string>    sv;
    
    for (auto const& s : mData)
        if (s.name != "NONE")
            sv.push_back( s.name );
    
    return sv;
}



std::vector<std::string> Ini::IniFile::GetKeyList( std::string section )
{
    std::vector<std::string>    sv;
    section = Str::Uppercase(section);
    
    for (auto const& s : mData)
        if (Str::Uppercase(s.name) == section)
            for (auto const& k : s.keys)
                if (!k.comment)
                    sv.push_back( k.name );
    
    return sv;
}



std::vector<std::string> Ini::IniFile::GetVal( std::string section, std::string key )
{
    if (section.empty() || key.empty())
    {
        gLog.Write( Log::ERROR, FUNC_NAME, "Failed to get value: Section or key name is blank." );
        return {};
    }
    
    if (section == "NONE")
    {
        gLog.Write( Log::ERROR, FUNC_NAME, "Failed to get value: Use of reserved section name." );
        return {};
    }
    
    for (auto& c : section)
    {
        if (!((std::isalnum(c)) || (c == '_')))
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get value: Invalid section name." );
            return {};
        }
    }

    for (auto& c : key)
    {
        if (!((std::isalnum(c)) || (c == '_')))
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get value: Invalid key name." );
            return {};
        }
    }

    // For case insensitive compare
    section = Str::Uppercase(section);
    key = Str::Uppercase(key);
    
    // Loop through date looking section+key and return value
    for (auto const& s : mData)
        if (Str::Uppercase(s.name) == section)
            for (auto const& k : s.keys)
                if (!k.comment)
                    if (Str::Uppercase(k.name) == key)
                        return k.values;
    
    // Return empty vector if not found
    gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to get value: Not found." );
    return {};
}



int Ini::IniFile::SetVal( std::string section, std::string key, std::vector<std::string> vals )
{
    if (section == "NONE")
    {
        gLog.Write( Log::ERROR, FUNC_NAME, "Failed to set value: Use of reserved section name." );
        return Err::INVALID_PARAMETER;
    }
    
    for (auto& c : section)
    {
        if (!((std::isalnum(c)) || (c == '_')))
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to set value: Invalid section name." );
            return Err::INVALID_PARAMETER;
        }
    }

    for (auto& c : key)
    {
        if (!((std::isalnum(c)) || (c == '_')))
        {
            gLog.Write( Log::DEBUG, FUNC_NAME, "Failed to set value: Invalid key name." );
            return Err::INVALID_PARAMETER;
        }
    }
            
    // find section or creat it if it doesn't exist
    for (auto& s : mData)
    {
        if (Str::CIComp( s.name, section)) // Ignore case
        {
            for (auto& k : s.keys)
            {
                if (!k.comment)
                    if (Str::CIComp( k.name, key )) // Ignore case
                    {
                        // Key found, so update values
                        k.values.clear();
                        k.values = vals;
                        return Err::OK;
                    }
            }
            
            // Key name not found, so create a new key
            Key         new_key;
            new_key.name    = key;
            new_key.comment = false;
            new_key.values  = vals;
            
            // Add new key to end of section
            s.keys.push_back( new_key );
            return Err::OK;
        }
    }

    // Section (and key) do not exist, so create them
    Key         new_key;
    new_key.name    = key;
    new_key.comment = false;
    new_key.values  = vals;
    
    Section     new_sec;
    new_sec.name    = section;
    new_sec.keys.push_back( new_key );
    
    // Add new section to the end of the section list
    mData.push_back( new_sec );
    
    return Err::OK;
}



int Ini::IniFile::SetStringVal( std::string section, std::string key, std::string val )
{
    return SetVal( section, key, {val} );
}



int Ini::IniFile::SetIntVal( std::string section, std::string key, int val )
{
    return SetVal( section, key, {std::to_string(val)} );
}



int Ini::IniFile::SetDoubleVal( std::string section, std::string key, double val )
{
    return SetVal( section, key, {std::to_string(val)} );
}



int Ini::IniFile::SetBoolVal( std::string section, std::string key, bool val )
{
    std::string     s = val ? "true" : "false";
    
    return SetVal( section, key, {s} );
}



bool Ini::IniFile::DoesSectionExist( std::string section )
{
    section = Str::Uppercase( section );
    
    for (auto const& s : mData)
        if (s.name != "NONE")
            if (Str::Uppercase(s.name) == section)
                return true;
    
    // Return false if not found
    return false;
}



bool Ini::IniFile::DoesKeyExist( std::string section, std::string key )
{
    ValVec          val;
    val = GetVal( section, key );
    
    return val.Count();
}



void Ini::IniFile::Clear()
{
    mData.clear();
}



Ini::IniFile::IniFile()
{
    //
}



Ini::IniFile::~IniFile()
{
    //
}



//////////////////////////////////////////////////////////
//  ValVec Helper class
//////////////////////////////////////////////////////////
unsigned int Ini::ValVec::Count()
{
    return mData.size();
}



std::string Ini::ValVec::String( unsigned int index )
{
    if (index >= mData.size())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Index is out of range." );
        return "";
    }
        
    return mData.at(index);
}



int Ini::ValVec::Int( unsigned int index )
{
    int             i = 0;
    
    if (index >= mData.size())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Index is out of range." );
        return 0;
    }
    
    try { i = std::stoi( mData.at(index) ); } catch (...)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "No integer conversion possible." );
        return 0;
    }
    
    return i;
}



double Ini::ValVec::Double( unsigned int index )
{
    double          d = 0;
    
    if (index >= mData.size())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Index is out of range." );
        return 0;
    }
    
    try { d = std::stod( mData.at(index) ); } catch (...)
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "No double conversion possible." );
        return 0;
    }
    
    return d;
}



bool Ini::ValVec::Bool( unsigned int index )
{
    bool            b = false;
    std::string     s;
    
    if (index >= mData.size())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Index is out of range." );
        return false;
    }
    
    s = Str::Uppercase( mData.at(index) );
    
    if ((s == "TRUE") || (s == "YES"))
        return true;
    
    if ((s == "FALSE") || (s == "NO"))
        return false;
    
    // If val doesnt match a known string, test for integer value
    try { b = std::stoi( mData.at(index) ); } catch (...)
    {
        // Return false if no conversion
        gLog.Write( Log::DEBUG, FUNC_NAME, "No integer conversion possible." );
        return false;
    }
    
    return b;
}



std::string Ini::ValVec::FullString( unsigned int index )
{
    std::string     s;
    
    if (index >= mData.size())
    {
        gLog.Write( Log::DEBUG, FUNC_NAME, "Index is out of range." );
        return "";
    }
    
    // Concatenate all value starting with index into a single string, separated by a space.
    for (unsigned int i = index; i < mData.size(); ++i)
        s = s + mData.at(i) + " ";
        
    // Trim trailing space.
    if (s.ends_with(' '))
        s = s.substr( 0, s.size() - 1 );
        
    return s;
}