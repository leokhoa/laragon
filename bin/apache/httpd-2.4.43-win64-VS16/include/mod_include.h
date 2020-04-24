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
 * @file mod_include.h
 * @brief Server Side Include Filter Extension Module for Apache
 *
 * @defgroup MOD_INCLUDE mod_include
 * @ingroup APACHE_MODS
 * @{
 */

#ifndef _MOD_INCLUDE_H
#define _MOD_INCLUDE_H 1

#include "apr_pools.h"
#include "apr_optional.h"

/*
 * Constants used for ap_ssi_get_tag_and_value's decode parameter
 */
#define SSI_VALUE_DECODED 1
#define SSI_VALUE_RAW     0

/*
 * Constants used for ap_ssi_parse_string's leave_name parameter
 */
#define SSI_EXPAND_LEAVE_NAME 1
#define SSI_EXPAND_DROP_NAME  0

/*
 * This macro creates a bucket which contains an error message and appends it
 * to the current pass brigade
 */
#define SSI_CREATE_ERROR_BUCKET(ctx, f, bb) APR_BRIGADE_INSERT_TAIL((bb), \
    apr_bucket_pool_create(apr_pstrdup((ctx)->pool, (ctx)->error_str),    \
                           strlen((ctx)->error_str), (ctx)->pool,         \
                           (f)->c->bucket_alloc))

/*
 * These constants are used to set or clear flag bits.
 */
#define SSI_FLAG_PRINTING         (1<<0)  /* Printing conditional lines. */
#define SSI_FLAG_COND_TRUE        (1<<1)  /* Conditional eval'd to true. */
#define SSI_FLAG_SIZE_IN_BYTES    (1<<2)  /* Sizes displayed in bytes.   */
#define SSI_FLAG_NO_EXEC          (1<<3)  /* No Exec in current context. */

#define SSI_FLAG_SIZE_ABBREV      (~(SSI_FLAG_SIZE_IN_BYTES))
#define SSI_FLAG_CLEAR_PRINT_COND (~((SSI_FLAG_PRINTING) | \
                                     (SSI_FLAG_COND_TRUE)))
#define SSI_FLAG_CLEAR_PRINTING   (~(SSI_FLAG_PRINTING))

/*
 * The public SSI context structure
 */
typedef struct {
    /* permanent pool, use this for creating bucket data */
    apr_pool_t  *pool;

    /* temp pool; will be cleared after the execution of every directive */
    apr_pool_t  *dpool;

    /* See the SSI_FLAG_XXXXX definitions. */
    int          flags;

    /* nesting of *invisible* ifs */
    int          if_nesting_level;

    /* if true, the current buffer will be passed down the filter chain before
     * continuing with next input bucket and the variable will be reset to
     * false.
     */
    int          flush_now;

    /* argument counter (of the current directive) */
    unsigned     argc;

    /* currently configured error string */
    const char  *error_str;

    /* currently configured time format */
    const char  *time_str;

    /* the current request */
    request_rec  *r;

    /* pointer to internal (non-public) data, don't touch */
    struct ssi_internal_ctx *intern;

} include_ctx_t;

typedef apr_status_t (include_handler_fn_t)(include_ctx_t *, ap_filter_t *,
                                            apr_bucket_brigade *);

APR_DECLARE_OPTIONAL_FN(void, ap_ssi_get_tag_and_value,
                        (include_ctx_t *ctx, char **tag, char **tag_val,
                         int dodecode));

APR_DECLARE_OPTIONAL_FN(char*, ap_ssi_parse_string,
                        (include_ctx_t *ctx, const char *in, char *out,
                         apr_size_t length, int leave_name));

APR_DECLARE_OPTIONAL_FN(void, ap_register_include_handler,
                        (char *tag, include_handler_fn_t *func));

#endif /* MOD_INCLUDE */
/** @} */
