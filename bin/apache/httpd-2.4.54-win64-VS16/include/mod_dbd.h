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
 * @file  mod_dbd.h
 * @brief Database Access Extension Module for Apache
 *
 * Overview of what this is and does:
 * http://www.apache.org/~niq/dbd.html
 * or
 * http://apache.webthing.com/database/
 *
 * @defgroup MOD_DBD mod_dbd
 * @ingroup APACHE_MODS
 * @{
 */

#ifndef DBD_H
#define DBD_H

/* Create a set of DBD_DECLARE(type), DBD_DECLARE_NONSTD(type) and
 * DBD_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(WIN32)
#define DBD_DECLARE(type)            type
#define DBD_DECLARE_NONSTD(type)     type
#define DBD_DECLARE_DATA
#elif defined(DBD_DECLARE_STATIC)
#define DBD_DECLARE(type)            type __stdcall
#define DBD_DECLARE_NONSTD(type)     type
#define DBD_DECLARE_DATA
#elif defined(DBD_DECLARE_EXPORT)
#define DBD_DECLARE(type)            __declspec(dllexport) type __stdcall
#define DBD_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define DBD_DECLARE_DATA             __declspec(dllexport)
#else
#define DBD_DECLARE(type)            __declspec(dllimport) type __stdcall
#define DBD_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define DBD_DECLARE_DATA             __declspec(dllimport)
#endif

#include <httpd.h>
#include <apr_optional.h>
#include <apr_hash.h>
#include <apr_hooks.h>

typedef struct {
    server_rec *server;
    const char *name;
    const char *params;
    int persist;
#if APR_HAS_THREADS
    int nmin;
    int nkeep;
    int nmax;
    int exptime;
    int set;
#endif
    apr_hash_t *queries;
    apr_array_header_t *init_queries;
} dbd_cfg_t;

typedef struct {
    apr_dbd_t *handle;
    const apr_dbd_driver_t *driver;
    apr_hash_t *prepared;
    apr_pool_t *pool;
} ap_dbd_t;

/* Export functions to access the database */

/* acquire a connection that MUST be explicitly closed.
 * Returns NULL on error
 */
DBD_DECLARE_NONSTD(ap_dbd_t*) ap_dbd_open(apr_pool_t*, server_rec*);

/* release a connection acquired with ap_dbd_open */
DBD_DECLARE_NONSTD(void) ap_dbd_close(server_rec*, ap_dbd_t*);

/* acquire a connection that will have the lifetime of a request
 * and MUST NOT be explicitly closed.  Return NULL on error.
 * This is the preferred function for most applications.
 */
DBD_DECLARE_NONSTD(ap_dbd_t*) ap_dbd_acquire(request_rec*);

/* acquire a connection that will have the lifetime of a connection
 * and MUST NOT be explicitly closed.  Return NULL on error.
 * This is the preferred function for most applications.
 */
DBD_DECLARE_NONSTD(ap_dbd_t*) ap_dbd_cacquire(conn_rec*);

/* Prepare a statement for use by a client module during
 * the server startup/configuration phase.  Can't be called
 * after the server has created its children (use apr_dbd_*).
 */
DBD_DECLARE_NONSTD(void) ap_dbd_prepare(server_rec*, const char*, const char*);

/* Also export them as optional functions for modules that prefer it */
APR_DECLARE_OPTIONAL_FN(ap_dbd_t*, ap_dbd_open, (apr_pool_t*, server_rec*));
APR_DECLARE_OPTIONAL_FN(void, ap_dbd_close, (server_rec*, ap_dbd_t*));
APR_DECLARE_OPTIONAL_FN(ap_dbd_t*, ap_dbd_acquire, (request_rec*));
APR_DECLARE_OPTIONAL_FN(ap_dbd_t*, ap_dbd_cacquire, (conn_rec*));
APR_DECLARE_OPTIONAL_FN(void, ap_dbd_prepare, (server_rec*, const char*, const char*));

APR_DECLARE_EXTERNAL_HOOK(dbd, DBD, apr_status_t, post_connect,
                          (apr_pool_t *, dbd_cfg_t *, ap_dbd_t *))

#endif
/** @} */

