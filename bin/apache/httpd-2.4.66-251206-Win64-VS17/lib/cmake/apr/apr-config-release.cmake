#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "apr::libapr-1" for configuration "Release"
set_property(TARGET apr::libapr-1 APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(apr::libapr-1 PROPERTIES
  IMPORTED_IMPLIB_RELEASE "${_IMPORT_PREFIX}/lib/libapr-1.lib"
  IMPORTED_LINK_INTERFACE_LIBRARIES_RELEASE ""
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/libapr-1.dll"
  )

list(APPEND _cmake_import_check_targets apr::libapr-1 )
list(APPEND _cmake_import_check_files_for_apr::libapr-1 "${_IMPORT_PREFIX}/lib/libapr-1.lib" "${_IMPORT_PREFIX}/bin/libapr-1.dll" )

# Import target "apr::apr-1" for configuration "Release"
set_property(TARGET apr::apr-1 APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(apr::apr-1 PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LINK_INTERFACE_LIBRARIES_RELEASE "ws2_32;rpcrt4"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/apr-1.lib"
  )

list(APPEND _cmake_import_check_targets apr::apr-1 )
list(APPEND _cmake_import_check_files_for_apr::apr-1 "${_IMPORT_PREFIX}/lib/apr-1.lib" )

# Import target "apr::libaprapp-1" for configuration "Release"
set_property(TARGET apr::libaprapp-1 APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(apr::libaprapp-1 PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libaprapp-1.lib"
  )

list(APPEND _cmake_import_check_targets apr::libaprapp-1 )
list(APPEND _cmake_import_check_files_for_apr::libaprapp-1 "${_IMPORT_PREFIX}/lib/libaprapp-1.lib" )

# Import target "apr::aprapp-1" for configuration "Release"
set_property(TARGET apr::aprapp-1 APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(apr::aprapp-1 PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/aprapp-1.lib"
  )

list(APPEND _cmake_import_check_targets apr::aprapp-1 )
list(APPEND _cmake_import_check_files_for_apr::aprapp-1 "${_IMPORT_PREFIX}/lib/aprapp-1.lib" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
