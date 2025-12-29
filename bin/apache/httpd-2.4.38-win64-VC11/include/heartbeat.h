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
 * @file  heartbeat.h
 * @brief commun structures for mod_heartmonitor.c and mod_lbmethod_heartbeat.c
 *
 * @defgroup HEARTBEAT heartbeat
 * @ingroup  APACHE_MODS
 * @{
 */

#ifndef HEARTBEAT_H
#define HEARTBEAT_H

#include "apr.h"
#include "apr_time.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Worse Case: IPv4-Mapped IPv6 Address
 * 0000:0000:0000:0000:0000:FFFF:255.255.255.255
 */
#define MAXIPSIZE  46
typedef struct hm_slot_server_t
{
    char ip[MAXIPSIZE];
    int busy;
    int ready;
    apr_time_t seen;
    int id;
} hm_slot_server_t;

/* default name of heartbeat data file, created in the configured
 * runtime directory when mod_slotmem_shm is not available
 */
#define DEFAULT_HEARTBEAT_STORAGE "hb.dat"

#ifdef __cplusplus
}
#endif

#endif /* HEARTBEAT_H */
/** @} */
