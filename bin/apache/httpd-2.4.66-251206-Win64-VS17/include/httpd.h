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
 * @file httpd.h
 * @brief HTTP Daemon routines
 *
 * @defgroup APACHE Apache HTTP Server
 *
 * Top level group of which all other groups are a member
 * @{
 *
 * @defgroup APACHE_MODS Loadable modules
 *           Top level group for modules
 * @defgroup APACHE_OS Operating System Specific
 * @defgroup APACHE_INTERNAL Internal interfaces
 * @defgroup APACHE_CORE Core routines
 * @{
 * @defgroup APACHE_CORE_DAEMON HTTP Daemon Routine
 * @{
 */

#ifndef APACHE_HTTPD_H
#define APACHE_HTTPD_H

/* XXX - We need to push more stuff to other .h files, or even .c files, to
 * make this file smaller
 */

/* Headers in which EVERYONE has an interest... */
#include "ap_config.h"
#include "ap_mmn.h"

#include "ap_release.h"

#include "apr.h"
#include "apr_version.h"
#include "apr_general.h"
#include "apr_tables.h"
#include "apr_pools.h"
#include "apr_time.h"
#include "apr_network_io.h"
#include "apr_buckets.h"
#include "apr_poll.h"
#include "apr_thread_proc.h"

#include "os.h"

#include "ap_regex.h"

#if APR_HAVE_STDLIB_H
#include <stdlib.h>
#endif

/* Note: apr_uri.h is also included, see below */

#ifdef __cplusplus
extern "C" {
#endif

/* ----------------------------- config dir ------------------------------ */

/** Define this to be the default server home dir. Most things later in this
 * file with a relative pathname will have this added.
 */
#ifndef HTTPD_ROOT
#ifdef OS2
/** Set default for OS/2 file system */
#define HTTPD_ROOT "/os2httpd"
#elif defined(WIN32)
/** Set default for Windows file system */
#define HTTPD_ROOT "/apache"
#elif defined (NETWARE)
/** Set the default for NetWare */
#define HTTPD_ROOT "/apache"
#else
/** Set for all other OSs */
#define HTTPD_ROOT "/usr/local/apache"
#endif
#endif /* HTTPD_ROOT */

/*
 * --------- You shouldn't have to edit anything below this line ----------
 *
 * Any modifications to any defaults not defined above should be done in the
 * respective configuration file.
 *
 */

/**
 * Default location of documents.  Can be overridden by the DocumentRoot
 * directive.
 */
#ifndef DOCUMENT_LOCATION
#ifdef OS2
/* Set default for OS/2 file system */
#define DOCUMENT_LOCATION  HTTPD_ROOT "/docs"
#else
/* Set default for non OS/2 file system */
#define DOCUMENT_LOCATION  HTTPD_ROOT "/htdocs"
#endif
#endif /* DOCUMENT_LOCATION */

/** Maximum number of dynamically loaded modules */
#ifndef DYNAMIC_MODULE_LIMIT
#define DYNAMIC_MODULE_LIMIT 256
#endif

/** Default administrator's address */
#define DEFAULT_ADMIN "[no address given]"

/** The name of the log files */
#ifndef DEFAULT_ERRORLOG
#if defined(OS2) || defined(WIN32)
#define DEFAULT_ERRORLOG "logs/error.log"
#else
#define DEFAULT_ERRORLOG "logs/error_log"
#endif
#endif /* DEFAULT_ERRORLOG */

/** Define this to be what your per-directory security files are called */
#ifndef DEFAULT_ACCESS_FNAME
#ifdef OS2
/* Set default for OS/2 file system */
#define DEFAULT_ACCESS_FNAME "htaccess"
#else
#define DEFAULT_ACCESS_FNAME ".htaccess"
#endif
#endif /* DEFAULT_ACCESS_FNAME */

/** The name of the server config file */
#ifndef SERVER_CONFIG_FILE
#define SERVER_CONFIG_FILE "conf/httpd.conf"
#endif

/** The default path for CGI scripts if none is currently set */
#ifndef DEFAULT_PATH
#define DEFAULT_PATH "/bin:/usr/bin:/usr/ucb:/usr/bsd:/usr/local/bin"
#endif

/** The path to the suExec wrapper, can be overridden in Configuration */
#ifndef SUEXEC_BIN
#define SUEXEC_BIN  HTTPD_ROOT "/bin/suexec"
#endif

/** The timeout for waiting for messages */
#ifndef DEFAULT_TIMEOUT
#define DEFAULT_TIMEOUT 60
#endif

/** The timeout for waiting for keepalive timeout until next request */
#ifndef DEFAULT_KEEPALIVE_TIMEOUT
#define DEFAULT_KEEPALIVE_TIMEOUT 5
#endif

/** The number of requests to entertain per connection */
#ifndef DEFAULT_KEEPALIVE
#define DEFAULT_KEEPALIVE 100
#endif

/*
 * Limits on the size of various request items.  These limits primarily
 * exist to prevent simple denial-of-service attacks on a server based
 * on misuse of the protocol.  The recommended values will depend on the
 * nature of the server resources -- CGI scripts and database backends
 * might require large values, but most servers could get by with much
 * smaller limits than we use below.  The request message body size can
 * be limited by the per-dir config directive LimitRequestBody.
 *
 * Internal buffer sizes are two bytes more than the DEFAULT_LIMIT_REQUEST_LINE
 * and DEFAULT_LIMIT_REQUEST_FIELDSIZE below, which explains the 8190.
 * These two limits can be lowered or raised by the server config
 * directives LimitRequestLine and LimitRequestFieldsize, respectively.
 *
 * DEFAULT_LIMIT_REQUEST_FIELDS can be modified or disabled (set = 0) by
 * the server config directive LimitRequestFields.
 */

/** default limit on bytes in Request-Line (Method+URI+HTTP-version) */
#ifndef DEFAULT_LIMIT_REQUEST_LINE
#define DEFAULT_LIMIT_REQUEST_LINE 8190
#endif
/** default limit on bytes in any one header field  */
#ifndef DEFAULT_LIMIT_REQUEST_FIELDSIZE
#define DEFAULT_LIMIT_REQUEST_FIELDSIZE 8190
#endif
/** default limit on number of request header fields */
#ifndef DEFAULT_LIMIT_REQUEST_FIELDS
#define DEFAULT_LIMIT_REQUEST_FIELDS 100
#endif
/** default/hard limit on number of leading/trailing empty lines */
#ifndef DEFAULT_LIMIT_BLANK_LINES
#define DEFAULT_LIMIT_BLANK_LINES 10
#endif

/**
 * The default default character set name to add if AddDefaultCharset is
 * enabled.  Overridden with AddDefaultCharsetName.
 */
#define DEFAULT_ADD_DEFAULT_CHARSET_NAME "iso-8859-1"

/** default HTTP Server protocol */
#define AP_SERVER_PROTOCOL "HTTP/1.1"


/* ------------------ stuff that modules are allowed to look at ----------- */

/** Define this to be what your HTML directory content files are called */
#ifndef AP_DEFAULT_INDEX
#define AP_DEFAULT_INDEX "index.html"
#endif

/** The name of the MIME types file */
#ifndef AP_TYPES_CONFIG_FILE
#define AP_TYPES_CONFIG_FILE "conf/mime.types"
#endif

/*
 * Define the HTML doctype strings centrally.
 */
/** HTML 2.0 Doctype */
#define DOCTYPE_HTML_2_0  "<!DOCTYPE HTML PUBLIC \"-//IETF//" \
                          "DTD HTML 2.0//EN\">\n"
/** HTML 3.2 Doctype */
#define DOCTYPE_HTML_3_2  "<!DOCTYPE HTML PUBLIC \"-//W3C//" \
                          "DTD HTML 3.2 Final//EN\">\n"
/** HTML 4.0 Strict Doctype */
#define DOCTYPE_HTML_4_0S "<!DOCTYPE HTML PUBLIC \"-//W3C//" \
                          "DTD HTML 4.0//EN\"\n" \
                          "\"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
/** HTML 4.0 Transitional Doctype */
#define DOCTYPE_HTML_4_0T "<!DOCTYPE HTML PUBLIC \"-//W3C//" \
                          "DTD HTML 4.0 Transitional//EN\"\n" \
                          "\"http://www.w3.org/TR/REC-html40/loose.dtd\">\n"
/** HTML 4.0 Frameset Doctype */
#define DOCTYPE_HTML_4_0F "<!DOCTYPE HTML PUBLIC \"-//W3C//" \
                          "DTD HTML 4.0 Frameset//EN\"\n" \
                          "\"http://www.w3.org/TR/REC-html40/frameset.dtd\">\n"
/** HTML 4.01 Doctype */
#define DOCTYPE_HTML_4_01 "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n"
/** HTML 5 Doctype */
#define DOCTYPE_HTML_5 "<!DOCTYPE html>\n"
/** XHTML 1.0 Strict Doctype */
#define DOCTYPE_XHTML_1_0S "<!DOCTYPE html PUBLIC \"-//W3C//" \
                           "DTD XHTML 1.0 Strict//EN\"\n" \
                           "\"http://www.w3.org/TR/xhtml1/DTD/" \
                           "xhtml1-strict.dtd\">\n"
/** XHTML 1.0 Transitional Doctype */
#define DOCTYPE_XHTML_1_0T "<!DOCTYPE html PUBLIC \"-//W3C//" \
                           "DTD XHTML 1.0 Transitional//EN\"\n" \
                           "\"http://www.w3.org/TR/xhtml1/DTD/" \
                           "xhtml1-transitional.dtd\">\n"
/** XHTML 1.0 Frameset Doctype */
#define DOCTYPE_XHTML_1_0F "<!DOCTYPE html PUBLIC \"-//W3C//" \
                           "DTD XHTML 1.0 Frameset//EN\"\n" \
                           "\"http://www.w3.org/TR/xhtml1/DTD/" \
                           "xhtml1-frameset.dtd\">"

/** Internal representation for a HTTP protocol number, e.g., HTTP/1.1 */
#define HTTP_VERSION(major,minor) (1000*(major)+(minor))
/** Major part of HTTP protocol */
#define HTTP_VERSION_MAJOR(number) ((number)/1000)
/** Minor part of HTTP protocol */
#define HTTP_VERSION_MINOR(number) ((number)%1000)

/* -------------- Port number for server running standalone --------------- */

/** default HTTP Port */
#define DEFAULT_HTTP_PORT       80
/** default HTTPS Port */
#define DEFAULT_HTTPS_PORT      443
/**
 * Check whether @a port is the default port for the request @a r.
 * @param port The port number
 * @param r The request
 * @see #ap_default_port
 */
#define ap_is_default_port(port,r)      ((port) == ap_default_port(r))
/**
 * Get the default port for a request (which depends on the scheme).
 * @param r The request
 */
#define ap_default_port(r)      ap_run_default_port(r)
/**
 * Get the scheme for a request.
 * @param r The request
 */
#define ap_http_scheme(r)       ap_run_http_scheme(r)

/** The default string length */
#define MAX_STRING_LEN HUGE_STRING_LEN

/** The length of a Huge string */
#define HUGE_STRING_LEN 8192

/** The size of the server's internal read-write buffers */
#define AP_IOBUFSIZE 8192

/** The max number of regex captures that can be expanded by ap_pregsub */
#define AP_MAX_REG_MATCH 10

/**
 * APR_HAS_LARGE_FILES introduces the problem of splitting sendfile into
 * multiple buckets, no greater than MAX(apr_size_t), and more granular
 * than that in case the brigade code/filters attempt to read it directly.
 * ### 16mb is an invention, no idea if it is reasonable.
 */
#define AP_MAX_SENDFILE 16777216  /* 2^24 */

/**
 * MPM child process exit status values
 * The MPM parent process may check the status to see if special
 * error handling is required.
 */
/** a normal exit */
#define APEXIT_OK               0x0
/** A fatal error arising during the server's init sequence */
#define APEXIT_INIT             0x2
/**  The child died during its init sequence */
#define APEXIT_CHILDINIT        0x3
/**
 *   The child exited due to a resource shortage.
 *   The parent should limit the rate of forking until
 *   the situation is resolved.
 */
#define APEXIT_CHILDSICK        0x7
/**
 *     A fatal error, resulting in the whole server aborting.
 *     If a child exits with this error, the parent process
 *     considers this a server-wide fatal error and aborts.
 */
#define APEXIT_CHILDFATAL       0xf

#ifndef AP_DECLARE
/**
 * Stuff marked #AP_DECLARE is part of the API, and intended for use
 * by modules. Its purpose is to allow us to add attributes that
 * particular platforms or compilers require to every exported function.
 */
# define AP_DECLARE(type)    type
#endif

#ifndef AP_DECLARE_NONSTD
/**
 * Stuff marked #AP_DECLARE_NONSTD is part of the API, and intended for
 * use by modules.  The difference between #AP_DECLARE and
 * #AP_DECLARE_NONSTD is that the latter is required for any functions
 * which use varargs or are used via indirect function call.  This
 * is to accommodate the two calling conventions in windows dlls.
 */
# define AP_DECLARE_NONSTD(type)    type
#endif
#ifndef AP_DECLARE_DATA
# define AP_DECLARE_DATA
#endif

#ifndef AP_MODULE_DECLARE
# define AP_MODULE_DECLARE(type)    type
#endif
#ifndef AP_MODULE_DECLARE_NONSTD
# define AP_MODULE_DECLARE_NONSTD(type)  type
#endif
#ifndef AP_MODULE_DECLARE_DATA
# define AP_MODULE_DECLARE_DATA
#endif

/**
 * @internal
 * modules should not use functions marked AP_CORE_DECLARE
 */
#ifndef AP_CORE_DECLARE
# define AP_CORE_DECLARE        AP_DECLARE
#endif

/**
 * @internal
 * modules should not use functions marked AP_CORE_DECLARE_NONSTD
 */

#ifndef AP_CORE_DECLARE_NONSTD
# define AP_CORE_DECLARE_NONSTD AP_DECLARE_NONSTD
#endif

/**
 * @defgroup APACHE_APR_STATUS_T HTTPD specific values of apr_status_t
 * @{
 */
#define AP_START_USERERR            (APR_OS_START_USERERR + 2000)
#define AP_USERERR_LEN              1000

/** The function declines to handle the request */
#define AP_DECLINED                 (AP_START_USERERR + 0)

/** @} */

/**
 * @brief The numeric version information is broken out into fields within this
 * structure.
 */
typedef struct {
    int major;              /**< major number */
    int minor;              /**< minor number */
    int patch;              /**< patch number */
    const char *add_string; /**< additional string like "-dev" */
} ap_version_t;

/**
 * Return httpd's version information in a numeric form.
 *
 *  @param version Pointer to a version structure for returning the version
 *                 information.
 */
AP_DECLARE(void) ap_get_server_revision(ap_version_t *version);

/**
 * Get the server banner in a form suitable for sending over the
 * network, with the level of information controlled by the
 * ServerTokens directive.
 * @return The server banner
 */
AP_DECLARE(const char *) ap_get_server_banner(void);

/**
 * Get the server description in a form suitable for local displays,
 * status reports, or logging.  This includes the detailed server
 * version and information about some modules.  It is not affected
 * by the ServerTokens directive.
 * @return The server description
 */
AP_DECLARE(const char *) ap_get_server_description(void);

/**
 * Add a component to the server description and banner strings
 * @param pconf The pool to allocate the component from
 * @param component The string to add
 */
AP_DECLARE(void) ap_add_version_component(apr_pool_t *pconf, const char *component);

/**
 * Get the date a time that the server was built
 * @return The server build time string
 */
AP_DECLARE(const char *) ap_get_server_built(void);

/* non-HTTP status codes returned by hooks */

#define OK           0  /**< Module has handled this stage. */
#define DECLINED    -1  /**< Module declines to handle */
#define DONE        -2  /**< Module has served the response completely
                         *   - it's safe to die() with no more output
                         */
#define SUSPENDED   -3  /**< Module will handle the remainder of the request.
                         *   The core will never invoke the request again */

/** Returned by the bottom-most filter if no data was written.
 *  @see ap_pass_brigade(). */
#define AP_NOBODY_WROTE         -100
/** Returned by the bottom-most filter if no data was read.
 *  @see ap_get_brigade(). */
#define AP_NOBODY_READ          -101
/** Returned by any filter if the filter chain encounters an error
 *  and has already dealt with the error response.
 */
#define AP_FILTER_ERROR         -102

/**
 * @defgroup HTTP_Status HTTP Status Codes
 * @{
 */
/**
 * The size of the static status_lines array in http_protocol.c for
 * storing all of the potential response status-lines (a sparse table).
 * When adding a new code here add it to status_lines as well.
 * A future version should dynamically generate the apr_table_t at startup.
 */
#define RESPONSE_CODES 103

#define HTTP_CONTINUE                        100
#define HTTP_SWITCHING_PROTOCOLS             101
#define HTTP_PROCESSING                      102
#define HTTP_OK                              200
#define HTTP_CREATED                         201
#define HTTP_ACCEPTED                        202
#define HTTP_NON_AUTHORITATIVE               203
#define HTTP_NO_CONTENT                      204
#define HTTP_RESET_CONTENT                   205
#define HTTP_PARTIAL_CONTENT                 206
#define HTTP_MULTI_STATUS                    207
#define HTTP_ALREADY_REPORTED                208
#define HTTP_IM_USED                         226
#define HTTP_MULTIPLE_CHOICES                300
#define HTTP_MOVED_PERMANENTLY               301
#define HTTP_MOVED_TEMPORARILY               302
#define HTTP_SEE_OTHER                       303
#define HTTP_NOT_MODIFIED                    304
#define HTTP_USE_PROXY                       305
#define HTTP_TEMPORARY_REDIRECT              307
#define HTTP_PERMANENT_REDIRECT              308
#define HTTP_BAD_REQUEST                     400
#define HTTP_UNAUTHORIZED                    401
#define HTTP_PAYMENT_REQUIRED                402
#define HTTP_FORBIDDEN                       403
#define HTTP_NOT_FOUND                       404
#define HTTP_METHOD_NOT_ALLOWED              405
#define HTTP_NOT_ACCEPTABLE                  406
#define HTTP_PROXY_AUTHENTICATION_REQUIRED   407
#define HTTP_REQUEST_TIME_OUT                408
#define HTTP_CONFLICT                        409
#define HTTP_GONE                            410
#define HTTP_LENGTH_REQUIRED                 411
#define HTTP_PRECONDITION_FAILED             412
#define HTTP_REQUEST_ENTITY_TOO_LARGE        413
#define HTTP_REQUEST_URI_TOO_LARGE           414
#define HTTP_UNSUPPORTED_MEDIA_TYPE          415
#define HTTP_RANGE_NOT_SATISFIABLE           416
#define HTTP_EXPECTATION_FAILED              417
#define HTTP_MISDIRECTED_REQUEST             421
#define HTTP_UNPROCESSABLE_ENTITY            422
#define HTTP_LOCKED                          423
#define HTTP_FAILED_DEPENDENCY               424
#define HTTP_UPGRADE_REQUIRED                426
#define HTTP_PRECONDITION_REQUIRED           428
#define HTTP_TOO_MANY_REQUESTS               429
#define HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE 431
#define HTTP_UNAVAILABLE_FOR_LEGAL_REASONS   451
#define HTTP_INTERNAL_SERVER_ERROR           500
#define HTTP_NOT_IMPLEMENTED                 501
#define HTTP_BAD_GATEWAY                     502
#define HTTP_SERVICE_UNAVAILABLE             503
#define HTTP_GATEWAY_TIME_OUT                504
#define HTTP_VERSION_NOT_SUPPORTED           505
#define HTTP_VARIANT_ALSO_VARIES             506
#define HTTP_INSUFFICIENT_STORAGE            507
#define HTTP_LOOP_DETECTED                   508
#define HTTP_NOT_EXTENDED                    510
#define HTTP_NETWORK_AUTHENTICATION_REQUIRED 511

/** is the status code informational */
#define ap_is_HTTP_INFO(x)         (((x) >= 100)&&((x) < 200))
/** is the status code OK ?*/
#define ap_is_HTTP_SUCCESS(x)      (((x) >= 200)&&((x) < 300))
/** is the status code a redirect */
#define ap_is_HTTP_REDIRECT(x)     (((x) >= 300)&&((x) < 400))
/** is the status code a error (client or server) */
#define ap_is_HTTP_ERROR(x)        (((x) >= 400)&&((x) < 600))
/** is the status code a client error  */
#define ap_is_HTTP_CLIENT_ERROR(x) (((x) >= 400)&&((x) < 500))
/** is the status code a server error  */
#define ap_is_HTTP_SERVER_ERROR(x) (((x) >= 500)&&((x) < 600))
/** is the status code a (potentially) valid response code?  */
#define ap_is_HTTP_VALID_RESPONSE(x) (((x) >= 100)&&((x) < 600))

/** should the status code drop the connection */
#define ap_status_drops_connection(x) \
                                   (((x) == HTTP_BAD_REQUEST)           || \
                                    ((x) == HTTP_REQUEST_TIME_OUT)      || \
                                    ((x) == HTTP_LENGTH_REQUIRED)       || \
                                    ((x) == HTTP_REQUEST_ENTITY_TOO_LARGE) || \
                                    ((x) == HTTP_REQUEST_URI_TOO_LARGE) || \
                                    ((x) == HTTP_INTERNAL_SERVER_ERROR) || \
                                    ((x) == HTTP_SERVICE_UNAVAILABLE) || \
                                    ((x) == HTTP_NOT_IMPLEMENTED))

/** does the status imply header only response (i.e. never w/ a body)? */
#define AP_STATUS_IS_HEADER_ONLY(x) ((x) == HTTP_NO_CONTENT || \
                                     (x) == HTTP_NOT_MODIFIED)
/** @} */

/**
 * @defgroup Methods List of Methods recognized by the server
 * @ingroup APACHE_CORE_DAEMON
 * @{
 *
 * @brief Methods recognized (but not necessarily handled) by the server.
 *
 * These constants are used in bit shifting masks of size int, so it is
 * unsafe to have more methods than bits in an int.  HEAD == M_GET.
 * This list must be tracked by the list in http_protocol.c in routine
 * ap_method_name_of().
 *
 */

#define M_GET                   0       /** RFC 2616: HTTP */
#define M_PUT                   1       /*  :             */
#define M_POST                  2
#define M_DELETE                3
#define M_CONNECT               4
#define M_OPTIONS               5
#define M_TRACE                 6       /** RFC 2616: HTTP */
#define M_PATCH                 7       /** RFC 5789: PATCH Method for HTTP */
#define M_PROPFIND              8       /** RFC 2518: WebDAV */
#define M_PROPPATCH             9       /*  :               */
#define M_MKCOL                 10
#define M_COPY                  11
#define M_MOVE                  12
#define M_LOCK                  13
#define M_UNLOCK                14      /** RFC 2518: WebDAV */
#define M_VERSION_CONTROL       15      /** RFC 3253: WebDAV Versioning */
#define M_CHECKOUT              16      /*  :                          */
#define M_UNCHECKOUT            17
#define M_CHECKIN               18
#define M_UPDATE                19
#define M_LABEL                 20
#define M_REPORT                21
#define M_MKWORKSPACE           22
#define M_MKACTIVITY            23
#define M_BASELINE_CONTROL      24
#define M_MERGE                 25
#define M_INVALID               26      /** no valid method */

/**
 * METHODS needs to be equal to the number of bits
 * we are using for limit masks.
 */
#define METHODS     64

/**
 * The method mask bit to shift for anding with a bitmask.
 */
#define AP_METHOD_BIT ((apr_int64_t)1)
/** @} */


/** @see ap_method_list_t */
typedef struct ap_method_list_t ap_method_list_t;

/**
 * @struct ap_method_list_t
 * @brief  Structure for handling HTTP methods.
 *
 * Methods known to the server are accessed via a bitmask shortcut;
 * extension methods are handled by an array.
 */
struct ap_method_list_t {
    /** The bitmask used for known methods */
    apr_int64_t method_mask;
    /** the array used for extension methods */
    apr_array_header_t *method_list;
};
/** @} */

/**
 * @defgroup bnotes Binary notes recognized by the server
 * @ingroup APACHE_CORE_DAEMON
 * @{
 *
 * @brief Binary notes recognized by the server.
 */

/**
 * The type used for request binary notes.
 */
typedef apr_uint64_t ap_request_bnotes_t;

/**
 * These constants represent bitmasks for notes associated with this
 * request. There are space for 64 bits in the apr_uint64_t.
 *
 */
#define AP_REQUEST_STRONG_ETAG 1 >> 0
#define AP_REQUEST_TRUSTED_CT  1 << 1

/**
 * This is a convenience macro to ease with getting specific request
 * binary notes.
 */
#define AP_REQUEST_GET_BNOTE(r, mask) \
    ((mask) & ((r)->bnotes))

/**
 * This is a convenience macro to ease with setting specific request
 * binary notes.
 */
#define AP_REQUEST_SET_BNOTE(r, mask, val) \
    (r)->bnotes = (((r)->bnotes & ~(mask)) | (val))

/**
 * Returns true if the strong etag flag is set for this request.
 */
#define AP_REQUEST_IS_STRONG_ETAG(r) \
        AP_REQUEST_GET_BNOTE((r), AP_REQUEST_STRONG_ETAG)
/** @} */

/**
 * Returns true if the content-type field is from a trusted source
 */
#define AP_REQUEST_IS_TRUSTED_CT(r) \
    (!!AP_REQUEST_GET_BNOTE((r), AP_REQUEST_TRUSTED_CT))
/** @} */

/**
 * @defgroup module_magic Module Magic mime types
 * @{
 */
/** Magic for mod_cgi[d] */
#define CGI_MAGIC_TYPE "application/x-httpd-cgi"
/** Magic for mod_include */
#define INCLUDES_MAGIC_TYPE "text/x-server-parsed-html"
/** Magic for mod_include */
#define INCLUDES_MAGIC_TYPE3 "text/x-server-parsed-html3"
/** Magic for mod_dir */
#define DIR_MAGIC_TYPE "httpd/unix-directory"
/** Default for r->handler if no content-type set by type_checker */
#define AP_DEFAULT_HANDLER_NAME ""
#define AP_IS_DEFAULT_HANDLER_NAME(x) (*x == '\0')

/** @} */
/* Just in case your linefeed isn't the one the other end is expecting. */
#if !APR_CHARSET_EBCDIC
/** linefeed */
#define LF 10
/** carriage return */
#define CR 13
/** carriage return /Line Feed Combo */
#define CRLF "\015\012"
#else /* APR_CHARSET_EBCDIC */
/* For platforms using the EBCDIC charset, the transition ASCII->EBCDIC is done
 * in the buff package (bread/bputs/bwrite).  Everywhere else, we use
 * "native EBCDIC" CR and NL characters. These are therefore
 * defined as
 * '\r' and '\n'.
 */
#define CR '\r'
#define LF '\n'
#define CRLF "\r\n"
#endif /* APR_CHARSET_EBCDIC */
/** Useful for common code with either platform charset. */
#define CRLF_ASCII "\015\012"

/**
 * @defgroup values_request_rec_body Possible values for request_rec.read_body
 * @{
 * Possible values for request_rec.read_body (set by handling module):
 */

/** Send 413 error if message has any body */
#define REQUEST_NO_BODY          0
/** Send 411 error if body without Content-Length */
#define REQUEST_CHUNKED_ERROR    1
/** If chunked, remove the chunks for me. */
#define REQUEST_CHUNKED_DECHUNK  2
/** @} // values_request_rec_body */

/**
 * @defgroup values_request_rec_used_path_info Possible values for request_rec.used_path_info
 * @ingroup APACHE_CORE_DAEMON
 * @{
 * Possible values for request_rec.used_path_info:
 */

/** Accept the path_info from the request */
#define AP_REQ_ACCEPT_PATH_INFO    0
/** Return a 404 error if path_info was given */
#define AP_REQ_REJECT_PATH_INFO    1
/** Module may chose to use the given path_info */
#define AP_REQ_DEFAULT_PATH_INFO   2

/** @} // values_request_rec_used_path_info */


/*
 * Things which may vary per file-lookup WITHIN a request ---
 * e.g., state of MIME config.  Basically, the name of an object, info
 * about the object, and any other info we may have which may need to
 * change as we go poking around looking for it (e.g., overridden by
 * .htaccess files).
 *
 * Note how the default state of almost all these things is properly
 * zero, so that allocating it with pcalloc does the right thing without
 * a whole lot of hairy initialization... so long as we are willing to
 * make the (fairly) portable assumption that the bit pattern of a NULL
 * pointer is, in fact, zero.
 */

/**
 * @brief This represents the result of calling htaccess; these are cached for
 * each request.
 */
struct htaccess_result {
    /** the directory to which this applies */
    const char *dir;
    /** the overrides allowed for the .htaccess file */
    int override;
    /** the override options allowed for the .htaccess file */
    int override_opts;
    /** Table of allowed directives for override */
    apr_table_t *override_list;
    /** the configuration directives */
    struct ap_conf_vector_t *htaccess;
    /** the next one, or NULL if no more; N.B. never change this */
    const struct htaccess_result *next;
};

/* The following four types define a hierarchy of activities, so that
 * given a request_rec r you can write r->connection->server->process
 * to get to the process_rec.  While this reduces substantially the
 * number of arguments that various hooks require beware that in
 * threaded versions of the server you must consider multiplexing
 * issues.  */


/** A structure that represents one process */
typedef struct process_rec process_rec;
/** A structure that represents a virtual server */
typedef struct server_rec server_rec;
/** A structure that represents one connection */
typedef struct conn_rec conn_rec;
/** A structure that represents the current request */
typedef struct request_rec request_rec;
/** A structure that represents the status of the current connection */
typedef struct conn_state_t conn_state_t;

/* ### would be nice to not include this from httpd.h ... */
/* This comes after we have defined the request_rec type */
#include "apr_uri.h"

/**
 * @brief A structure that represents one process
 */
struct process_rec {
    /** Global pool. Cleared upon normal exit */
    apr_pool_t *pool;
    /** Configuration pool. Cleared upon restart */
    apr_pool_t *pconf;
    /** The program name used to execute the program */
    const char *short_name;
    /** The command line arguments */
    const char * const *argv;
    /** Number of command line arguments passed to the program */
    int argc;
};

/**
 * @brief A structure that represents the current request
 */
struct request_rec {
    /** The pool associated with the request */
    apr_pool_t *pool;
    /** The connection to the client */
    conn_rec *connection;
    /** The virtual host for this request */
    server_rec *server;

    /** Pointer to the redirected request if this is an external redirect */
    request_rec *next;
    /** Pointer to the previous request if this is an internal redirect */
    request_rec *prev;

    /** Pointer to the main request if this is a sub-request
     * (see http_request.h) */
    request_rec *main;

    /* Info about the request itself... we begin with stuff that only
     * protocol.c should ever touch...
     */
    /** First line of request */
    char *the_request;
    /** HTTP/0.9, "simple" request (e.g. GET /foo\n w/no headers) */
    int assbackwards;
    /** A proxy request (calculated during post_read_request/translate_name)
     *  possible values PROXYREQ_NONE, PROXYREQ_PROXY, PROXYREQ_REVERSE,
     *                  PROXYREQ_RESPONSE
     */
    int proxyreq;
    /** HEAD request, as opposed to GET */
    int header_only;
    /** Protocol version number of protocol; 1.1 = 1001 */
    int proto_num;
    /** Protocol string, as given to us, or HTTP/0.9 */
    char *protocol;
    /** Host, as set by full URI or Host: header.
     *  For literal IPv6 addresses, this does NOT include the surrounding [ ]
     */
    const char *hostname;

    /** Time when the request started */
    apr_time_t request_time;

    /** Status line, if set by script */
    const char *status_line;
    /** Status line */
    int status;

    /* Request method, two ways; also, protocol, etc..  Outside of protocol.c,
     * look, but don't touch.
     */

    /** M_GET, M_POST, etc. */
    int method_number;
    /** Request method (eg. GET, HEAD, POST, etc.) */
    const char *method;

    /**
     *  'allowed' is a bitvector of the allowed methods.
     *
     *  A handler must ensure that the request method is one that
     *  it is capable of handling.  Generally modules should DECLINE
     *  any request methods they do not handle.  Prior to aborting the
     *  handler like this the handler should set r->allowed to the list
     *  of methods that it is willing to handle.  This bitvector is used
     *  to construct the "Allow:" header required for OPTIONS requests,
     *  and HTTP_METHOD_NOT_ALLOWED and HTTP_NOT_IMPLEMENTED status codes.
     *
     *  Since the default_handler deals with OPTIONS, all modules can
     *  usually decline to deal with OPTIONS.  TRACE is always allowed,
     *  modules don't need to set it explicitly.
     *
     *  Since the default_handler will always handle a GET, a
     *  module which does *not* implement GET should probably return
     *  HTTP_METHOD_NOT_ALLOWED.  Unfortunately this means that a Script GET
     *  handler can't be installed by mod_actions.
     */
    apr_int64_t allowed;
    /** Array of extension methods */
    apr_array_header_t *allowed_xmethods;
    /** List of allowed methods */
    ap_method_list_t *allowed_methods;

    /** byte count in stream is for body */
    apr_off_t sent_bodyct;
    /** body byte count, for easy access */
    apr_off_t bytes_sent;
    /** Last modified time of the requested resource */
    apr_time_t mtime;

    /* HTTP/1.1 connection-level features */

    /** The Range: header */
    const char *range;
    /** The "real" content length */
    apr_off_t clength;
    /** sending chunked transfer-coding */
    int chunked;

    /** Method for reading the request body
     * (eg. REQUEST_CHUNKED_ERROR, REQUEST_NO_BODY,
     *  REQUEST_CHUNKED_DECHUNK, etc...) */
    int read_body;
    /** reading chunked transfer-coding */
    int read_chunked;
    /** is client waiting for a 100 response? */
    unsigned expecting_100;
    /** The optional kept body of the request. */
    apr_bucket_brigade *kept_body;
    /** For ap_body_to_table(): parsed body */
    /* XXX: ap_body_to_table has been removed. Remove body_table too or
     * XXX: keep it to reintroduce ap_body_to_table without major bump? */
    apr_table_t *body_table;
    /** Remaining bytes left to read from the request body */
    apr_off_t remaining;
    /** Number of bytes that have been read  from the request body */
    apr_off_t read_length;

    /* MIME header environments, in and out.  Also, an array containing
     * environment variables to be passed to subprocesses, so people can
     * write modules to add to that environment.
     *
     * The difference between headers_out and err_headers_out is that the
     * latter are printed even on error, and persist across internal redirects
     * (so the headers printed for ErrorDocument handlers will have them).
     *
     * The 'notes' apr_table_t is for notes from one module to another, with no
     * other set purpose in mind...
     */

    /** MIME header environment from the request */
    apr_table_t *headers_in;
    /** MIME header environment for the response */
    apr_table_t *headers_out;
    /** MIME header environment for the response, printed even on errors and
     * persist across internal redirects */
    apr_table_t *err_headers_out;
    /** Array of environment variables to be used for sub processes */
    apr_table_t *subprocess_env;
    /** Notes from one module to another */
    apr_table_t *notes;

    /* content_type, handler, content_encoding, and all content_languages
     * MUST be lowercased strings.  They may be pointers to static strings;
     * they should not be modified in place.
     */
    /** The content-type for the current request */
    const char *content_type;   /* Break these out --- we dispatch on 'em */
    /** The handler string that we use to call a handler function */
    const char *handler;        /* What we *really* dispatch on */

    /** How to encode the data */
    const char *content_encoding;
    /** Array of strings representing the content languages */
    apr_array_header_t *content_languages;

    /** variant list validator (if negotiated) */
    char *vlist_validator;

    /** If an authentication check was made, this gets set to the user name. */
    char *user;
    /** If an authentication check was made, this gets set to the auth type. */
    char *ap_auth_type;

    /* What object is being requested (either directly, or via include
     * or content-negotiation mapping).
     */

    /** The URI without any parsing performed */
    char *unparsed_uri;
    /** The path portion of the URI, or "/" if no path provided */
    char *uri;
    /** The filename on disk corresponding to this response */
    char *filename;
    /** The true filename stored in the filesystem, as in the true alpha case
     *  and alias correction, e.g. "Image.jpeg" not "IMAGE$1.JPE" on Windows.
     *  The core map_to_storage canonicalizes r->filename when they mismatch */
    char *canonical_filename;
    /** The PATH_INFO extracted from this request */
    char *path_info;
    /** The QUERY_ARGS extracted from this request */
    char *args;

    /**
     * Flag for the handler to accept or reject path_info on
     * the current request.  All modules should respect the
     * AP_REQ_ACCEPT_PATH_INFO and AP_REQ_REJECT_PATH_INFO
     * values, while AP_REQ_DEFAULT_PATH_INFO indicates they
     * may follow existing conventions.  This is set to the
     * user's preference upon HOOK_VERY_FIRST of the fixups.
     */
    int used_path_info;

    /** A flag to determine if the eos bucket has been sent yet */
    int eos_sent;

    /* Various other config info which may change with .htaccess files
     * These are config vectors, with one void* pointer for each module
     * (the thing pointed to being the module's business).
     */

    /** Options set in config files, etc. */
    struct ap_conf_vector_t *per_dir_config;
    /** Notes on *this* request */
    struct ap_conf_vector_t *request_config;

    /** Optional request log level configuration. Will usually point
     *  to a server or per_dir config, i.e. must be copied before
     *  modifying */
    const struct ap_logconf *log;

    /** Id to identify request in access and error log. Set when the first
     *  error log entry for this request is generated.
     */
    const char *log_id;

    /**
     * A linked list of the .htaccess configuration directives
     * accessed by this request.
     * N.B. always add to the head of the list, _never_ to the end.
     * that way, a sub request's list can (temporarily) point to a parent's list
     */
    const struct htaccess_result *htaccess;

    /** A list of output filters to be used for this request */
    struct ap_filter_t *output_filters;
    /** A list of input filters to be used for this request */
    struct ap_filter_t *input_filters;

    /** A list of protocol level output filters to be used for this
     *  request */
    struct ap_filter_t *proto_output_filters;
    /** A list of protocol level input filters to be used for this
     *  request */
    struct ap_filter_t *proto_input_filters;

    /** This response can not be cached */
    int no_cache;
    /** There is no local copy of this response */
    int no_local_copy;

    /** Mutex protect callbacks registered with ap_mpm_register_timed_callback
     * from being run before the original handler finishes running
     */
    apr_thread_mutex_t *invoke_mtx;

    /** A struct containing the components of URI */
    apr_uri_t parsed_uri;
    /**  finfo.protection (st_mode) set to zero if no such file */
    apr_finfo_t finfo;

    /** remote address information from conn_rec, can be overridden if
     * necessary by a module.
     * This is the address that originated the request.
     */
    apr_sockaddr_t *useragent_addr;
    char *useragent_ip;

    /** MIME trailer environment from the request */
    apr_table_t *trailers_in;
    /** MIME trailer environment from the response */
    apr_table_t *trailers_out;

    /** Originator's DNS name, if known.  NULL if DNS hasn't been checked,
     *  "" if it has and no address was found.  N.B. Only access this though
     *  ap_get_useragent_host() */
    char *useragent_host;
    /** have we done double-reverse DNS? -1 yes/failure, 0 not yet,
     *  1 yes/success
     */
    int double_reverse;
    /** Request flags associated with this request. Use
     * AP_REQUEST_GET_BNOTE() and AP_REQUEST_SET_BNOTE() to access
     * the elements of this field.
     */
    ap_request_bnotes_t bnotes;
};

/**
 * @defgroup ProxyReq Proxy request types
 *
 * Possible values of request_rec->proxyreq. A request could be normal,
 *  proxied or reverse proxied. Normally proxied and reverse proxied are
 *  grouped together as just "proxied", but sometimes it's necessary to
 *  tell the difference between the two, such as for authentication.
 * @{
 */

#define PROXYREQ_NONE     0     /**< No proxy */
#define PROXYREQ_PROXY    1     /**< Standard proxy */
#define PROXYREQ_REVERSE  2     /**< Reverse proxy */
#define PROXYREQ_RESPONSE 3     /**< Origin response */

/* @} */

/**
 * @brief Enumeration of connection keepalive options
 */
typedef enum {
    AP_CONN_UNKNOWN,
    AP_CONN_CLOSE,
    AP_CONN_KEEPALIVE
} ap_conn_keepalive_e;

/**
 * @brief Structure to store things which are per connection
 */
struct conn_rec {
    /** Pool associated with this connection */
    apr_pool_t *pool;
    /** Physical vhost this conn came in on */
    server_rec *base_server;
    /** used by http_vhost.c */
    void *vhost_lookup_data;

    /* Information about the connection itself */
    /** local address */
    apr_sockaddr_t *local_addr;
    /** remote address; this is the end-point of the next hop, for the address
     *  of the request creator, see useragent_addr in request_rec
     */
    apr_sockaddr_t *client_addr;

    /** Client's IP address; this is the end-point of the next hop, for the
     *  IP of the request creator, see useragent_ip in request_rec
     */
    char *client_ip;
    /** Client's DNS name, if known.  NULL if DNS hasn't been checked,
     *  "" if it has and no address was found.  N.B. Only access this though
     * get_remote_host() */
    char *remote_host;
    /** Only ever set if doing rfc1413 lookups.  N.B. Only access this through
     *  get_remote_logname() */
    char *remote_logname;

    /** server IP address */
    char *local_ip;
    /** used for ap_get_server_name when UseCanonicalName is set to DNS
     *  (ignores setting of HostnameLookups) */
    char *local_host;

    /** ID of this connection; unique at any point in time */
    long id;
    /** Config vector containing pointers to connections per-server
     *  config structures. */
    struct ap_conf_vector_t *conn_config;
    /** Notes on *this* connection: send note from one module to
     *  another. must remain valid for all requests on this conn */
    apr_table_t *notes;
    /** A list of input filters to be used for this connection */
    struct ap_filter_t *input_filters;
    /** A list of output filters to be used for this connection */
    struct ap_filter_t *output_filters;
    /** handle to scoreboard information for this connection */
    void *sbh;
    /** The bucket allocator to use for all bucket/brigade creations */
    struct apr_bucket_alloc_t *bucket_alloc;
    /** The current state of this connection; may be NULL if not used by MPM */
    conn_state_t *cs;
    /** Is there data pending in the input filters? */
    int data_in_input_filters;
    /** Is there data pending in the output filters? */
    int data_in_output_filters;

    /** Are there any filters that clogg/buffer the input stream, breaking
     *  the event mpm.
     */
    unsigned int clogging_input_filters:1;

    /** have we done double-reverse DNS? -1 yes/failure, 0 not yet,
     *  1 yes/success */
    signed int double_reverse:2;

    /** Are we still talking? */
    unsigned aborted;

    /** Are we going to keep the connection alive for another request?
     * @see ap_conn_keepalive_e */
    ap_conn_keepalive_e keepalive;

    /** How many times have we used it? */
    int keepalives;

    /** Optional connection log level configuration. May point to a server or
     *  per_dir config, i.e. must be copied before modifying */
    const struct ap_logconf *log;

    /** Id to identify this connection in error log. Set when the first
     *  error log entry for this connection is generated.
     */
    const char *log_id;


    /** This points to the current thread being used to process this request,
     * over the lifetime of a request, the value may change. Users of the connection
     * record should not rely upon it staying the same between calls that involve
     * the MPM.
     */
#if APR_HAS_THREADS
    apr_thread_t *current_thread;
#endif

    /** The "real" master connection. NULL if I am the master. */
    conn_rec *master;

    int outgoing;
};

/**
 * Enumeration of connection states
 * The two states CONN_STATE_LINGER_NORMAL and CONN_STATE_LINGER_SHORT may
 * only be set by the MPM. Use CONN_STATE_LINGER outside of the MPM.
 */
typedef enum  {
    CONN_STATE_KEEPALIVE,           /* Kept alive in the MPM (using KeepAliveTimeout) */
    CONN_STATE_PROCESSING,          /* Processed by process_connection hooks */
    CONN_STATE_HANDLER,             /* Processed by the modules handlers */
    CONN_STATE_WRITE_COMPLETION,    /* Flushed by the MPM before entering CONN_STATE_KEEPALIVE */
    CONN_STATE_SUSPENDED,           /* Suspended in the MPM until ap_run_resume_suspended() */
    CONN_STATE_LINGER,              /* MPM flushes then closes the connection with lingering */
    CONN_STATE_LINGER_NORMAL,       /* MPM has started lingering close with normal timeout */
    CONN_STATE_LINGER_SHORT,        /* MPM has started lingering close with short timeout */

    CONN_STATE_ASYNC_WAITIO,        /* Returning this state to the MPM will make it wait for
                                     * the connection to be readable or writable according to
                                     * c->cs->sense (resp. CONN_SENSE_WANT_READ or _WRITE),
                                     * using the configured Timeout */

    CONN_STATE_NUM,                 /* Number of states (keep here before aliases) */

    /* Aliases (legacy) */
    CONN_STATE_CHECK_REQUEST_LINE_READABLE  = CONN_STATE_KEEPALIVE,
    CONN_STATE_READ_REQUEST_LINE            = CONN_STATE_PROCESSING,
} conn_state_e;

typedef enum  {
    CONN_SENSE_DEFAULT,
    CONN_SENSE_WANT_READ,       /* next event must be read */
    CONN_SENSE_WANT_WRITE       /* next event must be write */
} conn_sense_e;

/**
 * @brief A structure to contain connection state information
 */
struct conn_state_t {
    /** Current state of the connection */
    conn_state_e state;
    /** Whether to read instead of write, or write instead of read */
    conn_sense_e sense;
};

/* Per-vhost config... */

/**
 * The address 255.255.255.255, when used as a virtualhost address,
 * will become the "default" server when the ip doesn't match other vhosts.
 */
#define DEFAULT_VHOST_ADDR 0xfffffffful


/**
 * @struct server_addr_rec
 * @brief  A structure to be used for Per-vhost config
 */
typedef struct server_addr_rec server_addr_rec;
struct server_addr_rec {
    /** The next server in the list */
    server_addr_rec *next;
    /** The name given in "<VirtualHost>" */
    char *virthost;
    /** The bound address, for this server */
    apr_sockaddr_t *host_addr;
    /** The bound port, for this server */
    apr_port_t host_port;
};

struct ap_logconf {
    /** The per-module log levels */
    signed char *module_levels;

    /** The log level for this server */
    int level;
};
/**
 * @brief A structure to store information for each virtual server
 */
struct server_rec {
    /** The process this server is running in */
    process_rec *process;
    /** The next server in the list */
    server_rec *next;

    /* Log files --- note that transfer log is now in the modules... */

    /** The name of the error log */
    char *error_fname;
    /** A file descriptor that references the error log */
    apr_file_t *error_log;
    /** The log level configuration */
    struct ap_logconf log;

    /* Module-specific configuration for server, and defaults... */

    /** Config vector containing pointers to modules' per-server config
     *  structures. */
    struct ap_conf_vector_t *module_config;
    /** MIME type info, etc., before we start checking per-directory info */
    struct ap_conf_vector_t *lookup_defaults;

    /** The path to the config file that the server was defined in */
    const char *defn_name;
    /** The line of the config file that the server was defined on */
    unsigned defn_line_number;
    /** true if this is the virtual server */
    char is_virtual;


    /* Information for redirects */

    /** for redirects, etc. */
    apr_port_t port;
    /** The server request scheme for redirect responses */
    const char *server_scheme;

    /* Contact information */

    /** The admin's contact information */
    char *server_admin;
    /** The server hostname */
    char *server_hostname;

    /* Transaction handling */

    /** I haven't got a clue */
    server_addr_rec *addrs;
    /** Timeout, as an apr interval, before we give up */
    apr_interval_time_t timeout;
    /** The apr interval we will wait for another request */
    apr_interval_time_t keep_alive_timeout;
    /** Maximum requests per connection */
    int keep_alive_max;
    /** Use persistent connections? */
    int keep_alive;

    /** Normal names for ServerAlias servers */
    apr_array_header_t *names;
    /** Wildcarded names for ServerAlias servers */
    apr_array_header_t *wild_names;

    /** Pathname for ServerPath */
    const char *path;
    /** Length of path */
    int pathlen;

    /** limit on size of the HTTP request line    */
    int limit_req_line;
    /** limit on size of any request header field */
    int limit_req_fieldsize;
    /** limit on number of request header fields  */
    int limit_req_fields;

    /** Opaque storage location */
    void *context;

    /** Whether the keepalive timeout is explicit (1) or
     *  inherited (0) from the base server (either first
     *  server on the same IP:port or main server) */
    unsigned int keep_alive_timeout_set:1;
};

/**
 * @struct ap_sload_t
 * @brief  A structure to hold server load params
 */
typedef struct ap_sload_t ap_sload_t;
struct ap_sload_t {
    /* percentage of process/threads ready/idle (0->100)*/
    int idle;
    /* percentage of process/threads busy (0->100) */
    int busy;
    /* total bytes served */
    apr_off_t bytes_served;
    /* total access count */
    unsigned long access_count;
};

/**
 * @struct ap_loadavg_t
 * @brief  A structure to hold various server loadavg
 */
typedef struct ap_loadavg_t ap_loadavg_t;
struct ap_loadavg_t {
    /* current loadavg, ala getloadavg() */
    float loadavg;
    /* 5 min loadavg */
    float loadavg5;
    /* 15 min loadavg */
    float loadavg15;
};

/**
 * Get the context_document_root for a request. This is a generalization of
 * the document root, which is too limited in the presence of mappers like
 * mod_userdir and mod_alias. The context_document_root is the directory
 * on disk that maps to the context_prefix URI prefix.
 * @param r The request
 * @note For resources that do not map to the file system or for very complex
 * mappings, this information may still be wrong.
 */
AP_DECLARE(const char *) ap_context_document_root(request_rec *r);

/**
 * Get the context_prefix for a request. The context_prefix URI prefix
 * maps to the context_document_root on disk.
 * @param r The request
 */
AP_DECLARE(const char *) ap_context_prefix(request_rec *r);

/** Set context_prefix and context_document_root for a request.
 * @param r The request
 * @param prefix the URI prefix, without trailing slash
 * @param document_root the corresponding directory on disk, without trailing
 * slash
 * @note If one of prefix of document_root is NULL, the corrsponding
 * property will not be changed.
 */
AP_DECLARE(void) ap_set_context_info(request_rec *r, const char *prefix,
                                     const char *document_root);

/** Set per-request document root. This is for mass virtual hosting modules
 * that want to provide the correct DOCUMENT_ROOT value to scripts.
 * @param r The request
 * @param document_root the document root for the request.
 */
AP_DECLARE(void) ap_set_document_root(request_rec *r, const char *document_root);

/**
 * Examine a field value (such as a media-/content-type) string and return
 * it sans any parameters; e.g., strip off any ';charset=foo' and the like.
 * @param p Pool to allocate memory from
 * @param intype The field to examine
 * @return A copy of the field minus any parameters
 */
AP_DECLARE(char *) ap_field_noparam(apr_pool_t *p, const char *intype);

/**
 * Convert a time from an integer into a string in a specified format
 * @param p The pool to allocate memory from
 * @param t The time to convert
 * @param fmt The format to use for the conversion
 * @param gmt Convert the time for GMT?
 * @return The string that represents the specified time
 */
AP_DECLARE(char *) ap_ht_time(apr_pool_t *p, apr_time_t t, const char *fmt, int gmt);

/* String handling. The *_nc variants allow you to use non-const char **s as
   arguments (unfortunately C won't automatically convert a char ** to a const
   char **) */

/**
 * Get the characters until the first occurrence of a specified character
 * @param p The pool to allocate memory from
 * @param line The string to get the characters from
 * @param stop The character to stop at
 * @return A copy of the characters up to the first stop character
 */
AP_DECLARE(char *) ap_getword(apr_pool_t *p, const char **line, char stop);

/**
 * Get the characters until the first occurrence of a specified character
 * @param p The pool to allocate memory from
 * @param line The string to get the characters from
 * @param stop The character to stop at
 * @return A copy of the characters up to the first stop character
 * @note This is the same as ap_getword(), except it doesn't use const char **.
 */
AP_DECLARE(char *) ap_getword_nc(apr_pool_t *p, char **line, char stop);

/**
 * Get the first word from a given string.  A word is defined as all characters
 * up to the first whitespace.
 * @param p The pool to allocate memory from
 * @param line The string to traverse
 * @return The first word in the line
 */
AP_DECLARE(char *) ap_getword_white(apr_pool_t *p, const char **line);

/**
 * Get the first word from a given string.  A word is defined as all characters
 * up to the first whitespace.
 * @param p The pool to allocate memory from
 * @param line The string to traverse
 * @return The first word in the line
 * @note The same as ap_getword_white(), except it doesn't use const char**
 */
AP_DECLARE(char *) ap_getword_white_nc(apr_pool_t *p, char **line);

/**
 * Get all characters from the first occurrence of @a stop to the first "\0"
 * @param p The pool to allocate memory from
 * @param line The line to traverse
 * @param stop The character to start at
 * @return A copy of all characters after the first occurrence of the specified
 *         character
 */
AP_DECLARE(char *) ap_getword_nulls(apr_pool_t *p, const char **line,
                                    char stop);

/**
 * Get all characters from the first occurrence of @a stop to the first "\0"
 * @param p The pool to allocate memory from
 * @param line The line to traverse
 * @param stop The character to start at
 * @return A copy of all characters after the first occurrence of the specified
 *         character
 * @note The same as ap_getword_nulls(), except it doesn't use const char **.
 */
AP_DECLARE(char *) ap_getword_nulls_nc(apr_pool_t *p, char **line, char stop);

/**
 * Get the second word in the string paying attention to quoting
 * @param p The pool to allocate from
 * @param line The line to traverse
 * @return A copy of the string
 */
AP_DECLARE(char *) ap_getword_conf(apr_pool_t *p, const char **line);

/**
 * Get the second word in the string paying attention to quoting
 * @param p The pool to allocate from
 * @param line The line to traverse
 * @return A copy of the string
 * @note The same as ap_getword_conf(), except it doesn't use const char **.
 */
AP_DECLARE(char *) ap_getword_conf_nc(apr_pool_t *p, char **line);

/**
 * Get the second word in the string paying attention to quoting,
 * with {...} supported as well as "..." and '...'
 * @param p The pool to allocate from
 * @param line The line to traverse
 * @return A copy of the string
 */
AP_DECLARE(char *) ap_getword_conf2(apr_pool_t *p, const char **line);

/**
 * Get the second word in the string paying attention to quoting,
 * with {...} supported as well as "..." and '...'
 * @param p The pool to allocate from
 * @param line The line to traverse
 * @return A copy of the string
 * @note The same as ap_getword_conf2(), except it doesn't use const char **.
 */
AP_DECLARE(char *) ap_getword_conf2_nc(apr_pool_t *p, char **line);

/**
 * Check a string for any config define or environment variable construct
 * and replace each of them by the value of that variable, if it exists.
 * The default syntax of the constructs is ${ENV} but can be changed by
 * setting the define::* config defines. If the variable does not exist,
 * leave the ${ENV} construct alone but print a warning.
 * @param p The pool to allocate from
 * @param word The string to check
 * @return The string with the replaced environment variables
 */
AP_DECLARE(const char *) ap_resolve_env(apr_pool_t *p, const char * word);

/**
 * Size an HTTP header field list item, as separated by a comma.
 * @param field The field to size
 * @param len The length of the field
 * @return The return value is a pointer to the beginning of the non-empty
 * list item within the original string (or NULL if there is none) and the
 * address of field is shifted to the next non-comma, non-whitespace
 * character.  len is the length of the item excluding any beginning whitespace.
 */
AP_DECLARE(const char *) ap_size_list_item(const char **field, int *len);

/**
 * Retrieve an HTTP header field list item, as separated by a comma,
 * while stripping insignificant whitespace and lowercasing anything not in
 * a quoted string or comment.
 * @param p The pool to allocate from
 * @param field The field to retrieve
 * @return The return value is a new string containing the converted list
 *         item (or NULL if none) and the address pointed to by field is
 *         shifted to the next non-comma, non-whitespace.
 */
AP_DECLARE(char *) ap_get_list_item(apr_pool_t *p, const char **field);

/**
 * Find an item in canonical form (lowercase, no extra spaces) within
 * an HTTP field value list.
 * @param p The pool to allocate from
 * @param line The field value list to search
 * @param tok The token to search for
 * @return 1 if found, 0 if not found.
 */
AP_DECLARE(int) ap_find_list_item(apr_pool_t *p, const char *line, const char *tok);

/**
 * Do a weak ETag comparison within an HTTP field value list.
 * @param p The pool to allocate from
 * @param line The field value list to search
 * @param tok The token to search for
 * @return 1 if found, 0 if not found.
 */
AP_DECLARE(int) ap_find_etag_weak(apr_pool_t *p, const char *line, const char *tok);

/**
 * Do a strong ETag comparison within an HTTP field value list.
 * @param p The pool to allocate from
 * @param line The field value list to search
 * @param tok The token to search for
 * @return 1 if found, 0 if not found.
 */
AP_DECLARE(int) ap_find_etag_strong(apr_pool_t *p, const char *line, const char *tok);

/* Scan a string for field content chars, as defined by RFC7230 section 3.2
 * including VCHAR/obs-text, as well as HT and SP
 * @param ptr The string to scan
 * @return A pointer to the first (non-HT) ASCII ctrl character.
 * @note lws and trailing whitespace are scanned, the caller is responsible
 * for trimming leading and trailing whitespace
 */
AP_DECLARE(const char *) ap_scan_http_field_content(const char *ptr);

/* Scan a string for token characters, as defined by RFC7230 section 3.2.6 
 * @param ptr The string to scan
 * @return A pointer to the first non-token character.
 */
AP_DECLARE(const char *) ap_scan_http_token(const char *ptr);

/* Scan a string for visible ASCII (0x21-0x7E) or obstext (0x80+)
 * and return a pointer to the first SP/CTL/NUL character encountered.
 * @param ptr The string to scan
 * @return A pointer to the first SP/CTL character.
 */
AP_DECLARE(const char *) ap_scan_vchar_obstext(const char *ptr);

/**
 * Retrieve an array of tokens in the format "1#token" defined in RFC2616. Only
 * accepts ',' as a delimiter, does not accept quoted strings, and errors on
 * any separator.
 * @param p The pool to allocate from
 * @param tok The line to read tokens from
 * @param tokens Pointer to an array of tokens. If not NULL, must be an array
 *    of char*, otherwise it will be allocated on @a p when a token is found
 * @param skip_invalid If true, when an invalid separator is encountered, it
 *    will be ignored.
 * @return NULL on success, an error string otherwise.
 * @remark *tokens may be NULL on output if NULL in input and no token is found
 */
AP_DECLARE(const char *) ap_parse_token_list_strict(apr_pool_t *p, const char *tok,
                                                    apr_array_header_t **tokens,
                                                    int skip_invalid);

/**
 * Retrieve a token, spacing over it and adjusting the pointer to
 * the first non-white byte afterwards.  Note that these tokens
 * are delimited by semis and commas and can also be delimited
 * by whitespace at the caller's option.
 * @param p The pool to allocate from
 * @param accept_line The line to retrieve the token from (adjusted afterwards)
 * @param accept_white Is it delimited by whitespace
 * @return the token
 */
AP_DECLARE(char *) ap_get_token(apr_pool_t *p, const char **accept_line, int accept_white);

/**
 * Find http tokens, see the definition of token from RFC2068
 * @param p The pool to allocate from
 * @param line The line to find the token
 * @param tok The token to find
 * @return 1 if the token is found, 0 otherwise
 */
AP_DECLARE(int) ap_find_token(apr_pool_t *p, const char *line, const char *tok);

/**
 * find http tokens from the end of the line
 * @param p The pool to allocate from
 * @param line The line to find the token
 * @param tok The token to find
 * @return 1 if the token is found, 0 otherwise
 */
AP_DECLARE(int) ap_find_last_token(apr_pool_t *p, const char *line, const char *tok);

/**
 * Check for an Absolute URI syntax
 * @param u The string to check
 * @return 1 if URI, 0 otherwise
 */
AP_DECLARE(int) ap_is_url(const char *u);

/**
 * Unescape a string
 * @param url The string to unescape
 * @return 0 on success, non-zero otherwise
 */
AP_DECLARE(int) ap_unescape_all(char *url);

/**
 * Unescape a URL
 * @param url The url to unescape
 * @return 0 on success, non-zero otherwise
 */
AP_DECLARE(int) ap_unescape_url(char *url);

/**
 * Unescape a URL, but leaving %2f (slashes) escaped
 * @param url The url to unescape
 * @param decode_slashes Whether or not slashes should be decoded
 * @return 0 on success, non-zero otherwise
 */
AP_DECLARE(int) ap_unescape_url_keep2f(char *url, int decode_slashes);

#define AP_UNESCAPE_URL_KEEP_UNRESERVED (1u << 0)
#define AP_UNESCAPE_URL_FORBID_SLASHES  (1u << 1)
#define AP_UNESCAPE_URL_KEEP_SLASHES    (1u << 2)

/**
 * Unescape a URL, with options
 * @param url The url to unescape
 * @param flags Bitmask of AP_UNESCAPE_URL_* flags
 * @return 0 on success, non-zero otherwise
 */
AP_DECLARE(int) ap_unescape_url_ex(char *url, unsigned int flags);

/**
 * Unescape an application/x-www-form-urlencoded string
 * @param query The query to unescape
 * @return 0 on success, non-zero otherwise
 */
AP_DECLARE(int) ap_unescape_urlencoded(char *query);

/**
 * Convert all double slashes to single slashes, except where significant
 * to the filesystem on the current platform.
 * @param name The string to convert, assumed to be a filesystem path
 */
AP_DECLARE(void) ap_no2slash(char *name);

/**
 * Convert all double slashes to single slashes, except where significant
 * to the filesystem on the current platform.
 * @param name The string to convert
 * @param is_fs_path if set to 0, the significance of any double-slashes is 
 *        ignored.
 */
AP_DECLARE(void) ap_no2slash_ex(char *name, int is_fs_path);

#define AP_NORMALIZE_ALLOW_RELATIVE     (1u <<  0)
#define AP_NORMALIZE_NOT_ABOVE_ROOT     (1u <<  1)
#define AP_NORMALIZE_DECODE_UNRESERVED  (1u <<  2)
#define AP_NORMALIZE_MERGE_SLASHES      (1u <<  3)
#define AP_NORMALIZE_DROP_PARAMETERS    (0) /* deprecated */

/**
 * Remove all ////, /./ and /xx/../ substrings from a path, and more
 * depending on passed in flags.
 * @param path The path to normalize
 * @param flags bitmask of AP_NORMALIZE_* flags
 * @return non-zero on success
 */
AP_DECLARE(int) ap_normalize_path(char *path, unsigned int flags);

/**
 * Remove all ./ and xx/../ substrings from a file name. Also remove
 * any leading ../ or /../ substrings.
 * @param name the file name to parse
 */
AP_DECLARE(void) ap_getparents(char *name);

/**
 * Escape a path segment, as defined in RFC 1808
 * @param p The pool to allocate from
 * @param s The path to convert
 * @return The converted URL
 */
AP_DECLARE(char *) ap_escape_path_segment(apr_pool_t *p, const char *s);

/**
 * Escape a path segment, as defined in RFC 1808, to a preallocated buffer.
 * @param c The preallocated buffer to write to
 * @param s The path to convert
 * @return The converted URL (c)
 */
AP_DECLARE(char *) ap_escape_path_segment_buffer(char *c, const char *s);

/**
 * convert an OS path to a URL in an OS dependent way.
 * @param p The pool to allocate from
 * @param path The path to convert
 * @param partial if set, assume that the path will be appended to something
 *        with a '/' in it (and thus does not prefix "./")
 * @return The converted URL
 */
AP_DECLARE(char *) ap_os_escape_path(apr_pool_t *p, const char *path, int partial);

/** @see ap_os_escape_path */
#define ap_escape_uri(ppool,path) ap_os_escape_path(ppool,path,1)

/**
 * Escape a string as application/x-www-form-urlencoded
 * @param p The pool to allocate from
 * @param s The path to convert
 * @return The converted URL
 */
AP_DECLARE(char *) ap_escape_urlencoded(apr_pool_t *p, const char *s);

/**
 * Escape a string as application/x-www-form-urlencoded, to a preallocated buffer
 * @param c The preallocated buffer to write to
 * @param s The path to convert
 * @return The converted URL (c)
 */
AP_DECLARE(char *) ap_escape_urlencoded_buffer(char *c, const char *s);

/**
 * Escape an html string
 * @param p The pool to allocate from
 * @param s The html to escape
 * @return The escaped string
 */
#define ap_escape_html(p,s) ap_escape_html2(p,s,0)
/**
 * Escape an html string
 * @param p The pool to allocate from
 * @param s The html to escape
 * @param toasc Whether to escape all non-ASCII chars to \&\#nnn;
 * @return The escaped string
 */
AP_DECLARE(char *) ap_escape_html2(apr_pool_t *p, const char *s, int toasc);

/**
 * Escape a string for logging
 * @param p The pool to allocate from
 * @param str The string to escape
 * @return The escaped string
 */
AP_DECLARE(char *) ap_escape_logitem(apr_pool_t *p, const char *str);

/**
 * Escape a string for logging into the error log (without a pool)
 * @param dest The buffer to write to
 * @param source The string to escape
 * @param buflen The buffer size for the escaped string (including "\0")
 * @return The len of the escaped string (always < maxlen)
 */
AP_DECLARE(apr_size_t) ap_escape_errorlog_item(char *dest, const char *source,
                                               apr_size_t buflen);

/**
 * Construct a full hostname
 * @param p The pool to allocate from
 * @param hostname The hostname of the server
 * @param port The port the server is running on
 * @param r The current request
 * @return The server's hostname
 */
AP_DECLARE(char *) ap_construct_server(apr_pool_t *p, const char *hostname,
                                    apr_port_t port, const request_rec *r);

/**
 * Escape a shell command
 * @param p The pool to allocate from
 * @param s The command to escape
 * @return The escaped shell command
 */
AP_DECLARE(char *) ap_escape_shell_cmd(apr_pool_t *p, const char *s);

/**
 * Count the number of directories in a path
 * @param path The path to count
 * @return The number of directories
 */
AP_DECLARE(int) ap_count_dirs(const char *path);

/**
 * Copy at most @a n leading directories of @a s into @a d. @a d
 * should be at least as large as @a s plus 1 extra byte
 *
 * @param d The location to copy to
 * @param s The location to copy from
 * @param n The number of directories to copy
 * @return value is the ever useful pointer to the trailing "\0" of d
 * @note on platforms with drive letters, n = 0 returns the "/" root,
 * whereas n = 1 returns the "d:/" root.  On all other platforms, n = 0
 * returns the empty string.  */
AP_DECLARE(char *) ap_make_dirstr_prefix(char *d, const char *s, int n);

/**
 * Return the parent directory name (including trailing /) of the file
 * @a s
 * @param p The pool to allocate from
 * @param s The file to get the parent of
 * @return A copy of the file's parent directory
 */
AP_DECLARE(char *) ap_make_dirstr_parent(apr_pool_t *p, const char *s);

/**
 * Given a directory and filename, create a single path from them.  This
 * function is smart enough to ensure that there is a single '/' between the
 * directory and file names
 * @param a The pool to allocate from
 * @param dir The directory name
 * @param f The filename
 * @return A copy of the full path
 * @note Never consider using this function if you are dealing with filesystem
 * names that need to remain canonical, unless you are merging an apr_dir_read
 * path and returned filename.  Otherwise, the result is not canonical.
 */
AP_DECLARE(char *) ap_make_full_path(apr_pool_t *a, const char *dir, const char *f);

/**
 * Test if the given path has an absolute path.
 * @param p The pool to allocate from
 * @param dir The directory name
 * @note The converse is not necessarily true, some OS's (Win32/OS2/Netware) have
 * multiple forms of absolute paths.  This only reports if the path is absolute
 * in a canonical sense.
 */
AP_DECLARE(int) ap_os_is_path_absolute(apr_pool_t *p, const char *dir);

/**
 * Does the provided string contain wildcard characters?  This is useful
 * for determining if the string should be passed to strcmp_match or to strcmp.
 * The only wildcard characters recognized are '?' and '*'
 * @param str The string to check
 * @return 1 if the string has wildcards, 0 otherwise
 */
AP_DECLARE(int) ap_is_matchexp(const char *str);

/**
 * Determine if a string matches a pattern containing the wildcards '?' or '*'
 * @param str The string to check
 * @param expected The pattern to match against
 * @return 0 if the two strings match, 1 otherwise
 */
AP_DECLARE(int) ap_strcmp_match(const char *str, const char *expected);

/**
 * Determine if a string matches a pattern containing the wildcards '?' or '*',
 * ignoring case
 * @param str The string to check
 * @param expected The pattern to match against
 * @return 0 if the two strings match, 1 otherwise
 */
AP_DECLARE(int) ap_strcasecmp_match(const char *str, const char *expected);

/**
 * Find the first occurrence of the substring s2 in s1, regardless of case
 * @param s1 The string to search
 * @param s2 The substring to search for
 * @return A pointer to the beginning of the substring
 * @remark See apr_strmatch() for a faster alternative
 */
AP_DECLARE(char *) ap_strcasestr(const char *s1, const char *s2);

/**
 * Return a pointer to the location inside of bigstring immediately after prefix
 * @param bigstring The input string
 * @param prefix The prefix to strip away
 * @return A pointer relative to bigstring after prefix
 */
AP_DECLARE(const char *) ap_stripprefix(const char *bigstring,
                                        const char *prefix);

/**
 * Decode a base64 encoded string into memory allocated from a pool
 * @param p The pool to allocate from
 * @param bufcoded The encoded string
 * @return The decoded string
 */
AP_DECLARE(char *) ap_pbase64decode(apr_pool_t *p, const char *bufcoded);

/**
 * Encode a string into memory allocated from a pool in base 64 format
 * @param p The pool to allocate from
 * @param string The plaintext string
 * @return The encoded string
 */
AP_DECLARE(char *) ap_pbase64encode(apr_pool_t *p, char *string);

/**
 * Compile a regular expression to be used later. The regex is freed when
 * the pool is destroyed.
 * @param p The pool to allocate from
 * @param pattern the regular expression to compile
 * @param cflags The bitwise or of one or more of the following:
 *   @li REG_EXTENDED - Use POSIX extended Regular Expressions
 *   @li REG_ICASE    - Ignore case
 *   @li REG_NOSUB    - Support for substring addressing of matches
 *       not required
 *   @li REG_NEWLINE  - Match-any-character operators don't match new-line
 * @return The compiled regular expression
 */
AP_DECLARE(ap_regex_t *) ap_pregcomp(apr_pool_t *p, const char *pattern,
                                     int cflags);

/**
 * Free the memory associated with a compiled regular expression
 * @param p The pool the regex was allocated from
 * @param reg The regular expression to free
 * @note This function is only necessary if the regex should be cleaned
 * up before the pool
 */
AP_DECLARE(void) ap_pregfree(apr_pool_t *p, ap_regex_t *reg);

/**
 * After performing a successful regex match, you may use this function to
 * perform a series of string substitutions based on subexpressions that were
 * matched during the call to ap_regexec. This function is limited to
 * result strings of 64K. Consider using ap_pregsub_ex() instead.
 * @param p The pool to allocate from
 * @param input An arbitrary string containing $1 through $9.  These are
 *              replaced with the corresponding matched sub-expressions
 * @param source The string that was originally matched to the regex
 * @param nmatch the nmatch returned from ap_pregex
 * @param pmatch the pmatch array returned from ap_pregex
 * @return The substituted string, or NULL on error
 */
AP_DECLARE(char *) ap_pregsub(apr_pool_t *p, const char *input,
                              const char *source, apr_size_t nmatch,
                              ap_regmatch_t pmatch[]);

/**
 * After performing a successful regex match, you may use this function to
 * perform a series of string substitutions based on subexpressions that were
 * matched during the call to ap_regexec
 * @param p The pool to allocate from
 * @param result where to store the result, will be set to NULL on error
 * @param input An arbitrary string containing $1 through $9.  These are
 *              replaced with the corresponding matched sub-expressions
 * @param source The string that was originally matched to the regex
 * @param nmatch the nmatch returned from ap_pregex
 * @param pmatch the pmatch array returned from ap_pregex
 * @param maxlen the maximum string length to return, 0 for unlimited
 * @return APR_SUCCESS if successful, APR_ENOMEM or other error code otherwise.
 */
AP_DECLARE(apr_status_t) ap_pregsub_ex(apr_pool_t *p, char **result,
                                       const char *input, const char *source,
                                       apr_size_t nmatch,
                                       ap_regmatch_t pmatch[],
                                       apr_size_t maxlen);

/**
 * We want to downcase the type/subtype for comparison purposes
 * but nothing else because ;parameter=foo values are case sensitive.
 * @param s The content-type to convert to lowercase
 */
AP_DECLARE(void) ap_content_type_tolower(char *s);

/**
 * convert a string to all lowercase
 * @param s The string to convert to lowercase
 */
AP_DECLARE(void) ap_str_tolower(char *s);

/**
 * convert a string to all uppercase
 * @param s The string to convert to uppercase
 */
AP_DECLARE(void) ap_str_toupper(char *s);

/**
 * Search a string from left to right for the first occurrence of a
 * specific character
 * @param str The string to search
 * @param c The character to search for
 * @return The index of the first occurrence of c in str
 */
AP_DECLARE(int) ap_ind(const char *str, char c);        /* Sigh... */

/**
 * Search a string from right to left for the first occurrence of a
 * specific character
 * @param str The string to search
 * @param c The character to search for
 * @return The index of the first occurrence of c in str
 */
AP_DECLARE(int) ap_rind(const char *str, char c);

/**
 * Given a string, replace any bare &quot; with \\&quot; .
 * @param p The pool to allocate memory from
 * @param instring The string to search for &quot;
 * @return A copy of the string with escaped quotes
 */
AP_DECLARE(char *) ap_escape_quotes(apr_pool_t *p, const char *instring);

/**
 * Given a string, append the PID deliminated by delim.
 * Usually used to create a pid-appended filepath name
 * (eg: /a/b/foo -> /a/b/foo.6726). A function, and not
 * a macro, to avoid unistd.h dependency
 * @param p The pool to allocate memory from
 * @param string The string to append the PID to
 * @param delim The string to use to deliminate the string from the PID
 * @return A copy of the string with the PID appended
 */
AP_DECLARE(char *) ap_append_pid(apr_pool_t *p, const char *string,
                                 const char *delim);

/**
 * Parse a length string with decimal characters only, no leading sign nor
 * trailing character, like Content-Length or (Content-)Range headers.
 * @param len The parsed length (apr_off_t)
 * @param str The string to parse
 * @return 1 (success), 0 (failure)
 */
AP_DECLARE(int) ap_parse_strict_length(apr_off_t *len, const char *str);

/**
 * Parse a given timeout parameter string into an apr_interval_time_t value.
 * The unit of the time interval is given as postfix string to the numeric
 * string. Currently the following units are understood:
 *
 * ms    : milliseconds
 * s     : seconds
 * mi[n] : minutes
 * h     : hours
 *
 * If no unit is contained in the given timeout parameter the default_time_unit
 * will be used instead.
 * @param timeout_parameter The string containing the timeout parameter.
 * @param timeout The timeout value to be returned.
 * @param default_time_unit The default time unit to use if none is specified
 * in timeout_parameter.
 * @return Status value indicating whether the parsing was successful or not.
 */
AP_DECLARE(apr_status_t) ap_timeout_parameter_parse(
                                               const char *timeout_parameter,
                                               apr_interval_time_t *timeout,
                                               const char *default_time_unit);

/**
 * Determine if a request has a request body or not.
 *
 * @param r the request_rec of the request
 * @return truth value
 */
AP_DECLARE(int) ap_request_has_body(request_rec *r);

/**
 * Cleanup a string (mainly to be filesystem safe)
 * We only allow '_' and alphanumeric chars. Non-printable
 * map to 'x' and all others map to '_'
 *
 * @param  p pool to use to allocate dest
 * @param  src string to clean up
 * @param  dest cleaned up, allocated string
 * @return Status value indicating whether the cleaning was successful or not.
 */
AP_DECLARE(apr_status_t) ap_pstr2_alnum(apr_pool_t *p, const char *src,
                                        const char **dest);

/**
 * Cleanup a string (mainly to be filesystem safe)
 * We only allow '_' and alphanumeric chars. Non-printable
 * map to 'x' and all others map to '_'
 *
 * @param  src string to clean up
 * @param  dest cleaned up, pre-allocated string
 * @return Status value indicating whether the cleaning was successful or not.
 */
AP_DECLARE(apr_status_t) ap_str2_alnum(const char *src, char *dest);

/**
 * Structure to store the contents of an HTTP form of the type
 * application/x-www-form-urlencoded.
 *
 * Currently it contains the name as a char* of maximum length
 * HUGE_STRING_LEN, and a value in the form of a bucket brigade
 * of arbitrary length.
 */
typedef struct {
    const char *name;
    apr_bucket_brigade *value;
} ap_form_pair_t;

/**
 * Read the body and parse any form found, which must be of the
 * type application/x-www-form-urlencoded.
 * @param r request containing POSTed form data
 * @param f filter
 * @param ptr returned array of ap_form_pair_t
 * @param num max num of params or -1 for unlimited
 * @param size max size allowed for parsed data
 * @return OK or HTTP error
 */
AP_DECLARE(int) ap_parse_form_data(request_rec *r, struct ap_filter_t *f,
                                   apr_array_header_t **ptr,
                                   apr_size_t num, apr_size_t size);

/* Misc system hackery */
/**
 * Given the name of an object in the file system determine if it is a directory
 * @param p The pool to allocate from
 * @param name The name of the object to check
 * @return 1 if it is a directory, 0 otherwise
 */
AP_DECLARE(int) ap_is_rdirectory(apr_pool_t *p, const char *name);

/**
 * Given the name of an object in the file system determine if it is a directory - this version is symlink aware
 * @param p The pool to allocate from
 * @param name The name of the object to check
 * @return 1 if it is a directory, 0 otherwise
 */
AP_DECLARE(int) ap_is_directory(apr_pool_t *p, const char *name);

#ifdef _OSD_POSIX
extern int os_init_job_environment(server_rec *s, const char *user_name, int one_process);
#endif /* _OSD_POSIX */

/**
 * Determine the local host name for the current machine
 * @param p The pool to allocate from
 * @return A copy of the local host name
 */
char *ap_get_local_host(apr_pool_t *p);

/**
 * Log an assertion to the error log
 * @param szExp The assertion that failed
 * @param szFile The file the assertion is in
 * @param nLine The line the assertion is defined on
 */
AP_DECLARE(void) ap_log_assert(const char *szExp, const char *szFile, int nLine)
                            __attribute__((noreturn));

/**
 * @internal Internal Assert function
 */
#define ap_assert(exp) ((exp) ? (void)0 : ap_log_assert(#exp,__FILE__,__LINE__))

/**
 * Redefine assert() to something more useful for an Apache...
 *
 * Use ap_assert() if the condition should always be checked.
 * Use AP_DEBUG_ASSERT() if the condition should only be checked when AP_DEBUG
 * is defined.
 */
#ifdef AP_DEBUG
#define AP_DEBUG_ASSERT(exp) ap_assert(exp)
#else
#define AP_DEBUG_ASSERT(exp) ((void)0)
#endif

/**
 * @defgroup stopsignal Flags which indicate places where the server should stop for debugging.
 * @{
 * A set of flags which indicate places where the server should raise(SIGSTOP).
 * This is useful for debugging, because you can then attach to that process
 * with gdb and continue.  This is important in cases where one_process
 * debugging isn't possible.
 */
/** stop on a Detach */
#define SIGSTOP_DETACH                  1
/** stop making a child process */
#define SIGSTOP_MAKE_CHILD              2
/** stop spawning a child process */
#define SIGSTOP_SPAWN_CHILD             4
/** stop spawning a child process with a piped log */
#define SIGSTOP_PIPED_LOG_SPAWN         8
/** stop spawning a CGI child process */
#define SIGSTOP_CGI_CHILD               16

/** Macro to get GDB started */
#ifdef DEBUG_SIGSTOP
extern int raise_sigstop_flags;
#define RAISE_SIGSTOP(x)        do { \
        if (raise_sigstop_flags & SIGSTOP_##x) raise(SIGSTOP);\
    } while (0)
#else
#define RAISE_SIGSTOP(x)
#endif
/** @} */
/**
 * Get HTML describing the address and (optionally) admin of the server.
 * @param prefix Text which is prepended to the return value
 * @param r The request_rec
 * @return HTML describing the server, allocated in @a r's pool.
 */
AP_DECLARE(const char *) ap_psignature(const char *prefix, request_rec *r);

  /* The C library has functions that allow const to be silently dropped ...
     these macros detect the drop in maintainer mode, but use the native
     methods for normal builds

     Note that on some platforms (e.g., AIX with gcc, Solaris with gcc), string.h needs
     to be included before the macros are defined or compilation will fail.
  */
#include <string.h>

AP_DECLARE(char *) ap_strchr(char *s, int c);
AP_DECLARE(const char *) ap_strchr_c(const char *s, int c);
AP_DECLARE(char *) ap_strrchr(char *s, int c);
AP_DECLARE(const char *) ap_strrchr_c(const char *s, int c);
AP_DECLARE(char *) ap_strstr(char *s, const char *c);
AP_DECLARE(const char *) ap_strstr_c(const char *s, const char *c);

#ifdef AP_DEBUG

#undef strchr
# define strchr(s, c)  ap_strchr(s,c)
#undef strrchr
# define strrchr(s, c) ap_strrchr(s,c)
#undef strstr
# define strstr(s, c)  ap_strstr(s,c)

#else

/** use this instead of strchr */
# define ap_strchr(s, c)     strchr(s, c)
/** use this instead of strchr */
# define ap_strchr_c(s, c)   strchr(s, c)
/** use this instead of strrchr */
# define ap_strrchr(s, c)    strrchr(s, c)
/** use this instead of strrchr */
# define ap_strrchr_c(s, c)  strrchr(s, c)
/** use this instead of strrstr*/
# define ap_strstr(s, c)     strstr(s, c)
/** use this instead of strrstr*/
# define ap_strstr_c(s, c)   strstr(s, c)

#endif

/**
 * Generate pseudo random bytes.
 * This is a convenience interface to apr_random. It is cheaper but less
 * secure than apr_generate_random_bytes().
 * @param buf where to store the bytes
 * @param size number of bytes to generate
 * @note ap_random_insecure_bytes() is thread-safe, it uses a mutex on
 *       threaded MPMs.
 */
AP_DECLARE(void) ap_random_insecure_bytes(void *buf, apr_size_t size);

/**
 * Get a pseudo random number in a range.
 * @param min low end of range
 * @param max high end of range
 * @return a number in the range
 */
AP_DECLARE(apr_uint32_t) ap_random_pick(apr_uint32_t min, apr_uint32_t max);

/**
 * Abort with a error message signifying out of memory
 */
AP_DECLARE(void) ap_abort_on_oom(void) __attribute__((noreturn));

/**
 * Wrapper for malloc() that calls ap_abort_on_oom() if out of memory
 * @param size size of the memory block
 * @return pointer to the allocated memory
 * @note ap_malloc may be implemented as a macro
 */
AP_DECLARE(void *) ap_malloc(size_t size)
                    __attribute__((malloc))
                    AP_FN_ATTR_ALLOC_SIZE(1);

/**
 * Wrapper for calloc() that calls ap_abort_on_oom() if out of memory
 * @param nelem number of elements to allocate memory for
 * @param size size of a single element
 * @return pointer to the allocated memory
 * @note ap_calloc may be implemented as a macro
 */
AP_DECLARE(void *) ap_calloc(size_t nelem, size_t size)
                   __attribute__((malloc))
                   AP_FN_ATTR_ALLOC_SIZE2(1,2);

/**
 * Wrapper for realloc() that calls ap_abort_on_oom() if out of memory
 * @param ptr pointer to the old memory block (or NULL)
 * @param size new size of the memory block
 * @return pointer to the reallocated memory
 * @note ap_realloc may be implemented as a macro
 */
AP_DECLARE(void *) ap_realloc(void *ptr, size_t size)
                   AP_FN_ATTR_WARN_UNUSED_RESULT
                   AP_FN_ATTR_ALLOC_SIZE(2);

#if APR_HAS_THREADS

#if APR_VERSION_AT_LEAST(1,8,0) && !defined(AP_NO_THREAD_LOCAL)

/**
 * APR 1.8+ implement those already.
 */
#if APR_HAS_THREAD_LOCAL
#define AP_HAS_THREAD_LOCAL 1
#define AP_THREAD_LOCAL     APR_THREAD_LOCAL
#else
#define AP_HAS_THREAD_LOCAL 0
#endif
#define ap_thread_create                apr_thread_create
#define ap_thread_current               apr_thread_current
#define ap_thread_current_create        apr_thread_current_create
#define ap_thread_current_after_fork    apr_thread_current_after_fork

#else /* APR_VERSION_AT_LEAST(1,8,0) && !defined(AP_NO_THREAD_LOCAL) */

#ifndef AP_NO_THREAD_LOCAL
/**
 * AP_THREAD_LOCAL keyword mapping the compiler's.
 */
#if defined(__cplusplus) && __cplusplus >= 201103L
#define AP_THREAD_LOCAL thread_local
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112 && \
      (!defined(__GNUC__) || \
      __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
#define AP_THREAD_LOCAL _Thread_local
#elif defined(__GNUC__) /* works for clang too */
#define AP_THREAD_LOCAL __thread
#elif defined(WIN32) && defined(_MSC_VER)
#define AP_THREAD_LOCAL __declspec(thread)
#endif
#endif /* ndef AP_NO_THREAD_LOCAL */

#ifndef AP_THREAD_LOCAL
#define AP_HAS_THREAD_LOCAL 0
#define ap_thread_create apr_thread_create
#else /* AP_THREAD_LOCAL */
#define AP_HAS_THREAD_LOCAL 1
AP_DECLARE(apr_status_t) ap_thread_create(apr_thread_t **thread, 
                                          apr_threadattr_t *attr, 
                                          apr_thread_start_t func, 
                                          void *data, apr_pool_t *pool);
#endif /* AP_THREAD_LOCAL */

AP_DECLARE(apr_status_t) ap_thread_current_create(apr_thread_t **current,
                                                  apr_threadattr_t *attr,
                                                  apr_pool_t *pool);
AP_DECLARE(void) ap_thread_current_after_fork(void);
AP_DECLARE(apr_thread_t *) ap_thread_current(void);

#endif /* APR_VERSION_AT_LEAST(1,8,0) && !defined(AP_NO_THREAD_LOCAL) */

AP_DECLARE(apr_status_t) ap_thread_main_create(apr_thread_t **thread,
                                               apr_pool_t *pool);

#else  /* APR_HAS_THREADS */

#define AP_HAS_THREAD_LOCAL 0

#endif /* APR_HAS_THREADS */

/**
 * Get server load params
 * @param ld struct to populate: -1 in fields means error
 */
AP_DECLARE(void) ap_get_sload(ap_sload_t *ld);

/**
 * Get server load averages (ala getloadavg)
 * @param ld struct to populate: -1 in fields means error
 */
AP_DECLARE(void) ap_get_loadavg(ap_loadavg_t *ld);

/**
 * Convert binary data into a hex string
 * @param src pointer to the data
 * @param srclen length of the data
 * @param dest pointer to buffer of length (2 * srclen + 1). The resulting
 *        string will be NUL-terminated.
 */
AP_DECLARE(void) ap_bin2hex(const void *src, apr_size_t srclen, char *dest);

/**
 * Short function to execute a command and return the first line of
 * output minus \\r \\n. Useful for "obscuring" passwords via exec calls
 * @param p the pool to allocate from
 * @param cmd the command to execute
 * @param argv the arguments to pass to the cmd
 * @return ptr to characters or NULL on any error
 */
AP_DECLARE(char *) ap_get_exec_line(apr_pool_t *p,
                                    const char *cmd,
                                    const char * const *argv);

#define AP_NORESTART APR_OS_START_USEERR + 1

/**
 * Get the first index of the string in the array or -1 if not found. Start
 * searching a start. 
 * @param array The array the check
 * @param s The string to find
 * @param start Start index for search. If start is out of bounds (negative or  
                equal to array length or greater), -1 will be returned.
 * @return index of string in array or -1
 */
AP_DECLARE(int) ap_array_str_index(const apr_array_header_t *array, 
                                   const char *s,
                                   int start);

/**
 * Check if the string is member of the given array by strcmp.
 * @param array The array the check
 * @param s The string to find
 * @return !=0 iff string is member of array (via strcmp)
 */
AP_DECLARE(int) ap_array_str_contains(const apr_array_header_t *array, 
                                      const char *s);

/**
 * Perform a case-insensitive comparison of two strings @a str1 and @a str2,
 * treating upper and lower case values of the 26 standard C/POSIX alphabetic
 * characters as equivalent. Extended latin characters outside of this set
 * are treated as unique octets, irrespective of the current locale.
 *
 * Returns in integer greater than, equal to, or less than 0,
 * according to whether @a str1 is considered greater than, equal to,
 * or less than @a str2.
 *
 * @note Same code as apr_cstr_casecmp, which arrives in APR 1.6
 */
AP_DECLARE(int) ap_cstr_casecmp(const char *s1, const char *s2);

/**
 * Perform a case-insensitive comparison of two strings @a str1 and @a str2,
 * treating upper and lower case values of the 26 standard C/POSIX alphabetic
 * characters as equivalent. Extended latin characters outside of this set
 * are treated as unique octets, irrespective of the current locale.
 *
 * Returns in integer greater than, equal to, or less than 0,
 * according to whether @a str1 is considered greater than, equal to,
 * or less than @a str2.
 *
 * @note Same code as apr_cstr_casecmpn, which arrives in APR 1.6
 */
AP_DECLARE(int) ap_cstr_casecmpn(const char *s1, const char *s2, apr_size_t n);

/**
 * Default flags for ap_dir_*fnmatch().
 */
#define AP_DIR_FLAG_NONE      0

/**
 * If set, wildcards that match no files or directories will be ignored, otherwise
 * an error is triggered.
 */
#define AP_DIR_FLAG_OPTIONAL  1

/**
 * If set, and the wildcard resolves to a directory, recursively find all files
 * below that directory, otherwise return the directory.
 */
#define AP_DIR_FLAG_RECURSIVE 2

/**
 * Structure to provide the state of a directory match.
 */
typedef struct ap_dir_match_t ap_dir_match_t;

/**
 * Concrete structure to provide the state of a directory match.
 */
struct ap_dir_match_t {
    /** Pool to use for allocating the result */
    apr_pool_t *p;
    /** Temporary pool used for directory traversal */
    apr_pool_t *ptemp;
    /** Prefix for log messages */
    const char *prefix;
    /** Callback for each file found that matches the wildcard. Return NULL on success, an error string on error. */
    const char *(*cb)(ap_dir_match_t *w, const char *fname);
    /** Context for the callback */
    void *ctx;
    /** Flags to indicate whether optional or recursive */
    int flags;
    /** Recursion depth safety check */
    unsigned int depth;
};

/**
 * Search for files given a non wildcard filename with non native separators.
 *
 * If the provided filename points at a file, the callback within ap_dir_match_t is
 * triggered for that file, and this function returns the result of the callback.
 *
 * If the provided filename points at a directory, and recursive within ap_dir_match_t
 * is true, the callback will be triggered for every file found recursively beneath
 * that directory, otherwise the callback is triggered once for the directory itself.
 * This function returns the result of the callback.
 *
 * If the provided path points to neither a file nor a directory, and optional within
 * ap_dir_match_t is true, this function returns NULL. If optional within ap_dir_match_t
 * is false, this function will return an error string indicating that the path does not
 * exist.
 *
 * @param w Directory match structure containing callback and context.
 * @param fname The name of the file or directory, with non native separators.
 * @return NULL on success, or a string describing the error.
 */
AP_DECLARE(const char *)ap_dir_nofnmatch(ap_dir_match_t *w, const char *fname)
        __attribute__((nonnull(1,2)));

/**
 * Search for files given a wildcard filename with non native separators.
 *
 * If the filename contains a wildcard, all files and directories that match the wildcard
 * will be returned.
 *
 * ap_dir_nofnmatch() is called for each directory and file found, and the callback
 * within ap_dir_match_t triggered as described above.
 *
 * Wildcards may appear in both directory and file components in the path, and
 * wildcards may appear more than once.
 *
 * @param w Directory match structure containing callback and context.
 * @param path Path prefix for search, with non native separators and no wildcards.
 * @param fname The name of the file or directory, with non native separators and
 * optional wildcards.
 * @return NULL on success, or a string describing the error.
 */
AP_DECLARE(const char *)ap_dir_fnmatch(ap_dir_match_t *w, const char *path,
        const char *fname) __attribute__((nonnull(1,3)));

/**
 * Determine if the final Transfer-Encoding is "chunked".
 *
 * @param p The pool to allocate from
 * @param line the header field-value to scan
 * @return 1 if the last Transfer-Encoding is "chunked", else 0
 */
AP_DECLARE(int) ap_is_chunked(apr_pool_t *p, const char *line);


/**
 * apr_filepath_merge with an allow-list
 * Merge additional file path onto the previously processed rootpath
 * @param newpath the merged paths returned
 * @param rootpath the root file path (NULL uses the current working path)
 * @param addpath the path to add to the root path
 * @param flags the desired APR_FILEPATH_ rules to apply when merging
 * @param p the pool to allocate the new path string from
 * @remark if the flag APR_FILEPATH_TRUENAME is given, and the addpath
 * contains wildcard characters ('*', '?') on platforms that don't support
 * such characters within filenames, the paths will be merged, but the
 * result code will be APR_EPATHWILD, and all further segments will not
 * reflect the true filenames including the wildcard and following segments.
 */
AP_DECLARE(apr_status_t) ap_filepath_merge(char **newpath,
                                             const char *rootpath,
                                             const char *addpath,
                                             apr_int32_t flags,
                                             apr_pool_t *p);

#ifdef WIN32
#define apr_filepath_merge  ap_filepath_merge
#endif

/* Win32/NetWare/OS2 need to check for both forward and back slashes
 * in ap_normalize_path() and ap_escape_url().
 */
#ifdef CASE_BLIND_FILESYSTEM
#define AP_IS_SLASH(s) ((s == '/') || (s == '\\'))
#define AP_SLASHES "/\\"
#else
#define AP_IS_SLASH(s) (s == '/')
#define AP_SLASHES "/"
#endif

/**
 * Validates the path parameter is safe to pass to stat-like calls.
 * @param path The filesystem path to cehck
 * @param p a pool for temporary allocations
 * @return APR_SUCCESS if the stat-like call should be allowed
 */
AP_DECLARE(apr_status_t) ap_stat_check(const char *path, apr_pool_t *pool);


#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_HTTPD_H */

/** @} //APACHE Daemon      */
/** @} //APACHE Core        */
/** @} //APACHE super group */

