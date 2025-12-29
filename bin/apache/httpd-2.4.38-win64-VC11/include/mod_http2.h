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
 * HTTP/2 request engines
 ******************************************************************************/
 
struct apr_thread_cond_t;

typedef struct h2_req_engine h2_req_engine;

typedef void http2_output_consumed(void *ctx, conn_rec *c, apr_off_t consumed);

/**
 * Initialize a h2_req_engine. The structure will be passed in but
 * only the name and master are set. The function should initialize
 * all fields.
 * @param engine the allocated, partially filled structure
 * @param r      the first request to process, or NULL
 */
typedef apr_status_t http2_req_engine_init(h2_req_engine *engine, 
                                           const char *id, 
                                           const char *type,
                                           apr_pool_t *pool, 
                                           apr_size_t req_buffer_size,
                                           request_rec *r,
                                           http2_output_consumed **pconsumed,
                                           void **pbaton);

/**
 * Push a request to an engine with the specified name for further processing.
 * If no such engine is available, einit is not NULL, einit is called 
 * with a new engine record and the caller is responsible for running the
 * new engine instance.
 * @param engine_type the type of the engine to add the request to
 * @param r           the request to push to an engine for processing
 * @param einit       an optional initialization callback for a new engine 
 *                    of the requested type, should no instance be available.
 *                    By passing a non-NULL callback, the caller is willing
 *                    to init and run a new engine itself.
 * @return APR_SUCCESS iff slave was successfully added to an engine
 */
APR_DECLARE_OPTIONAL_FN(apr_status_t, 
                        http2_req_engine_push, (const char *engine_type, 
                                                request_rec *r,
                                                http2_req_engine_init *einit));

/**
 * Get a new request for processing in this engine.
 * @param engine      the engine which is done processing the slave
 * @param block       if call should block waiting for request to come
 * @param capacity    how many parallel requests are acceptable
 * @param pr          the request that needs processing or NULL
 * @return APR_SUCCESS if new request was assigned
 *         APR_EAGAIN  if no new request is available
 *         APR_EOF          if engine may shut down, as no more request will be scheduled
 *         APR_ECONNABORTED if the engine needs to shut down immediately
 */
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

#endif
