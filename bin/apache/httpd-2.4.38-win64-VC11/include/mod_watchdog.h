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

#ifndef MOD_WATCHDOG_H
#define MOD_WATCHDOG_H

/**
 * @file  mod_watchdog.h
 * @brief Watchdog module for Apache
 *
 * @defgroup MOD_WATCHDOG mod_watchdog
 * @ingroup  APACHE_MODS
 * @{
 */

#include "httpd.h"
#include "http_config.h"
#include "http_log.h"
#include "ap_provider.h"

#include "apr.h"
#include "apr_strings.h"
#include "apr_pools.h"
#include "apr_shm.h"
#include "apr_hash.h"
#include "apr_hooks.h"
#include "apr_optional.h"
#include "apr_file_io.h"
#include "apr_time.h"
#include "apr_thread_proc.h"
#include "apr_global_mutex.h"
#include "apr_thread_mutex.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Default singleton watchdog instance name.
 * Singleton watchdog is protected by mutex and
 * guaranteed to be run inside a single child process
 * at any time.
 */
#define AP_WATCHDOG_SINGLETON       "_singleton_"

/**
 * Default watchdog instance name
 */
#define AP_WATCHDOG_DEFAULT         "_default_"

/**
 * Default Watchdog interval
 */
#define AP_WD_TM_INTERVAL           APR_TIME_C(1000000)  /* 1 second     */

/**
 * Watchdog thread timer resolution
 */
#define AP_WD_TM_SLICE              APR_TIME_C(100000)   /* 100 ms       */

/* State values for callback */
#define AP_WATCHDOG_STATE_STARTING  1
#define AP_WATCHDOG_STATE_RUNNING   2
#define AP_WATCHDOG_STATE_STOPPING  3

typedef struct ap_watchdog_t ap_watchdog_t;

/* Create a set of AP_WD_DECLARE(type), AP_WD_DECLARE_NONSTD(type) and
 * AP_WD_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(AP_WD_DECLARE)
#if !defined(WIN32)
#define AP_WD_DECLARE(type)            type
#define AP_WD_DECLARE_NONSTD(type)     type
#define AP_WD_DECLARE_DATA
#elif defined(AP_WD_DECLARE_STATIC)
#define AP_WD_DECLARE(type)            type __stdcall
#define AP_WD_DECLARE_NONSTD(type)     type
#define AP_WD_DECLARE_DATA
#elif defined(AP_WD_DECLARE_EXPORT)
#define AP_WD_DECLARE(type)            __declspec(dllexport) type __stdcall
#define AP_WD_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define AP_WD_DECLARE_DATA             __declspec(dllexport)
#else
#define AP_WD_DECLARE(type)            __declspec(dllimport) type __stdcall
#define AP_WD_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define AP_WD_DECLARE_DATA             __declspec(dllimport)
#endif
#endif

/**
 * Callback function used for watchdog.
 * @param state Watchdog state function. See @p AP_WATCHDOG_STATE_ .
 * @param data is what was passed to @p ap_watchdog_register_callback function.
 * @param pool Temporary callback pool destroyed after the call.
 * @return APR_SUCCESS to continue calling this callback.
 */
typedef apr_status_t ap_watchdog_callback_fn_t(int state, void *data,
                                               apr_pool_t *pool);

/**
 * Get watchdog instance.
 * @param watchdog Storage for watchdog instance.
 * @param name Watchdog name.
 * @param parent Non-zero to get the parent process watchdog instance.
 * @param singleton Non-zero to get the singleton watchdog instance.
 * @param p The pool to use.
 * @return APR_SUCCESS if all went well
 * @remark Use @p AP_WATCHDOG_DEFAULT to get default watchdog instance.
 *         If separate watchdog thread is needed provide unique name
 *         and function will create a new watchdog instance.
 *         Note that default client process watchdog works in singleton mode.
 */
APR_DECLARE_OPTIONAL_FN(apr_status_t, ap_watchdog_get_instance,
                        (ap_watchdog_t **watchdog, const char *name, int parent,
                         int singleton, apr_pool_t *p));

/**
 * Register watchdog callback.
 * @param watchdog Watchdog to use
 * @param interval Interval on which the callback function will execute.
 * @param callback  The function to call on watchdog event.
 * @param data The data to pass to the callback function.
 * @return APR_SUCCESS if all went well. APR_EEXIST if already registered.
 */
APR_DECLARE_OPTIONAL_FN(apr_status_t, ap_watchdog_register_callback,
                        (ap_watchdog_t *watchdog, apr_interval_time_t interval,
                         const void *data, ap_watchdog_callback_fn_t *callback));

/**
 * Update registered watchdog callback interval.
 * @param w Watchdog to use
 * @param interval New interval on which the callback function will execute.
 * @param callback  The function to call on watchdog event.
 * @param data The data to pass to the callback function.
 * @return APR_SUCCESS if all went well. APR_EOF if callback was not found.
 */
APR_DECLARE_OPTIONAL_FN(apr_status_t, ap_watchdog_set_callback_interval,
                        (ap_watchdog_t *w, apr_interval_time_t interval,
                         const void *data, ap_watchdog_callback_fn_t *callback));

/**
 * Watchdog require hook.
 * @param s The server record
 * @param name Watchdog name.
 * @param parent Non-zero to indicate the parent process watchdog mode.
 * @param singleton Non-zero to indicate the singleton watchdog mode.
 * @return OK to enable notifications from this watchdog, DECLINED otherwise.
 * @remark This is called in post config phase for all watchdog instances
 *         that have no callbacks registered. Modules using this hook
 *         should ensure that their post_config hook is called after watchdog
 *         post_config.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, AP_WD, int, watchdog_need, (server_rec *s,
                          const char *name,
                          int parent, int singleton))


/**
 * Watchdog initialize hook.
 * It is called after the watchdog thread is initialized.
 * @param s The server record
 * @param name Watchdog name.
 * @param pool The pool used to create the watchdog.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, AP_WD, int, watchdog_init, (
                          server_rec *s,
                          const char *name,
                          apr_pool_t *pool))

/**
 * Watchdog terminate hook.
 * It is called when the watchdog thread is terminated.
 * @param s The server record
 * @param name Watchdog name.
 * @param pool The pool used to create the watchdog.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, AP_WD, int, watchdog_exit, (
                          server_rec *s,
                          const char *name,
                          apr_pool_t *pool))

/**
 * Fixed interval watchdog hook.
 * It is called regularly on @p AP_WD_TM_INTERVAL interval.
 * @param s The server record
 * @param name Watchdog name.
 * @param pool Temporary pool destroyed after the call.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, AP_WD, int, watchdog_step, (
                          server_rec *s,
                          const char *name,
                          apr_pool_t *pool))

#ifdef __cplusplus
}
#endif

#endif /* MOD_WATCHDOG_H */
/** @} */
