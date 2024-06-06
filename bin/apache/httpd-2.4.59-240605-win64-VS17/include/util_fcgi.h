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
 * @file  util_fcgi.h
 * @brief FastCGI protocol definitions and support routines
 *
 * @defgroup APACHE_CORE_FASTCGI FastCGI Tools
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_UTIL_FCGI_H
#define APACHE_UTIL_FCGI_H

#ifdef __cplusplus
extern "C" {
#endif

#include "httpd.h"

/**
 * @brief A structure that represents the fixed header fields
 * at the beginning of a "FastCGI record" (i.e., the data prior
 * to content data and padding).
 */
typedef struct {
    /** See values for version, below */
    unsigned char version;
    /** See values for type, below */
    unsigned char type;
    /** request id, in two parts */
    unsigned char requestIdB1;
    unsigned char requestIdB0;
    /** content length, in two parts */
    unsigned char contentLengthB1;
    unsigned char contentLengthB0;
    /** padding length */
    unsigned char paddingLength;
    /** 8-bit reserved field */
    unsigned char reserved;
} ap_fcgi_header;

/*
 * Number of bytes in the header portion of a FastCGI record
 * (i.e., ap_fcgi_header structure).  Future versions of the
 * protocol may increase the size.
 */
#define AP_FCGI_HEADER_LEN  8

/*
 * Maximum number of bytes in the content portion of a FastCGI record.
 */
#define AP_FCGI_MAX_CONTENT_LEN 65535

/**
 * Possible values for the version field of ap_fcgi_header
 */
#define AP_FCGI_VERSION_1 1

/**
 * Possible values for the type field of ap_fcgi_header
 */
#define AP_FCGI_BEGIN_REQUEST       1
#define AP_FCGI_ABORT_REQUEST       2
#define AP_FCGI_END_REQUEST         3
#define AP_FCGI_PARAMS              4
#define AP_FCGI_STDIN               5
#define AP_FCGI_STDOUT              6
#define AP_FCGI_STDERR              7
#define AP_FCGI_DATA                8
#define AP_FCGI_GET_VALUES          9
#define AP_FCGI_GET_VALUES_RESULT  10
#define AP_FCGI_UNKNOWN_TYPE       11
#define AP_FCGI_MAXTYPE (AP_FCGI_UNKNOWN_TYPE)

/**
 * Offsets of the various fields of ap_fcgi_header
 */
#define AP_FCGI_HDR_VERSION_OFFSET         0
#define AP_FCGI_HDR_TYPE_OFFSET            1
#define AP_FCGI_HDR_REQUEST_ID_B1_OFFSET   2
#define AP_FCGI_HDR_REQUEST_ID_B0_OFFSET   3
#define AP_FCGI_HDR_CONTENT_LEN_B1_OFFSET  4
#define AP_FCGI_HDR_CONTENT_LEN_B0_OFFSET  5
#define AP_FCGI_HDR_PADDING_LEN_OFFSET     6
#define AP_FCGI_HDR_RESERVED_OFFSET        7

/**
 * @brief This represents the content data of the FastCGI record when
 * the type is AP_FCGI_BEGIN_REQUEST.
 */
typedef struct {
    /**
     * role, in two parts
     * See values for role, below
     */
    unsigned char roleB1;
    unsigned char roleB0;
    /**
     * flags
     * See values for flags bits, below
     */
    unsigned char flags;
    /** reserved */
    unsigned char reserved[5];
} ap_fcgi_begin_request_body;

/*
 * Values for role component of ap_fcgi_begin_request_body
 */
#define AP_FCGI_RESPONDER  1
#define AP_FCGI_AUTHORIZER 2
#define AP_FCGI_FILTER     3

/*
 * Values for flags bits of ap_fcgi_begin_request_body
 */
#define AP_FCGI_KEEP_CONN  1  /* otherwise the application closes */

/**
 * Offsets of the various fields of ap_fcgi_begin_request_body
 */
#define AP_FCGI_BRB_ROLEB1_OFFSET       0
#define AP_FCGI_BRB_ROLEB0_OFFSET       1
#define AP_FCGI_BRB_FLAGS_OFFSET        2
#define AP_FCGI_BRB_RESERVED0_OFFSET    3
#define AP_FCGI_BRB_RESERVED1_OFFSET    4
#define AP_FCGI_BRB_RESERVED2_OFFSET    5
#define AP_FCGI_BRB_RESERVED3_OFFSET    6
#define AP_FCGI_BRB_RESERVED4_OFFSET    7

/**
 * Pack ap_fcgi_header
 * @param h The header to read from
 * @param a The array to write to, of size AP_FCGI_HEADER_LEN
 */
AP_DECLARE(void) ap_fcgi_header_to_array(ap_fcgi_header *h,
                                         unsigned char a[]);

/**
 * Unpack header of FastCGI record into ap_fcgi_header
 * @param h The header to write to
 * @param a The array to read from, of size AP_FCGI_HEADER_LEN
 */
AP_DECLARE(void) ap_fcgi_header_from_array(ap_fcgi_header *h,
                                           unsigned char a[]);

/**
 * Unpack header of FastCGI record into individual fields
 * @param version The version, on output
 * @param type The type, on output
 * @param request_id The request id, on output
 * @param content_len The content length, on output
 * @param padding_len The amount of padding following the content, on output
 * @param a The array to read from, of size AP_FCGI_HEADER_LEN
 */
AP_DECLARE(void) ap_fcgi_header_fields_from_array(unsigned char *version,
                                                  unsigned char *type,
                                                  apr_uint16_t *request_id,
                                                  apr_uint16_t *content_len,
                                                  unsigned char *padding_len,
                                                  unsigned char a[]);

/**
 * Pack ap_fcgi_begin_request_body
 * @param h The begin-request body to read from
 * @param a The array to write to, of size AP_FCGI_HEADER_LEN
 */
AP_DECLARE(void) ap_fcgi_begin_request_body_to_array(ap_fcgi_begin_request_body *h,
                                                     unsigned char a[]);

/**
 * Fill in a FastCGI request header with the required field values.
 * @param header The header to fill in
 * @param type The type of record
 * @param request_id The request id
 * @param content_len The amount of content which follows the header
 * @param padding_len The amount of padding which follows the content
 *
 * The header array must be at least AP_FCGI_HEADER_LEN bytes long.
 */
AP_DECLARE(void) ap_fcgi_fill_in_header(ap_fcgi_header *header,
                                        unsigned char type,
                                        apr_uint16_t request_id,
                                        apr_uint16_t content_len,
                                        unsigned char padding_len);

/**
 * Fill in a FastCGI begin request body with the required field values.
 * @param brb The begin-request-body to fill in
 * @param role AP_FCGI_RESPONDER or other roles
 * @param flags 0 or a combination of flags like AP_FCGI_KEEP_CONN
 */
AP_DECLARE(void) ap_fcgi_fill_in_request_body(ap_fcgi_begin_request_body *brb,
                                              int role,
                                              unsigned char flags);

/**
 * Compute the buffer size needed to encode the next portion of
 * the provided environment table.
 * @param env The environment table
 * @param maxlen The maximum buffer size allowable, capped at 
 * AP_FCGI_MAX_CONTENT_LEN.
 * @param starting_elem On input, the next element of the table array
 * to process in this FastCGI record.  On output, the next element to
 * process on the *next* FastCGI record.
 * @return Size of buffer needed to encode the next part, or 0
 * if no more can be encoded.  When 0 is returned: If starting_elem
 * has reached the end of the table array, all has been encoded;
 * otherwise, the next envvar can't be encoded within the specified
 * limit.
 * @note If an envvar can't be encoded within the specified limit,
 * the caller can log a warning and increment starting_elem and try 
 * again or increase the limit or fail, as appropriate for the module.
 */
AP_DECLARE(apr_size_t) ap_fcgi_encoded_env_len(apr_table_t *env,
                                               apr_size_t maxlen,
                                               int *starting_elem);

/**
 * Encode the next portion of the provided environment table using
 * a buffer previously allocated.
 * @param r The request, for logging
 * @param env The environment table
 * @param buffer A buffer to contain the encoded environment table
 * @param buflen The length of the buffer, previously computed by
 * ap_fcgi_encoded_env_len().
 * @param starting_elem On input, the next element of the table array
 * to process in this FastCGI record.  On output, the next element to
 * process on the *next* FastCGI record.
 * @return APR_SUCCESS if a section could be encoded or APR_ENOSPC
 * otherwise.
 * @note The output starting_elem from ap_fcgi_encoded_env_len
 * shouldn't be used as input to ap_fcgi_encode_env when building the
 * same FastCGI record.
 */
AP_DECLARE(apr_status_t) ap_fcgi_encode_env(request_rec *r,
                                            apr_table_t *env,
                                            void *buffer,
                                            apr_size_t buflen,
                                            int *starting_elem);

/**
 * String forms for the value of the FCGI_ROLE envvar
 */
#define AP_FCGI_RESPONDER_STR   "RESPONDER"
#define AP_FCGI_AUTHORIZER_STR  "AUTHORIZER"
#define AP_FCGI_FILTER_STR      "FILTER"

/**
 * FastCGI implementations that implement the AUTHORIZER role
 * for Apache httpd and allow the application to participate in
 * any of the Apache httpd AAA phases typically set the variable
 * FCGI_APACHE_ROLE to one of these strings to indicate the
 * specific AAA phase.
 */
#define AP_FCGI_APACHE_ROLE_AUTHENTICATOR_STR  "AUTHENTICATOR"
#define AP_FCGI_APACHE_ROLE_AUTHORIZER_STR     "AUTHORIZER"
#define AP_FCGI_APACHE_ROLE_ACCESS_CHECKER_STR "ACCESS_CHECKER"

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_UTIL_FCGI_H */
/** @} */
