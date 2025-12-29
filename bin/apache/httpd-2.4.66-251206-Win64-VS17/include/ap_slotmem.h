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

#ifndef SLOTMEM_H
#define SLOTMEM_H

/* Memory handler for a shared memory divided in slot.
 */
/**
 * @file  ap_slotmem.h
 * @brief Memory Slot Extension Storage Module for Apache
 *
 * @defgroup MEM mem
 * @ingroup  APACHE_MODS
 * @{
 */

#include "httpd.h"
#include "http_config.h"
#include "http_log.h"
#include "ap_provider.h"

#include "apr.h"
#include "apr_strings.h"
#include "apr_pools.h"
#include "apr_shm.h"
#include "apr_global_mutex.h"
#include "apr_file_io.h"
#include "apr_md5.h"

#if APR_HAVE_UNISTD_H
#include <unistd.h>         /* for getpid() */
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define AP_SLOTMEM_PROVIDER_GROUP "slotmem"
#define AP_SLOTMEM_PROVIDER_VERSION "0"

typedef unsigned int ap_slotmem_type_t;

/*
 * Values for ap_slotmem_type_t::
 *
 * AP_SLOTMEM_TYPE_PERSIST: For transitory providers, persist
 *    the data on the file-system
 *
 * AP_SLOTMEM_TYPE_NOTMPSAFE:
 *
 * AP_SLOTMEM_TYPE_PREALLOC: Access to slots require they be grabbed 1st
 *
 * AP_SLOTMEM_TYPE_CLEARINUSE: If persisting, clear 'inuse' array before
 *    storing
 */
#define AP_SLOTMEM_TYPE_PERSIST      (1 << 0)
#define AP_SLOTMEM_TYPE_NOTMPSAFE    (1 << 1)
#define AP_SLOTMEM_TYPE_PREGRAB      (1 << 2)
#define AP_SLOTMEM_TYPE_CLEARINUSE   (1 << 3)

typedef struct ap_slotmem_instance_t ap_slotmem_instance_t;

/**
 * callback function used for slotmem doall.
 * @param mem is the memory associated with a worker.
 * @param data is what is passed to slotmem.
 * @param pool is pool used
 * @return APR_SUCCESS if all went well
 */
typedef apr_status_t ap_slotmem_callback_fn_t(void* mem, void *data, apr_pool_t *pool);

struct ap_slotmem_provider_t {
    /*
     * Name of the provider method
     */
    const char *name;
    /**
     * call the callback on all worker slots
     * @param s ap_slotmem_instance_t to use.
     * @param funct callback function to call for each element.
     * @param data parameter for the callback function.
     * @param pool is pool used
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* doall)(ap_slotmem_instance_t *s, ap_slotmem_callback_fn_t *func, void *data, apr_pool_t *pool);
    /**
     * create a new slotmem with each item size is item_size.
     * This would create shared memory, basically.
     * @param inst where to store pointer to slotmem
     * @param name a key used for debugging and in mod_status output or allow another process to share this space.
     * @param item_size size of each item
     * @param item_num number of item to create.
     * @param type type of slotmem.
     * @param pool is pool used
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* create)(ap_slotmem_instance_t **inst, const char *name, apr_size_t item_size, unsigned int item_num, ap_slotmem_type_t type, apr_pool_t *pool);
    /**
     * attach to an existing slotmem.
     * This would attach to  shared memory, basically.
     * @param inst where to store pointer to slotmem
     * @param name a key used for debugging and in mod_status output or allow another process to share this space.
     * @param item_size size of each item
     * @param item_num max number of item.
     * @param pool is pool to memory allocate.
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* attach)(ap_slotmem_instance_t **inst, const char *name, apr_size_t *item_size, unsigned int *item_num, apr_pool_t *pool);
    /**
     * get the memory ptr associated with this worker slot.
     * @param s ap_slotmem_instance_t to use.
     * @param item_id item to return for 0 to item_num
     * @param mem address to store the pointer to the slot
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* dptr)(ap_slotmem_instance_t *s, unsigned int item_id, void**mem);
    /**
     * get/read the data associated with this worker slot.
     * @param s ap_slotmem_instance_t to use.
     * @param item_id item to return for 0 to item_num
     * @param dest address to store the data
     * @param dest_len length of dataset to retrieve
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* get)(ap_slotmem_instance_t *s, unsigned int item_id, unsigned char *dest, apr_size_t dest_len);
    /**
     * put/write the data associated with this worker slot.
     * @param s ap_slotmem_instance_t to use.
     * @param item_id item to return for 0 to item_num
     * @param src address of the data to store in the slot
     * @param src_len length of dataset to store in the slot
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* put)(ap_slotmem_instance_t *slot, unsigned int item_id, unsigned char *src, apr_size_t src_len);
    /**
     * return number of slots allocated for this entry.
     * @param s ap_slotmem_instance_t to use.
     * @return number of slots
     */
    unsigned int (* num_slots)(ap_slotmem_instance_t *s);
    /**
     * return number of free (not used) slots allocated for this entry.
     * Valid for slots which are AP_SLOTMEM_TYPE_PREGRAB as well as
     * any which use get/release.
     * @param s ap_slotmem_instance_t to use.
     * @return number of slots
     */
    unsigned int (* num_free_slots)(ap_slotmem_instance_t *s);
    /**
     * return slot size allocated for this entry.
     * @param s ap_slotmem_instance_t to use.
     * @return size of slot
     */
    apr_size_t (* slot_size)(ap_slotmem_instance_t *s);
    /**
     * grab (or alloc) a free slot
     * @param s ap_slotmem_instance_t to use.
     * @param item_id ptr to the available slot id and marked as in-use
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* grab)(ap_slotmem_instance_t *s, unsigned int *item_id);
    /**
     * release (or free) the slot associated with this item_id
     * @param s ap_slotmem_instance_t to use.
     * @param item_id slot id to free and mark as no longer in-use
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* release)(ap_slotmem_instance_t *s, unsigned int item_id);
    /**
     * forced grab (or alloc) a slot associated with this item_id
     * @param s ap_slotmem_instance_t to use.
     * @param item_id to the specified slot id and marked as in-use
     * @return APR_SUCCESS if all went well
     */
    apr_status_t (* fgrab)(ap_slotmem_instance_t *s, unsigned int item_id);
};

typedef struct ap_slotmem_provider_t ap_slotmem_provider_t;

#ifdef __cplusplus
}
#endif

#endif
/** @} */
