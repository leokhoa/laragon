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
 * @file  http_main.h
 * @brief Command line options
 *
 * @defgroup APACHE_CORE_MAIN Command line options
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef APACHE_HTTP_MAIN_H
#define APACHE_HTTP_MAIN_H

#include "httpd.h"
#include "apr_optional.h"

/** AP_SERVER_BASEARGS is the command argument list parsed by http_main.c
 * in apr_getopt() format.  Use this for default'ing args that the MPM
 * can safely ignore and pass on from its rewrite_args() handler.
 */
#define AP_SERVER_BASEARGS "C:c:D:d:E:e:f:vVlLtTSMh?X"

#ifdef __cplusplus
extern "C" {
#endif

/** The name of the Apache executable */
AP_DECLARE_DATA extern const char *ap_server_argv0;
/** The global server's ServerRoot */
AP_DECLARE_DATA extern const char *ap_server_root;
/** The global server's DefaultRuntimeDir
 * This is not usable directly in the general case; use
 * ap_runtime_dir_relative() instead.
 */
AP_DECLARE_DATA extern const char *ap_runtime_dir;
/** The global server's server_rec */
AP_DECLARE_DATA extern server_rec *ap_server_conf;
/** global pool, for access prior to creation of server_rec */
AP_DECLARE_DATA extern apr_pool_t *ap_pglobal;
/** state of the server (startup, exiting, ...) */
AP_DECLARE_DATA extern int ap_main_state;
/** run mode (normal, config test, config dump, ...) */
AP_DECLARE_DATA extern int ap_run_mode;
/** run mode (normal, config test, config dump, ...) */
AP_DECLARE_DATA extern int ap_config_generation;

/* for -C, -c and -D switches */
/** An array of all -C directives.  These are processed before the server's
 *  config file */
AP_DECLARE_DATA extern apr_array_header_t *ap_server_pre_read_config;
/** An array of all -c directives.  These are processed after the server's
 *  config file */
AP_DECLARE_DATA extern apr_array_header_t *ap_server_post_read_config;
/** An array of all -D defines on the command line.  This allows people to
 *  effect the server based on command line options */
AP_DECLARE_DATA extern apr_array_header_t *ap_server_config_defines;
/** Available integer for using the -T switch */
AP_DECLARE_DATA extern int ap_document_root_check;

/**
 * An optional function to send signal to server on presence of '-k'
 * command line argument.
 * @param status The exit status after sending signal
 * @param pool Memory pool to allocate from
 */
APR_DECLARE_OPTIONAL_FN(int, ap_signal_server, (int *status, apr_pool_t *pool));

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_HTTP_MAIN_H */
/** @} */
