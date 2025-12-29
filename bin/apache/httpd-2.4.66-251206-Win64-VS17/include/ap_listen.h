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
 * @file  ap_listen.h
 * @brief Apache Listeners Library
 *
 * @defgroup APACHE_CORE_LISTEN Apache Listeners Library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef AP_LISTEN_H
#define AP_LISTEN_H

#include "apr_network_io.h"
#include "httpd.h"
#include "http_config.h"
#include "apr_optional.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ap_slave_t ap_slave_t;
typedef struct ap_listen_rec ap_listen_rec;
typedef apr_status_t (*accept_function)(void **csd, ap_listen_rec *lr, apr_pool_t *ptrans);

/**
 * @brief Apache's listeners record.
 *
 * These are used in the Multi-Processing Modules
 * to setup all of the sockets for the MPM to listen to and accept on.
 */
struct ap_listen_rec {
    /**
     * The next listener in the list
     */
    ap_listen_rec *next;
    /**
     * The actual socket
     */
    apr_socket_t *sd;
    /**
     * The sockaddr the socket should bind to
     */
    apr_sockaddr_t *bind_addr;
    /**
     * The accept function for this socket
     */
    accept_function accept_func;
    /**
     * Is this socket currently active
     */
    int active;
    /**
     * The default protocol for this listening socket.
     */
    const char* protocol;

    ap_slave_t *slave;
};

/**
 * The global list of ap_listen_rec structures
 */
AP_DECLARE_DATA extern ap_listen_rec *ap_listeners;
AP_DECLARE_DATA extern int ap_num_listen_buckets;
AP_DECLARE_DATA extern int ap_have_so_reuseport;

/**
 * Setup all of the defaults for the listener list
 */
AP_DECLARE(void) ap_listen_pre_config(void);

/**
 * Loop through the global ap_listen_rec list and create all of the required
 * sockets.  This executes the listen and bind on the sockets.
 * @param s The global server_rec
 * @return The number of open sockets.
 */
AP_DECLARE(int) ap_setup_listeners(server_rec *s);

/**
 * This function duplicates ap_listeners into multiple buckets when configured
 * to (see ListenCoresBucketsRatio) and the platform supports it (eg. number of
 * online CPU cores and SO_REUSEPORT available).
 * @param p The config pool
 * @param s The global server_rec
 * @param buckets The array of listeners buckets.
 * @param num_buckets The total number of listeners buckets (array size).
 * @remark If the given *num_buckets is 0 (input), it will be computed
 *         according to the platform capacities, otherwise (positive) it
 *         will be preserved. The number of listeners duplicated will
 *         always match *num_buckets, be it computed or given.
 */
AP_DECLARE(apr_status_t) ap_duplicate_listeners(apr_pool_t *p, server_rec *s,
                                                ap_listen_rec ***buckets,
                                                int *num_buckets);

/**
 * Loop through the global ap_listen_rec list and close each of the sockets.
 */
AP_DECLARE_NONSTD(void) ap_close_listeners(void);

/**
 * Loop through the given ap_listen_rec list and close each of the sockets.
 * @param listeners The listener to close.
 */
AP_DECLARE_NONSTD(void) ap_close_listeners_ex(ap_listen_rec *listeners);

/**
 * FIXMEDOC
 */
AP_DECLARE_NONSTD(int) ap_close_selected_listeners(ap_slave_t *);

/* Although these functions are exported from libmain, they are not really
 * public functions.  These functions are actually called while parsing the
 * config file, when one of the LISTEN_COMMANDS directives is read.  These
 * should not ever be called by external modules.  ALL MPMs should include
 * LISTEN_COMMANDS in their command_rec table so that these functions are
 * called.
 */
AP_DECLARE_NONSTD(const char *) ap_set_listenbacklog(cmd_parms *cmd, void *dummy, const char *arg);
AP_DECLARE_NONSTD(const char *) ap_set_listentcpdeferaccept(cmd_parms *cmd, void *dummy, const char *arg);
AP_DECLARE_NONSTD(const char *) ap_set_listencbratio(cmd_parms *cmd, void *dummy, const char *arg);
AP_DECLARE_NONSTD(const char *) ap_set_listener(cmd_parms *cmd, void *dummy,
                                                int argc, char *const argv[]);
AP_DECLARE_NONSTD(const char *) ap_set_send_buffer_size(cmd_parms *cmd, void *dummy,
                                                        const char *arg);
AP_DECLARE_NONSTD(const char *) ap_set_receive_buffer_size(cmd_parms *cmd,
                                                           void *dummy,
                                                           const char *arg);

#ifdef HAVE_SYSTEMD
APR_DECLARE_OPTIONAL_FN(int,
                        ap_find_systemd_socket, (process_rec *, apr_port_t));

APR_DECLARE_OPTIONAL_FN(int,
                        ap_systemd_listen_fds, (int));
#endif


#define LISTEN_COMMANDS \
AP_INIT_TAKE1("ListenBacklog", ap_set_listenbacklog, NULL, RSRC_CONF, \
  "Maximum length of the queue of pending connections, as used by listen(2)"), \
AP_INIT_TAKE1("ListenCoresBucketsRatio", ap_set_listencbratio, NULL, RSRC_CONF, \
  "Ratio between the number of CPU cores (online) and the number of listeners buckets"), \
AP_INIT_TAKE_ARGV("Listen", ap_set_listener, NULL, RSRC_CONF, \
  "A port number or a numeric IP address and a port number, and an optional protocol"), \
AP_INIT_TAKE1("SendBufferSize", ap_set_send_buffer_size, NULL, RSRC_CONF, \
  "Send buffer size in bytes"), \
AP_INIT_TAKE1("ReceiveBufferSize", ap_set_receive_buffer_size, NULL, \
              RSRC_CONF, "Receive buffer size in bytes"), \
AP_INIT_TAKE1("ListenTCPDeferAccept", ap_set_listentcpdeferaccept, NULL, RSRC_CONF, \
  "Value set for the socket option TCP_DEFER_ACCEPT if it is set")

#ifdef __cplusplus
}
#endif

#endif
/** @} */
