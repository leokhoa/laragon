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
 * @file util_cookies.h
 * @brief Apache cookie library
 */

#ifndef UTIL_COOKIES_H
#define UTIL_COOKIES_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup APACHE_CORE_COOKIE Cookies
 * @ingroup  APACHE_CORE
 *
 * RFC2109 and RFC2965 compliant HTTP cookies can be read from and written
 * to using this set of functions.
 *
 * @{
 *
 */

#include "apr_errno.h"
#include "httpd.h"

#define SET_COOKIE "Set-Cookie"
#define SET_COOKIE2 "Set-Cookie2"
#define DEFAULT_ATTRS "HttpOnly;Secure;Version=1"
#define CLEAR_ATTRS "Version=1"

typedef struct {
    request_rec *r;
    const char *name;
    const char *encoded;
    apr_table_t *new_cookies;
    int duplicated;
} ap_cookie_do;

/**
 * Write an RFC2109 compliant cookie.
 *
 * @param r The request
 * @param name The name of the cookie.
 * @param val The value to place in the cookie.
 * @param attrs The string containing additional cookie attributes. If NULL, the
 *              DEFAULT_ATTRS will be used.
 * @param maxage If non zero, a Max-Age header will be added to the cookie.
 * @param ... A varargs array of zero or more (apr_table_t *) tables followed by NULL
 *            to which the cookies should be added.
 */
AP_DECLARE(apr_status_t) ap_cookie_write(request_rec * r, const char *name,
                                         const char *val, const char *attrs,
                                         long maxage, ...)
                         AP_FN_ATTR_SENTINEL;

/**
 * Write an RFC2965 compliant cookie.
 *
 * @param r The request
 * @param name2 The name of the cookie.
 * @param val The value to place in the cookie.
 * @param attrs2 The string containing additional cookie attributes. If NULL, the
 *               DEFAULT_ATTRS will be used.
 * @param maxage If non zero, a Max-Age header will be added to the cookie.
 * @param ... A varargs array of zero or more (apr_table_t *) tables followed by NULL
 *            to which the cookies should be added.
 */
AP_DECLARE(apr_status_t) ap_cookie_write2(request_rec * r, const char *name2,
                                          const char *val, const char *attrs2,
                                          long maxage, ...)
                         AP_FN_ATTR_SENTINEL;

/**
 * Remove an RFC2109 compliant cookie.
 *
 * @param r The request
 * @param name The name of the cookie.
 * @param attrs The string containing additional cookie attributes. If NULL, the
 *              CLEAR_ATTRS will be used.
 * @param ... A varargs array of zero or more (apr_table_t *) tables followed by NULL
 *            to which the cookies should be added.
 */
AP_DECLARE(apr_status_t) ap_cookie_remove(request_rec * r, const char *name,
                                          const char *attrs, ...)
                         AP_FN_ATTR_SENTINEL;

/**
 * Remove an RFC2965 compliant cookie.
 *
 * @param r The request
 * @param name2 The name of the cookie.
 * @param attrs2 The string containing additional cookie attributes. If NULL, the
 *               CLEAR_ATTRS will be used.
 * @param ... A varargs array of zero or more (apr_table_t *) tables followed by NULL
 *            to which the cookies should be added.
 */
AP_DECLARE(apr_status_t) ap_cookie_remove2(request_rec * r, const char *name2,
                                           const char *attrs2, ...)
                         AP_FN_ATTR_SENTINEL;

/**
 * Read a cookie called name, placing its value in val.
 *
 * Both the Cookie and Cookie2 headers are scanned for the cookie.
 *
 * If the cookie is duplicated, this function returns APR_EGENERAL. If found,
 * and if remove is non zero, the cookie will be removed from the headers, and
 * thus kept private from the backend.
 */
AP_DECLARE(apr_status_t) ap_cookie_read(request_rec * r, const char *name, const char **val,
                                        int remove);

/**
 * Sanity check a given string that it exists, is not empty,
 * and does not contain the special characters '=', ';' and '&'.
 *
 * It is used to sanity check the cookie names.
 */
AP_DECLARE(apr_status_t) ap_cookie_check_string(const char *string);

/**
 * @}
 */

#ifdef __cplusplus
}
#endif

#endif /* !UTIL_COOKIES_H */
