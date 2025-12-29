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

#endif /* __MOD_SSL_OPENSSL_H__ */
/** @} */
