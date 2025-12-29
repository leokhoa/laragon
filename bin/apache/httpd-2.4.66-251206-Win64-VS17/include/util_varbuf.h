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
 * @file util_varbuf.h
 * @brief Apache resizable variable length buffer library
 *
 * @defgroup APACHE_CORE_VARBUF Variable length buffer library
 * @ingroup APACHE_CORE
 *
 * This set of functions provides resizable buffers. While the primary
 * usage is with NUL-terminated strings, most functions also work with
 * arbitrary binary data.
 * 
 * @{
 */

#ifndef AP_VARBUF_H
#define AP_VARBUF_H

#include "apr.h"
#include "apr_allocator.h"

#include "httpd.h"

#ifdef __cplusplus
extern "C" {
#endif

#define AP_VARBUF_UNKNOWN APR_SIZE_MAX
struct ap_varbuf_info;

/** A resizable buffer. */
struct ap_varbuf {
    /** The actual buffer; will point to a const '\\0' if avail == 0 and
     *  to memory of the same lifetime as the pool otherwise. */
    char *buf;

    /** Allocated size of the buffer (minus one for the final \\0);
     *  must only be changed using ap_varbuf_grow(). */
    apr_size_t avail;

    /** Length of string in buffer, or AP_VARBUF_UNKNOWN. This determines how
     *  much memory is copied by ap_varbuf_grow() and where
     *  ap_varbuf_strmemcat() will append to the buffer. */
    apr_size_t strlen;

    /** The pool for memory allocations and for registering the cleanup;
     *  the buffer memory will be released when this pool is cleared. */
    apr_pool_t *pool;

    /** Opaque info for memory allocation. */
    struct ap_varbuf_info *info;
};

/**
 * Initialize a resizable buffer. It is safe to re-initialize a previously
 * used ap_varbuf. The old buffer will be released when the corresponding
 * pool is cleared. The buffer remains usable until the pool is cleared,
 * even if the ap_varbuf was located on the stack and has gone out of scope.
 * @param   pool        The pool to allocate small buffers from and to register
 *                      the cleanup with
 * @param   vb          Pointer to the ap_varbuf struct
 * @param   init_size   The initial size of the buffer (see ap_varbuf_grow() for
 *                      details)
 */
AP_DECLARE(void) ap_varbuf_init(apr_pool_t *pool, struct ap_varbuf *vb,
                                apr_size_t init_size);

/**
 * Grow a resizable buffer. If the vb->buf cannot be grown in place, it will
 * be reallocated and the first vb->strlen + 1 bytes of memory will be copied
 * to the new location. If vb->strlen == AP_VARBUF_UNKNOWN, the whole buffer
 * is copied.
 * @param   vb          Pointer to the ap_varbuf struct
 * @param   new_size    The minimum new size of the buffer
 * @note ap_varbuf_grow() will usually at least double vb->buf's size with
 *       every invocation in order to reduce reallocations.
 * @note ap_varbuf_grow() will use pool memory for small and allocator
 *       mem nodes for larger allocations.
 * @note ap_varbuf_grow() will call vb->pool's abort function if out of memory.
 */
AP_DECLARE(void) ap_varbuf_grow(struct ap_varbuf *vb, apr_size_t new_size);

/**
 * Release memory from a ap_varbuf immediately, if possible.
 * This allows to free large buffers before the corresponding pool is
 * cleared. Only larger allocations using mem nodes will be freed.
 * @param   vb          Pointer to the ap_varbuf struct
 * @note After ap_varbuf_free(), vb must not be used unless ap_varbuf_init()
 *       is called again.
 */
AP_DECLARE(void) ap_varbuf_free(struct ap_varbuf *vb);

/**
 * Concatenate a string to an ap_varbuf. vb->strlen determines where
 * the string is appended in the buffer. If vb->strlen == AP_VARBUF_UNKNOWN,
 * the string will be appended at the first NUL byte in the buffer.
 * If len == 0, ap_varbuf_strmemcat() does nothing.
 * @param   vb      Pointer to the ap_varbuf struct
 * @param   str     The string to append; must be at least len bytes long
 * @param   len     The number of characters of *str to concatenate to the buf
 * @note vb->strlen will be set to the length of the new string
 * @note if len != 0, vb->buf will always be NUL-terminated
 */
AP_DECLARE(void) ap_varbuf_strmemcat(struct ap_varbuf *vb, const char *str,
                                     int len);

/**
 * Duplicate an ap_varbuf's content into pool memory.
 * @param   p           The pool to allocate from
 * @param   vb          The ap_varbuf to copy from
 * @param   prepend     An optional buffer to prepend (may be NULL)
 * @param   prepend_len Length of prepend
 * @param   append      An optional buffer to append (may be NULL)
 * @param   append_len  Length of append
 * @param   new_len     Where to store the length of the resulting string
 *                      (may be NULL)
 * @return The new string
 * @note ap_varbuf_pdup() uses vb->strlen to determine how much memory to
 *       copy. It works even if 0-bytes are embedded in vb->buf, prepend, or
 *       append.
 * @note If vb->strlen equals AP_VARBUF_UNKNOWN, it will be set to
 *       strlen(vb->buf).
 */
AP_DECLARE(char *) ap_varbuf_pdup(apr_pool_t *p, struct ap_varbuf *vb,
                                  const char *prepend, apr_size_t prepend_len,
                                  const char *append, apr_size_t append_len,
                                  apr_size_t *new_len);


/**
 * Concatenate a string to an ap_varbuf.
 * @param   vb      Pointer to the ap_varbuf struct
 * @param   str     The string to append
 * @note vb->strlen will be set to the length of the new string
 */
#define ap_varbuf_strcat(vb, str) ap_varbuf_strmemcat(vb, str, strlen(str))

/**
 * Perform string substitutions based on regexp match, using an ap_varbuf.
 * This function behaves like ap_pregsub(), but appends to an ap_varbuf
 * instead of allocating the result from a pool.
 * @param   vb      The ap_varbuf to which the string will be appended
 * @param   input   An arbitrary string containing $1 through $9. These are
 *                  replaced with the corresponding matched sub-expressions
 * @param   source  The string that was originally matched to the regex
 * @param   nmatch  The nmatch returned from ap_pregex
 * @param   pmatch  The pmatch array returned from ap_pregex
 * @param   maxlen  The maximum string length to append to vb, 0 for unlimited
 * @return APR_SUCCESS if successful
 * @note Just like ap_pregsub(), this function does not copy the part of
 *       *source before the matching part (i.e. the first pmatch[0].rm_so
 *       characters).
 * @note If vb->strlen equals AP_VARBUF_UNKNOWN, it will be set to
 *       strlen(vb->buf) first.
 */
AP_DECLARE(apr_status_t) ap_varbuf_regsub(struct ap_varbuf *vb,
                                          const char *input,
                                          const char *source,
                                          apr_size_t nmatch,
                                          ap_regmatch_t pmatch[],
                                          apr_size_t maxlen);

/**
 * Read a line from an ap_configfile_t and append it to an ap_varbuf.
 * @param   vb      Pointer to the ap_varbuf struct
 * @param   cfp     Pointer to the ap_configfile_t
 * @param   max_len Maximum line length, including leading/trailing whitespace
 * @return See ap_cfg_getline()
 * @note vb->strlen will be set to the length of the line
 * @note If vb->strlen equals AP_VARBUF_UNKNOWN, it will be set to
 *       strlen(vb->buf) first.
 */
AP_DECLARE(apr_status_t) ap_varbuf_cfg_getline(struct ap_varbuf *vb,
                                               ap_configfile_t *cfp,
                                               apr_size_t max_len);

#ifdef __cplusplus
}
#endif

#endif  /* !AP_VARBUF_H */
/** @} */
