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
 * @file mod_cache.h
 * @brief Main include file for the Apache Transparent Cache
 *
 * @defgroup MOD_CACHE mod_cache
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef MOD_CACHE_H
#define MOD_CACHE_H

#include "httpd.h"
#include "apr_date.h"
#include "apr_optional.h"
#include "apr_hooks.h"

#include "cache_common.h"

/* Create a set of CACHE_DECLARE(type), CACHE_DECLARE_NONSTD(type) and
 * CACHE_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(WIN32)
#define CACHE_DECLARE(type)            type
#define CACHE_DECLARE_NONSTD(type)     type
#define CACHE_DECLARE_DATA
#elif defined(CACHE_DECLARE_STATIC)
#define CACHE_DECLARE(type)            type __stdcall
#define CACHE_DECLARE_NONSTD(type)     type
#define CACHE_DECLARE_DATA
#elif defined(CACHE_DECLARE_EXPORT)
#define CACHE_DECLARE(type)            __declspec(dllexport) type __stdcall
#define CACHE_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define CACHE_DECLARE_DATA             __declspec(dllexport)
#else
#define CACHE_DECLARE(type)            __declspec(dllimport) type __stdcall
#define CACHE_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define CACHE_DECLARE_DATA             __declspec(dllimport)
#endif

/* cache info information */
typedef struct cache_info cache_info;
struct cache_info {
    /**
     * the original time corresponding to the 'Date:' header of the request
     * served
     */
    apr_time_t date;
    /** a time when the cached entity is due to expire */
    apr_time_t expire;
    /** r->request_time from the same request */
    apr_time_t request_time;
    /** apr_time_now() at the time the entity was actually cached */
    apr_time_t response_time;
    /**
     * HTTP status code of the cached entity. Though not necessarily the
     * status code finally issued to the request.
     */
    int status;
    /* cached cache-control */
    cache_control_t control;
};

/* cache handle information */
typedef struct cache_object cache_object_t;
struct cache_object {
    const char *key;
    cache_object_t *next;
    cache_info info;
    /* Opaque portion (specific to the implementation) of the cache object */
    void *vobj;
};

typedef struct cache_handle cache_handle_t;
struct cache_handle {
    cache_object_t *cache_obj;
    apr_table_t *req_hdrs;        /* cached request headers */
    apr_table_t *resp_hdrs;       /* cached response headers */
};

#define CACHE_PROVIDER_GROUP "cache"

typedef struct {
    int (*remove_entity) (cache_handle_t *h);
    apr_status_t (*store_headers)(cache_handle_t *h, request_rec *r, cache_info *i);
    apr_status_t (*store_body)(cache_handle_t *h, request_rec *r, apr_bucket_brigade *in,
                           apr_bucket_brigade *out);
    apr_status_t (*recall_headers) (cache_handle_t *h, request_rec *r);
    apr_status_t (*recall_body) (cache_handle_t *h, apr_pool_t *p, apr_bucket_brigade *bb);
    int (*create_entity) (cache_handle_t *h, request_rec *r,
                           const char *urlkey, apr_off_t len, apr_bucket_brigade *bb);
    int (*open_entity) (cache_handle_t *h, request_rec *r,
                           const char *urlkey);
    int (*remove_url) (cache_handle_t *h, request_rec *r);
    apr_status_t (*commit_entity)(cache_handle_t *h, request_rec *r);
    apr_status_t (*invalidate_entity)(cache_handle_t *h, request_rec *r);
} cache_provider;

typedef enum {
    AP_CACHE_HIT,
    AP_CACHE_REVALIDATE,
    AP_CACHE_MISS,
    AP_CACHE_INVALIDATE
} ap_cache_status_e;

#define AP_CACHE_HIT_ENV "cache-hit"
#define AP_CACHE_REVALIDATE_ENV "cache-revalidate"
#define AP_CACHE_MISS_ENV "cache-miss"
#define AP_CACHE_INVALIDATE_ENV "cache-invalidate"
#define AP_CACHE_STATUS_ENV "cache-status"


/* cache_util.c */
/* do a HTTP/1.1 age calculation */
CACHE_DECLARE(apr_time_t) ap_cache_current_age(cache_info *info, const apr_time_t age_value,
                                               apr_time_t now);

CACHE_DECLARE(apr_time_t) ap_cache_hex2usec(const char *x);
CACHE_DECLARE(void) ap_cache_usec2hex(apr_time_t j, char *y);
CACHE_DECLARE(char *) ap_cache_generate_name(apr_pool_t *p, int dirlevels,
                                             int dirlength,
                                             const char *name);
CACHE_DECLARE(const char *)ap_cache_tokstr(apr_pool_t *p, const char *list, const char **str);

/* Create a new table consisting of those elements from an
 * headers table that are allowed to be stored in a cache.
 */
CACHE_DECLARE(apr_table_t *)ap_cache_cacheable_headers(apr_pool_t *pool,
                                                        apr_table_t *t,
                                                        server_rec *s);

/* Create a new table consisting of those elements from an input
 * headers table that are allowed to be stored in a cache.
 */
CACHE_DECLARE(apr_table_t *)ap_cache_cacheable_headers_in(request_rec *r);

/* Create a new table consisting of those elements from an output
 * headers table that are allowed to be stored in a cache;
 * ensure there is a content type and capture any errors.
 */
CACHE_DECLARE(apr_table_t *)ap_cache_cacheable_headers_out(request_rec *r);

/**
 * Parse the Cache-Control and Pragma headers in one go, marking
 * which tokens appear within the header. Populate the structure
 * passed in.
 */
int ap_cache_control(request_rec *r, cache_control_t *cc, const char *cc_header,
        const char *pragma_header, apr_table_t *headers);


/* hooks */

/**
 * Cache status hook.
 * This hook is called as soon as the cache has made a decision as to whether
 * an entity should be served from cache (hit), should be served from cache
 * after a successful validation (revalidate), or served from the backend
 * and potentially cached (miss).
 *
 * A basic implementation of this hook exists in mod_cache which writes this
 * information to the subprocess environment, and optionally to request
 * headers. Further implementations may add hooks as appropriate to perform
 * more advanced processing, or to store statistics about the cache behaviour.
 */
APR_DECLARE_EXTERNAL_HOOK(cache, CACHE, int, cache_status, (cache_handle_t *h,
                request_rec *r, apr_table_t *headers, ap_cache_status_e status,
                const char *reason))

APR_DECLARE_OPTIONAL_FN(apr_status_t,
                        ap_cache_generate_key,
                        (request_rec *r, apr_pool_t*p, const char **key));


#endif /*MOD_CACHE_H*/
/** @} */
