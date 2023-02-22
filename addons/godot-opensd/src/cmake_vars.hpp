////////////////////////////////////////////////////////////////////////////////////////////////////
//  OpenSD
//  An open-source userspace driver for Valve's Steam Deck hardware
//
//  Copyright 2022 seek
//  https://gitlab.com/open-sd/opensd
//  Licensed under the GNU GPLv3+
//
//    This program is free software: you can redistribute it and/or modify it
//    under the terms of the GNU General Public License as published by the Free
//    Software Foundation, either version 3 of the License, or (at your option)
//    any later version.
//
//    This program is distributed in the hope that it will be useful, but
//    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
//    for more details.
//
//    You should have received a copy of the GNU General Public License along
//    with this program. If not, see <https://www.gnu.org/licenses/>.
////////////////////////////////////////////////////////////////////////////////////////////////////
#ifndef __CMAKE_VARS_HPP__
#define __CMAKE_VARS_HPP__

#include <string>

namespace CMakeVar {

// Versioning
const std::string VERSION_STR = "0.48";
const int MAJOR_VER = 0;
const int MINOR_VER = 48;

// Paths
const std::string INSTALL_DATA_DIR = "/usr/local/share/opensd/";
const std::string INSTALL_DATA_CONFIG_DIR = "/usr/local/share/opensd//config/";
const std::string INSTALL_DATA_PROFILE_DIR =
    "/usr/local/share/opensd//profiles/";
const std::string SYSTEM_CONFIG_DIR = "/etc/opensd/";
const std::string SYSTEM_PROFILE_DIR = "/etc/opensd//profiles/";

// File names
const std::string DEFAULT_CONFIG_FILENAME = "config.ini";
const std::string DEFAULT_PROFILE_FILENAME = "default.profile";

} // namespace CMakeVar

#endif // __CMAKE_VARS_HPP__
