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
 * @file  util_mutex.h
 * @brief Apache Mutex support library
 *
 * @defgroup APACHE_CORE_MUTEX Mutex Library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef UTIL_MUTEX_H
#define UTIL_MUTEX_H

#include "httpd.h"
#include "http_config.h"
#include "apr_global_mutex.h"

#if APR_HAS_FLOCK_SERIALIZE
# define AP_LIST_FLOCK_SERIALIZE ", 'flock:/path/to/file'"
#else
# define AP_LIST_FLOCK_SERIALIZE
#endif
#if APR_HAS_FCNTL_SERIALIZE
# define AP_LIST_FCNTL_SERIALIZE ", 'fcntl:/path/to/file'"
#else
# define AP_LIST_FCNTL_SERIALIZE
#endif
#if APR_HAS_SYSVSEM_SERIALIZE
# define AP_LIST_SYSVSEM_SERIALIZE ", 'sysvsem'"
#else
# define AP_LIST_SYSVSEM_SERIALIZE
#endif
#if APR_HAS_POSIXSEM_SERIALIZE
# define AP_LIST_POSIXSEM_SERIALIZE ", 'posixsem'"
#else
# define AP_LIST_POSIXSEM_SERIALIZE
#endif
#if APR_HAS_PROC_PTHREAD_SERIALIZE
# define AP_LIST_PTHREAD_SERIALIZE ", 'pthread'"
#else
# define AP_LIST_PTHREAD_SERIALIZE
#endif
#if APR_HAS_FLOCK_SERIALIZE || APR_HAS_FCNTL_SERIALIZE
# define AP_LIST_FILE_SERIALIZE ", 'file:/path/to/file'"
#else
# define AP_LIST_FILE_SERIALIZE
#endif
#if APR_HAS_SYSVSEM_SERIALIZE || APR_HAS_POSIXSEM_SERIALIZE
# define AP_LIST_SEM_SERIALIZE ", 'sem'"
#else
# define AP_LIST_SEM_SERIALIZE
#endif

#define AP_ALL_AVAILABLE_MUTEXES_STRING                  \
    "Mutex mechanisms are: 'none', 'default'"            \
    AP_LIST_FLOCK_SERIALIZE   AP_LIST_FCNTL_SERIALIZE    \
    AP_LIST_FILE_SERIALIZE    AP_LIST_PTHREAD_SERIALIZE  \
    AP_LIST_SYSVSEM_SERIALIZE AP_LIST_POSIXSEM_SERIALIZE \
    AP_LIST_SEM_SERIALIZE

#define AP_AVAILABLE_MUTEXES_STRING                      \
    "Mutex mechanisms are: 'default'"                    \
    AP_LIST_FLOCK_SERIALIZE   AP_LIST_FCNTL_SERIALIZE    \
    AP_LIST_FILE_SERIALIZE    AP_LIST_PTHREAD_SERIALIZE  \
    AP_LIST_SYSVSEM_SERIALIZE AP_LIST_POSIXSEM_SERIALIZE \
    AP_LIST_SEM_SERIALIZE

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Get Mutex config data and parse it
 * @param arg The mutex config string
 * @param pool The allocation pool
 * @param mutexmech The APR mutex locking mechanism
 * @param mutexfile The lockfile to use as required
 * @return APR status code
 * @fn apr_status_t ap_parse_mutex(const char *arg, apr_pool_t *pool,
                                        apr_lockmech_e *mutexmech,
                                        const char **mutexfile)
 */
AP_DECLARE(apr_status_t) ap_parse_mutex(const char *arg, apr_pool_t *pool,
                                        apr_lockmech_e *mutexmech,
                                        const char **mutexfile);

/* private function to process the Mutex directive */
AP_DECLARE_NONSTD(const char *) ap_set_mutex(cmd_parms *cmd, void *dummy,
                                             const char *arg);

/* private function to initialize Mutex infrastructure */
AP_DECLARE_NONSTD(void) ap_mutex_init(apr_pool_t *p);

/**
 * option flags for ap_mutex_register(), ap_global_mutex_create(), and
 * ap_proc_mutex_create()
 */
#define AP_MUTEX_ALLOW_NONE    1 /* allow "none" as mutex implementation;
                                  * respected only on ap_mutex_register()
                                  */
#define AP_MUTEX_DEFAULT_NONE  2 /* default to "none" for this mutex;
                                  * respected only on ap_mutex_register()
                                  */

/**
 * Register a module's mutex type with core to allow configuration
 * with the Mutex directive.  This must be called in the pre_config
 * hook; otherwise, configuration directives referencing this mutex
 * type will be rejected.
 *
 * The default_dir and default_mech parameters allow a module to set
 * defaults for the lock file directory and mechanism.  These could
 * be based on compile-time settings.  These aren't required except
 * in special circumstances.
 *
 * The order of precedence for the choice of mechanism and lock file
 * directory is:
 *
 *   1. Mutex directive specifically for this mutex
 *      e.g., Mutex mpm-default flock:/tmp/mpmlocks
 *   2. Mutex directive for global default
 *      e.g., Mutex default flock:/tmp/httpdlocks
 *   3. Defaults for this mutex provided on the ap_mutex_register()
 *   4. Built-in defaults for all mutexes, which are
 *      APR_LOCK_DEFAULT and DEFAULT_REL_RUNTIMEDIR.
 *
 * @param pconf The pconf pool
 * @param type The type name of the mutex, used as the basename of the
 * file associated with the mutex, if any.  This must be unique among
 * all mutex types (mutex creation accommodates multi-instance mutex
 * types); mod_foo might have mutex  types "foo-pipe" and "foo-shm"
 * @param default_dir Default dir for any lock file required for this
 * lock, to override built-in defaults; should be NULL for most
 * modules, to respect built-in defaults
 * @param default_mech Default mechanism for this lock, to override
 * built-in defaults; should be APR_LOCK_DEFAULT for most modules, to
 * respect built-in defaults
 * or NULL if there are no defaults for this mutex.
 * @param options combination of AP_MUTEX_* constants, or 0 for defaults
 */
AP_DECLARE(apr_status_t) ap_mutex_register(apr_pool_t *pconf,
                                           const char *type,
                                           const char *default_dir,
                                           apr_lockmech_e default_mech,
                                           apr_int32_t options);

/**
 * Create an APR global mutex that has been registered previously with
 * ap_mutex_register().  Mutex files, permissions, and error logging will
 * be handled internally.
 * @param mutex The memory address where the newly created mutex will be
 * stored.  If this mutex is disabled, mutex will be set to NULL on
 * output.  (That is allowed only if the AP_MUTEX_ALLOW_NONE flag is
 * passed to ap_mutex_register().)
 * @param name The generated filename of the created mutex, or NULL if
 * no file was created.  Pass NULL if this result is not needed.
 * @param type The type name of the mutex, matching the type name passed
 * to ap_mutex_register().
 * @param instance_id A unique string to be used in the lock filename IFF
 * this mutex type is multi-instance, NULL otherwise.
 * @param server server_rec of main server
 * @param pool pool lifetime of the mutex
 * @param options combination of AP_MUTEX_* constants, or 0 for defaults
 * (currently none are defined for this function)
 */
AP_DECLARE(apr_status_t) ap_global_mutex_create(apr_global_mutex_t **mutex,
                                                const char **name,
                                                const char *type,
                                                const char *instance_id,
                                                server_rec *server,
                                                apr_pool_t *pool,
                                                apr_int32_t options);

/**
 * Create an APR proc mutex that has been registered previously with
 * ap_mutex_register().  Mutex files, permissions, and error logging will
 * be handled internally.
 * @param mutex The memory address where the newly created mutex will be
 * stored.  If this mutex is disabled, mutex will be set to NULL on
 * output.  (That is allowed only if the AP_MUTEX_ALLOW_NONE flag is
 * passed to ap_mutex_register().)
 * @param name The generated filename of the created mutex, or NULL if
 * no file was created.  Pass NULL if this result is not needed.
 * @param type The type name of the mutex, matching the type name passed
 * to ap_mutex_register().
 * @param instance_id A unique string to be used in the lock filename IFF
 * this mutex type is multi-instance, NULL otherwise.
 * @param server server_rec of main server
 * @param pool pool lifetime of the mutex
 * @param options combination of AP_MUTEX_* constants, or 0 for defaults
 * (currently none are defined for this function)
 */
AP_DECLARE(apr_status_t) ap_proc_mutex_create(apr_proc_mutex_t **mutex,
                                              const char **name,
                                              const char *type,
                                              const char *instance_id,
                                              server_rec *server,
                                              apr_pool_t *pool,
                                              apr_int32_t options);

AP_CORE_DECLARE(void) ap_dump_mutexes(apr_pool_t *p, server_rec *s, apr_file_t *out);

#ifdef __cplusplus
}
#endif

#endif /* UTIL_MUTEX_H */
/** @} */
