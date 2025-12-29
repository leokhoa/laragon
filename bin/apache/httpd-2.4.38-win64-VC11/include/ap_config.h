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
 * @file ap_config.h
 * @brief Symbol export macros and hook functions
 */

#ifndef AP_CONFIG_H
#define AP_CONFIG_H

#include "ap_hooks.h"

/* Although this file doesn't declare any hooks, declare the exports group here */
/**
 * @defgroup exports Apache exports
 * @ingroup  APACHE_CORE
 */

#ifdef DOXYGEN
/* define these just so doxygen documents them */

/**
 * AP_DECLARE_STATIC is defined when including Apache's Core headers,
 * to provide static linkage when the dynamic library may be unavailable.
 *
 * @see AP_DECLARE_EXPORT
 *
 * AP_DECLARE_STATIC and AP_DECLARE_EXPORT are left undefined when
 * including Apache's Core headers, to import and link the symbols from the
 * dynamic Apache Core library and assure appropriate indirection and calling
 * conventions at compile time.
 */
# define AP_DECLARE_STATIC
/**
 * AP_DECLARE_EXPORT is defined when building the Apache Core dynamic
 * library, so that all public symbols are exported.
 *
 * @see AP_DECLARE_STATIC
 */
# define AP_DECLARE_EXPORT

#endif /* def DOXYGEN */

#if !defined(WIN32)
/**
 * Apache Core dso functions are declared with AP_DECLARE(), so they may
 * use the most appropriate calling convention.  Hook functions and other
 * Core functions with variable arguments must use AP_DECLARE_NONSTD().
 * @code
 * AP_DECLARE(rettype) ap_func(args)
 * @endcode
 */
#define AP_DECLARE(type)            type

/**
 * Apache Core dso variable argument and hook functions are declared with
 * AP_DECLARE_NONSTD(), as they must use the C language calling convention.
 * @see AP_DECLARE
 * @code
 * AP_DECLARE_NONSTD(rettype) ap_func(args [...])
 * @endcode
 */
#define AP_DECLARE_NONSTD(type)     type

/**
 * Apache Core dso variables are declared with AP_MODULE_DECLARE_DATA.
 * This assures the appropriate indirection is invoked at compile time.
 *
 * @note AP_DECLARE_DATA extern type apr_variable; syntax is required for
 * declarations within headers to properly import the variable.
 * @code
 * AP_DECLARE_DATA type apr_variable
 * @endcode
 */
#define AP_DECLARE_DATA

#elif defined(AP_DECLARE_STATIC)
#define AP_DECLARE(type)            type __stdcall
#define AP_DECLARE_NONSTD(type)     type
#define AP_DECLARE_DATA
#elif defined(AP_DECLARE_EXPORT)
#define AP_DECLARE(type)            __declspec(dllexport) type __stdcall
#define AP_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define AP_DECLARE_DATA             __declspec(dllexport)
#else
#define AP_DECLARE(type)            __declspec(dllimport) type __stdcall
#define AP_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define AP_DECLARE_DATA             __declspec(dllimport)
#endif

#if !defined(WIN32) || defined(AP_MODULE_DECLARE_STATIC)
/**
 * Declare a dso module's exported module structure as AP_MODULE_DECLARE_DATA.
 *
 * Unless AP_MODULE_DECLARE_STATIC is defined at compile time, symbols
 * declared with AP_MODULE_DECLARE_DATA are always exported.
 * @code
 * module AP_MODULE_DECLARE_DATA mod_tag
 * @endcode
 */
#if defined(WIN32)
#define AP_MODULE_DECLARE(type)            type __stdcall
#else
#define AP_MODULE_DECLARE(type)            type
#endif
#define AP_MODULE_DECLARE_NONSTD(type)     type
#define AP_MODULE_DECLARE_DATA
#else
/**
 * AP_MODULE_DECLARE_EXPORT is a no-op.  Unless contradicted by the
 * AP_MODULE_DECLARE_STATIC compile-time symbol, it is assumed and defined.
 *
 * The old SHARED_MODULE compile-time symbol is now the default behavior,
 * so it is no longer referenced anywhere with Apache 2.0.
 */
#define AP_MODULE_DECLARE_EXPORT
#define AP_MODULE_DECLARE(type)          __declspec(dllexport) type __stdcall
#define AP_MODULE_DECLARE_NONSTD(type)   __declspec(dllexport) type
#define AP_MODULE_DECLARE_DATA           __declspec(dllexport)
#endif

#include "os.h"
#if (!defined(WIN32) && !defined(NETWARE)) || defined(__MINGW32__)
#include "ap_config_auto.h"
#endif
#include "ap_config_layout.h"

/* Where the main/parent process's pid is logged */
#ifndef DEFAULT_PIDLOG
#define DEFAULT_PIDLOG DEFAULT_REL_RUNTIMEDIR "/httpd.pid"
#endif

#if defined(NETWARE)
#define AP_NONBLOCK_WHEN_MULTI_LISTEN 1
#endif

#if defined(AP_ENABLE_DTRACE) && HAVE_SYS_SDT_H
#include <sys/sdt.h>
#else
#undef _DTRACE_VERSION
#endif

#ifdef _DTRACE_VERSION
#include "apache_probes.h"
#else
#include "apache_noprobes.h"
#endif

/* If APR has OTHER_CHILD logic, use reliable piped logs. */
#if APR_HAS_OTHER_CHILD
#define AP_HAVE_RELIABLE_PIPED_LOGS TRUE
#endif

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#define AP_HAVE_C99
#endif

/* Presume that the compiler supports C99-style designated
 * initializers if using GCC (but not G++), or for any other compiler
 * which claims C99 support. */
#if (defined(__GNUC__) && !defined(__cplusplus)) || defined(AP_HAVE_C99)
#define AP_HAVE_DESIGNATED_INITIALIZER
#endif

#ifndef __has_attribute         /* check for supported attributes on clang */
#define __has_attribute(x) 0
#endif
#if (defined(__GNUC__) && __GNUC__ >= 4) || __has_attribute(sentinel)
#define AP_FN_ATTR_SENTINEL __attribute__((sentinel))
#else
#define AP_FN_ATTR_SENTINEL
#endif

#if ( defined(__GNUC__) &&                                        \
      (__GNUC__ >= 4 || ( __GNUC__ == 3 && __GNUC_MINOR__ >= 4))) \
    || __has_attribute(warn_unused_result)
#define AP_FN_ATTR_WARN_UNUSED_RESULT   __attribute__((warn_unused_result))
#else
#define AP_FN_ATTR_WARN_UNUSED_RESULT
#endif

#if ( defined(__GNUC__) &&                                        \
      (__GNUC__ >= 4 && __GNUC_MINOR__ >= 3))                     \
    || __has_attribute(alloc_size)
#define AP_FN_ATTR_ALLOC_SIZE(x)     __attribute__((alloc_size(x)))
#define AP_FN_ATTR_ALLOC_SIZE2(x,y)  __attribute__((alloc_size(x,y)))
#else
#define AP_FN_ATTR_ALLOC_SIZE(x)
#define AP_FN_ATTR_ALLOC_SIZE2(x,y)
#endif

#endif /* AP_CONFIG_H */
