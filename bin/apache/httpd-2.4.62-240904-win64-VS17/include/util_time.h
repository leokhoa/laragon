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
 * @file  util_time.h
 * @brief Apache date-time handling functions
 *
 * @defgroup APACHE_CORE_TIME Date-time handling functions
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_UTIL_TIME_H
#define APACHE_UTIL_TIME_H

#include "apr.h"
#include "apr_time.h"
#include "httpd.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Maximum delta from the current time, in seconds, for a past time
 * to qualify as "recent" for use in the ap_explode_recent_*() functions:
 * (Must be a power of two minus one!)
 */
#define AP_TIME_RECENT_THRESHOLD 15

/* Options for ap_recent_ctime_ex */
/* No extension */
#define AP_CTIME_OPTION_NONE    0x0
/* Add sub second timestamps with micro second resolution */
#define AP_CTIME_OPTION_USEC    0x1
/* Use more compact ISO 8601 format */
#define AP_CTIME_OPTION_COMPACT 0x2
/* Add timezone offset from GMT ([+-]hhmm) */
#define AP_CTIME_OPTION_GMTOFF  0x4


/**
 * convert a recent time to its human readable components in local timezone
 * @param tm the exploded time
 * @param t the time to explode: MUST be within the last
 *          AP_TIME_RECENT_THRESHOLD seconds
 * @note This is a faster alternative to apr_time_exp_lt that uses
 *       a cache of pre-exploded time structures.  It is useful for things
 *       that need to explode the current time multiple times per second,
 *       like loggers.
 * @return APR_SUCCESS iff successful
 */
AP_DECLARE(apr_status_t) ap_explode_recent_localtime(apr_time_exp_t *tm,
                                                     apr_time_t t);

/**
 * convert a recent time to its human readable components in GMT timezone
 * @param tm the exploded time
 * @param t the time to explode: MUST be within the last
 *          AP_TIME_RECENT_THRESHOLD seconds
 * @note This is a faster alternative to apr_time_exp_gmt that uses
 *       a cache of pre-exploded time structures.  It is useful for things
 *       that need to explode the current time multiple times per second,
 *       like loggers.
 * @return APR_SUCCESS iff successful
 */
AP_DECLARE(apr_status_t) ap_explode_recent_gmt(apr_time_exp_t *tm,
                                               apr_time_t t);


/**
 * format a recent timestamp in the ctime() format.
 * @param date_str String to write to.
 * @param t the time to convert
 * @note Consider using ap_recent_ctime_ex instead.
 * @return APR_SUCCESS iff successful
 */
AP_DECLARE(apr_status_t) ap_recent_ctime(char *date_str, apr_time_t t);


/**
 * format a recent timestamp in an extended ctime() format.
 * @param date_str String to write to.
 * @param t the time to convert
 * @param option Additional formatting options (AP_CTIME_OPTION_*).
 * @param len Pointer to an int containing the length of the provided buffer.
 *        On successful return it contains the number of bytes written to the
 *        buffer (including trailing NUL byte).
 * @return APR_SUCCESS iff successful, APR_ENOMEM if buffer was to short.
 */
AP_DECLARE(apr_status_t) ap_recent_ctime_ex(char *date_str, apr_time_t t,
                                            int option, int *len);


/**
 * format a recent timestamp in the RFC822 format
 * @param date_str String to write to (must have length >= APR_RFC822_DATE_LEN)
 * @param t the time to convert
 */
AP_DECLARE(apr_status_t) ap_recent_rfc822_date(char *date_str, apr_time_t t);

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_UTIL_TIME_H */
/** @} */
