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
 * @file  mod_core.h
 * @brief mod_core private header file
 *
 * @defgroup MOD_CORE mod_core
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef MOD_CORE_H
#define MOD_CORE_H

#include "apr.h"
#include "apr_buckets.h"

#include "httpd.h"
#include "util_filter.h"


#ifdef __cplusplus
extern "C" {
#endif

/* Handles for core filters */
AP_DECLARE_DATA extern ap_filter_rec_t *ap_http_input_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_http_header_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_chunk_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_http_outerror_filter_handle;
AP_DECLARE_DATA extern ap_filter_rec_t *ap_byterange_filter_handle;

/*
 * These (input) filters are internal to the mod_core operation.
 */
apr_status_t ap_http_filter(ap_filter_t *f, apr_bucket_brigade *b,
                            ap_input_mode_t mode, apr_read_type_e block,
                            apr_off_t readbytes);

/* HTTP/1.1 chunked transfer encoding filter. */
apr_status_t ap_http_chunk_filter(ap_filter_t *f, apr_bucket_brigade *b);

/* Filter to handle any error buckets on output */
apr_status_t ap_http_outerror_filter(ap_filter_t *f,
                                     apr_bucket_brigade *b);

char *ap_response_code_string(request_rec *r, int error_index);

/**
 * Send the minimal part of an HTTP response header.
 * @param r The current request
 * @param bb The brigade to add the header to.
 * @warning Modules should be very careful about using this, and should
 *          the default behavior.  Much of the HTTP/1.1 implementation
 *          correctness depends on the full headers.
 * @fn void ap_basic_http_header(request_rec *r, apr_bucket_brigade *bb)
 */
AP_DECLARE(void) ap_basic_http_header(request_rec *r, apr_bucket_brigade *bb);

/**
 * Send an appropriate response to an http TRACE request.
 * @param r The current request
 * @note returns DONE or the HTTP status error if it handles the TRACE,
 * or DECLINED if the request was not for TRACE.
 * request method was not TRACE.
 */
AP_DECLARE_NONSTD(int) ap_send_http_trace(request_rec *r);

/**
 * Send an appropriate response to an http OPTIONS request.
 * @param r The current request
 */
AP_DECLARE(int) ap_send_http_options(request_rec *r);

/* Used for multipart/byteranges boundary string */
AP_DECLARE_DATA extern const char *ap_multipart_boundary;

/* Init RNG at startup */
AP_CORE_DECLARE(void) ap_init_rng(apr_pool_t *p);
/* Update RNG state in parent after fork */
AP_CORE_DECLARE(void) ap_random_parent_after_fork(void);

#ifdef __cplusplus
}
#endif

#endif  /* !MOD_CORE_H */
/** @} */
