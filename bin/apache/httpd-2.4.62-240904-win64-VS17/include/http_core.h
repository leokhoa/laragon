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
 * @file  http_core.h
 * @brief CORE HTTP Daemon
 *
 * @defgroup APACHE_CORE_HTTPD Core HTTP Daemon
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_HTTP_CORE_H
#define APACHE_HTTP_CORE_H

#include "apr.h"
#include "apr_hash.h"
#include "apr_optional.h"
#include "util_filter.h"
#include "ap_expr.h"
#include "apr_poll.h"
#include "apr_tables.h"

#include "http_config.h"

#if APR_HAVE_STRUCT_RLIMIT
#include <sys/time.h>
#include <sys/resource.h>
#endif


#ifdef __cplusplus
extern "C" {
#endif

/* ****************************************************************
 *
 * The most basic server code is encapsulated in a single module
 * known as the core, which is just *barely* functional enough to
 * serve documents, though not terribly well.
 *
 * Largely for NCSA back-compatibility reasons, the core needs to
 * make pieces of its config structures available to other modules.
 * The accessors are declared here, along with the interpretation
 * of one of them (allow_options).
 */

/**
 * @defgroup APACHE_CORE_HTTPD_ACESSORS Acessors
 *
 * @brief File/Directory Accessor directives
 *
 * @{
 */

/** No directives */
#define OPT_NONE 0
/** Indexes directive */
#define OPT_INDEXES 1
/** SSI is enabled without exec= permission  */
#define OPT_INCLUDES 2
/**  FollowSymLinks directive */
#define OPT_SYM_LINKS 4
/**  ExecCGI directive */
#define OPT_EXECCGI 8
/**  directive unset */
#define OPT_UNSET 16
/**  SSI exec= permission is permitted, iff OPT_INCLUDES is also set */
#define OPT_INC_WITH_EXEC 32
/** SymLinksIfOwnerMatch directive */
#define OPT_SYM_OWNER 64
/** MultiViews directive */
#define OPT_MULTI 128
/**  All directives */
#define OPT_ALL (OPT_INDEXES|OPT_INCLUDES|OPT_INC_WITH_EXEC|OPT_SYM_LINKS|OPT_EXECCGI)
/** @} */

/**
 * @defgroup get_remote_host Remote Host Resolution
 * @ingroup APACHE_CORE_HTTPD
 * @{
 */
/** REMOTE_HOST returns the hostname, or NULL if the hostname
 * lookup fails.  It will force a DNS lookup according to the
 * HostnameLookups setting.
 */
#define REMOTE_HOST (0)

/** REMOTE_NAME returns the hostname, or the dotted quad if the
 * hostname lookup fails.  It will force a DNS lookup according
 * to the HostnameLookups setting.
 */
#define REMOTE_NAME (1)

/** REMOTE_NOLOOKUP is like REMOTE_NAME except that a DNS lookup is
 * never forced.
 */
#define REMOTE_NOLOOKUP (2)

/** REMOTE_DOUBLE_REV will always force a DNS lookup, and also force
 * a double reverse lookup, regardless of the HostnameLookups
 * setting.  The result is the (double reverse checked) hostname,
 * or NULL if any of the lookups fail.
 */
#define REMOTE_DOUBLE_REV (3)

/** @} // get_remote_host */

/** all of the requirements must be met */
#define SATISFY_ALL 0
/**  any of the requirements must be met */
#define SATISFY_ANY 1
/** There are no applicable satisfy lines */
#define SATISFY_NOSPEC 2

/** Make sure we don't write less than 8000 bytes at any one time.
 */
#define AP_MIN_BYTES_TO_WRITE  8000

/** default maximum of internal redirects */
# define AP_DEFAULT_MAX_INTERNAL_REDIRECTS 10

/** default maximum subrequest nesting level */
# define AP_DEFAULT_MAX_SUBREQ_DEPTH 10

/**
 * Retrieve the value of Options for this request
 * @param r The current request
 * @return the Options bitmask
 */
AP_DECLARE(int) ap_allow_options(request_rec *r);

/**
 * Retrieve the value of the AllowOverride for this request
 * @param r The current request
 * @return the overrides bitmask
 */
AP_DECLARE(int) ap_allow_overrides(request_rec *r);

/**
 * Retrieve the document root for this server
 * @param r The current request
 * @warning Don't use this!  If your request went through a Userdir, or
 * something like that, it'll screw you.  But it's back-compatible...
 * @return The document root
 */
AP_DECLARE(const char *) ap_document_root(request_rec *r);

/**
 * Lookup the remote user agent's DNS name or IP address
 * @ingroup get_remote_host
 * @param req The current request
 * @param type The type of lookup to perform.  One of:
 * <pre>
 *     REMOTE_HOST returns the hostname, or NULL if the hostname
 *                 lookup fails.  It will force a DNS lookup according to the
 *                 HostnameLookups setting.
 *     REMOTE_NAME returns the hostname, or the dotted quad if the
 *                 hostname lookup fails.  It will force a DNS lookup according
 *                 to the HostnameLookups setting.
 *     REMOTE_NOLOOKUP is like REMOTE_NAME except that a DNS lookup is
 *                     never forced.
 *     REMOTE_DOUBLE_REV will always force a DNS lookup, and also force
 *                   a double reverse lookup, regardless of the HostnameLookups
 *                   setting.  The result is the (double reverse checked)
 *                   hostname, or NULL if any of the lookups fail.
 * </pre>
 * @param str_is_ip unless NULL is passed, this will be set to non-zero on
 *        output when an IP address string is returned
 * @return The remote hostname (based on the request useragent_ip)
 */
AP_DECLARE(const char *) ap_get_useragent_host(request_rec *req, int type,
                                               int *str_is_ip);

/**
 * Lookup the remote client's DNS name or IP address
 * @ingroup get_remote_host
 * @param conn The current connection
 * @param dir_config The directory config vector from the request
 * @param type The type of lookup to perform.  One of:
 * <pre>
 *     REMOTE_HOST returns the hostname, or NULL if the hostname
 *                 lookup fails.  It will force a DNS lookup according to the
 *                 HostnameLookups setting.
 *     REMOTE_NAME returns the hostname, or the dotted quad if the
 *                 hostname lookup fails.  It will force a DNS lookup according
 *                 to the HostnameLookups setting.
 *     REMOTE_NOLOOKUP is like REMOTE_NAME except that a DNS lookup is
 *                     never forced.
 *     REMOTE_DOUBLE_REV will always force a DNS lookup, and also force
 *                   a double reverse lookup, regardless of the HostnameLookups
 *                   setting.  The result is the (double reverse checked)
 *                   hostname, or NULL if any of the lookups fail.
 * </pre>
 * @param str_is_ip unless NULL is passed, this will be set to non-zero on output when an IP address
 *        string is returned
 * @return The remote hostname (based on the connection client_ip)
 */
AP_DECLARE(const char *) ap_get_remote_host(conn_rec *conn, void *dir_config, int type, int *str_is_ip);

/**
 * Retrieve the login name of the remote user.  Undef if it could not be
 * determined
 * @param r The current request
 * @return The user logged in to the client machine
 */
AP_DECLARE(const char *) ap_get_remote_logname(request_rec *r);

/* Used for constructing self-referencing URLs, and things like SERVER_PORT,
 * and SERVER_NAME.
 */
/**
 * build a fully qualified URL from the uri and information in the request rec
 * @param p The pool to allocate the URL from
 * @param uri The path to the requested file
 * @param r The current request
 * @return A fully qualified URL
 */
AP_DECLARE(char *) ap_construct_url(apr_pool_t *p, const char *uri, request_rec *r);

/**
 * Get the current server name from the request
 * @param r The current request
 * @return the server name
 */
AP_DECLARE(const char *) ap_get_server_name(request_rec *r);

/**
 * Get the current server name from the request for the purposes
 * of using in a URL.  If the server name is an IPv6 literal
 * address, it will be returned in URL format (e.g., "[fe80::1]").
 * @param r The current request
 * @return the server name
 */
AP_DECLARE(const char *) ap_get_server_name_for_url(request_rec *r);

/**
 * Get the current server port
 * @param r The current request
 * @return The server's port
 */
AP_DECLARE(apr_port_t) ap_get_server_port(const request_rec *r);

/**
 * Get the size of read buffers
 * @param r The current request
 * @return The read buffers size
 */
AP_DECLARE(apr_size_t) ap_get_read_buf_size(const request_rec *r);

/**
 * Return the limit on bytes in request msg body
 * @param r The current request
 * @return the maximum number of bytes in the request msg body
 */
AP_DECLARE(apr_off_t) ap_get_limit_req_body(const request_rec *r);

/**
 * Return the limit on bytes in XML request msg body
 * @param r The current request
 * @return the maximum number of bytes in XML request msg body
 */
AP_DECLARE(apr_size_t) ap_get_limit_xml_body(const request_rec *r);

/**
 * Install a custom response handler for a given status
 * @param r The current request
 * @param status The status for which the custom response should be used
 * @param string The custom response.  This can be a static string, a file
 *               or a URL
 */
AP_DECLARE(void) ap_custom_response(request_rec *r, int status, const char *string);

/**
 * Check if the current request is beyond the configured max. number of redirects or subrequests
 * @param r The current request
 * @return true (is exceeded) or false
 */
AP_DECLARE(int) ap_is_recursion_limit_exceeded(const request_rec *r);

/**
 * Check for a definition from the server command line
 * @param name The define to check for
 * @return 1 if defined, 0 otherwise
 */
AP_DECLARE(int) ap_exists_config_define(const char *name);
/* FIXME! See STATUS about how */
AP_DECLARE_NONSTD(int) ap_core_translate(request_rec *r);

/* Authentication stuff.  This is one of the places where compatibility
 * with the old config files *really* hurts; they don't discriminate at
 * all between different authentication schemes, meaning that we need
 * to maintain common state for all of them in the core, and make it
 * available to the other modules through interfaces.
 */

/** @see require_line */
typedef struct require_line require_line;

/**
 * @brief A structure to keep track of authorization requirements
*/
struct require_line {
    /** Where the require line is in the config file. */
    apr_int64_t method_mask;
    /** The complete string from the command line */
    char *requirement;
};

/**
 * Return the type of authorization required for this request
 * @param r The current request
 * @return The authorization required
 */
AP_DECLARE(const char *) ap_auth_type(request_rec *r);

/**
 * Return the current Authorization realm
 * @param r The current request
 * @return The current authorization realm
 */
AP_DECLARE(const char *) ap_auth_name(request_rec *r);

/**
 * How the requires lines must be met.
 * @param r The current request
 * @return How the requirements must be met.  One of:
 * <pre>
 *      SATISFY_ANY    -- any of the requirements must be met.
 *      SATISFY_ALL    -- all of the requirements must be met.
 *      SATISFY_NOSPEC -- There are no applicable satisfy lines
 * </pre>
 */
AP_DECLARE(int) ap_satisfies(request_rec *r);

/**
 * Core is also unlike other modules in being implemented in more than
 * one file... so, data structures are declared here, even though most of
 * the code that cares really is in http_core.c.  Also, another accessor.
 */
AP_DECLARE_DATA extern module core_module;

/**
 * Accessor for core_module's specific data. Equivalent to
 * ap_get_module_config(cv, &core_module) but more efficient.
 * @param cv The vector in which the modules configuration is stored.
 *        usually r->per_dir_config or s->module_config
 * @return The module-specific data
 */
AP_DECLARE(void *) ap_get_core_module_config(const ap_conf_vector_t *cv);

/**
 * Accessor to set core_module's specific data. Equivalent to
 * ap_set_module_config(cv, &core_module, val) but more efficient.
 * @param cv The vector in which the modules configuration is stored.
 *        usually r->per_dir_config or s->module_config
 * @param val The module-specific data to set
 */
AP_DECLARE(void) ap_set_core_module_config(ap_conf_vector_t *cv, void *val);

/** Get the socket from the core network filter. This should be used instead of
 * accessing the core connection config directly.
 * @param c The connection record
 * @return The socket
 */
AP_DECLARE(apr_socket_t *) ap_get_conn_socket(conn_rec *c);

#ifndef AP_DEBUG
#define AP_CORE_MODULE_INDEX  0
#define ap_get_core_module_config(v) \
    (((void **)(v))[AP_CORE_MODULE_INDEX])
#define ap_set_core_module_config(v, val) \
    ((((void **)(v))[AP_CORE_MODULE_INDEX]) = (val))
#else
#define AP_CORE_MODULE_INDEX  (AP_DEBUG_ASSERT(core_module.module_index == 0), 0)
#endif

/**
 * @brief  Per-request configuration
*/
typedef struct {
    /** bucket brigade used by getline for look-ahead and
     * ap_get_client_block for holding left-over request body */
    struct apr_bucket_brigade *bb;

    /** an array of per-request working data elements, accessed
     * by ID using ap_get_request_note()
     * (Use ap_register_request_note() during initialization
     * to add elements)
     */
    void **notes;

    /** Custom response strings registered via ap_custom_response(),
     * or NULL; check per-dir config if nothing found here
     */
    char **response_code_strings; /* from ap_custom_response(), not from
                                   * ErrorDocument
                                   */

    /** per-request document root of the server. This allows mass vhosting
     * modules better compatibility with some scripts. Normally the
     * context_* info should be used instead */
    const char *document_root;

    /*
     * more fine-grained context information which is set by modules like
     * mod_alias and mod_userdir
     */
    /** the context root directory on disk for the current resource,
     *  without trailing slash
     */
    const char *context_document_root;
    /** the URI prefix that corresponds to the context_document_root directory,
     *  without trailing slash
     */
    const char *context_prefix;

    /** There is a script processor installed on the output filter chain,
     * so it needs the default_handler to deliver a (script) file into
     * the chain so it can process it. Normally, default_handler only
     * serves files on a GET request (assuming the file is actual content),
     * since other methods are not content-retrieval. This flag overrides
     * that behavior, stating that the "content" is actually a script and
     * won't actually be delivered as the response for the non-GET method.
     */
    int deliver_script;

    /** Should addition of charset= be suppressed for this request?
     */
    int suppress_charset;
} core_request_config;

/* Standard entries that are guaranteed to be accessible via
 * ap_get_request_note() for each request (additional entries
 * can be added with ap_register_request_note())
 */
#define AP_NOTE_DIRECTORY_WALK 0
#define AP_NOTE_LOCATION_WALK  1
#define AP_NOTE_FILE_WALK      2
#define AP_NOTE_IF_WALK        3
#define AP_NUM_STD_NOTES       4

/**
 * Reserve an element in the core_request_config->notes array
 * for some application-specific data
 * @return An integer key that can be passed to ap_get_request_note()
 *         during request processing to access this element for the
 *         current request.
 */
AP_DECLARE(apr_size_t) ap_register_request_note(void);

/**
 * Retrieve a pointer to an element in the core_request_config->notes array
 * @param r The request
 * @param note_num  A key for the element: either a value obtained from
 *        ap_register_request_note() or one of the predefined AP_NOTE_*
 *        values.
 * @return NULL if the note_num is invalid, otherwise a pointer to the
 *         requested note element.
 * @remark At the start of a request, each note element is NULL.  The
 *         handle provided by ap_get_request_note() is a pointer-to-pointer
 *         so that the caller can point the element to some app-specific
 *         data structure.  The caller should guarantee that any such
 *         structure will last as long as the request itself.
 */
AP_DECLARE(void **) ap_get_request_note(request_rec *r, apr_size_t note_num);


typedef unsigned char allow_options_t;
typedef unsigned int overrides_t;

/*
 * Bits of info that go into making an ETag for a file
 * document.  Why a long?  Because char historically
 * proved too short for Options, and int can be different
 * sizes on different platforms.
 */
typedef unsigned long etag_components_t;

#define ETAG_UNSET  0
#define ETAG_NONE   (1 << 0)
#define ETAG_MTIME  (1 << 1)
#define ETAG_INODE  (1 << 2)
#define ETAG_SIZE   (1 << 3)
#define ETAG_DIGEST (1 << 4)
#define ETAG_ALL    (ETAG_MTIME | ETAG_INODE | ETAG_SIZE)
/* This is the default value used */
#define ETAG_BACKWARD (ETAG_MTIME | ETAG_SIZE)

/* Generic ON/OFF/UNSET for unsigned int foo :2 */
#define AP_CORE_CONFIG_OFF   (0)
#define AP_CORE_CONFIG_ON    (1)
#define AP_CORE_CONFIG_UNSET (2)

/* Generic merge of flag */
#define AP_CORE_MERGE_FLAG(field, to, base, over) to->field = \
               over->field != AP_CORE_CONFIG_UNSET            \
               ? over->field                                  \
               : base->field                                   

/**
 * @brief Server Signature Enumeration
 */
typedef enum {
    srv_sig_unset,
    srv_sig_off,
    srv_sig_on,
    srv_sig_withmail
} server_signature_e;

/**
 * @brief Per-directory configuration
 */
typedef struct {
    /** path of the directory/regex/etc. see also d_is_fnmatch/absolute below */
    char *d;
    /** the number of slashes in d */
    unsigned d_components;

    /** If (opts & OPT_UNSET) then no absolute assignment to options has
     * been made.
     * invariant: (opts_add & opts_remove) == 0
     * Which said another way means that the last relative (options + or -)
     * assignment made to each bit is recorded in exactly one of opts_add
     * or opts_remove.
     */
    allow_options_t opts;
    allow_options_t opts_add;
    allow_options_t opts_remove;
    overrides_t override;
    allow_options_t override_opts;

    /* Used to be the custom response config. No longer used. */
    char **response_code_strings; /* from ErrorDocument, not from
                                   * ap_custom_response() */

    /* Hostname resolution etc */
#define HOSTNAME_LOOKUP_OFF     0
#define HOSTNAME_LOOKUP_ON      1
#define HOSTNAME_LOOKUP_DOUBLE  2
#define HOSTNAME_LOOKUP_UNSET   3
    unsigned int hostname_lookups : 4;

    unsigned int content_md5 : 2;  /* calculate Content-MD5? */

#define USE_CANONICAL_NAME_OFF   (0)
#define USE_CANONICAL_NAME_ON    (1)
#define USE_CANONICAL_NAME_DNS   (2)
#define USE_CANONICAL_NAME_UNSET (3)
    unsigned use_canonical_name : 2;

    /* since is_fnmatch(conf->d) was being called so frequently in
     * directory_walk() and its relatives, this field was created and
     * is set to the result of that call.
     */
    unsigned d_is_fnmatch : 1;

    /* should we force a charset on any outgoing parameterless content-type?
     * if so, which charset?
     */
#define ADD_DEFAULT_CHARSET_OFF   (0)
#define ADD_DEFAULT_CHARSET_ON    (1)
#define ADD_DEFAULT_CHARSET_UNSET (2)
    unsigned add_default_charset : 2;
    const char *add_default_charset_name;

    /* System Resource Control */
#ifdef RLIMIT_CPU
    struct rlimit *limit_cpu;
#endif
#if defined (RLIMIT_DATA) || defined (RLIMIT_VMEM) || defined(RLIMIT_AS)
    struct rlimit *limit_mem;
#endif
#ifdef RLIMIT_NPROC
    struct rlimit *limit_nproc;
#endif
    apr_off_t limit_req_body;      /* limit on bytes in request msg body */
    long limit_xml_body;           /* limit on bytes in XML request msg body */

    /* logging options */

    server_signature_e server_signature;

    /* Access control */
    apr_array_header_t *sec_file;
    apr_array_header_t *sec_if;
    ap_regex_t *r;

    const char *mime_type;       /* forced with ForceType  */
    const char *handler;         /* forced by something other than SetHandler */
    const char *output_filters;  /* forced with SetOutputFilters */
    const char *input_filters;   /* forced with SetInputFilters */
    int accept_path_info;        /* forced with AcceptPathInfo */

    /*
     * What attributes/data should be included in ETag generation?
     */
    etag_components_t etag_bits;
    etag_components_t etag_add;
    etag_components_t etag_remove;

    /*
     * Run-time performance tuning
     */
#define ENABLE_MMAP_OFF    (0)
#define ENABLE_MMAP_ON     (1)
#define ENABLE_MMAP_UNSET  (2)
    unsigned int enable_mmap : 2;  /* whether files in this dir can be mmap'ed */

#define ENABLE_SENDFILE_OFF    (0)
#define ENABLE_SENDFILE_ON     (1)
#define ENABLE_SENDFILE_UNSET  (2)
    unsigned int enable_sendfile : 2;  /* files in this dir can be sendfile'ed */

#define USE_CANONICAL_PHYS_PORT_OFF   (0)
#define USE_CANONICAL_PHYS_PORT_ON    (1)
#define USE_CANONICAL_PHYS_PORT_UNSET (2)
    unsigned int use_canonical_phys_port : 2;

    unsigned int allow_encoded_slashes : 1; /* URLs may contain %2f w/o being
                                             * pitched indiscriminately */
    unsigned int decode_encoded_slashes : 1; /* whether to decode encoded slashes in URLs */

#define AP_CONDITION_IF        1
#define AP_CONDITION_ELSE      2
#define AP_CONDITION_ELSEIF    (AP_CONDITION_ELSE|AP_CONDITION_IF)
    unsigned int condition_ifelse : 2; /* is this an <If>, <ElseIf>, or <Else> */

    ap_expr_info_t *condition;   /* Conditionally merge <If> sections */

    /** per-dir log config */
    struct ap_logconf *log;

    /** Table of directives allowed per AllowOverrideList */
    apr_table_t *override_list;

#define AP_MAXRANGES_UNSET     -1
#define AP_MAXRANGES_DEFAULT   -2
#define AP_MAXRANGES_UNLIMITED -3
#define AP_MAXRANGES_NORANGES   0
    /** Number of Ranges before returning HTTP_OK. **/
    int max_ranges;
    /** Max number of Range overlaps (merges) allowed **/
    int max_overlaps;
    /** Max number of Range reversals (eg: 200-300, 100-125) allowed **/
    int max_reversals;

    /** Named back references */
    apr_array_header_t *refs;

    /** Custom response config with expression support. The hash table
     * contains compiled expressions keyed against the custom response
     * code.
     */
    apr_hash_t *response_code_exprs;

#define AP_CGI_PASS_AUTH_OFF     (0)
#define AP_CGI_PASS_AUTH_ON      (1)
#define AP_CGI_PASS_AUTH_UNSET   (2)
    /** CGIPassAuth: Whether HTTP authorization headers will be passed to
     * scripts as CGI variables; affects all modules calling
     * ap_add_common_vars(), as well as any others using this field as 
     * advice
     */
    unsigned int cgi_pass_auth : 2;
    unsigned int qualify_redirect_url :2;
    ap_expr_info_t  *expr_handler;         /* forced with SetHandler */

    /** Table of rules for building CGI variables, NULL if none configured */
    apr_hash_t *cgi_var_rules;

    apr_size_t read_buf_size;
} core_dir_config;

/* macro to implement off by default behaviour */
#define AP_SENDFILE_ENABLED(x) \
    ((x) == ENABLE_SENDFILE_ON ? APR_SENDFILE_ENABLED : 0)

/* Per-server core configuration */

typedef struct {

    char *gprof_dir;

    /* Name translations --- we want the core to be able to do *something*
     * so it's at least a minimally functional web server on its own (and
     * can be tested that way).  But let's keep it to the bare minimum:
     */
    const char *ap_document_root;

    /* Access control */

    char *access_name;
    apr_array_header_t *sec_dir;
    apr_array_header_t *sec_url;

    /* recursion backstopper */
    int redirect_limit; /* maximum number of internal redirects */
    int subreq_limit;   /* maximum nesting level of subrequests */

    const char *protocol;
    apr_table_t *accf_map;

    /* array of ap_errorlog_format_item for error log format string */
    apr_array_header_t *error_log_format;
    /*
     * two arrays of arrays of ap_errorlog_format_item for additional information
     * logged to the error log once per connection/request
     */
    apr_array_header_t *error_log_conn;
    apr_array_header_t *error_log_req;

    /* TRACE control */
#define AP_TRACE_UNSET    -1
#define AP_TRACE_DISABLE   0
#define AP_TRACE_ENABLE    1
#define AP_TRACE_EXTENDED  2
    int trace_enable;
#define AP_MERGE_TRAILERS_UNSET    0
#define AP_MERGE_TRAILERS_ENABLE   1
#define AP_MERGE_TRAILERS_DISABLE  2
    int merge_trailers;

    apr_array_header_t *protocols;
    int protocols_honor_order;

#define AP_HTTP09_UNSET   0
#define AP_HTTP09_ENABLE  1
#define AP_HTTP09_DISABLE 2
    char http09_enable;

#define AP_HTTP_CONFORMANCE_UNSET     0
#define AP_HTTP_CONFORMANCE_UNSAFE    1
#define AP_HTTP_CONFORMANCE_STRICT    2
    char http_conformance;

#define AP_HTTP_METHODS_UNSET         0
#define AP_HTTP_METHODS_LENIENT       1
#define AP_HTTP_METHODS_REGISTERED    2
    char http_methods;
    unsigned int merge_slashes;
 
    apr_size_t   flush_max_threshold;
    apr_int32_t  flush_max_pipelined;
    unsigned int strict_host_check;
#ifdef WIN32
    apr_array_header_t *unc_list;
#endif
} core_server_config;

/* for AddOutputFiltersByType in core.c */
void ap_add_output_filters_by_type(request_rec *r);

/* for http_config.c */
void ap_core_reorder_directories(apr_pool_t *, server_rec *);

/* for mod_perl */
AP_CORE_DECLARE(void) ap_add_per_dir_conf(server_rec *s, void *dir_config);
AP_CORE_DECLARE(void) ap_add_per_url_conf(server_rec *s, void *url_config);
AP_CORE_DECLARE(void) ap_add_file_conf(apr_pool_t *p, core_dir_config *conf, void *url_config);
AP_CORE_DECLARE(const char *) ap_add_if_conf(apr_pool_t *p, core_dir_config *conf, void *url_config);
AP_CORE_DECLARE_NONSTD(const char *) ap_limit_section(cmd_parms *cmd, void *dummy, const char *arg);

/* Core filters; not exported. */
apr_status_t ap_core_input_filter(ap_filter_t *f, apr_bucket_brigade *b,
                                  ap_input_mode_t mode, apr_read_type_e block,
                                  apr_off_t readbytes);
apr_status_t ap_core_output_filter(ap_filter_t *f, apr_bucket_brigade *b);


AP_DECLARE(const char*) ap_get_server_protocol(server_rec* s);
AP_DECLARE(void) ap_set_server_protocol(server_rec* s, const char* proto);

typedef struct core_output_filter_ctx core_output_filter_ctx_t;
typedef struct core_filter_ctx        core_ctx_t;

struct core_filter_ctx {
    apr_bucket_brigade *b;
    apr_bucket_brigade *tmpbb;
};

typedef struct core_net_rec {
    /** Connection to the client */
    apr_socket_t *client_socket;

    /** connection record */
    conn_rec *c;

    core_output_filter_ctx_t *out_ctx;
    core_ctx_t *in_ctx;
} core_net_rec;

/**
 * Insert the network bucket into the core input filter's input brigade.
 * This hook is intended for MPMs or protocol modules that need to do special
 * socket setup.
 * @param c The connection
 * @param bb The brigade to insert the bucket into
 * @param socket The socket to put into a bucket
 * @return AP_DECLINED if the current function does not handle this connection,
 *         APR_SUCCESS or an error otherwise.
 */
AP_DECLARE_HOOK(apr_status_t, insert_network_bucket,
                (conn_rec *c, apr_bucket_brigade *bb, apr_socket_t *socket))

/* ----------------------------------------------------------------------
 *
 * Runtime status/management
 */

typedef enum {
    ap_mgmt_type_string,
    ap_mgmt_type_long,
    ap_mgmt_type_hash
} ap_mgmt_type_e;

typedef union {
    const char *s_value;
    long i_value;
    apr_hash_t *h_value;
} ap_mgmt_value;

typedef struct {
    const char *description;
    const char *name;
    ap_mgmt_type_e vtype;
    ap_mgmt_value v;
} ap_mgmt_item_t;

/* Handles for core filters */
AP_DECLARE_DATA extern ap_filter_rec_t *ap_subreq_core_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_core_output_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_content_length_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_core_input_filter_handle;

/**
 * This hook provdes a way for modules to provide metrics/statistics about
 * their operational status.
 *
 * @param p A pool to use to create entries in the hash table
 * @param val The name of the parameter(s) that is wanted. This is
 *            tree-structured would be in the form ('*' is all the tree,
 *            'module.*' all of the module , 'module.foo.*', or
 *            'module.foo.bar' )
 * @param ht The hash table to store the results. Keys are item names, and
 *           the values point to ap_mgmt_item_t structures.
 * @ingroup hooks
 */
AP_DECLARE_HOOK(int, get_mgmt_items,
                (apr_pool_t *p, const char * val, apr_hash_t *ht))

/* ---------------------------------------------------------------------- */

/* ----------------------------------------------------------------------
 *
 * I/O logging with mod_logio
 */

APR_DECLARE_OPTIONAL_FN(void, ap_logio_add_bytes_out,
                        (conn_rec *c, apr_off_t bytes));

APR_DECLARE_OPTIONAL_FN(void, ap_logio_add_bytes_in,
                        (conn_rec *c, apr_off_t bytes));

APR_DECLARE_OPTIONAL_FN(apr_off_t, ap_logio_get_last_bytes, (conn_rec *c));

/* ----------------------------------------------------------------------
 *
 * Error log formats
 */

/**
 * The info structure passed to callback functions of errorlog handlers.
 * Not all information is available in all contexts. In particular, all
 * pointers may be NULL.
 */
typedef struct ap_errorlog_info {
    /** current server_rec.
     *  Should be preferred over c->base_server and r->server
     */
    const server_rec *s;

    /** current conn_rec.
     *  Should be preferred over r->connection
     */
    const conn_rec *c;

    /** current request_rec. */
    const request_rec *r;
    /** r->main if r is a subrequest, otherwise equal to r */
    const request_rec *rmain;

    /** pool passed to ap_log_perror, NULL otherwise */
    apr_pool_t *pool;

    /** name of source file where the log message was produced, NULL if N/A. */
    const char *file;
    /** line number in the source file, 0 if N/A */
    int line;

    /** module index of module that produced the log message, APLOG_NO_MODULE if N/A. */
    int module_index;
    /** log level of error message (flags like APLOG_STARTUP have been removed), -1 if N/A */
    int level;

    /** apr error status related to the log message, 0 if no error */
    apr_status_t status;

    /** 1 if logging to syslog, 0 otherwise */
    int using_syslog;
    /** 1 if APLOG_STARTUP was set for the log message, 0 otherwise */
    int startup;

    /** message format */
    const char *format;
} ap_errorlog_info;

/**
 * callback function prototype for a external errorlog handler
 * @note To avoid unbounded memory usage, these functions must not allocate
 * memory from the server, connection, or request pools. If an errorlog
 * handler absolutely needs a pool to pass to other functions, it must create
 * and destroy a sub-pool.
 */
typedef int ap_errorlog_handler_fn_t(const ap_errorlog_info *info,
                                     const char *arg, char *buf, int buflen);

/**
 * Register external errorlog handler
 * @param p config pool to use
 * @param tag the new format specifier (i.e. the letter after the %)
 * @param handler the handler function
 * @param flags flags (reserved, set to 0)
 */
AP_DECLARE(void) ap_register_errorlog_handler(apr_pool_t *p, char *tag,
                                              ap_errorlog_handler_fn_t *handler,
                                              int flags);

typedef struct ap_errorlog_handler {
    ap_errorlog_handler_fn_t *func;
    int flags; /* for future extensions */
} ap_errorlog_handler;

  /** item starts a new field */
#define AP_ERRORLOG_FLAG_FIELD_SEP       1
  /** item is the actual error message */
#define AP_ERRORLOG_FLAG_MESSAGE         2
  /** skip whole line if item is zero-length */
#define AP_ERRORLOG_FLAG_REQUIRED        4
  /** log zero-length item as '-' */
#define AP_ERRORLOG_FLAG_NULL_AS_HYPHEN  8

typedef struct {
    /** ap_errorlog_handler function */
    ap_errorlog_handler_fn_t *func;
    /** argument passed to item in {} */
    const char *arg;
    /** a combination of the AP_ERRORLOG_* flags */
    unsigned int flags;
    /** only log item if the message's log level is higher than this */
    unsigned int min_loglevel;
} ap_errorlog_format_item;

/**
 * hook method to log error messages
 * @ingroup hooks
 * @param info pointer to ap_errorlog_info struct which contains all
 *        the details
 * @param errstr the (unformatted) message to log
 * @warning Allocating from the usual pools (pool, info->c->pool, info->p->pool)
 *          must be avoided because it can cause memory leaks.
 *          Use a subpool if necessary.
 */
AP_DECLARE_HOOK(void, error_log, (const ap_errorlog_info *info,
                                  const char *errstr))

AP_CORE_DECLARE(void) ap_register_log_hooks(apr_pool_t *p);
AP_CORE_DECLARE(void) ap_register_config_hooks(apr_pool_t *p);

/* ----------------------------------------------------------------------
 *
 * ident lookups with mod_ident
 */

APR_DECLARE_OPTIONAL_FN(const char *, ap_ident_lookup,
                        (request_rec *r));

/* ----------------------------------------------------------------------
 *
 * authorization values with mod_authz_core
 */

APR_DECLARE_OPTIONAL_FN(int, authz_some_auth_required, (request_rec *r));
APR_DECLARE_OPTIONAL_FN(const char *, authn_ap_auth_type, (request_rec *r));
APR_DECLARE_OPTIONAL_FN(const char *, authn_ap_auth_name, (request_rec *r));

/* ----------------------------------------------------------------------
 *
 * authorization values with mod_access_compat
 */

APR_DECLARE_OPTIONAL_FN(int, access_compat_ap_satisfies, (request_rec *r));

/* ---------------------------------------------------------------------- */

/** Query the server for some state information
 * @param query_code Which information is requested
 * @return the requested state information
 */
AP_DECLARE(int) ap_state_query(int query_code);

/*
 * possible values for query_code in ap_state_query()
 */

  /** current status of the server */
#define AP_SQ_MAIN_STATE        0
  /** are we going to serve requests or are we just testing/dumping config */
#define AP_SQ_RUN_MODE          1
    /** generation of the top-level apache parent */
#define AP_SQ_CONFIG_GEN        2

/*
 * return values for ap_state_query()
 */

  /** return value for unknown query_code */
#define AP_SQ_NOT_SUPPORTED       -1

/* values returned for AP_SQ_MAIN_STATE */
  /** before the config preflight */
#define AP_SQ_MS_INITIAL_STARTUP   1
  /** initial configuration run for setting up log config, etc. */
#define AP_SQ_MS_CREATE_PRE_CONFIG 2
  /** tearing down configuration */
#define AP_SQ_MS_DESTROY_CONFIG    3
  /** normal configuration run */
#define AP_SQ_MS_CREATE_CONFIG     4
  /** running the MPM */
#define AP_SQ_MS_RUN_MPM           5
  /** cleaning up for exit */
#define AP_SQ_MS_EXITING           6

/* values returned for AP_SQ_RUN_MODE */
  /** command line not yet parsed */
#define AP_SQ_RM_UNKNOWN           1
  /** normal operation (server requests or signal server) */
#define AP_SQ_RM_NORMAL            2
  /** config test only */
#define AP_SQ_RM_CONFIG_TEST       3
  /** only dump some parts of the config */
#define AP_SQ_RM_CONFIG_DUMP       4

/** Get a apr_pollfd_t populated with descriptor and descriptor type
 * and the timeout to use for it.
 * @return APR_ENOTIMPL if not supported for a connection.
 */
AP_DECLARE_HOOK(apr_status_t, get_pollfd_from_conn,
                (conn_rec *c, struct apr_pollfd_t *pfd,
                 apr_interval_time_t *ptimeout))

/**
 * Pass in a `struct apr_pollfd_t*` and get `desc_type` and `desc`
 * populated with a suitable value for polling connection input.
 * For primary connection (c->master == NULL), this will be the connection
 * socket. For secondary connections this may differ or not be available
 * at all.
 * Note that APR_NO_DESC may be set to indicate that the connection
 * input is already closed.
 *
 * @param pfd  the pollfd to set the descriptor in
 * @param ptimeout  != NULL to retrieve the timeout in effect
 * @return ARP_SUCCESS when the information was assigned.
 */
AP_CORE_DECLARE(apr_status_t) ap_get_pollfd_from_conn(conn_rec *c,
                                      struct apr_pollfd_t *pfd,
                                      apr_interval_time_t *ptimeout);

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_HTTP_CORE_H */
/** @} */
