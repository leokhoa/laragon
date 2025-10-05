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
 * @file util_filter.h
 * @brief Apache filter library
 */

#ifndef AP_FILTER_H
#define AP_FILTER_H

#include "apr.h"
#include "apr_buckets.h"

#include "httpd.h"

#if APR_HAVE_STDARG_H
#include <stdarg.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief input filtering modes
 */
typedef enum {
    /** The filter should return at most readbytes data. */
    AP_MODE_READBYTES,
    /** The filter should return at most one line of CRLF data.
     *  (If a potential line is too long or no CRLF is found, the
     *   filter may return partial data).
     */
    AP_MODE_GETLINE,
    /** The filter should implicitly eat any CRLF pairs that it sees. */
    AP_MODE_EATCRLF,
    /** The filter read should be treated as speculative and any returned
     *  data should be stored for later retrieval in another mode. */
    AP_MODE_SPECULATIVE,
    /** The filter read should be exhaustive and read until it can not
     *  read any more.
     *  Use this mode with extreme caution.
     */
    AP_MODE_EXHAUSTIVE,
    /** The filter should initialize the connection if needed,
     *  NNTP or FTP over SSL for example.
     */
    AP_MODE_INIT
} ap_input_mode_t;

/**
 * @defgroup APACHE_CORE_FILTER Filter Chain
 * @ingroup  APACHE_CORE
 *
 * Filters operate using a "chaining" mechanism. The filters are chained
 * together into a sequence. When output is generated, it is passed through
 * each of the filters on this chain, until it reaches the end (or "bottom")
 * and is placed onto the network.
 *
 * The top of the chain, the code generating the output, is typically called
 * a "content generator." The content generator's output is fed into the
 * filter chain using the standard Apache output mechanisms: ap_rputs(),
 * ap_rprintf(), ap_rwrite(), etc.
 *
 * Each filter is defined by a callback. This callback takes the output from
 * the previous filter (or the content generator if there is no previous
 * filter), operates on it, and passes the result to the next filter in the
 * chain. This pass-off is performed using the ap_fc_* functions, such as
 * ap_fc_puts(), ap_fc_printf(), ap_fc_write(), etc.
 *
 * When content generation is complete, the system will pass an "end of
 * stream" marker into the filter chain. The filters will use this to flush
 * out any internal state and to detect incomplete syntax (for example, an
 * unterminated SSI directive).
 *
 * @{
 */

/* forward declare the filter type */
typedef struct ap_filter_t ap_filter_t;

/**
 * @name Filter callbacks
 *
 * This function type is used for filter callbacks. It will be passed a
 * pointer to "this" filter, and a "bucket brigade" containing the content
 * to be filtered.
 *
 * In filter->ctx, the callback will find its context. This context is
 * provided here, so that a filter may be installed multiple times, each
 * receiving its own per-install context pointer.
 *
 * Callbacks are associated with a filter definition, which is specified
 * by name. See ap_register_input_filter() and ap_register_output_filter()
 * for setting the association between a name for a filter and its
 * associated callback (and other information).
 *
 * If the initialization function argument passed to the registration
 * functions is non-NULL, it will be called iff the filter is in the input
 * or output filter chains and before any data is generated to allow the
 * filter to prepare for processing.
 *
 * The bucket brigade always belongs to the caller, but the filter
 * is free to use the buckets within it as it sees fit. Normally,
 * the brigade will be returned empty. Buckets *may not* be retained
 * between successive calls to the filter unless they have been
 * "set aside" with a call apr_bucket_setaside. Typically this will
 * be done with ap_save_brigade(). Buckets removed from the brigade
 * become the responsibility of the filter, which must arrange for
 * them to be deleted, either by doing so directly or by inserting
 * them in a brigade which will subsequently be destroyed.
 *
 * For the input and output filters, the return value of a filter should be
 * an APR status value.  For the init function, the return value should
 * be an HTTP error code or OK if it was successful.
 *
 * @ingroup filter
 * @{
 */
typedef apr_status_t (*ap_out_filter_func)(ap_filter_t *f,
                                           apr_bucket_brigade *b);
typedef apr_status_t (*ap_in_filter_func)(ap_filter_t *f,
                                          apr_bucket_brigade *b,
                                          ap_input_mode_t mode,
                                          apr_read_type_e block,
                                          apr_off_t readbytes);
typedef int (*ap_init_filter_func)(ap_filter_t *f);

typedef union ap_filter_func {
    ap_out_filter_func out_func;
    ap_in_filter_func in_func;
} ap_filter_func;

/** @} */

/**
 * Filters have different types/classifications. These are used to group
 * and sort the filters to properly sequence their operation.
 *
 * The types have a particular sort order, which allows us to insert them
 * into the filter chain in a determistic order. Within a particular grouping,
 * the ordering is equivalent to the order of calls to ap_add_*_filter().
 */
typedef enum {
    /** These filters are used to alter the content that is passed through
     *  them. Examples are SSI or PHP. */
    AP_FTYPE_RESOURCE     = 10,
    /** These filters are used to alter the content as a whole, but after all
     *  AP_FTYPE_RESOURCE filters are executed.  These filters should not
     *  change the content-type.  An example is deflate.  */
    AP_FTYPE_CONTENT_SET  = 20,
    /** These filters are used to handle the protocol between server and
     *  client.  Examples are HTTP and POP. */
    AP_FTYPE_PROTOCOL     = 30,
    /** These filters implement transport encodings (e.g., chunking). */
    AP_FTYPE_TRANSCODE    = 40,
    /** These filters will alter the content, but in ways that are
     *  more strongly associated with the connection.  Examples are
     *  splitting an HTTP connection into multiple requests and
     *  buffering HTTP responses across multiple requests.
     *
     *  It is important to note that these types of filters are not
     *  allowed in a sub-request. A sub-request's output can certainly
     *  be filtered by ::AP_FTYPE_RESOURCE filters, but all of the "final
     *  processing" is determined by the main request. */
    AP_FTYPE_CONNECTION  = 50,
    /** These filters don't alter the content.  They are responsible for
     *  sending/receiving data to/from the client. */
    AP_FTYPE_NETWORK     = 60
} ap_filter_type;

/**
 * This is the request-time context structure for an installed filter (in
 * the output filter chain). It provides the callback to use for filtering,
 * the request this filter is associated with (which is important when
 * an output chain also includes sub-request filters), the context for this
 * installed filter, and the filter ordering/chaining fields.
 *
 * Filter callbacks are free to use ->ctx as they please, to store context
 * during the filter process. Generally, this is superior over associating
 * the state directly with the request. A callback should not change any of
 * the other fields.
 */

typedef struct ap_filter_rec_t ap_filter_rec_t;
typedef struct ap_filter_provider_t ap_filter_provider_t;

/**
 * @brief This structure is used for recording information about the
 * registered filters. It associates a name with the filter's callback
 * and filter type.
 *
 * At the moment, these are simply linked in a chain, so a ->next pointer
 * is available.
 *
 * It is used for any filter that can be inserted in the filter chain.
 * This may be either a httpd-2.0 filter or a mod_filter harness.
 * In the latter case it contains dispatch, provider and protocol information.
 * In the former case, the new fields (from dispatch) are ignored.
 */
struct ap_filter_rec_t {
    /** The registered name for this filter */
    const char *name;

    /** The function to call when this filter is invoked. */
    ap_filter_func filter_func;

    /** The function to call directly before the handlers are invoked
     * for a request.  The init function is called once directly
     * before running the handlers for a request or subrequest.  The
     * init function is never called for a connection filter (with
     * ftype >= AP_FTYPE_CONNECTION).  Any use of this function for
     * filters for protocols other than HTTP is specified by the
     * module supported that protocol.
     */
    ap_init_filter_func filter_init_func;

    /** The next filter_rec in the list */
    struct ap_filter_rec_t *next;

    /** Providers for this filter */
    ap_filter_provider_t *providers;

    /** The type of filter, either AP_FTYPE_CONTENT or AP_FTYPE_CONNECTION.
     * An AP_FTYPE_CONTENT filter modifies the data based on information
     * found in the content.  An AP_FTYPE_CONNECTION filter modifies the
     * data based on the type of connection.
     */
    ap_filter_type ftype;

    /** Trace level for this filter */
    int debug;

    /** Protocol flags for this filter */
    unsigned int proto_flags;
};

/**
 * @brief The representation of a filter chain.
 *
 * Each request has a list
 * of these structures which are called in turn to filter the data.  Sub
 * requests get an exact copy of the main requests filter chain.
 */
struct ap_filter_t {
    /** The internal representation of this filter.  This includes
     *  the filter's name, type, and the actual function pointer.
     */
    ap_filter_rec_t *frec;

    /** A place to store any data associated with the current filter */
    void *ctx;

    /** The next filter in the chain */
    ap_filter_t *next;

    /** The request_rec associated with the current filter.  If a sub-request
     *  adds filters, then the sub-request is the request associated with the
     *  filter.
     */
    request_rec *r;

    /** The conn_rec associated with the current filter.  This is analogous
     *  to the request_rec, except that it is used for connection filters.
     */
    conn_rec *c;
};

/**
 * Get the current bucket brigade from the next filter on the filter
 * stack.  The filter returns an apr_status_t value.  If the bottom-most
 * filter doesn't read from the network, then ::AP_NOBODY_READ is returned.
 * The bucket brigade will be empty when there is nothing left to get.
 * @param filter The next filter in the chain
 * @param bucket The current bucket brigade.  The original brigade passed
 *               to ap_get_brigade() must be empty.
 * @param mode   The way in which the data should be read
 * @param block  How the operations should be performed
 *               ::APR_BLOCK_READ, ::APR_NONBLOCK_READ
 * @param readbytes How many bytes to read from the next filter.
 */
AP_DECLARE(apr_status_t) ap_get_brigade(ap_filter_t *filter,
                                        apr_bucket_brigade *bucket,
                                        ap_input_mode_t mode,
                                        apr_read_type_e block,
                                        apr_off_t readbytes);

/**
 * Pass the current bucket brigade down to the next filter on the filter
 * stack.  The filter returns an apr_status_t value.  If the bottom-most
 * filter doesn't write to the network, then ::AP_NOBODY_WROTE is returned.
 * @param filter The next filter in the chain
 * @param bucket The current bucket brigade
 *
 * @remark Ownership of the brigade is retained by the caller. On return,
 *         the contents of the brigade are UNDEFINED, and the caller must
 *         either call apr_brigade_cleanup or apr_brigade_destroy on
 *         the brigade.
 */
AP_DECLARE(apr_status_t) ap_pass_brigade(ap_filter_t *filter,
                                         apr_bucket_brigade *bucket);

/**
 * Pass the current bucket brigade down to the next filter on the filter
 * stack checking for filter errors.  The filter returns an apr_status_t value.
 * Returns ::OK if the brigade is successfully passed
 *         ::AP_FILTER_ERROR on a filter error
 *         ::HTTP_INTERNAL_SERVER_ERROR on all other errors
 * @param r      The request rec
 * @param bucket The current bucket brigade
 * @param fmt The format string. If NULL defaults to "ap_pass_brigade returned"
 * @param ... The arguments to use to fill out the format string
 * @remark Ownership of the brigade is retained by the caller. On return,
 *         the contents of the brigade are UNDEFINED, and the caller must
 *         either call apr_brigade_cleanup or apr_brigade_destroy on
 *         the brigade.
 */
AP_DECLARE(apr_status_t) ap_pass_brigade_fchk(request_rec *r,
                                              apr_bucket_brigade *bucket,
                                              const char *fmt,
                                              ...)
                                              __attribute__((format(printf,3,4)));

/**
 * This function is used to register an input filter with the system.
 * After this registration is performed, then a filter may be added
 * into the filter chain by using ap_add_input_filter() and simply
 * specifying the name.
 *
 * @param name The name to attach to the filter function
 * @param filter_func The filter function to name
 * @param filter_init The function to call before the filter handlers
                      are invoked
 * @param ftype The type of filter function, either ::AP_FTYPE_CONTENT_SET or
 *              ::AP_FTYPE_CONNECTION
 * @see add_input_filter()
 */
AP_DECLARE(ap_filter_rec_t *) ap_register_input_filter(const char *name,
                                          ap_in_filter_func filter_func,
                                          ap_init_filter_func filter_init,
                                          ap_filter_type ftype);

/** @deprecated @see ap_register_output_filter_protocol */
AP_DECLARE(ap_filter_rec_t *) ap_register_output_filter(const char *name,
                                            ap_out_filter_func filter_func,
                                            ap_init_filter_func filter_init,
                                            ap_filter_type ftype);

/* For httpd-?.? I suggest replacing the above with
#define ap_register_output_filter(name,ffunc,init,ftype) \
             ap_register_output_filter_protocol(name,ffunc,init,ftype,0)
*/

/**
 * This function is used to register an output filter with the system.
 * After this registration is performed, then a filter may be added
 * directly to the filter chain by using ap_add_output_filter() and
 * simply specifying the name, or as a provider under mod_filter.
 *
 * @param name The name to attach to the filter function
 * @param filter_func The filter function to name
 * @param filter_init The function to call before the filter handlers
 *                    are invoked
 * @param ftype The type of filter function, either ::AP_FTYPE_CONTENT_SET or
 *              ::AP_FTYPE_CONNECTION
 * @param proto_flags Protocol flags: logical OR of AP_FILTER_PROTO_* bits
 * @return the filter rec
 * @see ap_add_output_filter()
 */
AP_DECLARE(ap_filter_rec_t *) ap_register_output_filter_protocol(
                                            const char *name,
                                            ap_out_filter_func filter_func,
                                            ap_init_filter_func filter_init,
                                            ap_filter_type ftype,
                                            unsigned int proto_flags);

/**
 * Adds a named filter into the filter chain on the specified request record.
 * The filter will be installed with the specified context pointer.
 *
 * Filters added in this way will always be placed at the end of the filters
 * that have the same type (thus, the filters have the same order as the
 * calls to ap_add_filter). If the current filter chain contains filters
 * from another request, then this filter will be added before those other
 * filters.
 *
 * To re-iterate that last comment.  This function is building a FIFO
 * list of filters.  Take note of that when adding your filter to the chain.
 *
 * @param name The name of the filter to add
 * @param ctx Context data to provide to the filter
 * @param r The request to add this filter for (or NULL if it isn't associated with a request)
 * @param c The connection to add the fillter for
 */
AP_DECLARE(ap_filter_t *) ap_add_input_filter(const char *name, void *ctx,
                                              request_rec *r, conn_rec *c);

/**
 * Variant of ap_add_input_filter() that accepts a registered filter handle
 * (as returned by ap_register_input_filter()) rather than a filter name
 *
 * @param f The filter handle to add
 * @param ctx Context data to provide to the filter
 * @param r The request to add this filter for (or NULL if it isn't associated with a request)
 * @param c The connection to add the fillter for
 */
AP_DECLARE(ap_filter_t *) ap_add_input_filter_handle(ap_filter_rec_t *f,
                                                     void *ctx,
                                                     request_rec *r,
                                                     conn_rec *c);

/**
 * Returns the filter handle for use with ap_add_input_filter_handle.
 *
 * @param name The filter name to look up
 */
AP_DECLARE(ap_filter_rec_t *) ap_get_input_filter_handle(const char *name);

/**
 * Add a filter to the current request.  Filters are added in a FIFO manner.
 * The first filter added will be the first filter called.
 * @param name The name of the filter to add
 * @param ctx Context data to set in the filter
 * @param r The request to add this filter for (or NULL if it isn't associated with a request)
 * @param c The connection to add this filter for
 * @note If adding a connection-level output filter (i.e. where the type
 * is >= AP_FTYPE_CONNECTION) during processing of a request, the request
 * object r must be passed in to ensure the filter chains are modified
 * correctly.  f->r will still be initialized as NULL in the new filter.
 */
AP_DECLARE(ap_filter_t *) ap_add_output_filter(const char *name, void *ctx,
                                               request_rec *r, conn_rec *c);

/**
 * Variant of ap_add_output_filter() that accepts a registered filter handle
 * (as returned by ap_register_output_filter()) rather than a filter name
 *
 * @param f The filter handle to add
 * @param ctx Context data to set in the filter
 * @param r The request to add this filter for (or NULL if it isn't associated with a request)
 * @param c The connection to add the filter for
 * @note If adding a connection-level output filter (i.e. where the type
 * is >= AP_FTYPE_CONNECTION) during processing of a request, the request
 * object r must be passed in to ensure the filter chains are modified
 * correctly.  f->r will still be initialized as NULL in the new filter.
 */
AP_DECLARE(ap_filter_t *) ap_add_output_filter_handle(ap_filter_rec_t *f,
                                                      void *ctx,
                                                      request_rec *r,
                                                      conn_rec *c);

/**
 * Returns the filter handle for use with ap_add_output_filter_handle.
 *
 * @param name The filter name to look up
 */
AP_DECLARE(ap_filter_rec_t *) ap_get_output_filter_handle(const char *name);

/**
 * Remove an input filter from either the request or connection stack
 * it is associated with.
 * @param f The filter to remove
 */

AP_DECLARE(void) ap_remove_input_filter(ap_filter_t *f);

/**
 * Remove an output filter from either the request or connection stack
 * it is associated with.
 * @param f The filter to remove
 */

AP_DECLARE(void) ap_remove_output_filter(ap_filter_t *f);

/**
 * Remove an input filter from either the request or connection stack
 * it is associated with.
 * @param next   The filter stack to search
 * @param handle The filter handle (name) to remove
 * @return APR_SUCCESS on removal or error
 */
AP_DECLARE(apr_status_t) ap_remove_input_filter_byhandle(ap_filter_t *next,
                                                         const char *handle);
/**
 * Remove an output filter from either the request or connection stack
 * it is associated with.
 * @param next   The filter stack to search
 * @param handle The filter handle (name) to remove
 * @return APR_SUCCESS on removal or error
 */
AP_DECLARE(apr_status_t) ap_remove_output_filter_byhandle(ap_filter_t *next,
                                                          const char *handle);

/* The next two filters are for abstraction purposes only.  They could be
 * done away with, but that would require that we break modules if we ever
 * want to change our filter registration method.  The basic idea, is that
 * all filters have a place to store data, the ctx pointer.  These functions
 * fill out that pointer with a bucket brigade, and retrieve that data on
 * the next call.  The nice thing about these functions, is that they
 * automatically concatenate the bucket brigades together for you.  This means
 * that if you have already stored a brigade in the filters ctx pointer, then
 * when you add more it will be tacked onto the end of that brigade.  When
 * you retrieve data, if you pass in a bucket brigade to the get function,
 * it will append the current brigade onto the one that you are retrieving.
 */

/**
 * prepare a bucket brigade to be setaside.  If a different brigade was
 * set-aside earlier, then the two brigades are concatenated together.
 * @param f The current filter
 * @param save_to The brigade that was previously set-aside.  Regardless, the
 *             new bucket brigade is returned in this location.
 * @param b The bucket brigade to save aside.  This brigade is always empty
 *          on return
 * @param p Ensure that all data in the brigade lives as long as this pool
 */
AP_DECLARE(apr_status_t) ap_save_brigade(ap_filter_t *f,
                                         apr_bucket_brigade **save_to,
                                         apr_bucket_brigade **b, apr_pool_t *p);

/**
 * Flush function for apr_brigade_* calls.  This calls ap_pass_brigade
 * to flush the brigade if the brigade buffer overflows.
 * @param bb The brigade to flush
 * @param ctx The filter to pass the brigade to
 * @note this function has nothing to do with FLUSH buckets. It is simply
 * a way to flush content out of a brigade and down a filter stack.
 */
AP_DECLARE_NONSTD(apr_status_t) ap_filter_flush(apr_bucket_brigade *bb,
                                                void *ctx);

/**
 * Flush the current brigade down the filter stack.
 * @param f The filter we are passing to
 * @param bb The brigade to flush
 */
AP_DECLARE(apr_status_t) ap_fflush(ap_filter_t *f, apr_bucket_brigade *bb);

/**
 * Write a buffer for the current filter, buffering if possible.
 * @param f the filter we are writing to
 * @param bb The brigade to buffer into
 * @param data The data to write
 * @param nbyte The number of bytes in the data
 */
#define ap_fwrite(f, bb, data, nbyte) \
        apr_brigade_write(bb, ap_filter_flush, f, data, nbyte)

/**
 * Write a buffer for the current filter, buffering if possible.
 * @param f the filter we are writing to
 * @param bb The brigade to buffer into
 * @param str The string to write
 */
#define ap_fputs(f, bb, str) \
        apr_brigade_write(bb, ap_filter_flush, f, str, strlen(str))

/**
 * Write a character for the current filter, buffering if possible.
 * @param f the filter we are writing to
 * @param bb The brigade to buffer into
 * @param c The character to write
 */
#define ap_fputc(f, bb, c) \
        apr_brigade_putc(bb, ap_filter_flush, f, c)

/**
 * Write an unspecified number of strings to the current filter
 * @param f the filter we are writing to
 * @param bb The brigade to buffer into
 * @param ... The strings to write
 */
AP_DECLARE_NONSTD(apr_status_t) ap_fputstrs(ap_filter_t *f,
                                            apr_bucket_brigade *bb,
                                            ...)
                                AP_FN_ATTR_SENTINEL;

/**
 * Output data to the filter in printf format
 * @param f the filter we are writing to
 * @param bb The brigade to buffer into
 * @param fmt The format string
 * @param ... The arguments to use to fill out the format string
 */
AP_DECLARE_NONSTD(apr_status_t) ap_fprintf(ap_filter_t *f,
                                           apr_bucket_brigade *bb,
                                           const char *fmt,
                                           ...)
        __attribute__((format(printf,3,4)));

/**
 * set protocol requirements for an output content filter
 * (only works with AP_FTYPE_RESOURCE and AP_FTYPE_CONTENT_SET)
 * @param f the filter in question
 * @param proto_flags Logical OR of AP_FILTER_PROTO_* bits
 */
AP_DECLARE(void) ap_filter_protocol(ap_filter_t* f, unsigned int proto_flags);

/** Filter changes contents (so invalidating checksums/etc) */
#define AP_FILTER_PROTO_CHANGE 0x1

/** Filter changes length of contents (so invalidating content-length/etc) */
#define AP_FILTER_PROTO_CHANGE_LENGTH 0x2

/** Filter requires complete input and can't work on byteranges */
#define AP_FILTER_PROTO_NO_BYTERANGE 0x4

/** Filter should not run in a proxy */
#define AP_FILTER_PROTO_NO_PROXY 0x8

/** Filter makes output non-cacheable */
#define AP_FILTER_PROTO_NO_CACHE 0x10

/** Filter is incompatible with "Cache-Control: no-transform" */
#define AP_FILTER_PROTO_TRANSFORM 0x20

/**
 * @}
 */

#ifdef __cplusplus
}
#endif

#endif  /* !AP_FILTER_H */
