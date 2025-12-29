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
 * @file mod_log_config.h
 * @brief Logging Configuration Extension Module for Apache
 *
 * @defgroup MOD_LOG_CONFIG mod_log_config
 * @ingroup APACHE_MODS
 * @{
 */

#include "apr_optional.h"
#include "httpd.h"
#include "scoreboard.h"

#ifndef _MOD_LOG_CONFIG_H
#define _MOD_LOG_CONFIG_H 1

/**
 * callback function prototype for a external log handler
 */
typedef const char *ap_log_handler_fn_t(request_rec *r, char *a);

/**
 * callback function prototype for external writer initialization.
 */
typedef void *ap_log_writer_init(apr_pool_t *p, server_rec *s,
                                 const char *name);
/**
 * callback which gets called where there is a log line to write.
 */
typedef apr_status_t ap_log_writer(
                            request_rec *r,
                            void *handle,
                            const char **portions,
                            int *lengths,
                            int nelts,
                            apr_size_t len);

typedef struct ap_log_handler {
    ap_log_handler_fn_t *func;
    int want_orig_default;
} ap_log_handler;

APR_DECLARE_OPTIONAL_FN(void, ap_register_log_handler,
                        (apr_pool_t *p, char *tag, ap_log_handler_fn_t *func,
                         int def));
/**
 * you will need to set your init handler *BEFORE* the open_logs
 * in mod_log_config gets executed
 */
APR_DECLARE_OPTIONAL_FN(ap_log_writer_init*, ap_log_set_writer_init,(ap_log_writer_init *func));
/**
 * you should probably set the writer at the same time (ie..before open_logs)
 */
APR_DECLARE_OPTIONAL_FN(ap_log_writer*, ap_log_set_writer, (ap_log_writer* func));

#endif /* MOD_LOG_CONFIG */
/** @} */

