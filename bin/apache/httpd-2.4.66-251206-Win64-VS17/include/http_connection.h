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
 * @file  http_connection.h
 * @brief Apache connection library
 *
 * @defgroup APACHE_CORE_CONNECTION Connection Library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_HTTP_CONNECTION_H
#define APACHE_HTTP_CONNECTION_H

#include "apr_network_io.h"
#include "apr_buckets.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * This is the protocol module driver.  This calls all of the
 * pre-connection and connection hooks for all protocol modules.
 * @param c The connection on which the request is read
 * @param csd The mechanism on which this connection is to be read.
 *            Most times this will be a socket, but it is up to the module
 *            that accepts the request to determine the exact type.
 */
AP_CORE_DECLARE(void) ap_process_connection(conn_rec *c, void *csd);

/**
 * Shutdown the connection for writing.
 * @param c The connection to shutdown
 * @param flush Whether or not to flush pending data before
 * @return APR_SUCCESS or the underlying error
 */
AP_CORE_DECLARE(apr_status_t) ap_shutdown_conn(conn_rec *c, int flush);

/**
 * Flushes all remain data in the client send buffer
 * @param c The connection to flush
 * @remark calls ap_shutdown_conn(c, 1)
 */
AP_CORE_DECLARE(void) ap_flush_conn(conn_rec *c);

/**
 * This function is responsible for the following cases:
 * <pre>
 * we now proceed to read from the client until we get EOF, or until
 * MAX_SECS_TO_LINGER has passed.  The reasons for doing this are
 * documented in a draft:
 *
 * http://tools.ietf.org/html/draft-ietf-http-connection-00.txt
 *
 * in a nutshell -- if we don't make this effort we risk causing
 * TCP RST packets to be sent which can tear down a connection before
 * all the response data has been sent to the client.
 * </pre>
 * @param c The connection we are closing
 */
AP_DECLARE(void) ap_lingering_close(conn_rec *c);

AP_DECLARE(int) ap_prep_lingering_close(conn_rec *c);

AP_DECLARE(int) ap_start_lingering_close(conn_rec *c);

/* Hooks */
/**
 * create_connection is a RUN_FIRST hook which allows modules to create
 * connections. In general, you should not install filters with the
 * create_connection hook. If you require vhost configuration information
 * to make filter installation decisions, you must use the pre_connection
 * or install_network_transport hook. This hook should close the connection
 * if it encounters a fatal error condition.
 *
 * @param p The pool from which to allocate the connection record
 * @param server The server record to create the connection too.
 * @param csd The socket that has been accepted
 * @param conn_id A unique identifier for this connection.  The ID only
 *                needs to be unique at that time, not forever.
 * @param sbh A handle to scoreboard information for this connection.
 * @param alloc The bucket allocator to use for all bucket/brigade creations
 * @return An allocated connection record or NULL.
 */
AP_DECLARE_HOOK(conn_rec *, create_connection,
                (apr_pool_t *p, server_rec *server, apr_socket_t *csd,
                 long conn_id, void *sbh, apr_bucket_alloc_t *alloc))

/**
 * This hook gives protocol modules an opportunity to set everything up
 * before calling the protocol handler.  All pre-connection hooks are
 * run until one returns something other than ok or decline
 * @param c The connection on which the request has been received.
 * @param csd The mechanism on which this connection is to be read.
 *            Most times this will be a socket, but it is up to the module
 *            that accepts the request to determine the exact type.
 * @return OK or DECLINED
 */
AP_DECLARE_HOOK(int,pre_connection,(conn_rec *c, void *csd))

/**
 * This hook implements different protocols.  After a connection has been
 * established, the protocol module must read and serve the request.  This
 * function does that for each protocol module.  The first protocol module
 * to handle the request is the last module run.
 * @param c The connection on which the request has been received.
 * @return OK or DECLINED
 */
AP_DECLARE_HOOK(int,process_connection,(conn_rec *c))

/**
 * This hook implements different protocols.  Before a connection is closed,
 * protocols might have to perform some housekeeping actions, such as 
 * sending one last goodbye packet. The connection is, unless some other
 * error already happened before, still open and operational.
 * All pre-close-connection hooks are run until one returns something 
 * other than ok or decline
 * @param c The connection on which the request has been received.
 * @return OK or DECLINED
 */
AP_DECLARE_HOOK(int,pre_close_connection,(conn_rec *c))

/**
 * This is a wrapper around ap_run_pre_connection. In case that
 * ap_run_pre_connection returns an error it marks the connection as
 * aborted and ensures that the basic connection setup normally done
 * by the core module is done in case it was not done so far.
 * @param c The connection on which the request has been received.
 *          Same as for the pre_connection hook.
 * @param csd The mechanism on which this connection is to be read.
 *            Most times this will be a socket, but it is up to the module
 *            that accepts the request to determine the exact type.
 *            Same as for the pre_connection hook.
 * @return The result of ap_run_pre_connection
 */
AP_DECLARE(int) ap_pre_connection(conn_rec *c, void *csd);

/** End Of Connection (EOC) bucket */
AP_DECLARE_DATA extern const apr_bucket_type_t ap_bucket_type_eoc;

/**
 * Determine if a bucket is an End Of Connection (EOC) bucket
 * @param e The bucket to inspect
 * @return true or false
 */
#define AP_BUCKET_IS_EOC(e)         (e->type == &ap_bucket_type_eoc)

/**
 * Make the bucket passed in an End Of Connection (EOC) bucket
 * @param b The bucket to make into an EOC bucket
 * @return The new bucket, or NULL if allocation failed
 */
AP_DECLARE(apr_bucket *) ap_bucket_eoc_make(apr_bucket *b);

/**
 * Create a bucket referring to an End Of Connection (EOC). This indicates
 * that the connection will be closed.
 * @param list The freelist from which this bucket should be allocated
 * @return The new bucket, or NULL if allocation failed
 */
AP_DECLARE(apr_bucket *) ap_bucket_eoc_create(apr_bucket_alloc_t *list);

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_HTTP_CONNECTION_H */
/** @} */
