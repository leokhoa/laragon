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
 * @file mod_ssl.h
 * @brief SSL extension module for Apache
 *
 * @defgroup MOD_SSL mod_ssl
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef __MOD_SSL_H__
#define __MOD_SSL_H__

#include "httpd.h"
#include "http_config.h"
#include "apr_optional.h"
#include "apr_tables.h" /* for apr_array_header_t */

/* Create a set of SSL_DECLARE(type), SSL_DECLARE_NONSTD(type) and
 * SSL_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(WIN32)
#define SSL_DECLARE(type)            type
#define SSL_DECLARE_NONSTD(type)     type
#define SSL_DECLARE_DATA
#elif defined(SSL_DECLARE_STATIC)
#define SSL_DECLARE(type)            type __stdcall
#define SSL_DECLARE_NONSTD(type)     type
#define SSL_DECLARE_DATA
#elif defined(SSL_DECLARE_EXPORT)
#define SSL_DECLARE(type)            __declspec(dllexport) type __stdcall
#define SSL_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define SSL_DECLARE_DATA             __declspec(dllexport)
#else
#define SSL_DECLARE(type)            __declspec(dllimport) type __stdcall
#define SSL_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define SSL_DECLARE_DATA             __declspec(dllimport)
#endif

/** The ssl_var_lookup() optional function retrieves SSL environment
 * variables. */
APR_DECLARE_OPTIONAL_FN(char *, ssl_var_lookup,
                        (apr_pool_t *, server_rec *,
                         conn_rec *, request_rec *,
                         char *));

/** The ssl_ext_list() optional function attempts to build an array
 * of all the values contained in the named X.509 extension. The
 * returned array will be created in the supplied pool.
 * The client certificate is used if peer is non-zero; the server
 * certificate is used otherwise.
 * Extension specifies the extensions to use as a string. This can be
 * one of the "known" long or short names, or a numeric OID,
 * e.g. "1.2.3.4", 'nsComment' and 'DN' are all valid.
 * A pointer to an apr_array_header_t structure is returned if at
 * least one matching extension is found, NULL otherwise.
 */
APR_DECLARE_OPTIONAL_FN(apr_array_header_t *, ssl_ext_list,
                        (apr_pool_t *p, conn_rec *c, int peer,
                         const char *extension));

/** An optional function which returns non-zero if the given connection
 * is using SSL/TLS. */
APR_DECLARE_OPTIONAL_FN(int, ssl_is_https, (conn_rec *));

/** The ssl_proxy_enable() and ssl_engine_{set,disable}() optional
 * functions are used by mod_proxy to enable use of SSL for outgoing
 * connections. */

APR_DECLARE_OPTIONAL_FN(int, ssl_proxy_enable, (conn_rec *));
APR_DECLARE_OPTIONAL_FN(int, ssl_engine_disable, (conn_rec *));
APR_DECLARE_OPTIONAL_FN(int, ssl_engine_set, (conn_rec *,
                                              ap_conf_vector_t *,
                                              int proxy, int enable));
                                              
/* Check for availability of new hooks */
#define SSL_CERT_HOOKS
#ifdef SSL_CERT_HOOKS

/** Lets others add certificate and key files to the given server.
 * For each cert a key must also be added.
 * @param cert_file and array of const char* with the path to the certificate chain
 * @param key_file and array of const char* with the path to the private key file
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, add_cert_files,
                          (server_rec *s, apr_pool_t *p, 
                           apr_array_header_t *cert_files,
                           apr_array_header_t *key_files))

/** In case no certificates are available for a server, this
 * lets other modules add a fallback certificate for the time
 * being. Regular requests against this server will be answered
 * with a 503. 
 * @param cert_file and array of const char* with the path to the certificate chain
 * @param key_file and array of const char* with the path to the private key file
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, add_fallback_cert_files,
                          (server_rec *s, apr_pool_t *p, 
                           apr_array_header_t *cert_files,
                           apr_array_header_t *key_files))

#endif /* SSL_CERT_HOOKS */

#endif /* __MOD_SSL_H__ */
/** @} */
