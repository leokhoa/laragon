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

#ifndef MOD_PROXY_H
#define MOD_PROXY_H

/**
 * @file  mod_proxy.h
 * @brief Proxy Extension Module for Apache
 *
 * @defgroup MOD_PROXY mod_proxy
 * @ingroup  APACHE_MODS
 * @{
 */

#include "apr_hooks.h"
#include "apr_optional.h"
#include "apr.h"
#include "apr_lib.h"
#include "apr_strings.h"
#include "apr_buckets.h"
#include "apr_md5.h"
#include "apr_network_io.h"
#include "apr_pools.h"
#include "apr_strings.h"
#include "apr_uri.h"
#include "apr_date.h"
#include "apr_strmatch.h"
#include "apr_fnmatch.h"
#include "apr_reslist.h"
#define APR_WANT_STRFUNC
#include "apr_want.h"
#include "apr_uuid.h"
#include "util_mutex.h"
#include "apr_global_mutex.h"
#include "apr_thread_mutex.h"

#include "httpd.h"
#include "http_config.h"
#include "ap_config.h"
#include "http_core.h"
#include "http_protocol.h"
#include "http_request.h"
#include "http_vhost.h"
#include "http_main.h"
#include "http_log.h"
#include "http_connection.h"
#include "http_ssl.h"
#include "util_filter.h"
#include "util_ebcdic.h"
#include "ap_provider.h"
#include "ap_slotmem.h"

#if APR_HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#if APR_HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif

/* for proxy_canonenc() */
enum enctype {
    enc_path, enc_search, enc_user, enc_fpath, enc_parm
};

/* Flags for ap_proxy_canonenc_ex */
#define PROXY_CANONENC_FORCEDEC 0x01
#define PROXY_CANONENC_NOENCODEDSLASHENCODING 0x02

typedef enum {
    NONE, TCP, OPTIONS, HEAD, GET, CPING, PROVIDER, OPTIONS11, HEAD11, GET11, EOT
} hcmethod_t;

typedef struct {
    hcmethod_t method;
    char *name;
    int implemented;
} proxy_hcmethods_t;

typedef struct {
    unsigned int bit;
    char flag;
    const char *name;
} proxy_wstat_t;

#define BALANCER_PREFIX "balancer://"

#if APR_CHARSET_EBCDIC
#define CRLF   "\r\n"
#else /*APR_CHARSET_EBCDIC*/
#define CRLF   "\015\012"
#endif /*APR_CHARSET_EBCDIC*/

/* default Max-Forwards header setting */
/* Set this to -1, which complies with RFC2616 by not setting
 * max-forwards if the client didn't send it to us.
 */
#define DEFAULT_MAX_FORWARDS    -1

typedef struct proxy_balancer  proxy_balancer;
typedef struct proxy_worker    proxy_worker;
typedef struct proxy_conn_pool proxy_conn_pool;
typedef struct proxy_balancer_method proxy_balancer_method;

/* static information about a remote proxy */
struct proxy_remote {
    const char *scheme;     /* the schemes handled by this proxy, or '*' */
    const char *protocol;   /* the scheme used to talk to this proxy */
    const char *hostname;   /* the hostname of this proxy */
    ap_regex_t *regexp;     /* compiled regex (if any) for the remote */
    int use_regex;          /* simple boolean. True if we have a regex pattern */
    apr_port_t  port;       /* the port for this proxy */
};

#define PROXYPASS_NOCANON 0x01
#define PROXYPASS_INTERPOLATE 0x02
#define PROXYPASS_NOQUERY 0x04
#define PROXYPASS_MAP_ENCODED 0x08
#define PROXYPASS_MAP_SERVLET 0x18 /* + MAP_ENCODED */
struct proxy_alias {
    const char  *real;
    const char  *fake;
    ap_regex_t  *regex;
    unsigned int flags;
    proxy_balancer *balancer; /* only valid for reverse-proxys */
};

struct dirconn_entry {
    char *name;
    struct in_addr addr, mask;
    struct apr_sockaddr_t *hostaddr;
    int (*matcher) (struct dirconn_entry * This, request_rec *r);
};

struct noproxy_entry {
    const char *name;
    struct apr_sockaddr_t *addr;
};

typedef struct {
    apr_array_header_t *proxies;
    apr_array_header_t *sec_proxy;
    apr_array_header_t *aliases;
    apr_array_header_t *noproxies;
    apr_array_header_t *dirconn;
    apr_array_header_t *workers;    /* non-balancer workers, eg ProxyPass http://example.com */
    apr_array_header_t *balancers;  /* list of balancers @ config time */
    proxy_worker       *forward;    /* forward proxy worker */
    proxy_worker       *reverse;    /* reverse "module-driven" proxy worker */
    const char *domain;     /* domain name to use in absence of a domain name in the request */
    const char *id;
    apr_pool_t *pool;       /* Pool used for allocating this struct's elements */
    int req;                /* true if proxy requests are enabled */
    int max_balancers;      /* maximum number of allowed balancers */
    int bgrowth;            /* number of post-config balancers can added */
    enum {
      via_off,
      via_on,
      via_block,
      via_full
    } viaopt;                   /* how to deal with proxy Via: headers */
    apr_size_t recv_buffer_size;
    apr_size_t io_buffer_size;
    long maxfwd;
    apr_interval_time_t timeout;
    enum {
      bad_error,
      bad_ignore,
      bad_body
    } badopt;                   /* how to deal with bad headers */
    enum {
        status_off,
        status_on,
        status_full
    } proxy_status;             /* Status display options */
    apr_sockaddr_t *source_address;
    apr_global_mutex_t  *mutex; /* global lock, for pool, etc */
    ap_slotmem_instance_t *bslot;  /* balancers shm data - runtime */
    ap_slotmem_provider_t *storage;

    unsigned int req_set:1;
    unsigned int viaopt_set:1;
    unsigned int recv_buffer_size_set:1;
    unsigned int io_buffer_size_set:1;
    unsigned int maxfwd_set:1;
    unsigned int timeout_set:1;
    unsigned int badopt_set:1;
    unsigned int proxy_status_set:1;
    unsigned int source_address_set:1;
    unsigned int bgrowth_set:1;
    unsigned int bal_persist:1;
    unsigned int inherit:1;
    unsigned int inherit_set:1;
    unsigned int ppinherit:1;
    unsigned int ppinherit_set:1;
    unsigned int map_encoded_one:1;
    unsigned int map_encoded_all:1;
} proxy_server_conf;

typedef struct {
    const char *p;            /* The path */
    ap_regex_t  *r;            /* Is this a regex? */

/* FIXME
 * ProxyPassReverse and friends are documented as working inside
 * <Location>.  But in fact they never have done in the case of
 * more than one <Location>, because the server_conf can't see it.
 * We need to move them to the per-dir config.
 * Discussed in February 2005:
 * http://marc.theaimsgroup.com/?l=apache-httpd-dev&m=110726027118798&w=2
 */
    apr_array_header_t *raliases;
    apr_array_header_t* cookie_paths;
    apr_array_header_t* cookie_domains;
    signed char p_is_fnmatch; /* Is the path an fnmatch candidate? */
    signed char interpolate_env;
    struct proxy_alias *alias;

    /**
     * the following setting masks the error page
     * returned from the 'proxied server' and just
     * forwards the status code upwards.
     * This allows the main server (us) to generate
     * the error page, (so it will look like a error
     * returned from the rest of the system
     */
    unsigned int error_override:1;
    unsigned int preserve_host:1;
    unsigned int preserve_host_set:1;
    unsigned int error_override_set:1;
    unsigned int alias_set:1;
    unsigned int add_forwarded_headers:1;
    unsigned int add_forwarded_headers_set:1;

    /** Named back references */
    apr_array_header_t *refs;

    unsigned int forward_100_continue:1;
    unsigned int forward_100_continue_set:1;

    apr_array_header_t *error_override_codes;
} proxy_dir_conf;

/* if we interpolate env vars per-request, we'll need a per-request
 * copy of the reverse proxy config
 */
typedef struct {
    apr_array_header_t *raliases;
    apr_array_header_t* cookie_paths;
    apr_array_header_t* cookie_domains;
} proxy_req_conf;

typedef struct {
    conn_rec     *connection;
    request_rec  *r;           /* Request record of the backend request
                                * that is used over the backend connection. */
    proxy_worker *worker;      /* Connection pool this connection belongs to */
    apr_pool_t   *pool;        /* Subpool for hostname and addr data */
    const char   *hostname;
    apr_sockaddr_t *addr;      /* Preparsed remote address info */
    apr_pool_t   *scpool;      /* Subpool used for socket and connection data */
    apr_socket_t *sock;        /* Connection socket */
    void         *data;        /* per scheme connection data */
    void         *forward;     /* opaque forward proxy data */
    apr_uint32_t flags;        /* Connection flags */
    apr_port_t   port;
    unsigned int is_ssl:1;
    unsigned int close:1;      /* Close 'this' connection */
    unsigned int need_flush:1; /* Flag to decide whether we need to flush the
                                * filter chain or not */
    unsigned int inreslist:1;  /* connection in apr_reslist? */
    const char   *uds_path;    /* Unix domain socket path */
    const char   *ssl_hostname;/* Hostname (SNI) in use by SSL connection */
    apr_bucket_brigade *tmp_bb;/* Temporary brigade created with the connection
                                * and its scpool/bucket_alloc (NULL before),
                                * must be left cleaned when used (locally).
                                */
} proxy_conn_rec;

typedef struct {
        float cache_completion; /* completion percentage */
        int content_length; /* length of the content */
} proxy_completion;

/* Connection pool */
struct proxy_conn_pool {
    apr_pool_t     *pool;     /* The pool used in constructor and destructor calls */
    apr_sockaddr_t *addr;     /* Preparsed remote address info */
    apr_reslist_t  *res;      /* Connection resource list */
    proxy_conn_rec *conn;     /* Single connection for prefork mpm */
    apr_pool_t     *dns_pool; /* The pool used for worker scoped DNS resolutions */
};

#define AP_VOLATILIZE_T(T, x) (*(T volatile *)&(x))

/* worker status bits */
/*
 * NOTE: Keep up-to-date w/ proxy_wstat_tbl[]
 * in mod_proxy.c !
 */
#define PROXY_WORKER_INITIALIZED    0x0001
#define PROXY_WORKER_IGNORE_ERRORS  0x0002
#define PROXY_WORKER_DRAIN          0x0004
#define PROXY_WORKER_GENERIC        0x0008
#define PROXY_WORKER_IN_SHUTDOWN    0x0010
#define PROXY_WORKER_DISABLED       0x0020
#define PROXY_WORKER_STOPPED        0x0040
#define PROXY_WORKER_IN_ERROR       0x0080
#define PROXY_WORKER_HOT_STANDBY    0x0100
#define PROXY_WORKER_FREE           0x0200
#define PROXY_WORKER_HC_FAIL        0x0400
#define PROXY_WORKER_HOT_SPARE      0x0800

/* worker status flags */
#define PROXY_WORKER_INITIALIZED_FLAG    'O'
#define PROXY_WORKER_IGNORE_ERRORS_FLAG  'I'
#define PROXY_WORKER_DRAIN_FLAG          'N'
#define PROXY_WORKER_GENERIC_FLAG        'G'
#define PROXY_WORKER_IN_SHUTDOWN_FLAG    'U'
#define PROXY_WORKER_DISABLED_FLAG       'D'
#define PROXY_WORKER_STOPPED_FLAG        'S'
#define PROXY_WORKER_IN_ERROR_FLAG       'E'
#define PROXY_WORKER_HOT_STANDBY_FLAG    'H'
#define PROXY_WORKER_FREE_FLAG           'F'
#define PROXY_WORKER_HC_FAIL_FLAG        'C'
#define PROXY_WORKER_HOT_SPARE_FLAG      'R'

#define PROXY_WORKER_NOT_USABLE_BITMAP ( PROXY_WORKER_IN_SHUTDOWN | \
PROXY_WORKER_DISABLED | PROXY_WORKER_STOPPED | PROXY_WORKER_IN_ERROR | \
PROXY_WORKER_HC_FAIL )

/* NOTE: these check the shared status */
#define PROXY_WORKER_IS_INITIALIZED(f)  ( (f)->s->status &  PROXY_WORKER_INITIALIZED )

#define PROXY_WORKER_IS_STANDBY(f)   ( (f)->s->status &  PROXY_WORKER_HOT_STANDBY )

#define PROXY_WORKER_IS_SPARE(f)   ( (f)->s->status &  PROXY_WORKER_HOT_SPARE )

#define PROXY_WORKER_IS_USABLE(f)   ( ( !( (f)->s->status & PROXY_WORKER_NOT_USABLE_BITMAP) ) && \
  PROXY_WORKER_IS_INITIALIZED(f) )

#define PROXY_WORKER_IS_DRAINING(f)   ( (f)->s->status &  PROXY_WORKER_DRAIN )

#define PROXY_WORKER_IS_GENERIC(f)   ( (f)->s->status &  PROXY_WORKER_GENERIC )

#define PROXY_WORKER_IS_HCFAILED(f)   ( (f)->s->status &  PROXY_WORKER_HC_FAIL )

#define PROXY_WORKER_IS_ERROR(f)   ( (f)->s->status &  PROXY_WORKER_IN_ERROR )

#define PROXY_WORKER_IS(f, b)   ( (f)->s->status & (b) )

/* default worker retry timeout in seconds */
#define PROXY_WORKER_DEFAULT_RETRY    60

/* Some max char string sizes, for shm fields */
#define PROXY_WORKER_MAX_SCHEME_SIZE    16
#define PROXY_WORKER_MAX_ROUTE_SIZE     64
#define PROXY_BALANCER_MAX_ROUTE_SIZE PROXY_WORKER_MAX_ROUTE_SIZE
#define PROXY_WORKER_MAX_NAME_SIZE      96
#define PROXY_BALANCER_MAX_NAME_SIZE PROXY_WORKER_MAX_NAME_SIZE
#define PROXY_WORKER_MAX_HOSTNAME_SIZE  64
#define PROXY_BALANCER_MAX_HOSTNAME_SIZE PROXY_WORKER_MAX_HOSTNAME_SIZE
#define PROXY_BALANCER_MAX_STICKY_SIZE  64
#define PROXY_WORKER_MAX_SECRET_SIZE     64

#define PROXY_RFC1035_HOSTNAME_SIZE	256
#define PROXY_WORKER_EXT_NAME_SIZE      384

/* RFC-1035 mentions limits of 255 for host-names and 253 for domain-names,
 * dotted together(?) this would fit the below size (+ trailing NUL).
 */
#define PROXY_WORKER_RFC1035_NAME_SIZE  512

#define PROXY_MAX_PROVIDER_NAME_SIZE    16

#define PROXY_STRNCPY(dst, src) ap_proxy_strncpy((dst), (src), (sizeof(dst)))

#define PROXY_COPY_CONF_PARAMS(w, c) \
do {                             \
(w)->s->timeout              = (c)->timeout;               \
(w)->s->timeout_set          = (c)->timeout_set;           \
(w)->s->recv_buffer_size     = (c)->recv_buffer_size;      \
(w)->s->recv_buffer_size_set = (c)->recv_buffer_size_set;  \
(w)->s->io_buffer_size       = (c)->io_buffer_size;        \
(w)->s->io_buffer_size_set   = (c)->io_buffer_size_set;    \
} while (0)

#define PROXY_SHOULD_PING_100_CONTINUE(w, r) \
    ((w)->s->ping_timeout_set \
     && (PROXYREQ_REVERSE == (r)->proxyreq) \
     && ap_request_has_body((r)))

#define PROXY_DO_100_CONTINUE(w, r) \
    (PROXY_SHOULD_PING_100_CONTINUE(w, r) \
     && !apr_table_get((r)->subprocess_env, "force-proxy-request-1.0"))

/* use 2 hashes */
typedef struct {
    unsigned int def;
    unsigned int fnv;
} proxy_hashes ;

/* Runtime worker status information. Shared in scoreboard */
/* The addition of member uds_path in 2.4.7 was an incompatible API change. */
typedef struct {
    char      name[PROXY_WORKER_MAX_NAME_SIZE];
    char      scheme[PROXY_WORKER_MAX_SCHEME_SIZE];   /* scheme to use ajp|http|https */
    char      hostname[PROXY_WORKER_MAX_HOSTNAME_SIZE];  /* remote backend address (deprecated, use hostname_ex below) */
    char      route[PROXY_WORKER_MAX_ROUTE_SIZE];     /* balancing route */
    char      redirect[PROXY_WORKER_MAX_ROUTE_SIZE];  /* temporary balancing redirection route */
    char      flusher[PROXY_WORKER_MAX_SCHEME_SIZE];  /* flush provider used by mod_proxy_fdpass */
    char      uds_path[PROXY_WORKER_MAX_NAME_SIZE];   /* path to worker's unix domain socket if applicable */
    int             lbset;      /* load balancer cluster set */
    int             retries;    /* number of retries on this worker */
    int             lbstatus;   /* Current lbstatus */
    int             lbfactor;   /* dynamic lbfactor */
    int             min;        /* Desired minimum number of available connections */
    int             smax;       /* Soft maximum on the total number of connections */
    int             hmax;       /* Hard maximum on the total number of connections */
    int             flush_wait; /* poll wait time in microseconds if flush_auto */
    int             index;      /* shm array index */
    proxy_hashes    hash;       /* hash of worker name */
    unsigned int    status;     /* worker status bitfield */
    enum {
        flush_off,
        flush_on,
        flush_auto
    } flush_packets;           /* control AJP flushing */
    apr_time_t      updated;    /* timestamp of last update for dynamic workers, or queue-time of HC workers */
    apr_time_t      error_time; /* time of the last error */
    apr_interval_time_t ttl;    /* maximum amount of time in seconds a connection
                                 * may be available while exceeding the soft limit */
    apr_interval_time_t retry;   /* retry interval */
    apr_interval_time_t timeout; /* connection timeout */
    apr_interval_time_t acquire; /* acquire timeout when the maximum number of connections is exceeded */
    apr_interval_time_t ping_timeout;
    apr_interval_time_t conn_timeout;
    apr_size_t      recv_buffer_size;
    apr_size_t      io_buffer_size;
    apr_size_t      elected;    /* Number of times the worker was elected */
    apr_size_t      busy;       /* busyness factor */
    apr_port_t      port;
    apr_off_t       transferred;/* Number of bytes transferred to remote */
    apr_off_t       read;       /* Number of bytes read from remote */
    void            *context;   /* general purpose storage */
    unsigned int     keepalive:1;
    unsigned int     disablereuse:1;
    unsigned int     is_address_reusable:1;
    unsigned int     retry_set:1;
    unsigned int     timeout_set:1;
    unsigned int     acquire_set:1;
    unsigned int     ping_timeout_set:1;
    unsigned int     conn_timeout_set:1;
    unsigned int     recv_buffer_size_set:1;
    unsigned int     io_buffer_size_set:1;
    unsigned int     keepalive_set:1;
    unsigned int     disablereuse_set:1;
    unsigned int     was_malloced:1;
    unsigned int     is_name_matchable:1;
    char      hcuri[PROXY_WORKER_MAX_ROUTE_SIZE];     /* health check uri */
    char      hcexpr[PROXY_WORKER_MAX_SCHEME_SIZE];   /* name of condition expr for health check */
    int             passes;     /* number of successes for check to pass */
    int             pcount;     /* current count of passes */
    int             fails;      /* number of failures for check to fail */
    int             fcount;     /* current count of failures */
    hcmethod_t      method;     /* method to use for health check */
    apr_interval_time_t interval;
    char      upgrade[PROXY_WORKER_MAX_SCHEME_SIZE];/* upgrade protocol used by mod_proxy_wstunnel */
    char      hostname_ex[PROXY_RFC1035_HOSTNAME_SIZE];  /* RFC1035 compliant version of the remote backend address */
    apr_size_t   response_field_size; /* Size of proxy response buffer in bytes. */
    unsigned int response_field_size_set:1;
    char      secret[PROXY_WORKER_MAX_SECRET_SIZE]; /* authentication secret (e.g. AJP13) */
    char      name_ex[PROXY_WORKER_EXT_NAME_SIZE]; /* Extended name (>96 chars for 2.4.x) */
} proxy_worker_shared;

#define ALIGNED_PROXY_WORKER_SHARED_SIZE (APR_ALIGN_DEFAULT(sizeof(proxy_worker_shared)))

/* Worker configuration */
struct proxy_worker {
    proxy_hashes    hash;       /* hash of worker name */
    unsigned int local_status;  /* status of per-process worker */
    proxy_conn_pool     *cp;    /* Connection pool to use */
    proxy_worker_shared   *s;   /* Shared data */
    proxy_balancer  *balancer;  /* which balancer am I in? */
#if APR_HAS_THREADS
    apr_thread_mutex_t  *tmutex; /* Thread lock for updating address cache */
#endif
    void            *context;   /* general purpose storage */
    ap_conf_vector_t *section_config; /* <Proxy>-section wherein defined */
};

/* default to health check every 30 seconds */
#define HCHECK_WATHCHDOG_DEFAULT_INTERVAL (30)
/* The watchdog runs every 2 seconds, which is also the minimal check */
#define HCHECK_WATHCHDOG_INTERVAL (2)

/*
 * Time to wait (in microseconds) to find out if more data is currently
 * available at the backend.
 */
#define PROXY_FLUSH_WAIT 10000

typedef struct {
    char      sticky_path[PROXY_BALANCER_MAX_STICKY_SIZE];     /* URL sticky session identifier */
    char      sticky[PROXY_BALANCER_MAX_STICKY_SIZE];          /* sticky session identifier */
    char      lbpname[PROXY_MAX_PROVIDER_NAME_SIZE];  /* lbmethod provider name */
    char      nonce[APR_UUID_FORMATTED_LENGTH + 1];
    char      name[PROXY_BALANCER_MAX_NAME_SIZE];
    char      sname[PROXY_BALANCER_MAX_NAME_SIZE];
    char      vpath[PROXY_BALANCER_MAX_ROUTE_SIZE];
    char      vhost[PROXY_BALANCER_MAX_HOSTNAME_SIZE];
    apr_interval_time_t timeout;  /* Timeout for waiting on free connection */
    apr_time_t      wupdated;     /* timestamp of last change to workers list */
    int             max_attempts;     /* Number of attempts before failing */
    int             index;      /* shm array index */
    proxy_hashes hash;
    unsigned int    sticky_force:1;   /* Disable failover for sticky sessions */
    unsigned int    scolonsep:1;      /* true if ';' seps sticky session paths */
    unsigned int    max_attempts_set:1;
    unsigned int    was_malloced:1;
    unsigned int    need_reset:1;
    unsigned int    vhosted:1;
    unsigned int    inactive:1;
    unsigned int    forcerecovery:1;
    char      sticky_separator;                                /* separator for sessionid/route */
    unsigned int    forcerecovery_set:1;
    unsigned int    scolonsep_set:1;
    unsigned int    sticky_force_set:1; 
    unsigned int    nonce_set:1;
    unsigned int    sticky_separator_set:1;
} proxy_balancer_shared;

#define ALIGNED_PROXY_BALANCER_SHARED_SIZE (APR_ALIGN_DEFAULT(sizeof(proxy_balancer_shared)))

struct proxy_balancer {
    apr_array_header_t *workers;  /* initially configured workers */
    apr_array_header_t *errstatuses;  /* statuses to force members into error */
    ap_slotmem_instance_t *wslot;  /* worker shm data - runtime */
    ap_slotmem_provider_t *storage;
    int growth;                   /* number of post-config workers can added */
    int max_workers;              /* maximum number of allowed workers */
    proxy_hashes hash;
    apr_time_t      wupdated;    /* timestamp of last change to workers list */
    proxy_balancer_method *lbmethod;
    apr_global_mutex_t  *gmutex; /* global lock for updating list of workers */
#if APR_HAS_THREADS
    apr_thread_mutex_t  *tmutex; /* Thread lock for updating shm */
#endif
    proxy_server_conf *sconf;
    void            *context;    /* general purpose storage */
    proxy_balancer_shared *s;    /* Shared data */
    int failontimeout;           /* Whether to mark a member in Err if IO timeout occurs */
    unsigned int failontimeout_set:1;
    unsigned int growth_set:1;
    unsigned int lbmethod_set:1;
    ap_conf_vector_t *section_config; /* <Proxy>-section wherein defined */
};

struct proxy_balancer_method {
    const char *name;            /* name of the load balancer method*/
    proxy_worker *(*finder)(proxy_balancer *balancer,
                            request_rec *r);
    void            *context;   /* general purpose storage */
    apr_status_t (*reset)(proxy_balancer *balancer, server_rec *s);
    apr_status_t (*age)(proxy_balancer *balancer, server_rec *s);
    apr_status_t (*updatelbstatus)(proxy_balancer *balancer, proxy_worker *elected, server_rec *s);
};

#define PROXY_THREAD_LOCK(x)      ( (x) && (x)->tmutex ? apr_thread_mutex_lock((x)->tmutex) : APR_SUCCESS)
#define PROXY_THREAD_UNLOCK(x)    ( (x) && (x)->tmutex ? apr_thread_mutex_unlock((x)->tmutex) : APR_SUCCESS)

#define PROXY_GLOBAL_LOCK(x)      ( (x) && (x)->gmutex ? apr_global_mutex_lock((x)->gmutex) : APR_SUCCESS)
#define PROXY_GLOBAL_UNLOCK(x)    ( (x) && (x)->gmutex ? apr_global_mutex_unlock((x)->gmutex) : APR_SUCCESS)

/* hooks */

/* Create a set of PROXY_DECLARE(type), PROXY_DECLARE_NONSTD(type) and
 * PROXY_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(WIN32)
#define PROXY_DECLARE(type)            type
#define PROXY_DECLARE_NONSTD(type)     type
#define PROXY_DECLARE_DATA
#elif defined(PROXY_DECLARE_STATIC)
#define PROXY_DECLARE(type)            type __stdcall
#define PROXY_DECLARE_NONSTD(type)     type
#define PROXY_DECLARE_DATA
#elif defined(PROXY_DECLARE_EXPORT)
#define PROXY_DECLARE(type)            __declspec(dllexport) type __stdcall
#define PROXY_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define PROXY_DECLARE_DATA             __declspec(dllexport)
#else
#define PROXY_DECLARE(type)            __declspec(dllimport) type __stdcall
#define PROXY_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define PROXY_DECLARE_DATA             __declspec(dllimport)
#endif

/* Using PROXY_DECLARE_OPTIONAL_HOOK instead of
 * APR_DECLARE_EXTERNAL_HOOK allows build/make_nw_export.awk
 * to distinguish between hooks that implement
 * proxy_hook_xx and proxy_hook_get_xx in mod_proxy.c and
 * those which don't.
 */
#define PROXY_DECLARE_OPTIONAL_HOOK APR_DECLARE_EXTERNAL_HOOK

/* These 2 are in mod_proxy.c */
extern PROXY_DECLARE_DATA proxy_hcmethods_t proxy_hcmethods[];
extern PROXY_DECLARE_DATA proxy_wstat_t proxy_wstat_tbl[];

/* Following 4 from health check */
APR_DECLARE_OPTIONAL_FN(void, hc_show_exprs, (request_rec *));
APR_DECLARE_OPTIONAL_FN(void, hc_select_exprs, (request_rec *, const char *));
APR_DECLARE_OPTIONAL_FN(int, hc_valid_expr, (request_rec *, const char *));
APR_DECLARE_OPTIONAL_FN(const char *, set_worker_hc_param,
                        (apr_pool_t *, server_rec *, proxy_worker *,
                         const char *, const char *, void *));

APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, section_post_config,
                          (apr_pool_t *p, apr_pool_t *plog,
                           apr_pool_t *ptemp, server_rec *s,
                           ap_conf_vector_t *section_config))

APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, scheme_handler,
                          (request_rec *r, proxy_worker *worker,
                           proxy_server_conf *conf, char *url,
                           const char *proxyhost, apr_port_t proxyport))
APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, check_trans,
                          (request_rec *r, const char *url))
APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, canon_handler,
                          (request_rec *r, char *url))

APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, create_req, (request_rec *r, request_rec *pr))
APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, fixups, (request_rec *r))


/**
 * pre request hook.
 * It will return the most suitable worker at the moment
 * and corresponding balancer.
 * The url is rewritten from balancer://cluster/uri to scheme://host:port/uri
 * and then the scheme_handler is called.
 *
 */
APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, pre_request, (proxy_worker **worker,
                          proxy_balancer **balancer,
                          request_rec *r,
                          proxy_server_conf *conf, char **url))
/**
 * post request hook.
 * It is called after request for updating runtime balancer status.
 */
APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, post_request, (proxy_worker *worker,
                          proxy_balancer *balancer, request_rec *r,
                          proxy_server_conf *conf))

/**
 * request status hook
 * It is called after all proxy processing has been done.  This gives other
 * modules a chance to create default content on failure, for example
 */
APR_DECLARE_EXTERNAL_HOOK(proxy, PROXY, int, request_status,
                          (int *status, request_rec *r))

/* proxy_util.c */

PROXY_DECLARE(apr_status_t) ap_proxy_strncpy(char *dst, const char *src,
                                             apr_size_t dlen);
PROXY_DECLARE(int) ap_proxy_hex2c(const char *x);
PROXY_DECLARE(void) ap_proxy_c2hex(int ch, char *x);
PROXY_DECLARE(char *)ap_proxy_canonenc_ex(apr_pool_t *p, const char *x, int len, enum enctype t,
                                          int flags, int proxyreq);
PROXY_DECLARE(char *)ap_proxy_canonenc(apr_pool_t *p, const char *x, int len, enum enctype t,
                                       int forcedec, int proxyreq);
PROXY_DECLARE(char *)ap_proxy_canon_netloc(apr_pool_t *p, char **const urlp, char **userp,
                                           char **passwordp, char **hostp, apr_port_t *port);
PROXY_DECLARE(int) ap_proxyerror(request_rec *r, int statuscode, const char *message);
PROXY_DECLARE(int) ap_proxy_checkproxyblock(request_rec *r, proxy_server_conf *conf, apr_sockaddr_t *uri_addr);

/** Test whether the hostname/address of the request are blocked by the ProxyBlock
 * configuration.
 * @param r         request
 * @param conf      server configuration
 * @param hostname  hostname from request URI
 * @param addr      resolved address of hostname, or NULL if not known
 * @return OK on success, or else an error
 */
PROXY_DECLARE(int) ap_proxy_checkproxyblock2(request_rec *r, proxy_server_conf *conf, 
                                             const char *hostname, apr_sockaddr_t *addr);

PROXY_DECLARE(int) ap_proxy_pre_http_request(conn_rec *c, request_rec *r);
/* DEPRECATED (will be replaced with ap_proxy_connect_backend */
PROXY_DECLARE(int) ap_proxy_connect_to_backend(apr_socket_t **, const char *, apr_sockaddr_t *, const char *, proxy_server_conf *, request_rec *);
/* DEPRECATED (will be replaced with ap_proxy_check_connection */
PROXY_DECLARE(apr_status_t) ap_proxy_ssl_connection_cleanup(proxy_conn_rec *conn,
                                                            request_rec *r);
PROXY_DECLARE(int) ap_proxy_ssl_enable(conn_rec *c);
PROXY_DECLARE(int) ap_proxy_ssl_disable(conn_rec *c);
PROXY_DECLARE(int) ap_proxy_ssl_engine(conn_rec *c,
                                       ap_conf_vector_t *per_dir_config,
                                       int enable);
PROXY_DECLARE(int) ap_proxy_conn_is_https(conn_rec *c);
PROXY_DECLARE(const char *) ap_proxy_ssl_val(apr_pool_t *p, server_rec *s, conn_rec *c, request_rec *r, const char *var);

/* Header mapping functions, and a typedef of their signature */
PROXY_DECLARE(const char *) ap_proxy_location_reverse_map(request_rec *r, proxy_dir_conf *conf, const char *url);
PROXY_DECLARE(const char *) ap_proxy_cookie_reverse_map(request_rec *r, proxy_dir_conf *conf, const char *str);

#if !defined(WIN32)
typedef const char *(*ap_proxy_header_reverse_map_fn)(request_rec *,
                       proxy_dir_conf *, const char *);
#elif defined(PROXY_DECLARE_STATIC)
typedef const char *(__stdcall *ap_proxy_header_reverse_map_fn)(request_rec *,
                                 proxy_dir_conf *, const char *);
#elif defined(PROXY_DECLARE_EXPORT)
typedef __declspec(dllexport) const char *
  (__stdcall *ap_proxy_header_reverse_map_fn)(request_rec *,
               proxy_dir_conf *, const char *);
#else
typedef __declspec(dllimport) const char *
  (__stdcall *ap_proxy_header_reverse_map_fn)(request_rec *,
               proxy_dir_conf *, const char *);
#endif


/* Connection pool API */
/**
 * Return the user-land, UDS aware worker name
 * @param p        memory pool used for displaying worker name
 * @param worker   the worker
 * @return         name
 */

PROXY_DECLARE(char *) ap_proxy_worker_name(apr_pool_t *p,
                                           proxy_worker *worker);

/**
 * Return whether a worker upgrade configuration matches Upgrade header
 * @param p       memory pool used for displaying worker name
 * @param worker  the worker
 * @param upgrade the Upgrade header to match
 * @param dflt    default protocol (NULL for none)
 * @return        1 (true) or 0 (false)
 */
PROXY_DECLARE(int) ap_proxy_worker_can_upgrade(apr_pool_t *p,
                                               const proxy_worker *worker,
                                               const char *upgrade,
                                               const char *dflt);

/* Bitmask for ap_proxy_{define,get}_worker_ex(). */
#define AP_PROXY_WORKER_IS_PREFIX   (1u << 0)
#define AP_PROXY_WORKER_IS_MATCH    (1u << 1)
#define AP_PROXY_WORKER_IS_MALLOCED (1u << 2)
#define AP_PROXY_WORKER_NO_UDS      (1u << 3)

/**
 * Get the worker from proxy configuration, looking for either PREFIXED or
 * MATCHED or both types of workers according to given mask
 * @param p        memory pool used for finding worker
 * @param balancer the balancer that the worker belongs to
 * @param conf     current proxy server configuration
 * @param url      url to find the worker from
 * @param mask     bitmask of AP_PROXY_WORKER_IS_*
 * @return         proxy_worker or NULL if not found
 */
PROXY_DECLARE(proxy_worker *) ap_proxy_get_worker_ex(apr_pool_t *p,
                                                     proxy_balancer *balancer,
                                                     proxy_server_conf *conf,
                                                     const char *url,
                                                     unsigned int mask);

/**
 * Get the worker from proxy configuration, both types
 * @param p        memory pool used for finding worker
 * @param balancer the balancer that the worker belongs to
 * @param conf     current proxy server configuration
 * @param url      url to find the worker from
 * @return         proxy_worker or NULL if not found
 */
PROXY_DECLARE(proxy_worker *) ap_proxy_get_worker(apr_pool_t *p,
                                                  proxy_balancer *balancer,
                                                  proxy_server_conf *conf,
                                                  const char *url);

/**
 * Define and Allocate space for the worker to proxy configuration, of either
 * PREFIXED or MATCHED type according to given mask
 * @param p         memory pool to allocate worker from
 * @param worker    the new worker
 * @param balancer  the balancer that the worker belongs to
 * @param conf      current proxy server configuration
 * @param url       url containing worker name
 * @param mask      bitmask of AP_PROXY_WORKER_IS_*
 * @return          error message or NULL if successful (*worker is new worker)
 */
PROXY_DECLARE(char *) ap_proxy_define_worker_ex(apr_pool_t *p,
                                             proxy_worker **worker,
                                             proxy_balancer *balancer,
                                             proxy_server_conf *conf,
                                             const char *url,
                                             unsigned int mask);

 /**
 * Define and Allocate space for the worker to proxy configuration
 * @param p         memory pool to allocate worker from
 * @param worker    the new worker
 * @param balancer  the balancer that the worker belongs to
 * @param conf      current proxy server configuration
 * @param url       url containing worker name
 * @param do_malloc true if shared struct should be malloced
 * @return          error message or NULL if successful (*worker is new worker)
 */
PROXY_DECLARE(char *) ap_proxy_define_worker(apr_pool_t *p,
                                             proxy_worker **worker,
                                             proxy_balancer *balancer,
                                             proxy_server_conf *conf,
                                             const char *url,
                                             int do_malloc);

/**
 * Define and Allocate space for the ap_strcmp_match()able worker to proxy
 * configuration.
 * @param p         memory pool to allocate worker from
 * @param worker    the new worker
 * @param balancer  the balancer that the worker belongs to
 * @param conf      current proxy server configuration
 * @param url       url containing worker name (produces match pattern)
 * @param do_malloc true if shared struct should be malloced
 * @return          error message or NULL if successful (*worker is new worker)
 * @deprecated Replaced by ap_proxy_define_worker_ex()
 */
PROXY_DECLARE(char *) ap_proxy_define_match_worker(apr_pool_t *p,
                                             proxy_worker **worker,
                                             proxy_balancer *balancer,
                                             proxy_server_conf *conf,
                                             const char *url,
                                             int do_malloc);

/**
 * Share a defined proxy worker via shm
 * @param worker  worker to be shared
 * @param shm     location of shared info
 * @param i       index into shm
 * @return        APR_SUCCESS or error code
 */
PROXY_DECLARE(apr_status_t) ap_proxy_share_worker(proxy_worker *worker,
                                                  proxy_worker_shared *shm,
                                                  int i);

/**
 * Initialize the worker by setting up worker connection pool and mutex
 * @param worker worker to initialize
 * @param s      current server record
 * @param p      memory pool used for mutex and connection pool
 * @return       APR_SUCCESS or error code
 */
PROXY_DECLARE(apr_status_t) ap_proxy_initialize_worker(proxy_worker *worker,
                                                       server_rec *s,
                                                       apr_pool_t *p);

/**
 * Verifies valid balancer name (eg: balancer://foo)
 * @param name  name to test
 * @param i     number of chars to test; 0 for all.
 * @return      true/false
 */
PROXY_DECLARE(int) ap_proxy_valid_balancer_name(char *name, int i);


/**
 * Get the balancer from proxy configuration
 * @param p     memory pool used for temporary storage while finding balancer
 * @param conf  current proxy server configuration
 * @param url   url to find the worker from; must have balancer:// prefix
 * @param careactive true if we care if the balancer is active or not
 * @return      proxy_balancer or NULL if not found
 */
PROXY_DECLARE(proxy_balancer *) ap_proxy_get_balancer(apr_pool_t *p,
                                                      proxy_server_conf *conf,
                                                      const char *url,
                                                      int careactive);

/**
 * Update the balancer's vhost related fields
 * @param p     memory pool used for temporary storage while finding balancer
 * @param balancer  balancer to be updated
 * @param url   url to find vhost info
 * @return      error string or NULL if OK
 */
PROXY_DECLARE(char *) ap_proxy_update_balancer(apr_pool_t *p,
                                               proxy_balancer *balancer,
                                               const char *url);

/**
 * Define and Allocate space for the balancer to proxy configuration
 * @param p      memory pool to allocate balancer from
 * @param balancer the new balancer
 * @param conf   current proxy server configuration
 * @param url    url containing balancer name
 * @param alias  alias/fake-path to this balancer
 * @param do_malloc true if shared struct should be malloced
 * @return       error message or NULL if successful
 */
PROXY_DECLARE(char *) ap_proxy_define_balancer(apr_pool_t *p,
                                               proxy_balancer **balancer,
                                               proxy_server_conf *conf,
                                               const char *url,
                                               const char *alias,
                                               int do_malloc);

/**
 * Share a defined proxy balancer via shm
 * @param balancer  balancer to be shared
 * @param shm       location of shared info
 * @param i         index into shm
 * @return          APR_SUCCESS or error code
 */
PROXY_DECLARE(apr_status_t) ap_proxy_share_balancer(proxy_balancer *balancer,
                                                    proxy_balancer_shared *shm,
                                                    int i);

/**
 * Initialize the balancer as needed
 * @param balancer balancer to initialize
 * @param s        current server record
 * @param p        memory pool used for mutex and connection pool
 * @return         APR_SUCCESS or error code
 */
PROXY_DECLARE(apr_status_t) ap_proxy_initialize_balancer(proxy_balancer *balancer,
                                                         server_rec *s,
                                                         apr_pool_t *p);

typedef int (proxy_is_best_callback_fn_t)(proxy_worker *current, proxy_worker *prev_best, void *baton);

/**
 * Retrieve the best worker in a balancer for the current request
 * @param balancer balancer for which to find the best worker
 * @param r        current request record
 * @param is_best  a callback function provide by the lbmethod
 *                 that determines if the current worker is best
 * @param baton    an lbmethod-specific context pointer (baton)
 *                 passed to the is_best callback
 * @return         the best worker to be used for the request
 */
PROXY_DECLARE(proxy_worker *) ap_proxy_balancer_get_best_worker(proxy_balancer *balancer,
                                                                request_rec *r,
                                                                proxy_is_best_callback_fn_t *is_best,
                                                                void *baton);
/*
 * Needed by the lb modules.
 */
APR_DECLARE_OPTIONAL_FN(proxy_worker *, proxy_balancer_get_best_worker,
                                        (proxy_balancer *balancer,
                                         request_rec *r,
                                         proxy_is_best_callback_fn_t *is_best,
                                         void *baton));

/**
 * Find the shm of the worker as needed
 * @param storage slotmem provider
 * @param slot    slotmem instance
 * @param worker  worker to find
 * @param index   pointer to index within slotmem of worker
 * @return        pointer to shm of worker, or NULL
 */
PROXY_DECLARE(proxy_worker_shared *) ap_proxy_find_workershm(ap_slotmem_provider_t *storage,
                                                             ap_slotmem_instance_t *slot,
                                                             proxy_worker *worker,
                                                             unsigned int *index);

/**
 * Find the shm of the balancer as needed
 * @param storage  slotmem provider
 * @param slot     slotmem instance
 * @param balancer balancer of shm to find
 * @param index    pointer to index within slotmem of balancer
 * @return         pointer to shm of balancer, or NULL
 */
PROXY_DECLARE(proxy_balancer_shared *) ap_proxy_find_balancershm(ap_slotmem_provider_t *storage,
                                                                 ap_slotmem_instance_t *slot,
                                                                 proxy_balancer *balancer,
                                                                 unsigned int *index);

/**
 * Get the most suitable worker and/or balancer for the request
 * @param worker   worker used for processing request
 * @param balancer balancer used for processing request
 * @param r        current request
 * @param conf     current proxy server configuration
 * @param url      request url that balancer can rewrite.
 * @return         OK or  HTTP_XXX error
 * @note It calls balancer pre_request hook if the url starts with balancer://
 * The balancer then rewrites the url to particular worker, like http://host:port
 */
PROXY_DECLARE(int) ap_proxy_pre_request(proxy_worker **worker,
                                        proxy_balancer **balancer,
                                        request_rec *r,
                                        proxy_server_conf *conf,
                                        char **url);
/**
 * Post request worker and balancer cleanup
 * @param worker   worker used for processing request
 * @param balancer balancer used for processing request
 * @param r        current request
 * @param conf     current proxy server configuration
 * @return         OK or  HTTP_XXX error
 * @note Whenever the pre_request is called, the post_request has to be
 * called too.
 */
PROXY_DECLARE(int) ap_proxy_post_request(proxy_worker *worker,
                                         proxy_balancer *balancer,
                                         request_rec *r,
                                         proxy_server_conf *conf);

/**
 * Determine backend hostname and port
 * @param p       memory pool used for processing
 * @param r       current request
 * @param conf    current proxy server configuration
 * @param worker  worker used for processing request
 * @param conn    proxy connection struct
 * @param uri     processed uri
 * @param url     request url
 * @param proxyname are we connecting directly or via a proxy
 * @param proxyport proxy host port
 * @param server_portstr Via headers server port, must be non-NULL
 * @param server_portstr_size size of the server_portstr buffer; must
 * be at least one, even if the protocol doesn't use this
 * @return         OK or HTTP_XXX error
 */
PROXY_DECLARE(int) ap_proxy_determine_connection(apr_pool_t *p, request_rec *r,
                                                 proxy_server_conf *conf,
                                                 proxy_worker *worker,
                                                 proxy_conn_rec *conn,
                                                 apr_uri_t *uri,
                                                 char **url,
                                                 const char *proxyname,
                                                 apr_port_t proxyport,
                                                 char *server_portstr,
                                                 int server_portstr_size);

/**
 * Mark a worker for retry
 * @param proxy_function calling proxy scheme (http, ajp, ...)
 * @param worker  worker used for retrying
 * @param s       current server record
 * @return        OK if marked for retry, DECLINED otherwise
 * @note The error status of the worker will cleared if the retry interval has
 * elapsed since the last error.
 */
APR_DECLARE_OPTIONAL_FN(int, ap_proxy_retry_worker,
        (const char *proxy_function, proxy_worker *worker, server_rec *s));

/**
 * Acquire a connection from worker connection pool
 * @param proxy_function calling proxy scheme (http, ajp, ...)
 * @param conn    acquired connection
 * @param worker  worker used for obtaining connection
 * @param s       current server record
 * @return        OK or HTTP_XXX error
 * @note If the connection limit has been reached, the function will
 * block until a connection becomes available or the timeout has
 * elapsed.
 */
PROXY_DECLARE(int) ap_proxy_acquire_connection(const char *proxy_function,
                                               proxy_conn_rec **conn,
                                               proxy_worker *worker,
                                               server_rec *s);
/**
 * Release a connection back to worker connection pool
 * @param proxy_function calling proxy scheme (http, ajp, ...)
 * @param conn    acquired connection
 * @param s       current server record
 * @return        OK or HTTP_XXX error
 * @note The connection will be closed if conn->close_on_release is set
 */
PROXY_DECLARE(int) ap_proxy_release_connection(const char *proxy_function,
                                               proxy_conn_rec *conn,
                                               server_rec *s);

#define PROXY_CHECK_CONN_EMPTY (1 << 0)
/**
 * Check a connection to the backend
 * @param scheme calling proxy scheme (http, ajp, ...)
 * @param conn   acquired connection
 * @param server current server record
 * @param max_blank_lines how many blank lines to consume,
 *                        or zero for none (considered data)
 * @param flags  PROXY_CHECK_* bitmask
 * @return APR_SUCCESS: connection established,
 *         APR_ENOTEMPTY: connection established with data,
 *         APR_ENOSOCKET: not connected,
 *         APR_EINVAL: worker in error state (unusable),
 *         other: connection closed/aborted (remotely)
 */
PROXY_DECLARE(apr_status_t) ap_proxy_check_connection(const char *scheme,
                                                      proxy_conn_rec *conn,
                                                      server_rec *server,
                                                      unsigned max_blank_lines,
                                                      int flags);

/**
 * Make a connection to the backend
 * @param proxy_function calling proxy scheme (http, ajp, ...)
 * @param conn    acquired connection
 * @param worker  connection worker
 * @param s       current server record
 * @return        OK or HTTP_XXX error
 * @note In case the socket already exists for conn, just check the link
 * status.
 */
PROXY_DECLARE(int) ap_proxy_connect_backend(const char *proxy_function,
                                            proxy_conn_rec *conn,
                                            proxy_worker *worker,
                                            server_rec *s);

/**
 * Make a connection to a Unix Domain Socket (UDS) path
 * @param sock     UDS to connect
 * @param uds_path UDS path to connect to
 * @param p        pool to make the sock addr
 * @return         APR_SUCCESS or error status
 */
PROXY_DECLARE(apr_status_t) ap_proxy_connect_uds(apr_socket_t *sock,
                                                 const char *uds_path,
                                                 apr_pool_t *p);
/**
 * Make a connection record for backend connection
 * @param proxy_function calling proxy scheme (http, ajp, ...)
 * @param conn    acquired connection
 * @param c       client connection record (unused, deprecated)
 * @param s       current server record
 * @return        OK or HTTP_XXX error
 * @note The function will return immediately if conn->connection
 * is already set,
 */
PROXY_DECLARE(int) ap_proxy_connection_create(const char *proxy_function,
                                              proxy_conn_rec *conn,
                                              conn_rec *c, server_rec *s);

/**
 * Make a connection record for backend connection, using request dir config
 * @param proxy_function calling proxy scheme (http, ajp, ...)
 * @param conn    acquired connection
 * @param r       current request record
 * @return        OK or HTTP_XXX error
 * @note The function will return immediately if conn->connection
 * is already set,
 */
PROXY_DECLARE(int) ap_proxy_connection_create_ex(const char *proxy_function,
                                                 proxy_conn_rec *conn,
                                                 request_rec *r);
/**
 * Determine if proxy connection can potentially be reused at the
 * end of this request.
 * @param conn proxy connection
 * @return non-zero if reusable, 0 otherwise
 * @note Even if this function returns non-zero, the connection may
 * be subsequently marked for closure.
 */
PROXY_DECLARE(int) ap_proxy_connection_reusable(proxy_conn_rec *conn);

/**
 * Signal the upstream chain that the connection to the backend broke in the
 * middle of the response. This is done by sending an error bucket with
 * status HTTP_BAD_GATEWAY and an EOS bucket up the filter chain.
 * @param r       current request record of client request
 * @param brigade The brigade that is sent through the output filter chain
 */
PROXY_DECLARE(void) ap_proxy_backend_broke(request_rec *r,
                                           apr_bucket_brigade *brigade);

/**
 * Return a hash based on the passed string
 * @param str     string to produce hash from
 * @param method  hashing method to use
 * @return        hash as unsigned int
 */

typedef enum { PROXY_HASHFUNC_DEFAULT, PROXY_HASHFUNC_APR,  PROXY_HASHFUNC_FNV } proxy_hash_t;

PROXY_DECLARE(unsigned int) ap_proxy_hashfunc(const char *str, proxy_hash_t method);


/**
 * Set/unset the worker status bitfield depending on flag
 * @param c    flag
 * @param set  set or unset bit
 * @param w    worker to use
 * @return     APR_SUCCESS if valid flag
 */
PROXY_DECLARE(apr_status_t) ap_proxy_set_wstatus(char c, int set, proxy_worker *w);


/**
 * Create readable representation of worker status bitfield
 * @param p  pool
 * @param w  worker to use
 * @return   string representation of status
 */
PROXY_DECLARE(char *) ap_proxy_parse_wstatus(apr_pool_t *p, proxy_worker *w);


/**
 * Sync balancer and workers based on any updates w/i shm
 * @param b  balancer to check/update member list of
 * @param s  server rec
 * @param conf config
 * @return   APR_SUCCESS if all goes well
 */
PROXY_DECLARE(apr_status_t) ap_proxy_sync_balancer(proxy_balancer *b,
                                                   server_rec *s,
                                                   proxy_server_conf *conf);

/**
 * Configure and create workers (and balancer) in mod_balancer.
 * @param r request
 * @param params table with the parameters like b=mycluster etc.
 * @return 404 when the worker/balancer doesn't exist,
 *         400 if something is invalid
 *         200 for success.
 */ 
APR_DECLARE_OPTIONAL_FN(apr_status_t, balancer_manage,
        (request_rec *, apr_table_t *params));

/**
 * Find the matched alias for this request and setup for proxy handler
 * @param r     request
 * @param ent   proxy_alias record
 * @param dconf per-dir config or NULL
 * @return      OK if the alias matched,
 *              DONE if the alias matched and r->uri was normalized so
 *                   no further transformation should happen on it,
 *              DECLINED if proxying is disabled for this alias,
 *              HTTP_CONTINUE if the alias did not match
 */
PROXY_DECLARE(int) ap_proxy_trans_match(request_rec *r,
                                        struct proxy_alias *ent,
                                        proxy_dir_conf *dconf);

/**
 * Create a HTTP request header brigade,  old_cl_val and old_te_val as required.
 * @param p               pool
 * @param header_brigade  header brigade to use/fill
 * @param r               request
 * @param p_conn          proxy connection rec
 * @param worker          selected worker
 * @param conf            per-server proxy config
 * @param uri             uri
 * @param url             url
 * @param server_portstr  port as string
 * @param old_cl_val      stored old content-len val
 * @param old_te_val      stored old TE val
 * @return                OK or HTTP_EXPECTATION_FAILED
 */
PROXY_DECLARE(int) ap_proxy_create_hdrbrgd(apr_pool_t *p,
                                           apr_bucket_brigade *header_brigade,
                                           request_rec *r,
                                           proxy_conn_rec *p_conn,
                                           proxy_worker *worker,
                                           proxy_server_conf *conf,
                                           apr_uri_t *uri,
                                           char *url, char *server_portstr,
                                           char **old_cl_val,
                                           char **old_te_val);

/**
 * Prefetch the client request body (in memory), up to a limit.
 * Read what's in the client pipe. If nonblocking is set and read is EAGAIN,
 * pass a FLUSH bucket to the backend and read again in blocking mode.
 * @param r             client request
 * @param backend       backend connection
 * @param input_brigade input brigade to use/fill
 * @param block         blocking or non-blocking mode
 * @param bytes_read    number of bytes read
 * @param max_read      maximum number of bytes to read
 * @return              OK or HTTP_* error code
 * @note max_read is rounded up to APR_BUCKET_BUFF_SIZE
 */
PROXY_DECLARE(int) ap_proxy_prefetch_input(request_rec *r,
                                           proxy_conn_rec *backend,
                                           apr_bucket_brigade *input_brigade,
                                           apr_read_type_e block,
                                           apr_off_t *bytes_read,
                                           apr_off_t max_read);

/**
 * Spool the client request body to memory, or disk above given limit.
 * @param r             client request
 * @param backend       backend connection
 * @param input_brigade input brigade to use/fill
 * @param bytes_spooled number of bytes spooled
 * @param max_mem_spool maximum number of in-memory bytes
 * @return              OK or HTTP_* error code
 */
PROXY_DECLARE(int) ap_proxy_spool_input(request_rec *r,
                                        proxy_conn_rec *backend,
                                        apr_bucket_brigade *input_brigade,
                                        apr_off_t *bytes_spooled,
                                        apr_off_t max_mem_spool);

/**
 * Read what's in the client pipe. If the read would block (EAGAIN),
 * pass a FLUSH bucket to the backend and read again in blocking mode.
 * @param r             client request
 * @param backend       backend connection
 * @param input_brigade brigade to use/fill
 * @param max_read      maximum number of bytes to read
 * @return              OK or HTTP_* error code
 */
PROXY_DECLARE(int) ap_proxy_read_input(request_rec *r,
                                       proxy_conn_rec *backend,
                                       apr_bucket_brigade *input_brigade,
                                       apr_off_t max_read);

/**
 * @param bucket_alloc  bucket allocator
 * @param r             request
 * @param p_conn        proxy connection
 * @param origin        connection rec of origin
 * @param  bb           brigade to send to origin
 * @param  flush        flush
 * @return              status (OK)
 */
PROXY_DECLARE(int) ap_proxy_pass_brigade(apr_bucket_alloc_t *bucket_alloc,
                                         request_rec *r, proxy_conn_rec *p_conn,
                                         conn_rec *origin, apr_bucket_brigade *bb,
                                         int flush);

struct proxy_tunnel_conn; /* opaque */
typedef struct {
    request_rec *r;
    const char *scheme;
    apr_pollset_t *pollset;
    apr_array_header_t *pfds;
    apr_interval_time_t timeout;
    struct proxy_tunnel_conn *client,
                             *origin;
    apr_size_t read_buf_size;
    int replied; /* TODO 2.5+: one bit to merge in below bitmask */
    unsigned int nohalfclose :1;
} proxy_tunnel_rec;

/**
 * Create a tunnel, to be activated by ap_proxy_tunnel_run().
 * @param tunnel   tunnel created
 * @param r        client request
 * @param c_o      connection to origin
 * @param scheme   caller proxy scheme (connect, ws(s), http(s), ...)
 * @return         APR_SUCCESS or error status
 */
PROXY_DECLARE(apr_status_t) ap_proxy_tunnel_create(proxy_tunnel_rec **tunnel,
                                                   request_rec *r, conn_rec *c_o,
                                                   const char *scheme);

/**
 * Forward anything from either side of the tunnel to the other,
 * until one end aborts or a polling timeout/error occurs.
 * @param tunnel  tunnel to run
 * @return        OK if completion is full, HTTP_GATEWAY_TIME_OUT on timeout
 *                or another HTTP_ error otherwise.
 */
PROXY_DECLARE(int) ap_proxy_tunnel_run(proxy_tunnel_rec *tunnel);

/**
 * Clear the headers referenced by the Connection header from the given
 * table, and remove the Connection header.
 * @param r request
 * @param headers table of headers to clear
 * @return 1 if "close" was present, 0 otherwise.
 */
APR_DECLARE_OPTIONAL_FN(int, ap_proxy_clear_connection,
        (request_rec *r, apr_table_t *headers));

/**
 * Do a AJP CPING and wait for CPONG on the socket
 *
 */
APR_DECLARE_OPTIONAL_FN(apr_status_t, ajp_handle_cping_cpong,
        (apr_socket_t *sock, request_rec *r,
         apr_interval_time_t timeout));


/**
 * @param socket        socket to test
 * @return              TRUE if socket is connected/active
 */
PROXY_DECLARE(int) ap_proxy_is_socket_connected(apr_socket_t *socket);

#define PROXY_LBMETHOD "proxylbmethod"

/* The number of dynamic workers that can be added when reconfiguring.
 * If this limit is reached you must stop and restart the server.
 */
#define PROXY_DYNAMIC_BALANCER_LIMIT    16

/**
 * Calculate maximum number of workers in scoreboard.
 * @return  number of workers to allocate in the scoreboard
 */
int ap_proxy_lb_workers(void);

/**
 * Returns 1 if a response with the given status should be overridden.
 *
 * @param conf   proxy directory configuration
 * @param code   http status code
 * @return       1 if code is considered an error-code, 0 otherwise
 */
PROXY_DECLARE(int) ap_proxy_should_override(proxy_dir_conf *conf, int code);

/**
 * Return the port number of a known scheme (eg: http -> 80).
 * @param scheme        scheme to test
 * @return              port number or 0 if unknown
 */
PROXY_DECLARE(apr_port_t) ap_proxy_port_of_scheme(const char *scheme);

/**
 * Return the name of the health check method (eg: "OPTIONS").
 * @param method        method enum
 * @return              name of method
 */
PROXY_DECLARE (const char *) ap_proxy_show_hcmethod(hcmethod_t method);

/**
 * Strip a unix domain socket (UDS) prefix from the input URL
 * @param p             pool to allocate result from
 * @param url           a URL potentially prefixed with a UDS path
 * @return              URL with the UDS prefix removed
 */
PROXY_DECLARE(const char *) ap_proxy_de_socketfy(apr_pool_t *p, const char *url);

/*
 * Transform buckets from one bucket allocator to another one by creating a
 * transient bucket for each data bucket and let it use the data read from
 * the old bucket. Metabuckets are transformed by just recreating them.
 * Attention: Currently only the following bucket types are handled:
 *
 * All data buckets
 * FLUSH
 * EOS
 *
 * If an other bucket type is found its type is logged as a debug message
 * and APR_EGENERAL is returned.
 *
 * @param r     request_rec of the actual request. Used for logging purposes
 * @param from  the bucket brigade to take the buckets from
 * @param to    the bucket brigade to store the transformed buckets
 * @return      apr_status_t of the operation. Either APR_SUCCESS or
 *              APR_EGENERAL
 */
PROXY_DECLARE(apr_status_t) ap_proxy_buckets_lifetime_transform(request_rec *r,
                                                      apr_bucket_brigade *from,
                                                      apr_bucket_brigade *to);

/* 
 * The flags for ap_proxy_transfer_between_connections(), where for legacy and
 * compatibility reasons FLUSH_EACH and FLUSH_AFTER are boolean values.
 */
#define AP_PROXY_TRANSFER_FLUSH_EACH        (0x00)
#define AP_PROXY_TRANSFER_FLUSH_AFTER       (0x01)
#define AP_PROXY_TRANSFER_YIELD_PENDING     (0x02)
#define AP_PROXY_TRANSFER_YIELD_MAX_READS   (0x04)

/*
 * Sends all data that can be read non blocking from the input filter chain of
 * c_i and send it down the output filter chain of c_o. For reading it uses
 * the bucket brigade bb_i which should be created from the bucket allocator
 * associated with c_i. For sending through the output filter chain it uses
 * the bucket brigade bb_o which should be created from the bucket allocator
 * associated with c_o. In order to get the buckets from bb_i to bb_o
 * ap_proxy_buckets_lifetime_transform is used.
 *
 * @param r     request_rec of the actual request. Used for logging purposes
 * @param c_i   inbound connection conn_rec
 * @param c_o   outbound connection conn_rec
 * @param bb_i  bucket brigade for pulling data from the inbound connection
 * @param bb_o  bucket brigade for sending data through the outbound connection
 * @param name  string for logging from where data was pulled
 * @param sent  if not NULL will be set to 1 if data was sent through c_o
 * @param bsize maximum amount of data pulled in one iteration from c_i
 * @param flags AP_PROXY_TRANSFER_* bitmask
 * @return      apr_status_t of the operation. Could be any error returned from
 *              either the input filter chain of c_i or the output filter chain
 *              of c_o, APR_EPIPE if the outgoing connection was aborted, or
 *              APR_INCOMPLETE if AP_PROXY_TRANSFER_YIELD_PENDING was set and
 *              the output stack gets full before the input stack is exhausted.
 */
PROXY_DECLARE(apr_status_t) ap_proxy_transfer_between_connections(
                                                       request_rec *r,
                                                       conn_rec *c_i,
                                                       conn_rec *c_o,
                                                       apr_bucket_brigade *bb_i,
                                                       apr_bucket_brigade *bb_o,
                                                       const char *name,
                                                       int *sent,
                                                       apr_off_t bsize,
                                                       int flags);

extern module PROXY_DECLARE_DATA proxy_module;

#endif /*MOD_PROXY_H*/
/** @} */
