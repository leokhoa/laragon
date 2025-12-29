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
 * @file  mod_status.h
 * @brief Status Report Extension Module to Apache
 *
 * @defgroup MOD_STATUS mod_status
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef MOD_STATUS_H
#define MOD_STATUS_H

#include "ap_config.h"
#include "httpd.h"

#define AP_STATUS_SHORT    (0x1)  /* short, non-HTML report requested */
#define AP_STATUS_NOTABLE  (0x2)  /* HTML report without tables */
#define AP_STATUS_EXTENDED (0x4)  /* detailed report */

#if !defined(WIN32)
#define STATUS_DECLARE(type)            type
#define STATUS_DECLARE_NONSTD(type)     type
#define STATUS_DECLARE_DATA
#elif defined(STATUS_DECLARE_STATIC)
#define STATUS_DECLARE(type)            type __stdcall
#define STATUS_DECLARE_NONSTD(type)     type
#define STATUS_DECLARE_DATA
#elif defined(STATUS_DECLARE_EXPORT)
#define STATUS_DECLARE(type)            __declspec(dllexport) type __stdcall
#define STATUS_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define STATUS_DECLARE_DATA             __declspec(dllexport)
#else
#define STATUS_DECLARE(type)            __declspec(dllimport) type __stdcall
#define STATUS_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define STATUS_DECLARE_DATA             __declspec(dllimport)
#endif

/* Optional hooks which can insert extra content into the mod_status
 * output.  FLAGS will be set to the bitwise OR of any of the
 * AP_STATUS_* flags.
 *
 * Implementations of this hook should generate content using
 * functions in the ap_rputs/ap_rprintf family; each hook should
 * return OK or DECLINED. */
APR_DECLARE_EXTERNAL_HOOK(ap, STATUS, int, status_hook,
                          (request_rec *r, int flags))
#endif
/** @} */
