/* Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @file win32/os.h
 * @brief This file in included in all Apache source code. It contains definitions
 * of facilities available on _this_ operating system (HAVE_* macros),
 * and prototypes of OS specific functions defined in os.c or os-inline.c
 *
 * @defgroup APACHE_OS_WIN32 win32
 * @ingroup  APACHE_OS
 * @{
 */

#ifdef WIN32

#ifndef AP_OS_H
#define AP_OS_H
/* Delegate windows include to the apr.h header, if USER or GDI declarations
 * are required (for a window rather than console application), include
 * windows.h prior to any other Apache header files.
 */
#include "apr_pools.h"

#include <io.h>
#include <fcntl.h>

#ifdef _WIN64
#define PLATFORM "Win64"
#else
#define PLATFORM "Win32"
#endif

/* Define command-line rewriting for this platform, handled by core.
 * For Windows, this is currently handled inside the WinNT MPM.
 * XXX To support a choice of MPMs, extract common platform behavior
 * into a function specified here.
 */
#define AP_PLATFORM_REWRITE_ARGS_HOOK NULL

/* going away shortly... */
#define HAVE_DRIVE_LETTERS
#define HAVE_UNC_PATHS
#define CASE_BLIND_FILESYSTEM

#include <stddef.h>
#include <stdlib.h> /* for exit() */

#ifdef __cplusplus
extern "C" {
#endif

/* BIG RED WARNING: exit() is mapped to allow us to capture the exit
 * status.  This header must only be included from modules linked into
 * the ApacheCore.dll - since it's a horrible behavior to exit() from
 * any module outside the main() block, and we -will- assume it's a
 * fatal error.
 */

AP_DECLARE_DATA extern int ap_real_exit_code;

#define exit(status) ((exit)((ap_real_exit_code==2) \
                                ? (ap_real_exit_code = (status)) \
                                : ((ap_real_exit_code = 0), (status))))

#ifdef AP_DECLARE_EXPORT

/* Defined in util_win32.c and available only to the core module for
 * win32 MPM design.
 */

AP_DECLARE(apr_status_t) ap_os_proc_filepath(char **binpath, apr_pool_t *p);

typedef enum {
    AP_DLL_WINBASEAPI = 0,    /* kernel32 From WinBase.h      */
    AP_DLL_WINADVAPI = 1,     /* advapi32 From WinBase.h      */
    AP_DLL_WINSOCKAPI = 2,    /* mswsock  From WinSock.h      */
    AP_DLL_WINSOCK2API = 3,   /* ws2_32   From WinSock2.h     */
    AP_DLL_defined = 4        /* must define as last idx_ + 1 */
} ap_dlltoken_e;

FARPROC ap_load_dll_func(ap_dlltoken_e fnLib, char* fnName, int ordinal);

#define AP_DECLARE_LATE_DLL_FUNC(lib, rettype, calltype, fn, ord, args, names) \
    typedef rettype (calltype *ap_winapi_fpt_##fn) args; \
    static ap_winapi_fpt_##fn ap_winapi_pfn_##fn = NULL; \
    static APR_INLINE rettype ap_winapi_##fn args \
    {   if (!ap_winapi_pfn_##fn) \
            ap_winapi_pfn_##fn = (ap_winapi_fpt_##fn) ap_load_dll_func(lib, #fn, ord); \
        return (*(ap_winapi_pfn_##fn)) names; }; \

/* Win2K kernel only */
AP_DECLARE_LATE_DLL_FUNC(AP_DLL_WINADVAPI, BOOL, WINAPI, ChangeServiceConfig2A, 0, (
    SC_HANDLE hService,
    DWORD dwInfoLevel,
    LPVOID lpInfo),
    (hService, dwInfoLevel, lpInfo));
#undef ChangeServiceConfig2
#define ChangeServiceConfig2 ap_winapi_ChangeServiceConfig2A

/* WinNT kernel only */
AP_DECLARE_LATE_DLL_FUNC(AP_DLL_WINBASEAPI, BOOL, WINAPI, CancelIo, 0, (
    IN HANDLE hFile),
    (hFile));
#undef CancelIo
#define CancelIo ap_winapi_CancelIo

/* Win9x kernel only */
AP_DECLARE_LATE_DLL_FUNC(AP_DLL_WINBASEAPI, DWORD, WINAPI, RegisterServiceProcess, 0, (
    DWORD dwProcessId,
    DWORD dwType),
    (dwProcessId, dwType));
#define RegisterServiceProcess ap_winapi_RegisterServiceProcess

#endif /* def AP_DECLARE_EXPORT */

#ifdef __cplusplus
}
#endif

#endif  /* ndef AP_OS_H */
#endif  /* def WIN32 */
/** @} */
