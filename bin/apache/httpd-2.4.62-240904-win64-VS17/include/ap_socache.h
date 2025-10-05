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
 * @file ap_socache.h
 * @brief Small object cache provider interface.
 *
 * @defgroup AP_SOCACHE ap_socache
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef AP_SOCACHE_H
#define AP_SOCACHE_H

#include "httpd.h"
#include "ap_provider.h"
#include "apr_pools.h"
#include "apr_time.h"

#ifdef __cplusplus
extern "C" {
#endif

/** If this flag is set, the store/retrieve/remove/status interfaces
 * of the provider are NOT safe to be called concurrently from
 * multiple processes or threads, and an external global mutex must be
 * used to serialize access to the provider.
 */
/* XXX: Even if store/retrieve/remove is atomic, isn't it useful to note
 * independently that status and iterate may or may not be?
 */
#define AP_SOCACHE_FLAG_NOTMPSAFE (0x0001)

/** A cache instance. */
typedef struct ap_socache_instance_t ap_socache_instance_t;

/** Hints which may be passed to the init function; providers may
 * ignore some or all of these hints. */
struct ap_socache_hints {
    /** Approximate average length of IDs: */
    apr_size_t avg_id_len;
    /** Approximate average size of objects: */
    apr_size_t avg_obj_size;
    /** Suggested interval between expiry cleanup runs; */
    apr_interval_time_t expiry_interval;
};

/**
 * Iterator callback prototype for the ap_socache_provider_t->iterate() method
 * @param instance The cache instance
 * @param s Associated server context (for logging)
 * @param userctx User defined pointer passed from the iterator call
 * @param id Unique ID for the object (binary blob)
 * with a trailing null char for convenience
 * @param idlen Length of id blob
 * @param data Output buffer to place retrieved data (binary blob)
 * with a trailing null char for convenience
 * @param datalen Length of data buffer
 * @param pool Pool for temporary allocations
 * @return APR status value; return APR_SUCCESS or the iteration will halt;
 * this value is returned to the ap_socache_provider_t->iterate() caller
 */
typedef apr_status_t (ap_socache_iterator_t)(ap_socache_instance_t *instance,
                                             server_rec *s,
                                             void *userctx,
                                             const unsigned char *id,
                                             unsigned int idlen,
                                             const unsigned char *data,
                                             unsigned int datalen,
                                             apr_pool_t *pool);

/** A socache provider structure.  socache providers are registered
 * with the ap_provider.h interface using the AP_SOCACHE_PROVIDER_*
 * constants. */
typedef struct ap_socache_provider_t {
    /** Canonical provider name. */
    const char *name;

    /** Bitmask of AP_SOCACHE_FLAG_* flags. */
    unsigned int flags;

    /**
     * Create a session cache based on the given configuration string.
     * The instance pointer returned in the instance parameter will be
     * passed as the first argument to subsequent invocations.
     *
     * @param instance Output parameter to which instance object is written.
     * @param arg User-specified configuration string.  May be NULL to
     *        force use of defaults.
     * @param tmp Pool to be used for any temporary allocations
     * @param p Pool to be use for any allocations lasting as long as
     * the created instance
     * @return NULL on success, or an error string on failure.
     */
    const char *(*create)(ap_socache_instance_t **instance, const char *arg,
                          apr_pool_t *tmp, apr_pool_t *p);

    /**
     * Initialize the cache.  The cname must be of maximum length 16
     * characters, and uniquely identifies the consumer of the cache
     * within the server; using the module name is recommended, e.g.
     * "mod_ssl-sess".  This string may be used within a filesystem
     * path so use of only alphanumeric [a-z0-9_-] characters is
     * recommended.  If hints is non-NULL, it gives a set of hints for
     * the provider.  Returns APR error code.
     *
     * @param instance The cache instance
     * @param cname A unique string identifying the consumer of this API
     * @param hints Optional hints argument describing expected cache use
     * @param s Server structure to which the cache is associated
     * @param pool Pool for long-lived allocations
     * @return APR status value indicating success.
     */
    apr_status_t (*init)(ap_socache_instance_t *instance, const char *cname,
                         const struct ap_socache_hints *hints,
                         server_rec *s, apr_pool_t *pool);

    /**
     * Destroy a given cache instance object.
     * @param instance The cache instance to destroy.
     * @param s Associated server structure (for logging purposes)
     */
    void (*destroy)(ap_socache_instance_t *instance, server_rec *s);

    /**
     * Store an object in a cache instance.
     * @param instance The cache instance
     * @param s Associated server structure (for logging purposes)
     * @param id Unique ID for the object; binary blob
     * @param idlen Length of id blob
     * @param expiry Absolute time at which the object expires
     * @param data Data to store; binary blob
     * @param datalen Length of data blob
     * @param pool Pool for temporary allocations.
     * @return APR status value.
     */
    apr_status_t (*store)(ap_socache_instance_t *instance, server_rec *s,
                          const unsigned char *id, unsigned int idlen,
                          apr_time_t expiry,
                          unsigned char *data, unsigned int datalen,
                          apr_pool_t *pool);

    /**
     * Retrieve a cached object.
     * 
     * @param instance The cache instance
     * @param s Associated server structure (for logging purposes)
     * @param id Unique ID for the object; binary blob
     * @param idlen Length of id blob
     * @param data Output buffer to place retrievd data (binary blob)
     * @param datalen On entry, length of data buffer; on exit, the
     * number of bytes written to the data buffer.
     * @param pool Pool for temporary allocations.
     * @return APR status value; APR_NOTFOUND if the object was not
     * found
     */
    apr_status_t (*retrieve)(ap_socache_instance_t *instance, server_rec *s,
                             const unsigned char *id, unsigned int idlen,
                             unsigned char *data, unsigned int *datalen,
                             apr_pool_t *pool);

    /**
     * Remove an object from the cache
     *
     * @param instance The cache instance
     * @param s Associated server structure (for logging purposes)
     * @param id Unique ID for the object; binary blob
     * @param idlen Length of id blob
     * @param pool Pool for temporary allocations.
     */
    apr_status_t (*remove)(ap_socache_instance_t *instance, server_rec *s,
                           const unsigned char *id, unsigned int idlen,
                           apr_pool_t *pool);

    /** 
     * Dump the status of a cache instance for mod_status.  Will use
     * the ap_r* interfaces to produce appropriate status output.
     * XXX: ap_r* are deprecated, bad dogfood
     *
     * @param instance The cache instance
     * @param r The request structure
     * @param flags The AP_STATUS_* constants used (see mod_status.h)
     */
    void (*status)(ap_socache_instance_t *instance, request_rec *r, int flags);

    /**
     * Dump all cached objects through an iterator callback.
     * @param instance The cache instance
     * @param s Associated server context (for processing and logging)
     * @param userctx User defined pointer passed through to the iterator
     * @param iterator The user provided callback function which will receive
     * individual calls for each unexpired id/data pair
     * @param pool Pool for temporary allocations.
     * @return APR status value; APR_NOTFOUND if the object was not
     * found
     */
    apr_status_t (*iterate)(ap_socache_instance_t *instance, server_rec *s,
                            void *userctx, ap_socache_iterator_t *iterator,
                            apr_pool_t *pool);

} ap_socache_provider_t;

/** The provider group used to register socache providers. */
#define AP_SOCACHE_PROVIDER_GROUP "socache"
/** The provider version used to register socache providers. */
#define AP_SOCACHE_PROVIDER_VERSION "0"

/** Default provider name. */
#define AP_SOCACHE_DEFAULT_PROVIDER "default"

#ifdef __cplusplus
}
#endif

#endif /* AP_SOCACHE_H */
/** @} */
