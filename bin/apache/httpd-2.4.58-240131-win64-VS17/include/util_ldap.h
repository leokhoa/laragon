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
 * @file util_ldap.h
 * @brief Apache LDAP library
 */

#ifndef UTIL_LDAP_H
#define UTIL_LDAP_H

/* APR header files */
#include "apr.h"
#include "apr_thread_mutex.h"
#include "apr_thread_rwlock.h"
#include "apr_tables.h"
#include "apr_time.h"
#include "apr_version.h"
#if APR_MAJOR_VERSION < 2
/* The LDAP API is currently only present in APR 1.x */
#include "apr_ldap.h"
#else
#define APR_HAS_LDAP 0
#endif

#if APR_HAS_SHARED_MEMORY
#include "apr_rmm.h"
#include "apr_shm.h"
#endif

/* this whole thing disappears if LDAP is not enabled */
#if APR_HAS_LDAP

#if defined(LDAP_UNAVAILABLE) || APR_HAS_MICROSOFT_LDAPSDK
#define AP_LDAP_IS_SERVER_DOWN(s)                ((s) == LDAP_SERVER_DOWN \
                ||(s) == LDAP_UNAVAILABLE)
#else
#define AP_LDAP_IS_SERVER_DOWN(s)                ((s) == LDAP_SERVER_DOWN)
#endif

/* Apache header files */
#include "ap_config.h"
#include "httpd.h"
#include "http_config.h"
#include "http_core.h"
#include "http_log.h"
#include "http_protocol.h"
#include "http_request.h"
#include "apr_optional.h"

/* Create a set of LDAP_DECLARE macros with appropriate export
 * and import tags for the platform
 */
#if !defined(WIN32)
#define LDAP_DECLARE(type)            type
#define LDAP_DECLARE_NONSTD(type)     type
#define LDAP_DECLARE_DATA
#elif defined(LDAP_DECLARE_STATIC)
#define LDAP_DECLARE(type)            type __stdcall
#define LDAP_DECLARE_NONSTD(type)     type
#define LDAP_DECLARE_DATA
#elif defined(LDAP_DECLARE_EXPORT)
#define LDAP_DECLARE(type)            __declspec(dllexport) type __stdcall
#define LDAP_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define LDAP_DECLARE_DATA             __declspec(dllexport)
#else
#define LDAP_DECLARE(type)            __declspec(dllimport) type __stdcall
#define LDAP_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define LDAP_DECLARE_DATA             __declspec(dllimport)
#endif

#if APR_HAS_MICROSOFT_LDAPSDK
#define timeval l_timeval
#endif

#ifdef __cplusplus
extern "C" {
#endif

/*
 * LDAP Connections
 */

/* Values that the deref member can have */
typedef enum {
    never=LDAP_DEREF_NEVER,
    searching=LDAP_DEREF_SEARCHING,
    finding=LDAP_DEREF_FINDING,
    always=LDAP_DEREF_ALWAYS
} deref_options;

/* Structure representing an LDAP connection */
typedef struct util_ldap_connection_t {
    LDAP *ldap;
    apr_pool_t *pool;                   /* Pool from which this connection is created */
#if APR_HAS_THREADS
    apr_thread_mutex_t *lock;           /* Lock to indicate this connection is in use */
#endif

    const char *host;                   /* Name of the LDAP server (or space separated list) */
    int port;                           /* Port of the LDAP server */
    deref_options deref;                /* how to handle alias dereferening */

    const char *binddn;                 /* DN to bind to server (can be NULL) */
    const char *bindpw;                 /* Password to bind to server (can be NULL) */

    int bound;                          /* Flag to indicate whether this connection is bound yet */

    int secure;                         /* SSL/TLS mode of the connection */
    apr_array_header_t *client_certs;   /* Client certificates on this connection */

    const char *reason;                 /* Reason for an error failure */

    struct util_ldap_connection_t *next;
    struct util_ldap_state_t *st;        /* The LDAP vhost config this connection belongs to */
    int keep;                            /* Will this connection be kept when it's unlocked */

    int ChaseReferrals;                 /* [on|off] (default = AP_LDAP_CHASEREFERRALS_ON)*/
    int ReferralHopLimit;               /* # of referral hops to follow (default = AP_LDAP_DEFAULT_HOPLIMIT) */
    apr_time_t freed;                   /* the time this conn was placed back in the pool */
    apr_pool_t *rebind_pool;            /* frequently cleared pool for rebind data */
    int must_rebind;                    /* The connection was last bound with other then binddn/bindpw */
    request_rec *r;                     /* request_rec used to find this util_ldap_connection_t */
    apr_time_t last_backend_conn;       /* the approximate time of the last backend LDAP request */
} util_ldap_connection_t;

typedef struct util_ldap_config_t {
    int ChaseReferrals;
    int ReferralHopLimit;
    apr_array_header_t *client_certs;  /* Client certificates */
} util_ldap_config_t;

/* LDAP cache state information */
typedef struct util_ldap_state_t {
    apr_pool_t *pool;           /* pool from which this state is allocated */
#if APR_HAS_THREADS
    apr_thread_mutex_t *mutex;          /* mutex lock for the connection list */
#endif
    apr_global_mutex_t *util_ldap_cache_lock;

    apr_size_t cache_bytes;     /* Size (in bytes) of shared memory cache */
    char *cache_file;           /* filename for shm */
    long search_cache_ttl;      /* TTL for search cache */
    long search_cache_size;     /* Size (in entries) of search cache */
    long compare_cache_ttl;     /* TTL for compare cache */
    long compare_cache_size;    /* Size (in entries) of compare cache */

    struct util_ldap_connection_t *connections;
    apr_array_header_t *global_certs;  /* Global CA certificates */
    int   ssl_supported;
    int   secure;
    int   secure_set;
    int   verify_svr_cert;

#if APR_HAS_SHARED_MEMORY
    apr_shm_t *cache_shm;
    apr_rmm_t *cache_rmm;
#endif

    /* cache ald */
    void *util_ldap_cache;

    long  connectionTimeout;
    struct timeval *opTimeout;

    int debug_level;                    /* SDK debug level */
    apr_interval_time_t connection_pool_ttl;
    int retries;                        /* number of retries for failed bind/search/compare */
    apr_interval_time_t retry_delay;    /* delay between retries of failed bind/search/compare */
} util_ldap_state_t;

/* Used to store arrays of attribute labels/values. */
struct mod_auth_ldap_groupattr_entry_t {
    char *name;
};

/**
 * Open a connection to an LDAP server
 * @param ldc A structure containing the expanded details of the server
 *            to connect to. The handle to the LDAP connection is returned
 *            as ldc->ldap.
 * @tip This function connects to the LDAP server and binds. It does not
 *      connect if already connected (ldc->ldap != NULL). Does not bind
 *      if already bound.
 * @return If successful LDAP_SUCCESS is returned.
 * @fn int util_ldap_connection_open(request_rec *r,
 *                                        util_ldap_connection_t *ldc)
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_connection_open,(request_rec *r,
                                            util_ldap_connection_t *ldc));

/**
 * Close a connection to an LDAP server
 * @param ldc A structure containing the expanded details of the server
 *            that was connected.
 * @tip This function unbinds from the LDAP server, and clears ldc->ldap.
 *      It is possible to rebind to this server again using the same ldc
 *      structure, using apr_ldap_open_connection().
 * @fn util_ldap_close_connection(util_ldap_connection_t *ldc)
 */
APR_DECLARE_OPTIONAL_FN(void,uldap_connection_close,(util_ldap_connection_t *ldc));

/**
 * Unbind a connection to an LDAP server
 * @param ldc A structure containing the expanded details of the server
 *            that was connected.
 * @tip This function unbinds the LDAP connection, and disconnects from
 *      the server. It is used during error conditions, to bring the LDAP
 *      connection back to a known state.
 * @fn apr_status_t util_ldap_connection_unbind(util_ldap_connection_t *ldc)
 */
APR_DECLARE_OPTIONAL_FN(apr_status_t,uldap_connection_unbind,(void *param));

/**
 * Find a connection in a list of connections
 * @param r The request record
 * @param host The hostname to connect to (multiple hosts space separated)
 * @param port The port to connect to
 * @param binddn The DN to bind with
 * @param bindpw The password to bind with
 * @param deref The dereferencing behavior
 * @param secure use SSL on the connection
 * @tip Once a connection is found and returned, a lock will be acquired to
 *      lock that particular connection, so that another thread does not try and
 *      use this connection while it is busy. Once you are finished with a connection,
 *      apr_ldap_connection_close() must be called to release this connection.
 * @fn util_ldap_connection_t *util_ldap_connection_find(request_rec *r, const char *host, int port,
 *                                                           const char *binddn, const char *bindpw, deref_options deref,
 *                                                           int netscapessl, int starttls)
 */
APR_DECLARE_OPTIONAL_FN(util_ldap_connection_t *,uldap_connection_find,(request_rec *r, const char *host, int port,
                                                  const char *binddn, const char *bindpw, deref_options deref,
                                                  int secure));

/**
 * Compare two DNs for sameness
 * @param r The request record
 * @param ldc The LDAP connection being used.
 * @param url The URL of the LDAP connection - used for deciding which cache to use.
 * @param dn The first DN to compare.
 * @param reqdn The DN to compare the first DN to.
 * @param compare_dn_on_server Flag to determine whether the DNs should be checked using
 *                             LDAP calls or with a direct string comparison. A direct
 *                             string comparison is faster, but not as accurate - false
 *                             negative comparisons are possible.
 * @tip Two DNs can be equal and still fail a string comparison. Eg "dc=example,dc=com"
 *      and "dc=example, dc=com". Use the compare_dn_on_server unless there are serious
 *      performance issues.
 * @fn int util_ldap_cache_comparedn(request_rec *r, util_ldap_connection_t *ldc,
 *                                        const char *url, const char *dn, const char *reqdn,
 *                                        int compare_dn_on_server)
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_cache_comparedn,(request_rec *r, util_ldap_connection_t *ldc,
                              const char *url, const char *dn, const char *reqdn,
                              int compare_dn_on_server));

/**
 * A generic LDAP compare function
 * @param r The request record
 * @param ldc The LDAP connection being used.
 * @param url The URL of the LDAP connection - used for deciding which cache to use.
 * @param dn The DN of the object in which we do the compare.
 * @param attrib The attribute within the object we are comparing for.
 * @param value The value of the attribute we are trying to compare for.
 * @tip Use this function to determine whether an attribute/value pair exists within an
 *      object. Typically this would be used to determine LDAP top-level group
 *      membership.
 * @fn int util_ldap_cache_compare(request_rec *r, util_ldap_connection_t *ldc,
 *                                      const char *url, const char *dn, const char *attrib, const char *value)
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_cache_compare,(request_rec *r, util_ldap_connection_t *ldc,
                            const char *url, const char *dn, const char *attrib, const char *value));

/**
 * An LDAP function that checks if the specified user is a member of a subgroup.
 * @param r The request record
 * @param ldc The LDAP connection being used.
 * @param url The URL of the LDAP connection - used for deciding which cache to use.
 * @param dn The DN of the object in which we find subgroups to search within.
 * @param attrib The attribute within group objects that identify users.
 * @param value The user attribute value we are trying to compare for.
 * @param subgroupAttrs The attributes within group objects that identify subgroups.
 *                      Array of strings.
 * @param subgroupclasses The objectClass values used to identify groups (and
 *                      subgroups). apr_array_header_t *.
 * @param cur_subgroup_depth Current recursive depth during subgroup processing.
 * @param max_subgroup_depth Maximum depth of recursion allowed during subgroup
 *                           processing.
 * @tip Use this function to determine whether an attribute/value pair exists within a
 *      starting group object or one of its nested subgroups. Typically this would be
 *      used to determine LDAP nested group membership.
 * @deffunc int util_ldap_cache_check_subgroups(request_rec *r, util_ldap_connection_t
 *                                      *ldc, const char *url, const char *dn,
 *                                      const char *attrib, const char value,
 *                                      char **subgroupAttrs, apr_array_header_t
 *                                      *subgroupclasses, int cur_subgroup_depth, int
 *                                      max_subgroup_depth )
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_cache_check_subgroups,(request_rec *r, util_ldap_connection_t *ldc,
                                       const char *url, const char *dn, const char *attrib, const char *value,
                                       char **subgroupAttrs, apr_array_header_t *subgroupclasses,
                                       int cur_subgroup_depth, int max_subgroup_depth));

/**
 * Checks a username/password combination by binding to the LDAP server
 * @param r The request record
 * @param ldc The LDAP connection being used.
 * @param url The URL of the LDAP connection - used for deciding which cache to use.
 * @param basedn The Base DN to search for the user in.
 * @param scope LDAP scope of the search.
 * @param attrs LDAP attributes to return in search.
 * @param filter The user to search for in the form of an LDAP filter. This filter must return
 *               exactly one user for the check to be successful.
 * @param bindpw The user password to bind as.
 * @param binddn The DN of the user will be returned in this variable.
 * @param retvals The values corresponding to the attributes requested in the attrs array.
 * @tip The filter supplied will be searched for. If a single entry is returned, an attempt
 *      is made to bind as that user. If this bind succeeds, the user is not validated.
 * @fn int util_ldap_cache_checkuserid(request_rec *r, util_ldap_connection_t *ldc,
 *                                          char *url, const char *basedn, int scope, char **attrs,
 *                                          char *filter, char *bindpw, char **binddn, char ***retvals)
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_cache_checkuserid,(request_rec *r, util_ldap_connection_t *ldc,
                              const char *url, const char *basedn, int scope, char **attrs,
                              const char *filter, const char *bindpw, const char **binddn, const char ***retvals));

/**
 * Searches for a specified user object in an LDAP directory
 * @param r The request record
 * @param ldc The LDAP connection being used.
 * @param url The URL of the LDAP connection - used for deciding which cache to use.
 * @param basedn The Base DN to search for the user in.
 * @param scope LDAP scope of the search.
 * @param attrs LDAP attributes to return in search.
 * @param filter The user to search for in the form of an LDAP filter. This filter must return
 *               exactly one user for the check to be successful.
 * @param binddn The DN of the user will be returned in this variable.
 * @param retvals The values corresponding to the attributes requested in the attrs array.
 * @tip The filter supplied will be searched for. If a single entry is returned, an attempt
 *      is made to bind as that user. If this bind succeeds, the user is not validated.
 * @fn int util_ldap_cache_getuserdn(request_rec *r, util_ldap_connection_t *ldc,
 *                                          char *url, const char *basedn, int scope, char **attrs,
 *                                          char *filter, char **binddn, char ***retvals)
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_cache_getuserdn,(request_rec *r, util_ldap_connection_t *ldc,
                              const char *url, const char *basedn, int scope, char **attrs,
                              const char *filter, const char **binddn, const char ***retvals));

/**
 * Checks if SSL support is available in mod_ldap
 * @fn int util_ldap_ssl_supported(request_rec *r)
 */
APR_DECLARE_OPTIONAL_FN(int,uldap_ssl_supported,(request_rec *r));

/* from apr_ldap_cache.c */

/**
 * Init the LDAP cache
 * @param pool The pool to use to initialise the cache
 * @param reqsize The size of the shared memory segment to request. A size
 *                of zero requests the max size possible from
 *                apr_shmem_init()
 * @fn void util_ldap_cache_init(apr_pool_t *p, util_ldap_state_t *st)
 * @return The status code returned is the status code of the
 *         apr_smmem_init() call. Regardless of the status, the cache
 *         will be set up at least for in-process or in-thread operation.
 */
apr_status_t util_ldap_cache_init(apr_pool_t *pool, util_ldap_state_t *st);

/* from apr_ldap_cache_mgr.c */

/**
 * Display formatted stats for cache
 * @param The pool to allocate the returned string from
 * @tip This function returns a string allocated from the provided pool that describes
 *      various stats about the cache.
 * @fn char *util_ald_cache_display(apr_pool_t *pool, util_ldap_state_t *st)
 */
char *util_ald_cache_display(request_rec *r, util_ldap_state_t *st);
#ifdef __cplusplus
}
#endif
#endif /* APR_HAS_LDAP */
#endif /* UTIL_LDAP_H */
