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
 * @file mod_ssl_openssl.h
 * @brief Interface to OpenSSL-specific APIs provided by mod_ssl
 *
 * @defgroup MOD_SSL mod_ssl_openssl
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef __MOD_SSL_OPENSSL_H__
#define __MOD_SSL_OPENSSL_H__

#include "mod_ssl.h"

/* OpenSSL headers */

#ifndef SSL_PRIVATE_H
#include <openssl/opensslv.h>
#if (OPENSSL_VERSION_NUMBER >= 0x10001000)
/* must be defined before including ssl.h */
#define OPENSSL_NO_SSL_INTERN
#endif
#include <openssl/ssl.h>
#endif

/**
 * init_server hook -- allow SSL_CTX-specific initialization to be performed by
 * a module for each SSL-enabled server (one at a time)
 * @param s SSL-enabled [virtual] server
 * @param p pconf pool
 * @param is_proxy 1 if this server supports backend connections
 * over SSL/TLS, 0 if it supports client connections over SSL/TLS
 * @param ctx OpenSSL SSL Context for the server
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, init_server,
                          (server_rec *s, apr_pool_t *p, int is_proxy, SSL_CTX *ctx))

/**
 * pre_handshake hook
 * @param c conn_rec for new connection from client or to backend server
 * @param ssl OpenSSL SSL Connection for the client or backend server
 * @param is_proxy 1 if this handshake is for a backend connection, 0 otherwise
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, pre_handshake,
                          (conn_rec *c, SSL *ssl, int is_proxy))

/**
 * proxy_post_handshake hook -- allow module to abort after successful
 * handshake with backend server and subsequent peer checks
 * @param c conn_rec for connection to backend server
 * @param ssl OpenSSL SSL Connection for the client or backend server
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, proxy_post_handshake,
                          (conn_rec *c, SSL *ssl))

/** On TLS connections that do not relate to a configured virtual host,
 * allow other modules to provide a X509 certificate and EVP_PKEY to
 * be used on the connection. This first hook which does not
 * return DECLINED will determine the outcome. */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, answer_challenge,
                          (conn_rec *c, const char *server_name, 
                          X509 **pcert, EVP_PKEY **pkey))

/** During post_config phase, ask around if someone wants to provide
 * OCSP stapling status information for the given cert (with the also
 * provided issuer certificate). The first hook which does not
 * return DECLINED promises to take responsibility (and respond
 * in later calls via hook ssl_get_stapling_status).
 * If no hook takes over, mod_ssl's own stapling implementation will
 * be applied (if configured).
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, init_stapling_status,
                          (server_rec *s, apr_pool_t *p, 
                          X509 *cert, X509 *issuer))

/** Anyone answering positive to ssl_init_stapling_status for a 
 * certificate, needs to register here and supply the actual OCSP stapling
 * status data (OCSP_RESP) for a new connection.
 * A hook supplying the response data must return APR_SUCCESS.
 * The data is returned in DER encoded bytes via pder and pderlen. The
 * returned pointer may be NULL, which indicates that data is (currently)
 * unavailable.
 * If DER data is returned, it MUST come from a response with
 * status OCSP_RESPONSE_STATUS_SUCCESSFUL and V_OCSP_CERTSTATUS_GOOD
 * or V_OCSP_CERTSTATUS_REVOKED, not V_OCSP_CERTSTATUS_UNKNOWN. This means
 * errors in OCSP retrieval are to be handled/logged by the hook and
 * are not done by mod_ssl.
 * Any DER bytes returned MUST be allocated via malloc() and ownership
 * passes to mod_ssl. Meaning, the hook must return a malloced copy of
 * the data it has. mod_ssl (or OpenSSL) will free it. 
 */
APR_DECLARE_EXTERNAL_HOOK(ssl, SSL, int, get_stapling_status,
                          (unsigned char **pder, int *pderlen, 
                          conn_rec *c, server_rec *s, X509 *cert))
                          
#endif /* __MOD_SSL_OPENSSL_H__ */
/** @} */
