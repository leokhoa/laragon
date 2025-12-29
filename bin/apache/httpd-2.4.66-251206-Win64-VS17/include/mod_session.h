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

#ifndef MOD_SESSION_H
#define MOD_SESSION_H

/* Create a set of SESSION_DECLARE(type), SESSION_DECLARE_NONSTD(type) and
 * SESSION_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(WIN32)
#define SESSION_DECLARE(type)        type
#define SESSION_DECLARE_NONSTD(type) type
#define SESSION_DECLARE_DATA
#elif defined(SESSION_DECLARE_STATIC)
#define SESSION_DECLARE(type)        type __stdcall
#define SESSION_DECLARE_NONSTD(type) type
#define SESSION_DECLARE_DATA
#elif defined(SESSION_DECLARE_EXPORT)
#define SESSION_DECLARE(type)        __declspec(dllexport) type __stdcall
#define SESSION_DECLARE_NONSTD(type) __declspec(dllexport) type
#define SESSION_DECLARE_DATA         __declspec(dllexport)
#else
#define SESSION_DECLARE(type)        __declspec(dllimport) type __stdcall
#define SESSION_DECLARE_NONSTD(type) __declspec(dllimport) type
#define SESSION_DECLARE_DATA         __declspec(dllimport)
#endif

/**
 * @file  mod_session.h
 * @brief Session Module for Apache
 *
 * @defgroup MOD_SESSION mod_session
 * @ingroup  APACHE_MODS
 * @{
 */

#include "apr_hooks.h"
#include "apr_optional.h"
#include "apr_tables.h"
#include "apr_uuid.h"
#include "apr_pools.h"
#include "apr_time.h"

#include "httpd.h"
#include "http_config.h"
#include "ap_config.h"

#define MOD_SESSION_NOTES_KEY "mod_session_key"

/**
 * Define the name of a username stored in the session, so that modules interested
 * in the username can find it in a standard place.
 */
#define MOD_SESSION_USER "user"

/**
 * Define the name of a password stored in the session, so that modules interested
 * in the password can find it in a standard place.
 */
#define MOD_SESSION_PW "pw"

/**
 * A session structure.
 *
 * At the core of the session is a set of name value pairs making up the
 * session.
 *
 * The session might be uniquely identified by an anonymous uuid, or
 * a remote_user value, or both.
 */
typedef struct {
    apr_pool_t *pool;             /* pool to be used for this session */
    apr_uuid_t *uuid;             /* anonymous uuid of this particular session */
    const char *remote_user;      /* user who owns this particular session */
    apr_table_t *entries;         /* key value pairs */
    const char *encoded;          /* the encoded version of the key value pairs */
    apr_time_t expiry;            /* if > 0, the time of expiry of this session */
    long maxage;                  /* if > 0, the maxage of the session, from
                                   * which expiry is calculated */
    int dirty;                    /* dirty flag */
    int cached;                   /* true if this session was loaded from a
                                   * cache of some kind */
    int written;                  /* true if this session has already been
                                   * written */
} session_rec;

/**
 * Structure to carry the per-dir session config.
 */
typedef struct {
    int enabled;                  /* whether the session has been enabled for
                                   * this directory */
    int enabled_set;
    long maxage;                  /* seconds until session expiry */
    int maxage_set;
    const char *header;           /* header to inject session */
    int header_set;
    int env;                      /* whether the session has been enabled for
                                   * this directory */
    int env_set;
    apr_array_header_t *includes; /* URL prefixes to be included. All
                                   * URLs included if empty */
    apr_array_header_t *excludes; /* URL prefixes to be excluded. No
                                   * URLs excluded if empty */
    apr_time_t expiry_update_time; /* seconds the session expiry may change and
                                    * not have to be rewritten */
    int expiry_update_set;
} session_dir_conf;

/**
 * Hook to load the session.
 *
 * If the session doesn't exist, a blank one will be created.
 *
 * @param r The request
 * @param z A pointer to where the session will be written.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, SESSION, apr_status_t, session_load,
        (request_rec * r, session_rec ** z))

/**
 * Hook to save the session.
 *
 * In most implementations the session is only saved if the dirty flag is
 * true. This prevents the session being saved unnecessarily.
 *
 * @param r The request
 * @param z A pointer to where the session will be written.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, SESSION, apr_status_t, session_save,
        (request_rec * r, session_rec * z))

/**
 * Hook to encode the session.
 *
 * In the default implementation, the key value pairs are encoded using
 * key value pairs separated by equals, in turn separated by ampersand,
 * like a web form.
 *
 * @param r The request
 * @param z A pointer to where the session will be written.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, SESSION, apr_status_t, session_encode,
        (request_rec * r, session_rec * z))

/**
 * Hook to decode the session.
 *
 * In the default implementation, the key value pairs are encoded using
 * key value pairs separated by equals, in turn separated by ampersand,
 * like a web form.
 *
 * @param r The request
 * @param z A pointer to where the session will be written.
 */
APR_DECLARE_EXTERNAL_HOOK(ap, SESSION, apr_status_t, session_decode,
        (request_rec * r, session_rec * z))

APR_DECLARE_OPTIONAL_FN(
        apr_status_t,
        ap_session_get,
        (request_rec * r, session_rec * z, const char *key, const char **value));
APR_DECLARE_OPTIONAL_FN(apr_status_t, ap_session_set,
        (request_rec * r, session_rec * z, const char *key, const char *value));
APR_DECLARE_OPTIONAL_FN(apr_status_t, ap_session_load,
        (request_rec *, session_rec **));
APR_DECLARE_OPTIONAL_FN(apr_status_t, ap_session_save,
        (request_rec *, session_rec *));

/**
 * The name of the module.
 */
extern module AP_MODULE_DECLARE_DATA session_module;

#endif /* MOD_SESSION_H */
/** @} */
