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
 * @file  util_md5.h
 * @brief Apache MD5 library
 *
 * @defgroup APACHE_CORE_MD5 MD5 Package Library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_UTIL_MD5_H
#define APACHE_UTIL_MD5_H

#ifdef __cplusplus
extern "C" {
#endif

#include "apr_md5.h"

/**
 * Create an MD5 checksum of a given string.
 * @param   a       Pool to allocate out of
 * @param   string  String to get the checksum of
 * @return The checksum
 */
AP_DECLARE(char *) ap_md5(apr_pool_t *a, const unsigned char *string);

/**
 * Create an MD5 checksum of a string of binary data.
 * @param   a       Pool to allocate out of
 * @param   buf     Buffer to generate checksum for
 * @param   len     The length of the buffer
 * @return The checksum
 */
AP_DECLARE(char *) ap_md5_binary(apr_pool_t *a, const unsigned char *buf, int len);

/**
 * Convert an MD5 checksum into a base64 encoding.
 * @param   p       The pool to allocate out of
 * @param   context The context to convert
 * @return The converted encoding
 */
AP_DECLARE(char *) ap_md5contextTo64(apr_pool_t *p, apr_md5_ctx_t *context);

/**
 * Create an MD5 Digest for a given file.
 * @param   p       The pool to allocate out of
 * @param   infile  The file to create the digest for
 */
AP_DECLARE(char *) ap_md5digest(apr_pool_t *p, apr_file_t *infile);

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_UTIL_MD5_H */
/** @} */
