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
 * @file  http_log.h
 * @brief Apache Logging library
 *
 * @defgroup APACHE_CORE_LOG Logging library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_HTTP_LOG_H
#define APACHE_HTTP_LOG_H

#ifdef __cplusplus
extern "C" {
#endif

#include "apr_thread_proc.h"
#include "http_config.h"

#ifdef HAVE_SYSLOG
#include <syslog.h>

#ifndef LOG_PRIMASK
#define LOG_PRIMASK 7
#endif

#define APLOG_EMERG     LOG_EMERG       /* system is unusable */
#define APLOG_ALERT     LOG_ALERT       /* action must be taken immediately */
#define APLOG_CRIT      LOG_CRIT        /* critical conditions */
#define APLOG_ERR       LOG_ERR         /* error conditions */
#define APLOG_WARNING   LOG_WARNING     /* warning conditions */
#define APLOG_NOTICE    LOG_NOTICE      /* normal but significant condition */
#define APLOG_INFO      LOG_INFO        /* informational */
#define APLOG_DEBUG     LOG_DEBUG       /* debug-level messages */
#define APLOG_TRACE1   (LOG_DEBUG + 1)  /* trace-level 1 messages */
#define APLOG_TRACE2   (LOG_DEBUG + 2)  /* trace-level 2 messages */
#define APLOG_TRACE3   (LOG_DEBUG + 3)  /* trace-level 3 messages */
#define APLOG_TRACE4   (LOG_DEBUG + 4)  /* trace-level 4 messages */
#define APLOG_TRACE5   (LOG_DEBUG + 5)  /* trace-level 5 messages */
#define APLOG_TRACE6   (LOG_DEBUG + 6)  /* trace-level 6 messages */
#define APLOG_TRACE7   (LOG_DEBUG + 7)  /* trace-level 7 messages */
#define APLOG_TRACE8   (LOG_DEBUG + 8)  /* trace-level 8 messages */

#define APLOG_LEVELMASK 15     /* mask off the level value */

#else

#define APLOG_EMERG      0     /* system is unusable */
#define APLOG_ALERT      1     /* action must be taken immediately */
#define APLOG_CRIT       2     /* critical conditions */
#define APLOG_ERR        3     /* error conditions */
#define APLOG_WARNING    4     /* warning conditions */
#define APLOG_NOTICE     5     /* normal but significant condition */
#define APLOG_INFO       6     /* informational */
#define APLOG_DEBUG      7     /* debug-level messages */
#define APLOG_TRACE1     8     /* trace-level 1 messages */
#define APLOG_TRACE2     9     /* trace-level 2 messages */
#define APLOG_TRACE3    10     /* trace-level 3 messages */
#define APLOG_TRACE4    11     /* trace-level 4 messages */
#define APLOG_TRACE5    12     /* trace-level 5 messages */
#define APLOG_TRACE6    13     /* trace-level 6 messages */
#define APLOG_TRACE7    14     /* trace-level 7 messages */
#define APLOG_TRACE8    15     /* trace-level 8 messages */

#define APLOG_LEVELMASK 15     /* mask off the level value */

#endif

/* APLOG_NOERRNO is ignored and should not be used.  It will be
 * removed in a future release of Apache.
 */
#define APLOG_NOERRNO           (APLOG_LEVELMASK + 1)

/** Use APLOG_TOCLIENT on ap_log_rerror() to give content
 * handlers the option of including the error text in the
 * ErrorDocument sent back to the client. Setting APLOG_TOCLIENT
 * will cause the error text to be saved in the request_rec->notes
 * table, keyed to the string "error-notes", if and only if:
 * - the severity level of the message is APLOG_WARNING or greater
 * - there are no other "error-notes" set in request_rec->notes
 * Once error-notes is set, it is up to the content handler to
 * determine whether this text should be sent back to the client.
 * Note: Client generated text streams sent back to the client MUST
 * be escaped to prevent CSS attacks.
 */
#define APLOG_TOCLIENT          ((APLOG_LEVELMASK + 1) * 2)

/* normal but significant condition on startup, usually printed to stderr */
#define APLOG_STARTUP           ((APLOG_LEVELMASK + 1) * 4)

#ifndef DEFAULT_LOGLEVEL
#define DEFAULT_LOGLEVEL        APLOG_WARNING
#endif

/**
 * APLOGNO() should be used at the start of the format string passed
 * to ap_log_error() and friends. The argument must be a 5 digit decimal
 * number. It creates a tag of the form "AH02182: "
 * See docs/log-message-tags/README for details.
 */
#define APLOGNO(n)              "AH" #n ": "

/**
 * APLOG_NO_MODULE may be passed as module_index to ap_log_error() and related
 * functions if the module causing the log message is not known. Normally this
 * should not be used directly. Use ::APLOG_MARK or ::APLOG_MODULE_INDEX
 * instead.
 *
 * @see APLOG_MARK
 * @see APLOG_MODULE_INDEX
 * @see ap_log_error
 */
#define APLOG_NO_MODULE         -1

#ifdef __cplusplus
/**
 * C++ modules must invoke ::APLOG_USE_MODULE or ::AP_DECLARE_MODULE in
 * every file which uses ap_log_* before the first use of ::APLOG_MARK
 * or ::APLOG_MODULE_INDEX.
 * (C modules *should* do that as well, to enable module-specific log
 * levels. C modules need not obey the ordering, though).
 */
#else /* __cplusplus */
/**
 * Constant to store module_index for the current file.
 * Objects with static storage duration are set to NULL if not
 * initialized explicitly. This means that if aplog_module_index
 * is not initialized using the ::APLOG_USE_MODULE or the
 * ::AP_DECLARE_MODULE macro, we can safely fall back to
 * use ::APLOG_NO_MODULE. This variable will usually be optimized away.
 */
static int * const aplog_module_index;
#endif /* __cplusplus */

/**
 * APLOG_MODULE_INDEX contains the module_index of the current module if
 * it has been set via the ::APLOG_USE_MODULE or ::AP_DECLARE_MODULE macro.
 * Otherwise it contains ::APLOG_NO_MODULE (for example in unmodified httpd
 * 2.2 modules).
 *
 * If ::APLOG_MARK is used in ap_log_error() and related functions,
 * ::APLOG_MODULE_INDEX will be passed as module_index. In cases where
 * ::APLOG_MARK cannot be used, ::APLOG_MODULE_INDEX should normally be passed
 * as module_index.
 *
 * @see APLOG_MARK
 * @see ap_log_error
 */
#ifdef __cplusplus
#define APLOG_MODULE_INDEX (*aplog_module_index)
#else /* __cplusplus */
#define APLOG_MODULE_INDEX  \
    (aplog_module_index ? *aplog_module_index : APLOG_NO_MODULE)
#endif /* __cplusplus */

/**
 * APLOG_MAX_LOGLEVEL can be defined to remove logging above some
 * specified level at compile time.
 *
 * This requires a C99 compiler.
 */
#ifdef DOXYGEN
#define APLOG_MAX_LOGLEVEL
#endif
#ifndef APLOG_MAX_LOGLEVEL
#define APLOG_MODULE_IS_LEVEL(s,module_index,level)              \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||       \
            (s == NULL) ||                                       \
            (ap_get_server_module_loglevel(s, module_index)      \
             >= ((level)&APLOG_LEVELMASK) ) )
#define APLOG_C_MODULE_IS_LEVEL(c,module_index,level)            \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||       \
            (ap_get_conn_module_loglevel(c, module_index)        \
             >= ((level)&APLOG_LEVELMASK) ) )
#define APLOG_CS_MODULE_IS_LEVEL(c,s,module_index,level)            \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||          \
            (ap_get_conn_server_module_loglevel(c, s, module_index) \
             >= ((level)&APLOG_LEVELMASK) ) )
#define APLOG_R_MODULE_IS_LEVEL(r,module_index,level)            \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||       \
            (ap_get_request_module_loglevel(r, module_index)     \
             >= ((level)&APLOG_LEVELMASK) ) )
#else
#define APLOG_MODULE_IS_LEVEL(s,module_index,level)              \
        ( (((level)&APLOG_LEVELMASK) <= APLOG_MAX_LOGLEVEL) &&   \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||       \
            (s == NULL) ||                                       \
            (ap_get_server_module_loglevel(s, module_index)      \
             >= ((level)&APLOG_LEVELMASK) ) ) )
#define APLOG_CS_MODULE_IS_LEVEL(c,s,module_index,level)            \
        ( (((level)&APLOG_LEVELMASK) <= APLOG_MAX_LOGLEVEL) &&      \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||          \
            (ap_get_conn_server_module_loglevel(c, s, module_index) \
             >= ((level)&APLOG_LEVELMASK) ) ) )
#define APLOG_C_MODULE_IS_LEVEL(c,module_index,level)            \
        ( (((level)&APLOG_LEVELMASK) <= APLOG_MAX_LOGLEVEL) &&   \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||       \
            (ap_get_conn_module_loglevel(c, module_index)        \
             >= ((level)&APLOG_LEVELMASK) ) ) )
#define APLOG_R_MODULE_IS_LEVEL(r,module_index,level)            \
        ( (((level)&APLOG_LEVELMASK) <= APLOG_MAX_LOGLEVEL) &&   \
          ( (((level)&APLOG_LEVELMASK) <= APLOG_NOTICE) ||       \
            (ap_get_request_module_loglevel(r, module_index)     \
             >= ((level)&APLOG_LEVELMASK) ) ) )
#endif

#define APLOG_IS_LEVEL(s,level)     \
    APLOG_MODULE_IS_LEVEL(s,APLOG_MODULE_INDEX,level)
#define APLOG_C_IS_LEVEL(c,level)   \
    APLOG_C_MODULE_IS_LEVEL(c,APLOG_MODULE_INDEX,level)
#define APLOG_CS_IS_LEVEL(c,s,level) \
    APLOG_CS_MODULE_IS_LEVEL(c,s,APLOG_MODULE_INDEX,level)
#define APLOG_R_IS_LEVEL(r,level)   \
    APLOG_R_MODULE_IS_LEVEL(r,APLOG_MODULE_INDEX,level)


#define APLOGinfo(s)                APLOG_IS_LEVEL(s,APLOG_INFO)
#define APLOGdebug(s)               APLOG_IS_LEVEL(s,APLOG_DEBUG)
#define APLOGtrace1(s)              APLOG_IS_LEVEL(s,APLOG_TRACE1)
#define APLOGtrace2(s)              APLOG_IS_LEVEL(s,APLOG_TRACE2)
#define APLOGtrace3(s)              APLOG_IS_LEVEL(s,APLOG_TRACE3)
#define APLOGtrace4(s)              APLOG_IS_LEVEL(s,APLOG_TRACE4)
#define APLOGtrace5(s)              APLOG_IS_LEVEL(s,APLOG_TRACE5)
#define APLOGtrace6(s)              APLOG_IS_LEVEL(s,APLOG_TRACE6)
#define APLOGtrace7(s)              APLOG_IS_LEVEL(s,APLOG_TRACE7)
#define APLOGtrace8(s)              APLOG_IS_LEVEL(s,APLOG_TRACE8)

#define APLOGrinfo(r)               APLOG_R_IS_LEVEL(r,APLOG_INFO)
#define APLOGrdebug(r)              APLOG_R_IS_LEVEL(r,APLOG_DEBUG)
#define APLOGrtrace1(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE1)
#define APLOGrtrace2(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE2)
#define APLOGrtrace3(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE3)
#define APLOGrtrace4(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE4)
#define APLOGrtrace5(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE5)
#define APLOGrtrace6(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE6)
#define APLOGrtrace7(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE7)
#define APLOGrtrace8(r)             APLOG_R_IS_LEVEL(r,APLOG_TRACE8)

#define APLOGcinfo(c)               APLOG_C_IS_LEVEL(c,APLOG_INFO)
#define APLOGcdebug(c)              APLOG_C_IS_LEVEL(c,APLOG_DEBUG)
#define APLOGctrace1(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE1)
#define APLOGctrace2(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE2)
#define APLOGctrace3(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE3)
#define APLOGctrace4(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE4)
#define APLOGctrace5(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE5)
#define APLOGctrace6(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE6)
#define APLOGctrace7(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE7)
#define APLOGctrace8(c)             APLOG_C_IS_LEVEL(c,APLOG_TRACE8)

AP_DECLARE_DATA extern int ap_default_loglevel;

/**
 * APLOG_MARK is a convenience macro for use as the first three parameters in
 * ap_log_error() and related functions, i.e. file, line, and module_index.
 *
 * The module_index parameter was introduced in version 2.3.6. Before that
 * version, APLOG_MARK only replaced the file and line parameters.
 * This means that APLOG_MARK can be used with ap_log_*error in all versions
 * of Apache httpd.
 *
 * @see APLOG_MODULE_INDEX
 * @see ap_log_error
 * @see ap_log_cerror
 * @see ap_log_rerror
 * @see ap_log_cserror
 */
#define APLOG_MARK     __FILE__,__LINE__,APLOG_MODULE_INDEX

/**
 * Set up for logging to stderr.
 * @param p The pool to allocate out of
 */
AP_DECLARE(void) ap_open_stderr_log(apr_pool_t *p);

/**
 * Replace logging to stderr with logging to the given file.
 * @param p The pool to allocate out of
 * @param file Name of the file to log stderr output
 */
AP_DECLARE(apr_status_t) ap_replace_stderr_log(apr_pool_t *p,
                                               const char *file);

/**
 * Open the error log and replace stderr with it.
 * @param pconf Not used
 * @param plog  The pool to allocate the logs from
 * @param ptemp Pool used for temporary allocations
 * @param s_main The main server
 * @note ap_open_logs isn't expected to be used by modules, it is
 * an internal core function
 */
int ap_open_logs(apr_pool_t *pconf, apr_pool_t *plog,
                 apr_pool_t *ptemp, server_rec *s_main);

/**
 * Perform special processing for piped loggers in MPM child
 * processes.
 * @param p Not used
 * @param s Not used
 * @note ap_logs_child_init is not for use by modules; it is an
 * internal core function
 */
void ap_logs_child_init(apr_pool_t *p, server_rec *s);

/*
 * The primary logging functions, ap_log_error, ap_log_rerror, ap_log_cerror,
 * and ap_log_perror use a printf style format string to build the log message.
 * It is VERY IMPORTANT that you not include any raw data from the network,
 * such as the request-URI or request header fields, within the format
 * string.  Doing so makes the server vulnerable to a denial-of-service
 * attack and other messy behavior.  Instead, use a simple format string
 * like "%s", followed by the string containing the untrusted data.
 */

/**
 * ap_log_error() - log messages which are not related to a particular
 * request or connection.  This uses a printf-like format to log messages
 * to the error_log.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index The module_index of the module generating this message
 * @param level The level of this error message
 * @param status The status code from the previous command
 * @param s The server on which we are logging
 * @param fmt The format string
 * @param ... The arguments to use to fill out fmt.
 * @note ap_log_error is implemented as a macro
 * @note Use APLOG_MARK to fill out file and line
 * @note If a request_rec is available, use that with ap_log_rerror()
 * in preference to calling this function.  Otherwise, if a conn_rec is
 * available, use that with ap_log_cerror() in preference to calling
 * this function.
 * @warning It is VERY IMPORTANT that you not include any raw data from
 * the network, such as the request-URI or request header fields, within
 * the format string.  Doing so makes the server vulnerable to a
 * denial-of-service attack and other messy behavior.  Instead, use a
 * simple format string like "%s", followed by the string containing the
 * untrusted data.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_error(const char *file, int line, int module_index,
                              int level, apr_status_t status,
                              const server_rec *s, const char *fmt, ...);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_error(...) ap_log_error__(__VA_ARGS__)
/* need server_rec *sr = ... for the case if s is verbatim NULL */
#define ap_log_error__(file, line, mi, level, status, s, ...)           \
    do { const server_rec *sr__ = s; if (APLOG_MODULE_IS_LEVEL(sr__, mi, level)) \
             ap_log_error_(file, line, mi, level, status, sr__, __VA_ARGS__);    \
    } while(0)
#else
#define ap_log_error ap_log_error_
#endif
AP_DECLARE(void) ap_log_error_(const char *file, int line, int module_index,
                               int level, apr_status_t status,
                               const server_rec *s, const char *fmt, ...)
                              __attribute__((format(printf,7,8)));
#endif

/**
 * ap_log_perror() - log messages which are not related to a particular
 * request, connection, or virtual server.  This uses a printf-like
 * format to log messages to the error_log.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index ignored dummy value for use by APLOG_MARK
 * @param level The level of this error message
 * @param status The status code from the previous command
 * @param p The pool which we are logging for
 * @param fmt The format string
 * @param ... The arguments to use to fill out fmt.
 * @note ap_log_perror is implemented as a macro
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @warning It is VERY IMPORTANT that you not include any raw data from
 * the network, such as the request-URI or request header fields, within
 * the format string.  Doing so makes the server vulnerable to a
 * denial-of-service attack and other messy behavior.  Instead, use a
 * simple format string like "%s", followed by the string containing the
 * untrusted data.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_perror(const char *file, int line, int module_index,
                               int level, apr_status_t status, apr_pool_t *p,
                               const char *fmt, ...);
#else
#if defined(AP_HAVE_C99) && defined(APLOG_MAX_LOGLEVEL)
/* need additional step to expand APLOG_MARK first */
#define ap_log_perror(...) ap_log_perror__(__VA_ARGS__)
#define ap_log_perror__(file, line, mi, level, status, p, ...)            \
    do { if ((level) <= APLOG_MAX_LOGLEVEL )                              \
             ap_log_perror_(file, line, mi, level, status, p,             \
                            __VA_ARGS__); } while(0)
#else
#define ap_log_perror ap_log_perror_
#endif
AP_DECLARE(void) ap_log_perror_(const char *file, int line, int module_index,
                                int level, apr_status_t status, apr_pool_t *p,
                                const char *fmt, ...)
                               __attribute__((format(printf,7,8)));
#endif

/**
 * ap_log_rerror() - log messages which are related to a particular
 * request.  This uses a printf-like format to log messages to the
 * error_log.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index The module_index of the module generating this message
 * @param level The level of this error message
 * @param status The status code from the previous command
 * @param r The request which we are logging for
 * @param fmt The format string
 * @param ... The arguments to use to fill out fmt.
 * @note ap_log_rerror is implemented as a macro
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @warning It is VERY IMPORTANT that you not include any raw data from
 * the network, such as the request-URI or request header fields, within
 * the format string.  Doing so makes the server vulnerable to a
 * denial-of-service attack and other messy behavior.  Instead, use a
 * simple format string like "%s", followed by the string containing the
 * untrusted data.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_rerror(const char *file, int line, int module_index,
                               int level, apr_status_t status,
                               const request_rec *r, const char *fmt, ...);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_rerror(...) ap_log_rerror__(__VA_ARGS__)
#define ap_log_rerror__(file, line, mi, level, status, r, ...)              \
    do { if (APLOG_R_MODULE_IS_LEVEL(r, mi, level))                         \
             ap_log_rerror_(file, line, mi, level, status, r, __VA_ARGS__); \
    } while(0)
#else
#define ap_log_rerror ap_log_rerror_
#endif
AP_DECLARE(void) ap_log_rerror_(const char *file, int line, int module_index,
                                int level, apr_status_t status,
                                const request_rec *r, const char *fmt, ...)
                                __attribute__((format(printf,7,8)));
#endif

/**
 * ap_log_cerror() - log messages which are related to a particular
 * connection.  This uses a printf-like format to log messages to the
 * error_log.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param level The level of this error message
 * @param module_index The module_index of the module generating this message
 * @param status The status code from the previous command
 * @param c The connection which we are logging for
 * @param fmt The format string
 * @param ... The arguments to use to fill out fmt.
 * @note ap_log_cerror is implemented as a macro
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @note If a request_rec is available, use that with ap_log_rerror()
 * in preference to calling this function.
 * @warning It is VERY IMPORTANT that you not include any raw data from
 * the network, such as the request-URI or request header fields, within
 * the format string.  Doing so makes the server vulnerable to a
 * denial-of-service attack and other messy behavior.  Instead, use a
 * simple format string like "%s", followed by the string containing the
 * untrusted data.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_cerror(const char *file, int line, int module_index,
                               int level, apr_status_t status,
                               const conn_rec *c, const char *fmt, ...);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_cerror(...) ap_log_cerror__(__VA_ARGS__)
#define ap_log_cerror__(file, line, mi, level, status, c, ...)              \
    do { if (APLOG_C_MODULE_IS_LEVEL(c, mi, level))                         \
             ap_log_cerror_(file, line, mi, level, status, c, __VA_ARGS__); \
    } while(0)
#else
#define ap_log_cerror ap_log_cerror_
#endif
AP_DECLARE(void) ap_log_cerror_(const char *file, int line, int module_index,
                                int level, apr_status_t status,
                                const conn_rec *c, const char *fmt, ...)
                                __attribute__((format(printf,7,8)));
#endif

/**
 * ap_log_cserror() - log messages which are related to a particular
 * connection and to a vhost other than c->base_server.  This uses a
 * printf-like format to log messages to the error_log.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param level The level of this error message
 * @param module_index The module_index of the module generating this message
 * @param status The status code from the previous command
 * @param c The connection which we are logging for
 * @param s The server which we are logging for
 * @param fmt The format string
 * @param ... The arguments to use to fill out fmt.
 * @note ap_log_cserror is implemented as a macro
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @note If a request_rec is available, use that with ap_log_rerror()
 * in preference to calling this function. This function is mainly useful for
 * modules like mod_ssl to use before the request_rec is created.
 * @warning It is VERY IMPORTANT that you not include any raw data from
 * the network, such as the request-URI or request header fields, within
 * the format string.  Doing so makes the server vulnerable to a
 * denial-of-service attack and other messy behavior.  Instead, use a
 * simple format string like "%s", followed by the string containing the
 * untrusted data.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_cserror(const char *file, int line, int module_index,
                                int level, apr_status_t status,
                                const conn_rec *c, const server_rec *s,
                                const char *fmt, ...);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_cserror(...) ap_log_cserror__(__VA_ARGS__)
#define ap_log_cserror__(file, line, mi, level, status, c, s, ...)  \
    do { if (APLOG_CS_MODULE_IS_LEVEL(c, s, mi, level))             \
             ap_log_cserror_(file, line, mi, level, status, c, s,   \
                             __VA_ARGS__);                          \
    } while(0)
#else
#define ap_log_cserror ap_log_cserror_
#endif
AP_DECLARE(void) ap_log_cserror_(const char *file, int line, int module_index,
                                 int level, apr_status_t status,
                                 const conn_rec *c, const server_rec *s,
                                 const char *fmt, ...)
                             __attribute__((format(printf,8,9)));
#endif

/*
 * The buffer logging functions, ap_log_data, ap_log_rdata, ap_log_cdata,
 * and ap_log_csdata log a buffer in printable and hex format.  The exact
 * format is controlled by processing flags, described next.
 */

/**
 * Processing flags for ap_log_data() et al
 *
 * AP_LOG_DATA_DEFAULT - default formatting, with printable chars and hex
 * AP_LOG_DATA_SHOW_OFFSET - prefix each line with hex offset from the start
 * of the buffer
 */
#define AP_LOG_DATA_DEFAULT       0
#define AP_LOG_DATA_SHOW_OFFSET   1

/**
 * ap_log_data() - log buffers which are not related to a particular request
 * or connection.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index The module_index of the module logging this buffer
 * @param level The log level
 * @param s The server on which we are logging
 * @param label A label for the buffer, to be logged preceding the buffer
 * @param data The buffer to be logged
 * @param len The length of the buffer
 * @param flags Special processing flags like AP_LOG_DATA_SHOW_OFFSET
 * @note ap_log_data is implemented as a macro.
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @note If a request_rec is available, use that with ap_log_rdata()
 * in preference to calling this function.  Otherwise, if a conn_rec is
 * available, use that with ap_log_cdata() in preference to calling
 * this function.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_data(const char *file, int line, int module_index,
                             int level, const server_rec *s, const char *label,
                             const void *data, apr_size_t len, unsigned int flags);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_data(...) ap_log_data__(__VA_ARGS__)
/* need server_rec *sr = ... for the case if s is verbatim NULL */
#define ap_log_data__(file, line, mi, level, s, ...)           \
    do { const server_rec *sr__ = s; if (APLOG_MODULE_IS_LEVEL(sr__, mi, level)) \
             ap_log_data_(file, line, mi, level, sr__, __VA_ARGS__);    \
    } while(0)
#else
#define ap_log_data ap_log_data_
#endif
AP_DECLARE(void) ap_log_data_(const char *file, int line, int module_index,
                              int level, const server_rec *s, const char *label,
                              const void *data, apr_size_t len, unsigned int flags);
#endif

/**
 * ap_log_rdata() - log buffers which are related to a particular request.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index The module_index of the module logging this buffer
 * @param level The log level
 * @param r The request which we are logging for
 * @param label A label for the buffer, to be logged preceding the buffer
 * @param data The buffer to be logged
 * @param len The length of the buffer
 * @param flags Special processing flags like AP_LOG_DATA_SHOW_OFFSET
 * @note ap_log_rdata is implemented as a macro.
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @note If a request_rec is available, use that with ap_log_rerror()
 * in preference to calling this function.  Otherwise, if a conn_rec is
 * available, use that with ap_log_cerror() in preference to calling
 * this function.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_rdata(const char *file, int line, int module_index,
                              int level, const request_rec *r, const char *label,
                              const void *data, apr_size_t len, unsigned int flags);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_rdata(...) ap_log_rdata__(__VA_ARGS__)
#define ap_log_rdata__(file, line, mi, level, r, ...)           \
    do { if (APLOG_R_MODULE_IS_LEVEL(r, mi, level)) \
             ap_log_rdata_(file, line, mi, level, r, __VA_ARGS__);    \
    } while(0)
#else
#define ap_log_rdata ap_log_rdata_
#endif
AP_DECLARE(void) ap_log_rdata_(const char *file, int line, int module_index,
                               int level, const request_rec *r, const char *label,
                               const void *data, apr_size_t len, unsigned int flags);
#endif

/**
 * ap_log_cdata() - log buffers which are related to a particular connection.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index The module_index of the module logging this buffer
 * @param level The log level
 * @param c The connection which we are logging for
 * @param label A label for the buffer, to be logged preceding the buffer
 * @param data The buffer to be logged
 * @param len The length of the buffer
 * @param flags Special processing flags like AP_LOG_DATA_SHOW_OFFSET
 * @note ap_log_cdata is implemented as a macro
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @note If a request_rec is available, use that with ap_log_rerror()
 * in preference to calling this function.  Otherwise, if a conn_rec is
 * available, use that with ap_log_cerror() in preference to calling
 * this function.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_cdata(const char *file, int line, int module_index,
                              int level, const conn_rec *c, const char *label,
                              const void *data, apr_size_t len, unsigned int flags);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_cdata(...) ap_log_cdata__(__VA_ARGS__)
#define ap_log_cdata__(file, line, mi, level, c, ...)           \
    do { if (APLOG_C_MODULE_IS_LEVEL(c, mi, level)) \
             ap_log_cdata_(file, line, mi, level, c, __VA_ARGS__);    \
    } while(0)
#else
#define ap_log_cdata ap_log_cdata_
#endif
AP_DECLARE(void) ap_log_cdata_(const char *file, int line, int module_index,
                               int level, const conn_rec *c, const char *label,
                               const void *data, apr_size_t len, unsigned int flags);
#endif

/**
 * ap_log_csdata() - log buffers which are related to a particular connection
 * and to a vhost other than c->base_server.
 * @param file The file in which this function is called
 * @param line The line number on which this function is called
 * @param module_index The module_index of the module logging this buffer
 * @param level The log level
 * @param c The connection which we are logging for
 * @param s The server which we are logging for
 * @param label A label for the buffer, to be logged preceding the buffer
 * @param data The buffer to be logged
 * @param len The length of the buffer
 * @param flags Special processing flags like AP_LOG_DATA_SHOW_OFFSET
 * @note ap_log_csdata is implemented as a macro
 * @note Use APLOG_MARK to fill out file, line, and module_index
 * @note If a request_rec is available, use that with ap_log_rerror()
 * in preference to calling this function.  Otherwise, if a conn_rec is
 * available, use that with ap_log_cerror() in preference to calling
 * this function.
 */
#ifdef DOXYGEN
AP_DECLARE(void) ap_log_csdata(const char *file, int line, int module_index,
                               int level, const conn_rec *c, const server_rec *s,
                               const char *label, const void *data,
                               apr_size_t len, unsigned int flags);
#else
#ifdef AP_HAVE_C99
/* need additional step to expand APLOG_MARK first */
#define ap_log_csdata(...) ap_log_csdata__(__VA_ARGS__)
#define ap_log_csdata__(file, line, mi, level, c, s, ...)              \
    do { if (APLOG_CS_MODULE_IS_LEVEL(c, s, mi, level))                \
             ap_log_csdata_(file, line, mi, level, c, s, __VA_ARGS__); \
    } while(0)
#else
#define ap_log_cdata ap_log_cdata_
#endif
AP_DECLARE(void) ap_log_csdata_(const char *file, int line, int module_index,
                                int level, const conn_rec *c, const server_rec *s,
                                const char *label, const void *data,
                                apr_size_t len, unsigned int flags);
#endif

/**
 * Convert stderr to the error log
 * @param s The current server
 */
AP_DECLARE(void) ap_error_log2stderr(server_rec *s);

/**
 * Log the command line used to start the server.
 * @param p The pool to use for logging
 * @param s The server_rec whose process's command line we want to log.
 * The command line is logged to that server's error log.
 */
AP_DECLARE(void) ap_log_command_line(apr_pool_t *p, server_rec *s);

/**
 * Log common (various) MPM shared data at startup.
 * @param s The server_rec of the error log we want to log to.
 * Misc commonly logged data is logged to that server's error log.
 */
AP_DECLARE(void) ap_log_mpm_common(server_rec *s);

/**
 * Log the current pid of the parent process
 * @param p The pool to use for processing
 * @param fname The name of the file to log to.  If the filename is not
 * absolute then it is assumed to be relative to ServerRoot.
 */
AP_DECLARE(void) ap_log_pid(apr_pool_t *p, const char *fname);

/**
 * Remove the pidfile.
 * @param p The pool to use for processing
 * @param fname The name of the pid file to remove.  If the filename is not
 * absolute then it is assumed to be relative to ServerRoot.
 */
AP_DECLARE(void) ap_remove_pid(apr_pool_t *p, const char *fname);

/**
 * Retrieve the pid from a pidfile.
 * @param p The pool to use for processing
 * @param filename The name of the file containing the pid.  If the filename is not
 * absolute then it is assumed to be relative to ServerRoot.
 * @param mypid Pointer to pid_t (valid only if return APR_SUCCESS)
 */
AP_DECLARE(apr_status_t) ap_read_pid(apr_pool_t *p, const char *filename, pid_t *mypid);

/** @see piped_log */
typedef struct piped_log piped_log;

/**
 * Open the piped log process
 * @param p The pool to allocate out of
 * @param program The program to run in the logging process
 * @return The piped log structure
 * @note The log program is invoked as @p APR_PROGRAM_ENV,
 *      @see ap_open_piped_log_ex to modify this behavior
 */
AP_DECLARE(piped_log *) ap_open_piped_log(apr_pool_t *p, const char *program);

/**
 * Open the piped log process specifying the execution choice for program
 * @param p The pool to allocate out of
 * @param program The program to run in the logging process
 * @param cmdtype How to invoke program, e.g. APR_PROGRAM, APR_SHELLCMD_ENV, etc
 * @return The piped log structure
 */
AP_DECLARE(piped_log *) ap_open_piped_log_ex(apr_pool_t *p,
                                             const char *program,
                                             apr_cmdtype_e cmdtype);

/**
 * Close the piped log and kill the logging process
 * @param pl The piped log structure
 */
AP_DECLARE(void) ap_close_piped_log(piped_log *pl);

/**
 * A function to return the read side of the piped log pipe
 * @param pl The piped log structure
 * @return The native file descriptor
 */
AP_DECLARE(apr_file_t *) ap_piped_log_read_fd(piped_log *pl);

/**
 * A function to return the write side of the piped log pipe
 * @param pl The piped log structure
 * @return The native file descriptor
 */
AP_DECLARE(apr_file_t *) ap_piped_log_write_fd(piped_log *pl);

/**
 * hook method to generate unique id for connection or request
 * @ingroup hooks
 * @param c the conn_rec of the connections
 * @param r the request_req (may be NULL)
 * @param id the place where to store the unique id
 * @return OK or DECLINE
 */
AP_DECLARE_HOOK(int, generate_log_id,
                (const conn_rec *c, const request_rec *r, const char **id))


#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_HTTP_LOG_H */
/** @} */
