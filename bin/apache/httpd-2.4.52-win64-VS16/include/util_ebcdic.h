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
 * @file  util_ebcdic.h
 * @brief Utilities for EBCDIC conversion
 *
 * @defgroup APACHE_CORE_EBCDIC Utilities for EBCDIC conversion
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_UTIL_EBCDIC_H
#define APACHE_UTIL_EBCDIC_H


#ifdef __cplusplus
extern "C" {
#endif

#include "apr_xlate.h"
#include "httpd.h"
#include "util_charset.h"

#if APR_CHARSET_EBCDIC || defined(DOXYGEN)

/**
 * Setup all of the global translation handlers.
 * @param   pool    The pool to allocate out of.
 * @note On non-EBCDIC system, this function does <b>not</b> exist.
 * So, its use should be guarded by \#if APR_CHARSET_EBCDIC.
 */
apr_status_t ap_init_ebcdic(apr_pool_t *pool);

/**
 * Convert protocol data from the implementation character
 * set to ASCII.
 * @param   buffer  Buffer to translate.
 * @param   len     Number of bytes to translate.
 * @note On non-EBCDIC system, this function is replaced by an 
 * empty macro.
 */
void ap_xlate_proto_to_ascii(char *buffer, apr_size_t len);

/**
 * Convert protocol data to the implementation character
 * set from ASCII.
 * @param   buffer  Buffer to translate.
 * @param   len     Number of bytes to translate.
 * @note On non-EBCDIC system, this function is replaced by an 
 * empty macro.
 */
void ap_xlate_proto_from_ascii(char *buffer, apr_size_t len);

/**
 * Convert protocol data from the implementation character
 * set to ASCII, then send it.
 * @param   r       The current request.
 * @param   ...     The strings to write, followed by a NULL pointer.
 * @note On non-EBCDIC system, this function is replaced by a call to
 * #ap_rvputs.
 */
int ap_rvputs_proto_in_ascii(request_rec *r, ...);

#else   /* APR_CHARSET_EBCDIC */

#define ap_xlate_proto_to_ascii(x,y)          /* NOOP */
#define ap_xlate_proto_from_ascii(x,y)        /* NOOP */

#define ap_rvputs_proto_in_ascii  ap_rvputs

#endif  /* APR_CHARSET_EBCDIC */

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_UTIL_EBCDIC_H */
/** @} */
