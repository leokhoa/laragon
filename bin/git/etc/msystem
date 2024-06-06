# MSYSTEM Environment Information
# Copyright (C) 2016 Renato Silva
# Licensed under public domain

# Once sourced, this script provides common information associated with the
# current MSYSTEM. For example, the compiler architecture and host type.

# The MSYSTEM_ prefix is used for avoiding too generic names. For example,
# makepkg is sensitive to the value of CARCH, so MSYSTEM_CARCH is defined
# instead. The MINGW_ prefix does not influence makepkg-mingw variables and
# is not used for the MSYS shell.

export MSYSTEM="${MSYSTEM:-MSYS}"

unset MSYSTEM_PREFIX
unset MSYSTEM_CARCH
unset MSYSTEM_CHOST

unset MINGW_CHOST
unset MINGW_PREFIX
unset MINGW_PACKAGE_PREFIX

case "${MSYSTEM}" in
    MINGW32)
        MSYSTEM_PREFIX='/mingw32'
        MSYSTEM_CARCH='i686'
        MSYSTEM_CHOST='i686-w64-mingw32'
        MINGW_CHOST="${MSYSTEM_CHOST}"
        MINGW_PREFIX="${MSYSTEM_PREFIX}"
        MINGW_PACKAGE_PREFIX="mingw-w64-${MSYSTEM_CARCH}"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST MINGW_CHOST MINGW_PREFIX MINGW_PACKAGE_PREFIX
        ;;
    MINGW64)
        MSYSTEM_PREFIX='/mingw64'
        MSYSTEM_CARCH='x86_64'
        MSYSTEM_CHOST='x86_64-w64-mingw32'
        MINGW_CHOST="${MSYSTEM_CHOST}"
        MINGW_PREFIX="${MSYSTEM_PREFIX}"
        MINGW_PACKAGE_PREFIX="mingw-w64-${MSYSTEM_CARCH}"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST MINGW_CHOST MINGW_PREFIX MINGW_PACKAGE_PREFIX
        ;;
    CLANG32)
        MSYSTEM_PREFIX='/clang32'
        MSYSTEM_CARCH='i686'
        MSYSTEM_CHOST='i686-w64-mingw32'
        MINGW_CHOST="${MSYSTEM_CHOST}"
        MINGW_PREFIX="${MSYSTEM_PREFIX}"
        MINGW_PACKAGE_PREFIX="mingw-w64-clang-${MSYSTEM_CARCH}"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST MINGW_CHOST MINGW_PREFIX MINGW_PACKAGE_PREFIX
        ;;
    CLANG64)
        MSYSTEM_PREFIX='/clang64'
        MSYSTEM_CARCH='x86_64'
        MSYSTEM_CHOST='x86_64-w64-mingw32'
        MINGW_CHOST="${MSYSTEM_CHOST}"
        MINGW_PREFIX="${MSYSTEM_PREFIX}"
        MINGW_PACKAGE_PREFIX="mingw-w64-clang-${MSYSTEM_CARCH}"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST MINGW_CHOST MINGW_PREFIX MINGW_PACKAGE_PREFIX
        ;;
    CLANGARM64)
        MSYSTEM_PREFIX='/clangarm64'
        MSYSTEM_CARCH='aarch64'
        MSYSTEM_CHOST='aarch64-w64-mingw32'
        MINGW_CHOST="${MSYSTEM_CHOST}"
        MINGW_PREFIX="${MSYSTEM_PREFIX}"
        MINGW_PACKAGE_PREFIX="mingw-w64-clang-${MSYSTEM_CARCH}"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST MINGW_CHOST MINGW_PREFIX MINGW_PACKAGE_PREFIX
        ;;
    UCRT64)
        MSYSTEM_PREFIX='/ucrt64'
        MSYSTEM_CARCH='x86_64'
        MSYSTEM_CHOST='x86_64-w64-mingw32'
        MINGW_CHOST="${MSYSTEM_CHOST}"
        MINGW_PREFIX="${MSYSTEM_PREFIX}"
        MINGW_PACKAGE_PREFIX="mingw-w64-ucrt-${MSYSTEM_CARCH}"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST MINGW_CHOST MINGW_PREFIX MINGW_PACKAGE_PREFIX
        ;;
    *)
        MSYSTEM_PREFIX='/usr'
        MSYSTEM_CARCH="$(/usr/bin/uname -m)"
        MSYSTEM_CHOST="${MSYSTEM_CARCH}-pc-msys"
        export MSYSTEM_PREFIX MSYSTEM_CARCH MSYSTEM_CHOST
        ;;
esac
