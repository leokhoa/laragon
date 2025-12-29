#***************************************************************************
#                                  _   _ ____  _
#  Project                     ___| | | |  _ \| |
#                             / __| | | | |_) | |
#                            | (__| |_| |  _ <| |___
#                             \___|\___/|_| \_\_____|
#
# Copyright (C) Daniel Stenberg, <daniel@haxx.se>, et al.
#
# This software is licensed as described in the file COPYING, which
# you should have received as part of this distribution. The terms
# are also available at https://curl.se/docs/copyright.html.
#
# You may opt to use, copy, modify, merge, publish, distribute and/or sell
# copies of the Software, and permit persons to whom the Software is
# furnished to do so, under the terms of the COPYING file.
#
# This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
# KIND, either express or implied.
#
# SPDX-License-Identifier: curl
#
###########################################################################

####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was curl-config.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################

include(CMakeFindDependencyMacro)
if("ON")
  if("3")
    find_dependency(OpenSSL "3")
  else()
    find_dependency(OpenSSL)
  endif()
endif()
if("ON")
  find_dependency(ZLIB "1")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/CURLTargets.cmake")

# Alias for either shared or static library
if(NOT TARGET CURL::libcurl)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.11 AND CMAKE_VERSION VERSION_LESS 3.18)
    set_target_properties(CURL::libcurl_shared PROPERTIES IMPORTED_GLOBAL TRUE)
  endif()
  add_library(CURL::libcurl ALIAS CURL::libcurl_shared)
endif()

# For compatibility with CMake's FindCURL.cmake
set(CURL_VERSION_STRING "8.17.0")
set(CURL_LIBRARIES CURL::libcurl)
set_and_check(CURL_INCLUDE_DIRS "${PACKAGE_PREFIX_DIR}/include")

set(CURL_SUPPORTED_PROTOCOLS "DICT;FILE;FTP;FTPS;GOPHER;GOPHERS;HTTP;HTTPS;IMAP;IMAPS;IPFS;IPNS;LDAP;LDAPS;MQTT;POP3;POP3S;RTSP;SMB;SMBS;SMTP;SMTPS;TELNET;TFTP;WS;WSS")
set(CURL_SUPPORTED_FEATURES "alt-svc;AsynchDNS;brotli;HSTS;HTTP2;HTTPS-proxy;IPv6;Kerberos;Largefile;libz;MultiSSL;NTLM;SPNEGO;SSL;SSPI;threadsafe;TLS-SRP;Unicode;UnixSockets")

foreach(_item IN LISTS CURL_SUPPORTED_PROTOCOLS CURL_SUPPORTED_FEATURES)
  set(CURL_SUPPORTS_${_item} TRUE)
endforeach()

set(_missing_req "")
foreach(_item IN LISTS CURL_FIND_COMPONENTS)
  if(CURL_SUPPORTS_${_item})
    set(CURL_${_item}_FOUND TRUE)
  elseif(CURL_FIND_REQUIRED_${_item})
    list(APPEND _missing_req ${_item})
  endif()
endforeach()

if(_missing_req)
  string(REPLACE ";" " " _missing_req "${_missing_req}")
  if(CURL_FIND_REQUIRED)
    message(FATAL_ERROR "CURL: missing required components: ${_missing_req}")
  endif()
  unset(_missing_req)
endif()

check_required_components("CURL")
