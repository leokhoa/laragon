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
 * @file ap_regkey.h
 * @brief APR-style Win32 Registry Manipulation
 */

#ifndef AP_REGKEY_H
#define AP_REGKEY_H

#if defined(WIN32) || defined(DOXYGEN)

#include "apr.h"
#include "apr_pools.h"
#include "ap_config.h"      /* Just for AP_DECLARE */

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ap_regkey_t ap_regkey_t;

/* Used to recover AP_REGKEY_* constants
 */
AP_DECLARE(const ap_regkey_t *) ap_regkey_const(int i);

/**
 * Win32 Only: Constants for ap_regkey_open()
 */
#define AP_REGKEY_CLASSES_ROOT         ap_regkey_const(0)
#define AP_REGKEY_CURRENT_CONFIG       ap_regkey_const(1)
#define AP_REGKEY_CURRENT_USER         ap_regkey_const(2)
#define AP_REGKEY_LOCAL_MACHINE        ap_regkey_const(3)
#define AP_REGKEY_USERS                ap_regkey_const(4)
#define AP_REGKEY_PERFORMANCE_DATA     ap_regkey_const(5)
#define AP_REGKEY_DYN_DATA             ap_regkey_const(6)

/**
 * Win32 Only: Flags for ap_regkey_value_set()
 */
#define AP_REGKEY_EXPAND               0x0001

/**
 * Win32 Only: Open the specified registry key.
 * @param newkey The opened registry key
 * @param parentkey The open registry key of the parent, or one of
 * <PRE>
 *           AP_REGKEY_CLASSES_ROOT
 *           AP_REGKEY_CURRENT_CONFIG
 *           AP_REGKEY_CURRENT_USER
 *           AP_REGKEY_LOCAL_MACHINE
 *           AP_REGKEY_USERS
 *           AP_REGKEY_PERFORMANCE_DATA
 *           AP_REGKEY_DYN_DATA
 * </PRE>
 * @param keyname The path of the key relative to the parent key
 * @param flags Or'ed value of:
 * <PRE>
 *           APR_READ             open key for reading
 *           APR_WRITE            open key for writing
 *           APR_CREATE           create the key if it doesn't exist
 *           APR_EXCL             return error if APR_CREATE and key exists
 * </PRE>
 * @param pool The pool in which newkey is allocated
 */
AP_DECLARE(apr_status_t) ap_regkey_open(ap_regkey_t **newkey,
                                        const ap_regkey_t *parentkey,
                                        const char *keyname,
                                        apr_int32_t flags,
                                        apr_pool_t *pool);

/**
 * Win32 Only: Close the registry key opened or created by ap_regkey_open().
 * @param key The registry key to close
 */
AP_DECLARE(apr_status_t) ap_regkey_close(ap_regkey_t *key);

/**
 * Win32 Only: Remove the given registry key.
 * @param parent The open registry key of the parent, or one of
 * <PRE>
 *           AP_REGKEY_CLASSES_ROOT
 *           AP_REGKEY_CURRENT_CONFIG
 *           AP_REGKEY_CURRENT_USER
 *           AP_REGKEY_LOCAL_MACHINE
 *           AP_REGKEY_USERS
 *           AP_REGKEY_PERFORMANCE_DATA
 *           AP_REGKEY_DYN_DATA
 * </PRE>
 * @param keyname The path of the key relative to the parent key
 * @param pool The pool used for temp allocations
 * @remark ap_regkey_remove() is not recursive, although it removes
 * all values within the given keyname, it will not remove a key
 * containing subkeys.
 */
AP_DECLARE(apr_status_t) ap_regkey_remove(const ap_regkey_t *parent,
                                          const char *keyname,
                                          apr_pool_t *pool);

/**
 * Win32 Only: Retrieve a registry value string from an open key.
 * @param result The string value retrieved
 * @param key The registry key to retrieve the value from
 * @param valuename The named value to retrieve (pass "" for the default)
 * @param pool The pool used to store the result
 * @remark There is no toggle to prevent environment variable expansion
 * if the registry value is set with AP_REG_EXPAND (REG_EXPAND_SZ), such
 * expansions are always performed.
 */
AP_DECLARE(apr_status_t) ap_regkey_value_get(char **result,
                                             ap_regkey_t *key,
                                             const char *valuename,
                                             apr_pool_t *pool);

/**
 * Win32 Only: Store a registry value string into an open key.
 * @param key The registry key to store the value into
 * @param valuename The named value to store (pass "" for the default)
 * @param value The string to store for the named value
 * @param flags The option AP_REGKEY_EXPAND or 0, where AP_REGKEY_EXPAND
 * values will find all %foo% variables expanded from the environment.
 * @param pool The pool used for temp allocations
 */
AP_DECLARE(apr_status_t) ap_regkey_value_set(ap_regkey_t *key,
                                             const char *valuename,
                                             const char *value,
                                             apr_int32_t flags,
                                             apr_pool_t *pool);

/**
 * Win32 Only: Retrieve a raw byte value from an open key.
 * @param result The raw bytes value retrieved
 * @param resultsize Pointer to a variable to store the number raw bytes retrieved
 * @param resulttype Pointer to a variable to store the registry type of the value retrieved
 * @param key The registry key to retrieve the value from
 * @param valuename The named value to retrieve (pass "" for the default)
 * @param pool The pool used to store the result
 */
AP_DECLARE(apr_status_t) ap_regkey_value_raw_get(void **result,
                                                 apr_size_t *resultsize,
                                                 apr_int32_t *resulttype,
                                                 ap_regkey_t *key,
                                                 const char *valuename,
                                                 apr_pool_t *pool);

/**
 * Win32 Only: Store a raw bytes value into an open key.
 * @param key The registry key to store the value into
 * @param valuename The named value to store (pass "" for the default)
 * @param value The bytes to store for the named value
 * @param valuesize The number of bytes for value
 * @param valuetype The
 * values will find all %foo% variables expanded from the environment.
 * @param pool The pool used for temp allocations
 */
AP_DECLARE(apr_status_t) ap_regkey_value_raw_set(ap_regkey_t *key,
                                                 const char *valuename,
                                                 const void *value,
                                                 apr_size_t  valuesize,
                                                 apr_int32_t valuetype,
                                                 apr_pool_t *pool);

/**
 * Win32 Only: Retrieve a registry value string from an open key.
 * @param result The string elements retrieved from a REG_MULTI_SZ string array
 * @param key The registry key to retrieve the value from
 * @param valuename The named value to retrieve (pass "" for the default)
 * @param pool The pool used to store the result
 */
AP_DECLARE(apr_status_t) ap_regkey_value_array_get(apr_array_header_t **result,
                                                   ap_regkey_t *key,
                                                   const char *valuename,
                                                   apr_pool_t *pool);

/**
 * Win32 Only: Store a registry value string array into an open key.
 * @param key The registry key to store the value into
 * @param valuename The named value to store (pass "" for the default)
 * @param nelts The string elements to store in a REG_MULTI_SZ string array
 * @param elts The number of elements in the elts string array
 * @param pool The pool used for temp allocations
 */
AP_DECLARE(apr_status_t) ap_regkey_value_array_set(ap_regkey_t *key,
                                                   const char *valuename,
                                                   int nelts,
                                                   const char * const * elts,
                                                   apr_pool_t *pool);

/**
 * Win32 Only: Remove a registry value from an open key.
 * @param key The registry key to remove the value from
 * @param valuename The named value to remove (pass "" for the default)
 * @param pool The pool used for temp allocations
 */
AP_DECLARE(apr_status_t) ap_regkey_value_remove(const ap_regkey_t *key,
                                                const char *valuename,
                                                apr_pool_t *pool);

#ifdef __cplusplus
}
#endif

#endif /* def WIN32 || def DOXYGEN */

#endif /* AP_REGKEY_H */
