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

#ifndef __MOD_HTTP2_H__
#define __MOD_HTTP2_H__

/** The http2_var_lookup() optional function retrieves HTTP2 environment
 * variables. */
APR_DECLARE_OPTIONAL_FN(char *, 
                        http2_var_lookup, (apr_pool_t *, server_rec *,
                                           conn_rec *, request_rec *,  char *));

/** An optional function which returns non-zero if the given connection
 * or its master connection is using HTTP/2. */
APR_DECLARE_OPTIONAL_FN(int, 
                        http2_is_h2, (conn_rec *));


/*******************************************************************************
 * START HTTP/2 request engines (DEPRECATED)
 ******************************************************************************/

/* The following functions were introduced for the experimental mod_proxy_http2
 * support, but have been abandoned since.
 * They are still declared here for backward compatibility, in case someone
 * tries to build an old mod_proxy_http2 against it, but will disappear
 * completely sometime in the future.
 */ 
 
struct apr_thread_cond_t;
typedef struct h2_req_engine h2_req_engine;
typedef void http2_output_consumed(void *ctx, conn_rec *c, apr_off_t consumed);

typedef apr_status_t http2_req_engine_init(h2_req_engine *engine, 
                                           const char *id, 
                                           const char *type,
                                           apr_pool_t *pool, 
                                           apr_size_t req_buffer_size,
                                           request_rec *r,
                                           http2_output_consumed **pconsumed,
                                           void **pbaton);

APR_DECLARE_OPTIONAL_FN(apr_status_t, 
                        http2_req_engine_push, (const char *engine_type, 
                                                request_rec *r,
                                                http2_req_engine_init *einit));

APR_DECLARE_OPTIONAL_FN(apr_status_t, 
                        http2_req_engine_pull, (h2_req_engine *engine, 
                                                apr_read_type_e block,
                                                int capacity,
                                                request_rec **pr));
APR_DECLARE_OPTIONAL_FN(void, 
                        http2_req_engine_done, (h2_req_engine *engine, 
                                                conn_rec *rconn,
                                                apr_status_t status));

APR_DECLARE_OPTIONAL_FN(void,
                        http2_get_num_workers, (server_rec *s,
                                                int *minw, int *max));

/*******************************************************************************
 * END HTTP/2 request engines (DEPRECATED)
 ******************************************************************************/

#endif
