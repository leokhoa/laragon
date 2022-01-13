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
 * @file  mod_dav.h
 * @brief DAV extension module for Apache 2.0.*
 *
 * @defgroup MOD_DAV mod_dav
 * @ingroup APACHE_MODS
 * @{
 */

#ifndef _MOD_DAV_H_
#define _MOD_DAV_H_

#include "apr_hooks.h"
#include "apr_hash.h"
#include "apr_dbm.h"
#include "apr_tables.h"

#include "httpd.h"
#include "util_filter.h"
#include "util_xml.h"

#include <limits.h>     /* for INT_MAX */
#include <time.h>       /* for time_t */

#ifdef __cplusplus
extern "C" {
#endif


#define DAV_VERSION             AP_SERVER_BASEREVISION

#define DAV_XML_HEADER          "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
#define DAV_XML_CONTENT_TYPE    "text/xml; charset=\"utf-8\""

#define DAV_READ_BLOCKSIZE      2048    /* used for reading input blocks */

#define DAV_RESPONSE_BODY_1	"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n<html>\n<head>\n<title>"
#define DAV_RESPONSE_BODY_2     "</title>\n</head><body>\n<h1>"
#define DAV_RESPONSE_BODY_3     "</h1>\n<p>"
#define DAV_RESPONSE_BODY_4     "</p>\n"
#define DAV_RESPONSE_BODY_5     "</body></html>\n"

#define DAV_DO_COPY             0
#define DAV_DO_MOVE             1


#if 1
#define DAV_DEBUG        1
#define DEBUG_CR         "\n"
#define DBG0(f)          ap_log_error(APLOG_MARK, \
                                APLOG_ERR, 0, NULL, (f))
#define DBG1(f,a1)       ap_log_error(APLOG_MARK, \
                                APLOG_ERR, 0, NULL, f, a1)
#define DBG2(f,a1,a2)    ap_log_error(APLOG_MARK, \
                                APLOG_ERR, 0, NULL, f, a1, a2)
#define DBG3(f,a1,a2,a3) ap_log_error(APLOG_MARK, \
                                APLOG_ERR, 0, NULL, f, a1, a2, a3)
#else
#undef DAV_DEBUG
#define DEBUG_CR        ""
#endif

#define DAV_INFINITY    INT_MAX    /* for the Depth: header */

/* Create a set of DAV_DECLARE(type), DAV_DECLARE_NONSTD(type) and
 * DAV_DECLARE_DATA with appropriate export and import tags for the platform
 */
#if !defined(WIN32)
#define DAV_DECLARE(type)            type
#define DAV_DECLARE_NONSTD(type)     type
#define DAV_DECLARE_DATA
#elif defined(DAV_DECLARE_STATIC)
#define DAV_DECLARE(type)            type __stdcall
#define DAV_DECLARE_NONSTD(type)     type
#define DAV_DECLARE_DATA
#elif defined(DAV_DECLARE_EXPORT)
#define DAV_DECLARE(type)            __declspec(dllexport) type __stdcall
#define DAV_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define DAV_DECLARE_DATA             __declspec(dllexport)
#else
#define DAV_DECLARE(type)            __declspec(dllimport) type __stdcall
#define DAV_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define DAV_DECLARE_DATA             __declspec(dllimport)
#endif

/* --------------------------------------------------------------------
**
** ERROR MANAGEMENT
*/

/*
** dav_error structure.
**
** In most cases, mod_dav uses a pointer to a dav_error structure. If the
** pointer is NULL, then no error has occurred.
**
** In certain cases, a dav_error structure is directly used. In these cases,
** a status value of 0 means that an error has not occurred.
**
** Note: this implies that status != 0 whenever an error occurs.
**
** The desc field is optional (it may be NULL). When NULL, it typically
** implies that Apache has a proper description for the specified status.
*/
typedef struct dav_error {
    int status;                 /* suggested HTTP status (0 for no error) */
    int error_id;               /* DAV-specific error ID */
    const char *desc;           /* DAV:responsedescription and error log */

    apr_status_t aprerr;        /* APR error if any, or 0/APR_SUCCESS */

    const char *namespace;      /* [optional] namespace of error */
    const char *tagname;        /* name of error-tag */

    struct dav_error *prev;     /* previous error (in stack) */

    const char *childtags;      /* error-tag may have children */

} dav_error;

/*
** Create a new error structure. save_errno will be filled with the current
** errno value.
*/
DAV_DECLARE(dav_error*) dav_new_error(apr_pool_t *p, int status,
                                      int error_id, apr_status_t aprerr,
                                      const char *desc);


/*
** Create a new error structure with tagname and (optional) namespace;
** namespace may be NULL, which means "DAV:".
*/
DAV_DECLARE(dav_error*) dav_new_error_tag(apr_pool_t *p, int status,
                                          int error_id, apr_status_t aprerr,
                                          const char *desc,
                                          const char *namespace,
                                          const char *tagname);


/*
** Push a new error description onto the stack of errors.
**
** This function is used to provide an additional description to an existing
** error.
**
** <status> should contain the caller's view of what the current status is,
** given the underlying error. If it doesn't have a better idea, then the
** caller should pass prev->status.
**
** <error_id> can specify a new error_id since the topmost description has
** changed.
*/
DAV_DECLARE(dav_error*) dav_push_error(apr_pool_t *p, int status, int error_id,
                                       const char *desc, dav_error *prev);


/*
** Join two errors together.
**
** This function is used to add a new error stack onto an existing error so
** that subsequent errors can be reported after the first error.  It returns
** the correct error stack to use so that the caller can blindly call it
** without checking that both dest and src are not NULL.
** 
** <dest> is the error stack that the error will be added to.
**
** <src> is the error stack that will be appended.
*/
DAV_DECLARE(dav_error*) dav_join_error(dav_error* dest, dav_error* src);

typedef struct dav_response dav_response;

/*
** dav_handle_err()
**
** Handle the standard error processing. <err> must be non-NULL.
**
** <response> is set by the following:
**   - dav_validate_request()
**   - dav_add_lock()
**   - repos_hooks->remove_resource
**   - repos_hooks->move_resource
**   - repos_hooks->copy_resource
**   - vsn_hooks->update
*/
DAV_DECLARE(int) dav_handle_err(request_rec *r, dav_error *err,
                                dav_response *response);

/* error ID values... */

/* IF: header errors */
#define DAV_ERR_IF_PARSE                100    /* general parsing error */
#define DAV_ERR_IF_MULTIPLE_NOT         101    /* multiple "Not" found */
#define DAV_ERR_IF_UNK_CHAR             102    /* unknown char in header */
#define DAV_ERR_IF_ABSENT               103    /* no locktokens given */
#define DAV_ERR_IF_TAGGED               104    /* in parsing tagged-list */
#define DAV_ERR_IF_UNCLOSED_PAREN       105    /* in no-tagged-list */

/* Prop DB errors */
#define DAV_ERR_PROP_BAD_MAJOR          200    /* major version was wrong */
#define DAV_ERR_PROP_READONLY           201    /* prop is read-only */
#define DAV_ERR_PROP_NO_DATABASE        202    /* writable db not avail */
#define DAV_ERR_PROP_NOT_FOUND          203    /* prop not found */
#define DAV_ERR_PROP_BAD_LOCKDB         204    /* could not open lockdb */
#define DAV_ERR_PROP_OPENING            205    /* problem opening propdb */
#define DAV_ERR_PROP_EXEC               206    /* problem exec'ing patch */

/* Predefined DB errors */
/* ### any to define?? */

/* Predefined locking system errors */
#define DAV_ERR_LOCK_OPENDB             400    /* could not open lockdb */
#define DAV_ERR_LOCK_NO_DB              401    /* no database defined */
#define DAV_ERR_LOCK_CORRUPT_DB         402    /* DB is corrupt */
#define DAV_ERR_LOCK_UNK_STATE_TOKEN    403    /* unknown State-token */
#define DAV_ERR_LOCK_PARSE_TOKEN        404    /* bad opaquelocktoken */
#define DAV_ERR_LOCK_SAVE_LOCK          405    /* err saving locks */

/*
** Some comments on Error ID values:
**
** The numbers do not necessarily need to be unique. Uniqueness simply means
** that two errors that have not been predefined above can be distinguished
** from each other. At the moment, mod_dav does not use this distinguishing
** feature, but it could be used in the future to collapse <response> elements
** into groups based on the error ID (and associated responsedescription).
**
** If a compute_desc is provided, then the error ID should be unique within
** the context of the compute_desc function (so the function can figure out
** what to filled into the desc).
**
** Basically, subsystems can ignore defining new error ID values if they want
** to. The subsystems *do* need to return the predefined errors when
** appropriate, so that mod_dav can figure out what to do. Subsystems can
** simply leave the error ID field unfilled (zero) if there isn't an error
** that must be placed there.
*/


/* --------------------------------------------------------------------
**
** HOOK STRUCTURES
**
** These are here for forward-declaration purposes. For more info, see
** the section title "HOOK HANDLING" for more information, plus each
** structure definition.
*/

/* forward-declare this structure */
typedef struct dav_hooks_propdb dav_hooks_propdb;
typedef struct dav_hooks_locks dav_hooks_locks;
typedef struct dav_hooks_vsn dav_hooks_vsn;
typedef struct dav_hooks_repository dav_hooks_repository;
typedef struct dav_hooks_liveprop dav_hooks_liveprop;
typedef struct dav_hooks_binding dav_hooks_binding;
typedef struct dav_hooks_search dav_hooks_search;

/* ### deprecated name */
typedef dav_hooks_propdb dav_hooks_db;


/* --------------------------------------------------------------------
**
** RESOURCE HANDLING
*/

/*
** Resource Types:
** The base protocol defines only file and collection resources.
** The versioning protocol defines several additional resource types
** to represent artifacts of a version control system.
**
** This enumeration identifies the type of URL used to identify the
** resource. Since the same resource may have more than one type of
** URL which can identify it, dav_resource_type cannot be used
** alone to determine the type of the resource; attributes of the
** dav_resource object must also be consulted.
*/
typedef enum {
    DAV_RESOURCE_TYPE_UNKNOWN,

    DAV_RESOURCE_TYPE_REGULAR,          /* file or collection; could be
                                         * unversioned, or version selector,
                                         * or baseline selector */

    DAV_RESOURCE_TYPE_VERSION,          /* version or baseline URL */

    DAV_RESOURCE_TYPE_HISTORY,          /* version or baseline history URL */

    DAV_RESOURCE_TYPE_WORKING,          /* working resource URL */

    DAV_RESOURCE_TYPE_WORKSPACE,        /* workspace URL */

    DAV_RESOURCE_TYPE_ACTIVITY,         /* activity URL */

    DAV_RESOURCE_TYPE_PRIVATE           /* repository-private type */

} dav_resource_type;

/*
** Opaque, repository-specific information for a resource.
*/
typedef struct dav_resource_private dav_resource_private;

/*
** Resource descriptor, generated by a repository provider.
**
** Note: the lock-null state is not explicitly represented here,
** since it may be expensive to compute. Use dav_get_resource_state()
** to determine whether a non-existent resource is a lock-null resource.
**
** A quick explanation of how the flags can apply to different resources:
**
** unversioned file or collection:
**     type       = DAV_RESOURCE_TYPE_REGULAR
**     exists     = ? (1 if exists)
**     collection = ? (1 if collection)
**     versioned  = 0
**     baselined  = 0
**     working    = 0
**
** version-controlled resource or configuration:
**     type       = DAV_RESOURCE_TYPE_REGULAR
**     exists     = 1
**     collection = ? (1 if collection)
**     versioned  = 1
**     baselined  = ? (1 if configuration)
**     working    = ? (1 if checked out)
**
** version/baseline history:
**     type       = DAV_RESOURCE_TYPE_HISTORY
**     exists     = 1
**     collection = 0
**     versioned  = 0
**     baselined  = 0
**     working    = 0
**
** version/baseline:
**     type       = DAV_RESOURCE_TYPE_VERSION
**     exists     = 1
**     collection = ? (1 if collection)
**     versioned  = 1
**     baselined  = ? (1 if baseline)
**     working    = 0
**
** working resource:
**     type       = DAV_RESOURCE_TYPE_WORKING
**     exists     = 1
**     collection = ? (1 if collection)
**     versioned  = 1
**     baselined  = 0
**     working    = 1
**
** workspace:
**     type       = DAV_RESOURCE_TYPE_WORKSPACE
**     exists     = ? (1 if exists)
**     collection = 1
**     versioned  = ? (1 if version-controlled)
**     baselined  = ? (1 if baseline-controlled)
**     working    = ? (1 if checked out)
**
** activity:
**     type       = DAV_RESOURCE_TYPE_ACTIVITY
**     exists     = ? (1 if exists)
**     collection = 0
**     versioned  = 0
**     baselined  = 0
**     working    = 0
*/
typedef struct dav_resource {
    dav_resource_type type;

    int exists;         /* 0 => null resource */

    int collection;     /* 0 => file; can be 1 for
                         * REGULAR, VERSION, and WORKING resources,
                         * and is always 1 for WORKSPACE */

    int versioned;      /* 0 => unversioned; can be 1 for
                         * REGULAR and WORKSPACE resources,
                         * and is always 1 for VERSION and WORKING */

    int baselined;      /* 0 => not baselined; can be 1 for
                         * REGULAR, VERSION, and WORKSPACE resources;
                         * versioned == 1 when baselined == 1 */

    int working;        /* 0 => not checked out; can be 1 for
                         * REGULAR and WORKSPACE resources,
                         * and is always 1 for WORKING */

    const char *uri;    /* the URI for this resource;
                         * currently has an ABI flaw where sometimes it is
                         * assumed to be encoded and sometimes not */

    dav_resource_private *info;         /* the provider's private info */

    const dav_hooks_repository *hooks;  /* hooks used for this resource */

    /* When allocating items related specifically to this resource, the
       following pool should be used. Its lifetime will be at least as
       long as the dav_resource structure. */
    apr_pool_t *pool;

} dav_resource;

/*
** Lock token type. Lock providers define the details of a lock token.
** However, all providers are expected to at least be able to parse
** the "opaquelocktoken" scheme, which is represented by a uuid_t.
*/
typedef struct dav_locktoken dav_locktoken;

DAV_DECLARE(dav_error *) dav_get_resource(request_rec *r, int label_allowed,
                                          int use_checked_in, dav_resource **res_p);


/* --------------------------------------------------------------------
**
** BUFFER HANDLING
**
** These buffers are used as a lightweight buffer reuse mechanism. Apache
** provides sub-pool creation and destruction to much the same effect, but
** the sub-pools are a bit more general and heavyweight than these buffers.
*/

/* buffer for reuse; can grow to accommodate needed size */
typedef struct
{
    apr_size_t alloc_len;       /* how much has been allocated */
    apr_size_t cur_len;         /* how much is currently being used */
    char *buf;                  /* buffer contents */
} dav_buffer;
#define DAV_BUFFER_MINSIZE      256    /* minimum size for buffer */
#define DAV_BUFFER_PAD          64     /* amount of pad when growing */

/* set the cur_len to the given size and ensure space is available */
DAV_DECLARE(void) dav_set_bufsize(apr_pool_t *p, dav_buffer *pbuf,
                                  apr_size_t size);

/* initialize a buffer and copy the specified (null-term'd) string into it */
DAV_DECLARE(void) dav_buffer_init(apr_pool_t *p, dav_buffer *pbuf,
                                  const char *str);

/* check that the buffer can accommodate <extra_needed> more bytes */
DAV_DECLARE(void) dav_check_bufsize(apr_pool_t *p, dav_buffer *pbuf,
                                    apr_size_t extra_needed);

/* append a string to the end of the buffer, adjust length */
DAV_DECLARE(void) dav_buffer_append(apr_pool_t *p, dav_buffer *pbuf,
                                    const char *str);

/* place a string on the end of the buffer, do NOT adjust length */
DAV_DECLARE(void) dav_buffer_place(apr_pool_t *p, dav_buffer *pbuf,
                                   const char *str);

/* place some memory on the end of a buffer; do NOT adjust length */
DAV_DECLARE(void) dav_buffer_place_mem(apr_pool_t *p, dav_buffer *pbuf,
                                       const void *mem, apr_size_t amt,
                                       apr_size_t pad);


/* --------------------------------------------------------------------
**
** HANDY UTILITIES
*/

/* contains results from one of the getprop functions */
typedef struct
{
    apr_text * propstats;       /* <propstat> element text */
    apr_text * xmlns;           /* namespace decls for <response> elem */
} dav_get_props_result;

/* holds the contents of a <response> element */
struct dav_response
{
    const char *href;           /* always */
    const char *desc;           /* optional description at <response> level */

    /* use status if propresult.propstats is NULL. */
    dav_get_props_result propresult;

    int status;

    struct dav_response *next;
};

typedef struct
{
    request_rec *rnew;          /* new subrequest */
    dav_error err;              /* potential error response */
} dav_lookup_result;


DAV_DECLARE(dav_lookup_result) dav_lookup_uri(const char *uri, request_rec *r,
                                              int must_be_absolute);

/* defines type of property info a provider is to return */
typedef enum {
    DAV_PROP_INSERT_NOTDEF,     /* property is defined by this provider,
                                   but nothing was inserted because the
                                   (live) property is not defined for this
                                   resource (it may be present as a dead
                                   property). */
    DAV_PROP_INSERT_NOTSUPP,    /* property is recognized by this provider,
                                   but it is not supported, and cannot be
                                   treated as a dead property */
    DAV_PROP_INSERT_NAME,       /* a property name (empty elem) was
                                   inserted into the text block */
    DAV_PROP_INSERT_VALUE,      /* a property name/value pair was inserted
                                   into the text block */
    DAV_PROP_INSERT_SUPPORTED   /* a supported live property was added to
                                   the text block as a
                                   <DAV:supported-live-property> element */
} dav_prop_insert;

/* ### this stuff is private to dav/fs/repos.c; move it... */
/* format a time string (buf must be at least DAV_TIMEBUF_SIZE chars) */
#define DAV_STYLE_ISO8601       1
#define DAV_STYLE_RFC822        2
#define DAV_TIMEBUF_SIZE        30

/* Write a complete RESPONSE object out as a <DAV:response> xml
 * element.  Data is sent into brigade BB, which is auto-flushed into
 * the output filter stack for request R.  Use POOL for any temporary
 * allocations.
 *
 * [Presumably the <multistatus> tag has already been written;  this
 * routine is shared by dav_send_multistatus and dav_stream_response.]
 */
DAV_DECLARE(void) dav_send_one_response(dav_response *response,
                                        apr_bucket_brigade *bb,
                                        request_rec *r,
                                        apr_pool_t *pool);

/* Factorized helper function: prep request_rec R for a multistatus
 * response and write <multistatus> tag into BB, destined for
 * R->output_filters.  Use xml NAMESPACES in initial tag, if
 * non-NULL.
 */
DAV_DECLARE(void) dav_begin_multistatus(apr_bucket_brigade *bb,
                                        request_rec *r, int status,
                                        apr_array_header_t *namespaces);

/* Finish a multistatus response started by dav_begin_multistatus: */
DAV_DECLARE(apr_status_t) dav_finish_multistatus(request_rec *r,
                                                 apr_bucket_brigade *bb);

/* Send a multistatus response */
DAV_DECLARE(void) dav_send_multistatus(request_rec *r, int status,
                                       dav_response *first,
                                       apr_array_header_t *namespaces);

DAV_DECLARE(apr_text *) dav_failed_proppatch(apr_pool_t *p,
                                             apr_array_header_t *prop_ctx);
DAV_DECLARE(apr_text *) dav_success_proppatch(apr_pool_t *p,
                                              apr_array_header_t *prop_ctx);

DAV_DECLARE(int) dav_get_depth(request_rec *r, int def_depth);

DAV_DECLARE(int) dav_validate_root(const apr_xml_doc *doc,
                                   const char *tagname);
DAV_DECLARE(int) dav_validate_root_ns(const apr_xml_doc *doc,
                                      int ns, const char *tagname);
DAV_DECLARE(apr_xml_elem *) dav_find_child(const apr_xml_elem *elem,
                                           const char *tagname);
DAV_DECLARE(apr_xml_elem *) dav_find_child_ns(const apr_xml_elem *elem,
                                              int ns, const char *tagname);
DAV_DECLARE(apr_xml_elem *) dav_find_next_ns(const apr_xml_elem *elem,
                                             int ns, const char *tagname);

/* find and return the attribute with a name in the given namespace */
DAV_DECLARE(apr_xml_attr *) dav_find_attr_ns(const apr_xml_elem *elem,
                                             int ns, const char *attrname);

/* find and return the attribute with a given DAV: tagname */
DAV_DECLARE(apr_xml_attr *) dav_find_attr(const apr_xml_elem *elem,
                                          const char *attrname);

/* gather up all the CDATA into a single string */
DAV_DECLARE(const char *) dav_xml_get_cdata(const apr_xml_elem *elem, apr_pool_t *pool,
                              int strip_white);

/*
** XML namespace handling
**
** This structure tracks namespace declarations (xmlns:prefix="URI").
** It maintains a one-to-many relationship of URIs-to-prefixes. In other
** words, one URI may be defined by many prefixes, but any specific
** prefix will specify only one URI.
**
** Prefixes using the "g###" pattern can be generated automatically if
** the caller does not have specific prefix requirements.
*/
typedef struct {
    apr_pool_t *pool;
    apr_hash_t *uri_prefix;     /* map URIs to an available prefix */
    apr_hash_t *prefix_uri;     /* map all prefixes to their URIs */
    int count;                  /* counter for "g###" prefixes */
} dav_xmlns_info;

/* create an empty dav_xmlns_info structure */
DAV_DECLARE(dav_xmlns_info *) dav_xmlns_create(apr_pool_t *pool);

/* add a specific prefix/URI pair. the prefix/uri should have a lifetime
   at least that of xmlns->pool */
DAV_DECLARE(void) dav_xmlns_add(dav_xmlns_info *xi,
                                const char *prefix, const char *uri);

/* add a URI (if not present); any prefix is acceptable and is returned.
   the uri should have a lifetime at least that xmlns->pool */
DAV_DECLARE(const char *) dav_xmlns_add_uri(dav_xmlns_info *xi,
                                            const char *uri);

/* return the URI for a specified prefix (or NULL if the prefix is unknown) */
DAV_DECLARE(const char *) dav_xmlns_get_uri(dav_xmlns_info *xi,
                                            const char *prefix);

/* return an available prefix for a specified URI (or NULL if the URI
   is unknown) */
DAV_DECLARE(const char *) dav_xmlns_get_prefix(dav_xmlns_info *xi,
                                               const char *uri);

/* generate xmlns declarations (appending into the given text) */
DAV_DECLARE(void) dav_xmlns_generate(dav_xmlns_info *xi,
                                     apr_text_header *phdr);

/* --------------------------------------------------------------------
**
** DAV PLUGINS
*/

/* ### docco ... */

/*
** dav_provider
**
** This structure wraps up all of the hooks that a mod_dav provider can
** supply. The provider MUST supply <repos> and <propdb>. The rest are
** optional and should contain NULL if that feature is not supplied.
**
** Note that a provider cannot pick and choose portions from various
** underlying implementations (which was theoretically possible in
** mod_dav 1.0). There are too many dependencies between a dav_resource
** (defined by <repos>) and the other functionality.
**
** Live properties and report extensions are not part of the dav_provider
** structure because they are handled through the APR_HOOK interface (to
** allow for multiple providers). The core always provides some
** properties, and then a given provider will add more properties.
**
** Some providers may need to associate a context with the dav_provider
** structure -- the ctx field is available for storing this context. Just
** leave it NULL if it isn't required.
*/
typedef struct {
    const dav_hooks_repository *repos;
    const dav_hooks_propdb *propdb;
    const dav_hooks_locks *locks;
    const dav_hooks_vsn *vsn;
    const dav_hooks_binding *binding;
    const dav_hooks_search *search;

    void *ctx;
} dav_provider;

/*
** gather_propsets: gather all live property propset-URIs
**
** The hook implementor should push one or more URIs into the specified
** array. These URIs are returned in the DAV: header to let clients know
** what sets of live properties are supported by the installation. mod_dav
** will place open/close angle brackets around each value (much like
** a Coded-URL); quotes and brackets should not be in the value.
**
** Example:    http://apache.org/dav/props/
**
** (of course, use your own domain to ensure a unique value)
*/
APR_DECLARE_EXTERNAL_HOOK(dav, DAV, void, gather_propsets,
                         (apr_array_header_t *uris))

/*
** find_liveprop: find a live property, returning a non-zero, unique,
**                opaque identifier.
**
** If the hook implementor determines the specified URI/name refers to
** one of its properties, then it should fill in HOOKS and return a
** non-zero value. The returned value is the "property ID" and will
** be passed to the various liveprop hook functions.
**
** Return 0 if the property is not defined by the hook implementor.
*/
APR_DECLARE_EXTERNAL_HOOK(dav, DAV, int, find_liveprop,
                         (const dav_resource *resource,
                          const char *ns_uri, const char *name,
                          const dav_hooks_liveprop **hooks))

/*
** insert_all_liveprops: insert all (known) live property names/values.
**
** The hook implementor should append XML text to PHDR, containing liveprop
** names. If INSVALUE is true, then the property values should also be
** inserted into the output XML stream.
**
** The liveprop provider should insert *all* known and *defined* live
** properties on the specified resource. If a particular liveprop is
** not defined for this resource, then it should not be inserted.
*/
APR_DECLARE_EXTERNAL_HOOK(dav, DAV, void, insert_all_liveprops,
                         (request_rec *r, const dav_resource *resource,
                          dav_prop_insert what, apr_text_header *phdr))

/*
** deliver_report: given a parsed report request, process the request
**                 an deliver the resulting report.
**
** The hook implementer should decide whether it should handle the given
** report, and if so, write the response to the output filter. If the
** report is not relevant, return DECLINED.
*/
APR_DECLARE_EXTERNAL_HOOK(dav, DAV, int, deliver_report,
                         (request_rec *r,
                          const dav_resource *resource,
                          const apr_xml_doc *doc,
                          ap_filter_t *output, dav_error **err))

/*
** gather_reports: get all reports.
**
** The hook implementor should push one or more dav_report_elem structures
** containing report names into the specified array. These names are returned
** in the DAV:supported-reports-set property to let clients know
** what reports are supported by the installation.
**
*/
APR_DECLARE_EXTERNAL_HOOK(dav, DAV, void, gather_reports,
                          (request_rec *r, const dav_resource *resource,
                           apr_array_header_t *reports, dav_error **err))

/*
 ** method_precondition: check method preconditions.
 **
 ** If a WebDAV extension needs to set any preconditions on a method, this
 ** hook is where to do it. If the precondition fails, return an error
 ** response with the tagname set to the value of the failed precondition.
 **
 ** If the method requires an XML body, this will be read and provided as
 ** the doc value. If not, doc is NULL. An extension that needs to verify
 ** the non-XML body of a request should register an input filter to do so
 ** within this hook.
 **
 ** Methods like PUT will supply a single src resource, and the dst will
 ** be NULL.
 **
 ** Methods like COPY or MOVE will trigger this hook twice. The first
 ** invocation will supply just the source resource. The second invocation
 ** will supply a source and destination. This allows preconditions on the
 ** source resource to be verified before making an attempt to get the
 ** destination resource.
 **
 ** Methods like PROPFIND and LABEL will trigger this hook initially for
 ** the src resource, and then subsequently for each resource that has
 ** been walked during processing, with the walked resource passed in dst,
 ** and NULL passed in src.
 **
 ** As a rule, the src resource originates from a request that has passed
 ** through httpd's authn/authz hooks, while the dst resource has not.
 */
APR_DECLARE_EXTERNAL_HOOK(dav, DAV, int, method_precondition,
                          (request_rec *r,
                           dav_resource *src, const dav_resource *dst,
                           const apr_xml_doc *doc, dav_error **err))


DAV_DECLARE(const dav_hooks_locks *) dav_get_lock_hooks(request_rec *r);
DAV_DECLARE(const dav_hooks_propdb *) dav_get_propdb_hooks(request_rec *r);
DAV_DECLARE(const dav_hooks_vsn *) dav_get_vsn_hooks(request_rec *r);
DAV_DECLARE(const dav_hooks_binding *) dav_get_binding_hooks(request_rec *r);
DAV_DECLARE(const dav_hooks_search *) dav_get_search_hooks(request_rec *r);

DAV_DECLARE(void) dav_register_provider(apr_pool_t *p, const char *name,
                                        const dav_provider *hooks);
DAV_DECLARE(const dav_provider *) dav_lookup_provider(const char *name);
DAV_DECLARE(const char *) dav_get_provider_name(request_rec *r);
DAV_DECLARE(const dav_provider *) dav_get_provider(request_rec *r);


/* ### deprecated */
#define DAV_GET_HOOKS_PROPDB(r)         dav_get_propdb_hooks(r)
#define DAV_GET_HOOKS_LOCKS(r)          dav_get_lock_hooks(r)
#define DAV_GET_HOOKS_VSN(r)            dav_get_vsn_hooks(r)
#define DAV_GET_HOOKS_BINDING(r)        dav_get_binding_hooks(r)
#define DAV_GET_HOOKS_SEARCH(r)         dav_get_search_hooks(r)


/* --------------------------------------------------------------------
**
** IF HEADER PROCESSING
**
** Here is the definition of the If: header from RFC 2518, S9.4:
**
**    If = "If" ":" (1*No-tag-list | 1*Tagged-list)
**    No-tag-list = List
**    Tagged-list = Resource 1*List
**    Resource = Coded-URL
**    List = "(" 1*(["Not"](State-token | "[" entity-tag "]")) ")"
**    State-token = Coded-URL
**    Coded-URL = "<" absoluteURI ">"        ; absoluteURI from RFC 2616
**
** List corresponds to dav_if_state_list. No-tag-list corresponds to
** dav_if_header with uri==NULL. Tagged-list corresponds to a sequence of
** dav_if_header structures with (duplicate) uri==Resource -- one
** dav_if_header per state_list. A second Tagged-list will start a new
** sequence of dav_if_header structures with the new URI.
**
** A summary of the semantics, mapped into our structures:
**    - Chained dav_if_headers: OR
**    - Chained dav_if_state_lists: AND
**    - NULL uri matches all resources
*/

typedef enum
{
    dav_if_etag,
    dav_if_opaquelock,
    dav_if_unknown /* the "unknown" state type; always matches false. */
} dav_if_state_type;

typedef struct dav_if_state_list
{
    dav_if_state_type type;

    int condition;
#define DAV_IF_COND_NORMAL      0
#define DAV_IF_COND_NOT         1    /* "Not" was applied */

    const char *etag;
    dav_locktoken *locktoken;

    struct dav_if_state_list *next;
} dav_if_state_list;

typedef struct dav_if_header
{
    const char *uri;
    apr_size_t uri_len;
    struct dav_if_state_list *state;
    struct dav_if_header *next;

    int dummy_header;   /* used internally by the lock/etag validation */
} dav_if_header;

typedef struct dav_locktoken_list
{
    dav_locktoken *locktoken;
    struct dav_locktoken_list *next;
} dav_locktoken_list;

DAV_DECLARE(dav_error *) dav_get_locktoken_list(request_rec *r,
                                                dav_locktoken_list **ltl);


/* --------------------------------------------------------------------
**
** LIVE PROPERTY HANDLING
*/

/* opaque type for PROPPATCH rollback information */
typedef struct dav_liveprop_rollback dav_liveprop_rollback;

struct dav_hooks_liveprop
{
    /*
    ** Insert property information into a text block. The property to
    ** insert is identified by the propid value. The information to insert
    ** is identified by the "what" argument, as follows:
    **   DAV_PROP_INSERT_NAME
    **      property name, as an empty XML element
    **   DAV_PROP_INSERT_VALUE
    **      property name/value, as an XML element
    **   DAV_PROP_INSERT_SUPPORTED
    **      if the property is defined on the resource, then
    **      a DAV:supported-live-property element, as defined
    **      by the DeltaV extensions to RFC2518.
    **
    ** Providers should return DAV_PROP_INSERT_NOTDEF if the property is
    ** known and not defined for this resource, so should be handled as a
    ** dead property. If a provider recognizes, but does not support, a
    ** property, and does not want it handled as a dead property, it should
    ** return DAV_PROP_INSERT_NOTSUPP.
    **
    ** Some DAV extensions, like CalDAV, specify both document elements
    ** and property elements that need to be taken into account when
    ** generating a property. The document element and property element
    ** are made available in the dav_liveprop_elem structure under the
    ** resource, accessible as follows:
    **
    ** dav_get_liveprop_element(resource);
    **
    ** Returns one of DAV_PROP_INSERT_* based on what happened.
    **
    ** ### we may need more context... ie. the lock database
    */
    dav_prop_insert (*insert_prop)(const dav_resource *resource,
                                   int propid, dav_prop_insert what,
                                   apr_text_header *phdr);

    /*
    ** Determine whether a given property is writable.
    **
    ** ### we may want a different semantic. i.e. maybe it should be
    ** ### "can we write <value> into this property?"
    **
    ** Returns 1 if the live property can be written, 0 if read-only.
    */
    int (*is_writable)(const dav_resource *resource, int propid);

    /*
    ** This member defines the set of namespace URIs that the provider
    ** uses for its properties. When insert_all is called, it will be
    ** passed a list of integers that map from indices into this list
    ** to namespace IDs for output generation.
    **
    ** The last entry in this list should be a NULL value (sentinel).
    */
    const char * const * namespace_uris;

    /*
    ** ### this is not the final design. we want an open-ended way for
    ** ### liveprop providers to attach *new* properties. To this end,
    ** ### we'll have a "give me a list of the props you define", a way
    ** ### to check for a prop's existence, a way to validate a set/remove
    ** ### of a prop, and a way to execute/commit/rollback that change.
    */

    /*
    ** Validate that the live property can be assigned a value, and that
    ** the provided value is valid.
    **
    ** elem will point to the XML element that names the property. For
    ** example:
    **     <lp1:executable>T</lp1:executable>
    **
    ** The provider can access the cdata fields and the child elements
    ** to extract the relevant pieces.
    **
    ** operation is one of DAV_PROP_OP_SET or _DELETE.
    **
    ** The provider may return a value in *context which will be passed
    ** to each of the exec/commit/rollback functions. For example, this
    ** may contain an internal value which has been processed from the
    ** input element.
    **
    ** The provider must set defer_to_dead to true (non-zero) or false.
    ** If true, then the set/remove is deferred to the dead property
    ** database. Note: it will be set to zero on entry.
    */
    dav_error * (*patch_validate)(const dav_resource *resource,
                                  const apr_xml_elem *elem,
                                  int operation,
                                  void **context,
                                  int *defer_to_dead);

    /* ### doc... */
    dav_error * (*patch_exec)(const dav_resource *resource,
                              const apr_xml_elem *elem,
                              int operation,
                              void *context,
                              dav_liveprop_rollback **rollback_ctx);

    /* ### doc... */
    void (*patch_commit)(const dav_resource *resource,
                         int operation,
                         void *context,
                         dav_liveprop_rollback *rollback_ctx);

    /* ### doc... */
    dav_error * (*patch_rollback)(const dav_resource *resource,
                                  int operation,
                                  void *context,
                                  dav_liveprop_rollback *rollback_ctx);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;
};

/*
** dav_liveprop_spec: specify a live property
**
** This structure is used as a standard way to determine if a particular
** property is a live property. Its use is not part of the mandated liveprop
** interface, but can be used by liveprop providers in conjunction with the
** utility routines below.
**
** spec->name == NULL is the defined end-sentinel for a list of specs.
*/
typedef struct {
    int ns;             /* provider-local namespace index */
    const char *name;   /* name of the property */

    int propid;         /* provider-local property ID */

    int is_writable;    /* is the property writable? */

} dav_liveprop_spec;

/*
** dav_liveprop_group: specify a group of liveprops
**
** This structure specifies a group of live properties, their namespaces,
** and how to handle them.
*/
typedef struct {
    const dav_liveprop_spec *specs;
    const char * const *namespace_uris;
    const dav_hooks_liveprop *hooks;

} dav_liveprop_group;

/* ### docco */
DAV_DECLARE(int) dav_do_find_liveprop(const char *ns_uri, const char *name,
                                      const dav_liveprop_group *group,
                                      const dav_hooks_liveprop **hooks);

/* ### docco */
DAV_DECLARE(long) dav_get_liveprop_info(int propid,
                                        const dav_liveprop_group *group,
                                        const dav_liveprop_spec **info);

/* ### docco */
DAV_DECLARE(void) dav_register_liveprop_group(apr_pool_t *pool,
                                              const dav_liveprop_group *group);

/* ### docco */
DAV_DECLARE(long) dav_get_liveprop_ns_index(const char *uri);

/* ### docco */
DAV_DECLARE(long) dav_get_liveprop_ns_count(void);

/* ### docco */
DAV_DECLARE(void) dav_add_all_liveprop_xmlns(apr_pool_t *p,
                                             apr_text_header *phdr);

typedef struct {
    const apr_xml_doc *doc;
    const apr_xml_elem *elem;
} dav_liveprop_elem;

/*
 ** When calling insert_prop(), the associated request element and
 ** document is accessible using the following call.
 */
DAV_DECLARE(dav_liveprop_elem *) dav_get_liveprop_element(const dav_resource
                                                          *resource);

/*
** The following three functions are part of mod_dav's internal handling
** for the core WebDAV properties. They are not part of mod_dav's API.
*/
DAV_DECLARE_NONSTD(int) dav_core_find_liveprop(
    const dav_resource *resource,
    const char *ns_uri,
    const char *name,
    const dav_hooks_liveprop **hooks);
DAV_DECLARE_NONSTD(void) dav_core_insert_all_liveprops(
    request_rec *r,
    const dav_resource *resource,
    dav_prop_insert what,
    apr_text_header *phdr);
DAV_DECLARE_NONSTD(void) dav_core_register_uris(apr_pool_t *p);


/*
** Standard WebDAV Property Identifiers
**
** A live property provider does not need to use these; they are simply
** provided for convenience.
**
** Property identifiers need to be unique within a given provider, but not
** *across* providers (note: this uniqueness constraint was different in
** older versions of mod_dav).
**
** The identifiers start at 20000 to make it easier for providers to avoid
** conflicts with the standard properties. The properties are arranged
** alphabetically, and may be reordered from time to time (as properties
** are introduced).
**
** NOTE: there is no problem with reordering (e.g. binary compat) since the
** identifiers are only used within a given provider, which would pick up
** the entire set of changes upon a recompile.
*/
enum {
    DAV_PROPID_BEGIN = 20000,

    /* Standard WebDAV properties (RFC 2518) */
    DAV_PROPID_creationdate,
    DAV_PROPID_displayname,
    DAV_PROPID_getcontentlanguage,
    DAV_PROPID_getcontentlength,
    DAV_PROPID_getcontenttype,
    DAV_PROPID_getetag,
    DAV_PROPID_getlastmodified,
    DAV_PROPID_lockdiscovery,
    DAV_PROPID_resourcetype,
    DAV_PROPID_source,
    DAV_PROPID_supportedlock,

    /* DeltaV properties (from the I-D (#14)) */
    DAV_PROPID_activity_checkout_set,
    DAV_PROPID_activity_set,
    DAV_PROPID_activity_version_set,
    DAV_PROPID_auto_merge_set,
    DAV_PROPID_auto_version,
    DAV_PROPID_baseline_collection,
    DAV_PROPID_baseline_controlled_collection,
    DAV_PROPID_baseline_controlled_collection_set,
    DAV_PROPID_checked_in,
    DAV_PROPID_checked_out,
    DAV_PROPID_checkin_fork,
    DAV_PROPID_checkout_fork,
    DAV_PROPID_checkout_set,
    DAV_PROPID_comment,
    DAV_PROPID_creator_displayname,
    DAV_PROPID_current_activity_set,
    DAV_PROPID_current_workspace_set,
    DAV_PROPID_default_variant,
    DAV_PROPID_eclipsed_set,
    DAV_PROPID_label_name_set,
    DAV_PROPID_merge_set,
    DAV_PROPID_precursor_set,
    DAV_PROPID_predecessor_set,
    DAV_PROPID_root_version,
    DAV_PROPID_subactivity_set,
    DAV_PROPID_subbaseline_set,
    DAV_PROPID_successor_set,
    DAV_PROPID_supported_method_set,
    DAV_PROPID_supported_live_property_set,
    DAV_PROPID_supported_report_set,
    DAV_PROPID_unreserved,
    DAV_PROPID_variant_set,
    DAV_PROPID_version_controlled_binding_set,
    DAV_PROPID_version_controlled_configuration,
    DAV_PROPID_version_history,
    DAV_PROPID_version_name,
    DAV_PROPID_workspace,
    DAV_PROPID_workspace_checkout_set,

    DAV_PROPID_END
};

/*
** Property Identifier Registration
**
** At the moment, mod_dav requires live property providers to ensure that
** each property returned has a unique value. For now, this is done through
** central registration (there are no known providers other than the default,
** so this remains manageable).
**
** WARNING: the TEST ranges should never be "shipped".
*/
#define DAV_PROPID_CORE         10000   /* ..10099. defined by mod_dav */
#define DAV_PROPID_FS           10100   /* ..10299.
                                           mod_dav filesystem provider. */
#define DAV_PROPID_TEST1        10300   /* ..10399 */
#define DAV_PROPID_TEST2        10400   /* ..10499 */
#define DAV_PROPID_TEST3        10500   /* ..10599 */
/* Next: 10600 */


/* --------------------------------------------------------------------
**
** DATABASE FUNCTIONS
*/

typedef struct dav_db dav_db;
typedef struct dav_namespace_map dav_namespace_map;
typedef struct dav_deadprop_rollback dav_deadprop_rollback;

typedef struct {
    const char *ns;     /* "" signals "no namespace" */
    const char *name;
} dav_prop_name;

/* hook functions to enable pluggable databases */
struct dav_hooks_propdb
{
    dav_error * (*open)(apr_pool_t *p, const dav_resource *resource, int ro,
                        dav_db **pdb);
    void (*close)(dav_db *db);

    /*
    ** In bulk, define any namespaces that the values and their name
    ** elements may need.
    **
    ** Note: sometimes mod_dav will defer calling this until output_value
    ** returns found==1. If the output process needs the dav_xmlns_info
    ** filled for its work, then it will need to fill it on demand rather
    ** than depending upon this hook to fill in the structure.
    **
    ** Note: this will *always* be called during an output sequence. Thus,
    ** the provider may rely solely on using this to fill the xmlns info.
    */
    dav_error * (*define_namespaces)(dav_db *db, dav_xmlns_info *xi);

    /*
    ** Output the value from the database (i.e. add an element name and
    ** the value into *phdr). Set *found based on whether the name/value
    ** was found in the propdb.
    **
    ** Note: it is NOT an error for the key/value pair to not exist.
    **
    ** The dav_xmlns_info passed to define_namespaces() is also passed to
    ** each output_value() call so that namespaces can be added on-demand.
    ** It can also be used to look up prefixes or URIs during the output
    ** process.
    */
    dav_error * (*output_value)(dav_db *db, const dav_prop_name *name,
                                dav_xmlns_info *xi,
                                apr_text_header *phdr, int *found);

    /*
    ** Build a mapping from "global" namespaces (stored in apr_xml_*)
    ** into provider-local namespace identifiers.
    **
    ** This mapping should be done once per set of namespaces, and the
    ** resulting mapping should be passed into the store() hook function.
    **
    ** Note: usually, there is just a single document/namespaces for all
    ** elements passed. However, the generality of creating multiple
    ** mappings and passing them to store() is provided here.
    **
    ** Note: this is only in preparation for a series of store() calls.
    ** As a result, the propdb must be open for read/write access when
    ** this function is called.
    */
    dav_error * (*map_namespaces)(dav_db *db,
                                  const apr_array_header_t *namespaces,
                                  dav_namespace_map **mapping);

    /*
    ** Store a property value for a given name. The value->combined field
    ** MUST be set for this call.
    **
    ** ### WARNING: current providers will quote the text within ELEM.
    ** ### this implies you can call this function only once with a given
    ** ### element structure (a second time will quote it again).
    */
    dav_error * (*store)(dav_db *db, const dav_prop_name *name,
                         const apr_xml_elem *elem,
                         dav_namespace_map *mapping);

    /* remove a given property */
    dav_error * (*remove)(dav_db *db, const dav_prop_name *name);

    /* returns 1 if the record specified by "key" exists; 0 otherwise */
    int (*exists)(dav_db *db, const dav_prop_name *name);

    /*
    ** Iterate over the property names in the database.
    **
    ** iter->name.ns == iter->name.name == NULL when there are no more names.
    **
    ** Note: only one iteration may occur over the propdb at a time.
    */
    dav_error * (*first_name)(dav_db *db, dav_prop_name *pname);
    dav_error * (*next_name)(dav_db *db, dav_prop_name *pname);

    /*
    ** Rollback support: get rollback context, and apply it.
    **
    ** struct dav_deadprop_rollback is a provider-private structure; it
    ** should remember the name, and the name's old value (or the fact that
    ** the value was not present, and should be deleted if a rollback occurs).
    */
    dav_error * (*get_rollback)(dav_db *db, const dav_prop_name *name,
                                dav_deadprop_rollback **prollback);
    dav_error * (*apply_rollback)(dav_db *db,
                                  dav_deadprop_rollback *rollback);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;
};


/* --------------------------------------------------------------------
**
** LOCK FUNCTIONS
*/

/* Used to represent a Timeout header of "Infinity" */
#define DAV_TIMEOUT_INFINITE 0

DAV_DECLARE(time_t) dav_get_timeout(request_rec *r);

/*
** Opaque, provider-specific information for a lock database.
*/
typedef struct dav_lockdb_private dav_lockdb_private;

/*
** Opaque, provider-specific information for a lock record.
*/
typedef struct dav_lock_private dav_lock_private;

/*
** Lock database type. Lock providers are urged to implement a "lazy" open, so
** doing an "open" is cheap until something is actually needed from the DB.
*/
typedef struct
{
    const dav_hooks_locks *hooks;   /* the hooks used for this lockdb */
    int ro;                         /* was it opened readonly? */

    dav_lockdb_private *info;

} dav_lockdb;

typedef enum {
    DAV_LOCKSCOPE_UNKNOWN,
    DAV_LOCKSCOPE_EXCLUSIVE,
    DAV_LOCKSCOPE_SHARED
} dav_lock_scope;

typedef enum {
    DAV_LOCKTYPE_UNKNOWN,
    DAV_LOCKTYPE_WRITE
} dav_lock_type;

typedef enum {
    DAV_LOCKREC_DIRECT,             /* lock asserted on this resource */
    DAV_LOCKREC_INDIRECT,           /* lock inherited from a parent */
    DAV_LOCKREC_INDIRECT_PARTIAL    /* most info is not filled in */
} dav_lock_rectype;

/*
** dav_lock: hold information about a lock on a resource.
**
** This structure is used for both direct and indirect locks. A direct lock
** is a lock applied to a specific resource by the client. An indirect lock
** is one that is inherited from a parent resource by virtue of a non-zero
** Depth: header when the lock was applied.
**
** mod_dav records both types of locks in the lock database, managing their
** addition/removal as resources are moved about the namespace.
**
** Note that the lockdb is free to marshal this structure in any form that
** it likes.
**
** For a "partial" lock, the <rectype> and <locktoken> fields must be filled
** in. All other (user) fields should be zeroed. The lock provider will
** usually fill in the <info> field, and the <next> field may be used to
** construct a list of partial locks.
**
** The lock provider MUST use the info field to store a value such that a
** dav_lock structure can locate itself in the underlying lock database.
** This requirement is needed for refreshing: when an indirect dav_lock is
** refreshed, its reference to the direct lock does not specify the direct's
** resource, so the only way to locate the (refreshed, direct) lock in the
** database is to use the info field.
**
** Note that <is_locknull> only refers to the resource where this lock was
** found.
** ### hrm. that says the abstraction is wrong. is_locknull may disappear.
*/
typedef struct dav_lock
{
    dav_lock_rectype rectype;   /* type of lock record */
    int is_locknull;            /* lock establishes a locknull resource */

    /* ### put the resource in here? */

    dav_lock_scope scope;       /* scope of the lock */
    dav_lock_type type;         /* type of lock */
    int depth;                  /* depth of the lock */
    time_t timeout;             /* when the lock will timeout */

    const dav_locktoken *locktoken;  /* the token that was issued */

    const char *owner;          /* (XML) owner of the lock */
    const char *auth_user;      /* auth'd username owning lock */

    dav_lock_private *info;     /* private to the lockdb */

    struct dav_lock *next;      /* for managing a list of locks */
} dav_lock;

/* Property-related public lock functions */
DAV_DECLARE(const char *)dav_lock_get_activelock(request_rec *r,
                                                 dav_lock *locks,
                                                 dav_buffer *pbuf);

/* LockDB-related public lock functions */
DAV_DECLARE(dav_error *) dav_open_lockdb(request_rec *r,
                                         int ro,
                                         dav_lockdb **lockdb);
DAV_DECLARE(void) dav_close_lockdb(dav_lockdb *lockdb);
DAV_DECLARE(dav_error *) dav_lock_parse_lockinfo(request_rec *r,
                                                 const dav_resource *resrouce,
                                                 dav_lockdb *lockdb,
                                                 const apr_xml_doc *doc,
                                                 dav_lock **lock_request);
DAV_DECLARE(int) dav_unlock(request_rec *r,
                            const dav_resource *resource,
                            const dav_locktoken *locktoken);
DAV_DECLARE(dav_error *) dav_add_lock(request_rec *r,
                                      const dav_resource *resource,
                                      dav_lockdb *lockdb, dav_lock *request,
                                      dav_response **response);
DAV_DECLARE(dav_error *) dav_notify_created(request_rec *r,
                                            dav_lockdb *lockdb,
                                            const dav_resource *resource,
                                            int resource_state,
                                            int depth);

DAV_DECLARE(dav_error*) dav_lock_query(dav_lockdb *lockdb,
                                       const dav_resource *resource,
                                       dav_lock **locks);

DAV_DECLARE(dav_error *) dav_validate_request(request_rec *r,
                                              dav_resource *resource,
                                              int depth,
                                              dav_locktoken *locktoken,
                                              dav_response **response,
                                              int flags,
                                              dav_lockdb *lockdb);
/*
** flags:
**    0x0F -- reserved for <dav_lock_scope> values
**
**    other flags, detailed below
*/
#define DAV_VALIDATE_RESOURCE   0x0010  /* validate just the resource */
#define DAV_VALIDATE_PARENT     0x0020  /* validate resource AND its parent */
#define DAV_VALIDATE_ADD_LD     0x0040  /* add DAV:lockdiscovery into
                                           the 424 DAV:response */
#define DAV_VALIDATE_USE_424    0x0080  /* return 424 status, not 207 */
#define DAV_VALIDATE_IS_PARENT  0x0100  /* for internal use */
#define DAV_VALIDATE_NO_MODIFY  0x0200  /* resource is not being modified
                                           so allow even if lock token
                                           is not provided */

/* Lock-null related public lock functions */
DAV_DECLARE(int) dav_get_resource_state(request_rec *r,
                                        const dav_resource *resource);

/* Lock provider hooks. Locking is optional, so there may be no
 * lock provider for a given repository.
 */
struct dav_hooks_locks
{
    /* Return the supportedlock property for a resource */
    const char * (*get_supportedlock)(
        const dav_resource *resource
    );

    /* Parse a lock token URI, returning a lock token object allocated
     * in the given pool.
     */
    dav_error * (*parse_locktoken)(
        apr_pool_t *p,
        const char *char_token,
        dav_locktoken **locktoken_p
    );

    /* Format a lock token object into a URI string, allocated in
     * the given pool.
     *
     * Always returns non-NULL.
     */
    const char * (*format_locktoken)(
        apr_pool_t *p,
        const dav_locktoken *locktoken
    );

    /* Compare two lock tokens.
     *
     * Result < 0  => lt1 < lt2
     * Result == 0 => lt1 == lt2
     * Result > 0  => lt1 > lt2
     */
    int (*compare_locktoken)(
        const dav_locktoken *lt1,
        const dav_locktoken *lt2
    );

    /* Open the provider's lock database.
     *
     * The provider may or may not use a "real" database for locks
     * (a lock could be an attribute on a resource, for example).
     *
     * The provider may choose to use the value of the DAVLockDB directive
     * (as returned by dav_get_lockdb_path()) to decide where to place
     * any storage it may need.
     *
     * The request storage pool should be associated with the lockdb,
     * so it can be used in subsequent operations.
     *
     * If ro != 0, only readonly operations will be performed.
     * If force == 0, the open can be "lazy"; no subsequent locking operations
     * may occur.
     * If force != 0, locking operations will definitely occur.
     */
    dav_error * (*open_lockdb)(
        request_rec *r,
        int ro,
        int force,
        dav_lockdb **lockdb
    );

    /* Indicates completion of locking operations */
    void (*close_lockdb)(
        dav_lockdb *lockdb
    );

    /* Take a resource out of the lock-null state. */
    dav_error * (*remove_locknull_state)(
        dav_lockdb *lockdb,
        const dav_resource *resource
    );

    /*
    ** Create a (direct) lock structure for the given resource. A locktoken
    ** will be created.
    **
    ** The lock provider may store private information into lock->info.
    */
    dav_error * (*create_lock)(dav_lockdb *lockdb,
                               const dav_resource *resource,
                               dav_lock **lock);

    /*
    ** Get the locks associated with the specified resource.
    **
    ** If resolve_locks is true (non-zero), then any indirect locks are
    ** resolved to their actual, direct lock (i.e. the reference to followed
    ** to the original lock).
    **
    ** The locks, if any, are returned as a linked list in no particular
    ** order. If no locks are present, then *locks will be NULL.
    */
    dav_error * (*get_locks)(dav_lockdb *lockdb,
                             const dav_resource *resource,
                             int calltype,
                             dav_lock **locks);

#define DAV_GETLOCKS_RESOLVED   0    /* resolve indirects to directs */
#define DAV_GETLOCKS_PARTIAL    1    /* leave indirects partially filled */
#define DAV_GETLOCKS_COMPLETE   2    /* fill out indirect locks */

    /*
    ** Find a particular lock on a resource (specified by its locktoken).
    **
    ** *lock will be set to NULL if the lock is not found.
    **
    ** Note that the provider can optimize the unmarshalling -- only one
    ** lock (or none) must be constructed and returned.
    **
    ** If partial_ok is true (non-zero), then an indirect lock can be
    ** partially filled in. Otherwise, another lookup is done and the
    ** lock structure will be filled out as a DAV_LOCKREC_INDIRECT.
    */
    dav_error * (*find_lock)(dav_lockdb *lockdb,
                             const dav_resource *resource,
                             const dav_locktoken *locktoken,
                             int partial_ok,
                             dav_lock **lock);

    /*
    ** Quick test to see if the resource has *any* locks on it.
    **
    ** This is typically used to determine if a non-existent resource
    ** has a lock and is (therefore) a locknull resource.
    **
    ** WARNING: this function may return TRUE even when timed-out locks
    **          exist (i.e. it may not perform timeout checks).
    */
    dav_error * (*has_locks)(dav_lockdb *lockdb,
                             const dav_resource *resource,
                             int *locks_present);

    /*
    ** Append the specified lock(s) to the set of locks on this resource.
    **
    ** If "make_indirect" is true (non-zero), then the specified lock(s)
    ** should be converted to an indirect lock (if it is a direct lock)
    ** before appending. Note that the conversion to an indirect lock does
    ** not alter the passed-in lock -- the change is internal the
    ** append_locks function.
    **
    ** Multiple locks are specified using the lock->next links.
    */
    dav_error * (*append_locks)(dav_lockdb *lockdb,
                                const dav_resource *resource,
                                int make_indirect,
                                const dav_lock *lock);

    /*
    ** Remove any lock that has the specified locktoken.
    **
    ** If locktoken == NULL, then ALL locks are removed.
    */
    dav_error * (*remove_lock)(dav_lockdb *lockdb,
                               const dav_resource *resource,
                               const dav_locktoken *locktoken);

    /*
    ** Refresh all locks, found on the specified resource, which has a
    ** locktoken in the provided list.
    **
    ** If the lock is indirect, then the direct lock is referenced and
    ** refreshed.
    **
    ** Each lock that is updated is returned in the <locks> argument.
    ** Note that the locks will be fully resolved.
    */
    dav_error * (*refresh_locks)(dav_lockdb *lockdb,
                                 const dav_resource *resource,
                                 const dav_locktoken_list *ltl,
                                 time_t new_time,
                                 dav_lock **locks);

    /*
    ** Look up the resource associated with a particular locktoken.
    **
    ** The search begins at the specified <start_resource> and the lock
    ** specified by <locktoken>.
    **
    ** If the resource/token specifies an indirect lock, then the direct
    ** lock will be looked up, and THAT resource will be returned. In other
    ** words, this function always returns the resource where a particular
    ** lock (token) was asserted.
    **
    ** NOTE: this function pointer is allowed to be NULL, indicating that
    **       the provider does not support this type of functionality. The
    **       caller should then traverse up the repository hierarchy looking
    **       for the resource defining a lock with this locktoken.
    */
    dav_error * (*lookup_resource)(dav_lockdb *lockdb,
                                   const dav_locktoken *locktoken,
                                   const dav_resource *start_resource,
                                   const dav_resource **resource);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;
};

/* what types of resources can be discovered by dav_get_resource_state() */
#define DAV_RESOURCE_LOCK_NULL  10    /* resource lock-null */
#define DAV_RESOURCE_NULL       11    /* resource null */
#define DAV_RESOURCE_EXISTS     12    /* resource exists */
#define DAV_RESOURCE_ERROR      13    /* an error occurred */


/* --------------------------------------------------------------------
**
** PROPERTY HANDLING
*/

typedef struct dav_propdb dav_propdb;


DAV_DECLARE(dav_error *) dav_open_propdb(
    request_rec *r,
    dav_lockdb *lockdb,
    const dav_resource *resource,
    int ro,
    apr_array_header_t *ns_xlate,
    dav_propdb **propdb);

DAV_DECLARE(dav_error *) dav_popen_propdb(
    apr_pool_t *p,
    request_rec *r,
    dav_lockdb *lockdb,
    const dav_resource *resource,
    int ro,
    apr_array_header_t *ns_xlate,
    dav_propdb **propdb);


DAV_DECLARE(void) dav_close_propdb(dav_propdb *db);

DAV_DECLARE(dav_get_props_result) dav_get_props(
    dav_propdb *db,
    apr_xml_doc *doc);

DAV_DECLARE(dav_get_props_result) dav_get_allprops(
    dav_propdb *db,
    dav_prop_insert what);

DAV_DECLARE(void) dav_get_liveprop_supported(
    dav_propdb *propdb,
    const char *ns_uri,
    const char *propname,
    apr_text_header *body);

/*
** 3-phase property modification.
**
**   1) validate props. readable? unlocked? ACLs allow access?
**   2) execute operation (set/delete)
**   3) commit or rollback
**
** ### eventually, auth must be available. a ref to the request_rec (which
** ### contains the auth info) should be in the shared context struct.
**
** Each function may alter the error values and information contained within
** the context record. This should be done as an "increasing" level of
** error, rather than overwriting any previous error.
**
** Note that commit() cannot generate errors. It should simply free the
** rollback information.
**
** rollback() may generate additional errors because the rollback operation
** can sometimes fail(!).
**
** The caller should allocate an array of these, one per operation. It should
** be zero-initialized, then the db, operation, and prop fields should be
** filled in before calling dav_prop_validate. Note that the set/delete
** operations are order-dependent. For a given (logical) context, the same
** pointer must be passed to each phase.
**
** error_type is an internal value, but will have the same numeric value
** for each possible "desc" value. This allows the caller to group the
** descriptions via the error_type variable, rather than through string
** comparisons. Note that "status" does not provide enough granularity to
** differentiate/group the "desc" values.
**
** Note that the propdb will maintain some (global) context across all
** of the property change contexts. This implies that you can have only
** one open transaction per propdb.
*/
typedef struct dav_prop_ctx
{
    dav_propdb *propdb;

    apr_xml_elem *prop;             /* property to affect */

    int operation;
#define DAV_PROP_OP_SET        1    /* set a property value */
#define DAV_PROP_OP_DELETE     2    /* delete a prop value */
/* ### add a GET? */

    /* private items to the propdb */
    int is_liveprop;
    void *liveprop_ctx;
    struct dav_rollback_item *rollback;  /* optional rollback info */

    dav_error *err;                 /* error (if any) */

    /* private to mod_dav.c */
    request_rec *r;

} dav_prop_ctx;

DAV_DECLARE_NONSTD(void) dav_prop_validate(dav_prop_ctx *ctx);
DAV_DECLARE_NONSTD(void) dav_prop_exec(dav_prop_ctx *ctx);
DAV_DECLARE_NONSTD(void) dav_prop_commit(dav_prop_ctx *ctx);
DAV_DECLARE_NONSTD(void) dav_prop_rollback(dav_prop_ctx *ctx);

#define DAV_PROP_CTX_HAS_ERR(dpc)  ((dpc).err && (dpc).err->status >= 300)


/* --------------------------------------------------------------------
**
** WALKER STRUCTURE
*/

enum {
    DAV_CALLTYPE_MEMBER = 1,    /* called for a member resource */
    DAV_CALLTYPE_COLLECTION,    /* called for a collection */
    DAV_CALLTYPE_LOCKNULL       /* called for a locknull resource */
};

typedef struct
{
    /* the client-provided context */
    void *walk_ctx;

    /* pool to use for allocations in the callback */
    apr_pool_t *pool;

    /* the current resource */
    const dav_resource *resource;

    /* OUTPUT: add responses to this */
    dav_response *response;

} dav_walk_resource;

typedef struct
{
    int walk_type;
#define DAV_WALKTYPE_AUTH       0x0001  /* limit to authorized files */
#define DAV_WALKTYPE_NORMAL     0x0002  /* walk normal files */
#define DAV_WALKTYPE_LOCKNULL   0x0004  /* walk locknull resources */

    /* callback function and a client context for the walk */
    dav_error * (*func)(dav_walk_resource *wres, int calltype);
    void *walk_ctx;

    /* what pool to use for allocations needed by walk logic */
    apr_pool_t *pool;

    /* beginning root of the walk */
    const dav_resource *root;

    /* lock database to enable walking LOCKNULL resources */
    dav_lockdb *lockdb;

} dav_walk_params;

/* directory tree walking context */
typedef struct dav_walker_ctx
{
    /* input: */
    dav_walk_params w;


    /* ### client data... phasing out this big glom */

    /* this brigade buffers data being sent to r->output_filters */
    apr_bucket_brigade *bb;

    /* a scratch pool, used to stream responses and iteratively cleared. */
    apr_pool_t *scratchpool;

    request_rec *r;                 /* original request */

    /* for PROPFIND operations */
    apr_xml_doc *doc;
    int propfind_type;
#define DAV_PROPFIND_IS_ALLPROP     1
#define DAV_PROPFIND_IS_PROPNAME    2
#define DAV_PROPFIND_IS_PROP        3

    apr_text *propstat_404;         /* (cached) propstat giving a 404 error */

    const dav_if_header *if_header; /* for validation */
    const dav_locktoken *locktoken; /* for UNLOCK */
    const dav_lock *lock;           /* for LOCK */
    int skip_root;                  /* for dav_inherit_locks() */

    int flags;

    dav_buffer work_buf;            /* for dav_validate_request() */

} dav_walker_ctx;

DAV_DECLARE(void) dav_add_response(dav_walk_resource *wres,
                                   int status,
                                   dav_get_props_result *propstats);


/* --------------------------------------------------------------------
**
** "STREAM" STRUCTURE
**
** mod_dav uses this abstraction for interacting with the repository
** while fetching/storing resources. mod_dav views resources as a stream
** of bytes.
**
** Note that the structure is opaque -- it is private to the repository
** that created the stream in the repository's "open" function.
**
** ### THIS STUFF IS GOING AWAY ... GET/read requests are handled by
** ### having the provider jam stuff straight into the filter stack.
** ### this is only left for handling PUT/write requests.
*/

typedef struct dav_stream dav_stream;

typedef enum {
    DAV_MODE_WRITE_TRUNC,      /* truncate and open for writing */
    DAV_MODE_WRITE_SEEKABLE    /* open for writing; random access */
} dav_stream_mode;


/* --------------------------------------------------------------------
**
** REPOSITORY FUNCTIONS
*/

/* Repository provider hooks */
struct dav_hooks_repository
{
    /* Flag for whether repository requires special GET handling.
     * If resources in the repository are not visible in the
     * filesystem location which URLs map to, then special handling
     * is required to first fetch a resource from the repository,
     * respond to the GET request, then free the resource copy.
     */
    int handle_get;

    /* Get a resource descriptor for the URI in a request. A descriptor
     * should always be returned even if the resource does not exist. This
     * repository has been identified as handling the resource given by
     * the URI, so an answer must be given. If there is a problem with the
     * URI or accessing the resource or whatever, then an error should be
     * returned.
     *
     * root_dir:
     *   the root of the directory for which this repository is configured.
     *
     * label:
     *   if a Label: header is present (and allowed), this is the label
     *   to use to identify a version resource from the resource's
     *   corresponding version history. Otherwise, it will be NULL.
     *
     * use_checked_in:
     *   use the DAV:checked-in property of the resource identified by the
     *   Request-URI to identify and return a version resource
     *
     * The provider may associate the request storage pool with the resource
     * (in the resource->pool field), to use in other operations on that
     * resource.
     */
    dav_error * (*get_resource)(
        request_rec *r,
        const char *root_dir,
        const char *label,
        int use_checked_in,
        dav_resource **resource
    );

    /* Get a resource descriptor for the parent of the given resource.
     * The resources need not exist.  NULL is returned if the resource
     * is the root collection.
     *
     * An error should be returned only if there is a fatal error in
     * fetching information about the parent resource.
     */
    dav_error * (*get_parent_resource)(
        const dav_resource *resource,
        dav_resource **parent_resource
    );

    /* Determine whether two resource descriptors refer to the same resource.
    *
     * Result != 0 => the resources are the same.
     */
    int (*is_same_resource)(
        const dav_resource *res1,
        const dav_resource *res2
    );

    /* Determine whether one resource is a parent (immediate or otherwise)
     * of another.
     *
     * Result != 0 => res1 is a parent of res2.
     */
    int (*is_parent_resource)(
        const dav_resource *res1,
        const dav_resource *res2
    );

    /*
    ** Open a stream for this resource, using the specified mode. The
    ** stream will be returned in *stream.
    */
    dav_error * (*open_stream)(const dav_resource *resource,
                               dav_stream_mode mode,
                               dav_stream **stream);

    /*
    ** Close the specified stream.
    **
    ** mod_dav will (ideally) make sure to call this. For safety purposes,
    ** a provider should (ideally) register a cleanup function with the
    ** request pool to get this closed and cleaned up.
    **
    ** Note the possibility of an error from the close -- it is entirely
    ** feasible that the close does a "commit" of some kind, which can
    ** produce an error.
    **
    ** commit should be TRUE (non-zero) or FALSE (0) if the stream was
    ** opened for writing. This flag states whether to retain the file
    ** or not.
    ** Note: the commit flag is ignored for streams opened for reading.
    */
    dav_error * (*close_stream)(dav_stream *stream, int commit);

    /*
    ** Write data to the stream.
    **
    ** All of the bytes must be written, or an error should be returned.
    */
    dav_error * (*write_stream)(dav_stream *stream,
                                const void *buf, apr_size_t bufsize);

    /*
    ** Seek to an absolute position in the stream. This is used to support
    ** Content-Range in a GET/PUT.
    **
    ** NOTE: if this function is NULL (which is allowed), then any
    **       operations using Content-Range will be refused.
    */
    dav_error * (*seek_stream)(dav_stream *stream, apr_off_t abs_position);

    /*
    ** If a GET is processed using a stream (open_stream, read_stream)
    ** rather than via a sub-request (on get_pathname), then this function
    ** is used to provide the repository with a way to set the headers
    ** in the response.
    **
    ** This function may be called without a following deliver(), to
    ** handle a HEAD request.
    **
    ** This may be NULL if handle_get is FALSE.
    */
    dav_error * (*set_headers)(request_rec *r,
                               const dav_resource *resource);

    /*
    ** The provider should deliver the resource into the specified filter.
    ** Basically, this is the response to the GET method.
    **
    ** Note that this is called for all resources, including collections.
    ** The provider should determine what has content to deliver or not.
    **
    ** set_headers will be called prior to this function, allowing the
    ** provider to set the appropriate response headers.
    **
    ** This may be NULL if handle_get is FALSE.
    ** ### maybe toss handle_get and just use this function as the marker
    */
    dav_error * (*deliver)(const dav_resource *resource,
                           ap_filter_t *output);

    /* Create a collection resource. The resource must not already exist.
     *
     * Result == NULL if the collection was created successfully. Also, the
     * resource object is updated to reflect that the resource exists, and
     * is a collection.
     */
    dav_error * (*create_collection)(
        dav_resource *resource
    );

    /* Copy one resource to another. The destination may exist, if it is
     * versioned.
     * Handles both files and collections. Properties are copied as well.
     * If the destination exists and is versioned, the provider must update
     * the destination to have identical content to the source,
     * recursively for collections.
     * The depth argument is ignored for a file, and can be either 0 or
     * DAV_INFINITY for a collection.
     * If an error occurs in a child resource, then the return value is
     * non-NULL, and *response is set to a multistatus response.
     * If the copy is successful, the dst resource object is
     * updated to reflect that the resource exists.
     */
    dav_error * (*copy_resource)(
        const dav_resource *src,
        dav_resource *dst,
        int depth,
        dav_response **response
    );

    /* Move one resource to another. The destination must not exist.
     * Handles both files and collections. Properties are moved as well.
     * If an error occurs in a child resource, then the return value is
     * non-NULL, and *response is set to a multistatus response.
     * If the move is successful, the src and dst resource objects are
     * updated to reflect that the source no longer exists, and the
     * destination does.
     */
    dav_error * (*move_resource)(
        dav_resource *src,
        dav_resource *dst,
        dav_response **response
    );

    /* Remove a resource. Handles both files and collections.
     * Removes any associated properties as well.
     * If an error occurs in a child resource, then the return value is
     * non-NULL, and *response is set to a multistatus response.
     * If the delete is successful, the resource object is updated to
     * reflect that the resource no longer exists.
     */
    dav_error * (*remove_resource)(
        dav_resource *resource,
        dav_response **response
    );

    /* Walk a resource hierarchy.
     *
     * Iterates over the resource hierarchy specified by params->root.
     * Control of the walk and the callback are specified by 'params'.
     *
     * An error may be returned. *response will contain multistatus
     * responses (if any) suitable for the body of the error. It is also
     * possible to return NULL, yet still have multistatus responses.
     * In this case, typically the caller should return a 207 (Multistatus)
     * and the responses (in the body) as the HTTP response.
     */
    dav_error * (*walk)(const dav_walk_params *params, int depth,
                        dav_response **response);

    /* Get the entity tag for a resource */
    const char * (*getetag)(const dav_resource *resource);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;

    /* Get the request rec for a resource */
    request_rec * (*get_request_rec)(const dav_resource *resource);

    /* Get the pathname for a resource */
    const char * (*get_pathname)(const dav_resource *resource);
};


/* --------------------------------------------------------------------
**
** VERSIONING FUNCTIONS
*/


/* dav_add_vary_header
 *
 * If there were any headers in the request which require a Vary header
 * in the response, add it.
 */
DAV_DECLARE(void) dav_add_vary_header(request_rec *in_req,
                                      request_rec *out_req,
                                      const dav_resource *resource);

/*
** Flags specifying auto-versioning behavior, returned by
** the auto_versionable hook. The value returned depends
** on both the state of the resource and the value of the
** DAV:auto-versioning property for the resource.
**
** If the resource does not exist (null or lock-null),
** DAV_AUTO_VERSION_ALWAYS causes creation of a new version-controlled resource
**
** If the resource is checked in,
** DAV_AUTO_VERSION_ALWAYS causes it to be checked out always,
** DAV_AUTO_VERSION_LOCKED causes it to be checked out only when locked
**
** If the resource is checked out,
** DAV_AUTO_VERSION_ALWAYS causes it to be checked in always,
** DAV_AUTO_VERSION_LOCKED causes it to be checked in when unlocked
** (note: a provider should allow auto-checkin only for resources which
** were automatically checked out)
**
** In all cases, DAV_AUTO_VERSION_NEVER results in no auto-versioning behavior.
*/
typedef enum {
    DAV_AUTO_VERSION_NEVER,
    DAV_AUTO_VERSION_ALWAYS,
    DAV_AUTO_VERSION_LOCKED
} dav_auto_version;

/*
** This structure is used to record what auto-versioning operations
** were done to make a resource writable, so that they can be undone
** at the end of a request.
*/
typedef struct {
    int resource_versioned;             /* 1 => resource was auto-version-controlled */
    int resource_checkedout;            /* 1 => resource was auto-checked-out */
    int parent_checkedout;              /* 1 => parent was auto-checked-out */
    dav_resource *parent_resource;      /* parent resource, if it was needed */
} dav_auto_version_info;

/* Ensure that a resource is writable. If there is no versioning
 * provider, then this is essentially a no-op. Versioning repositories
 * require explicit resource creation and checkout before they can
 * be written to. If a new resource is to be created, or an existing
 * resource deleted, the parent collection must be checked out as well.
 *
 * Set the parent_only flag to only make the parent collection writable.
 * Otherwise, both parent and child are made writable as needed. If the
 * child does not exist, then a new versioned resource is created and
 * checked out.
 *
 * If auto-versioning is not enabled for a versioned resource, then an error is
 * returned, since the resource cannot be modified.
 *
 * The dav_auto_version_info structure is filled in with enough information
 * to restore both parent and child resources to the state they were in
 * before the auto-versioning operations occurred.
 */
DAV_DECLARE(dav_error *) dav_auto_checkout(
    request_rec *r,
    dav_resource *resource,
    int parent_only,
    dav_auto_version_info *av_info);

/* Revert the writability of resources back to what they were
 * before they were modified. If undo == 0, then the resource
 * modifications are maintained (i.e. they are checked in).
 * If undo != 0, then resource modifications are discarded
 * (i.e. they are unchecked out).
 *
 * Set the unlock flag to indicate that the resource is about
 * to be unlocked; it will be checked in if the resource
 * auto-versioning property indicates it should be. In this case,
 * av_info is ignored, so it can be NULL.
 *
 * The resource argument may be NULL if only the parent resource
 * was checked out (i.e. the parent_only was != 0 in the
 * dav_auto_checkout call).
 */
DAV_DECLARE(dav_error *) dav_auto_checkin(
    request_rec *r,
    dav_resource *resource,
    int undo,
    int unlock,
    dav_auto_version_info *av_info);

/*
** This structure is used to describe available reports
**
** "nmspace" should be valid XML and URL-quoted. mod_dav will place
** double-quotes around it and use it in an xmlns declaration.
*/
typedef struct {
    const char *nmspace;        /* namespace of the XML report element */
    const char *name;           /* element name for the XML report */
} dav_report_elem;


/* Versioning provider hooks */
struct dav_hooks_vsn
{
    /*
    ** MANDATORY HOOKS
    ** The following hooks are mandatory for all versioning providers;
    ** they define the functionality needed to implement "core" versioning.
    */

    /* Return supported versioning options.
     * Each dav_text item in the list will be returned as a separate
     * DAV header. Providers are advised to limit the length of an
     * individual text item to 63 characters, to conform to the limit
     * used by MS Web Folders.
     */
    void (*get_vsn_options)(apr_pool_t *p, apr_text_header *phdr);

    /* Get the value of a specific option for an OPTIONS request.
     * The option being requested is given by the parsed XML
     * element object "elem". The value of the option should be
     * appended to the "option" text object.
     */
    dav_error * (*get_option)(const dav_resource *resource,
                              const apr_xml_elem *elem,
                              apr_text_header *option);

    /* Determine whether a non-versioned (or non-existent) resource
     * is versionable. Returns != 0 if resource can be versioned.
     */
    int (*versionable)(const dav_resource *resource);

    /* Determine whether auto-versioning is enabled for a resource
     * (which may not exist, or may not be versioned). If the resource
     * is a checked-out resource, the provider must only enable
     * auto-checkin if the resource was automatically checked out.
     *
     * The value returned depends on both the state of the resource
     * and the value of its DAV:auto-version property. See the description
     * of the dav_auto_version enumeration above for the details.
     */
    dav_auto_version (*auto_versionable)(const dav_resource *resource);

    /* Put a resource under version control. If the resource already
     * exists unversioned, then it becomes the initial version of the
     * new version history, and it is replaced by a version selector
     * which targets the new version.
     *
     * If the resource does not exist, then a new version-controlled
     * resource is created which either targets an existing version (if the
     * "target" argument is not NULL), or the initial, empty version
     * in a new history resource (if the "target" argument is NULL).
     *
     * If successful, the resource object state is updated appropriately
     * (that is, changed to refer to the new version-controlled resource).
     */
    dav_error * (*vsn_control)(dav_resource *resource,
                               const char *target);

    /* Checkout a resource. If successful, the resource
     * object state is updated appropriately.
     *
     * The auto_checkout flag will be set if this checkout is being
     * done automatically, as part of some method which modifies
     * the resource. The provider must remember that the resource
     * was automatically checked out, so it can determine whether it
     * can be automatically checked in. (Auto-checkin should only be
     * enabled for resources which were automatically checked out.)
     *
     * If the working resource has a different URL from the
     * target resource, a dav_resource descriptor is returned
     * for the new working resource. Otherwise, the original
     * resource descriptor will refer to the working resource.
     * The working_resource argument can be NULL if the caller
     * is not interested in the working resource.
     *
     * If the client has specified DAV:unreserved or DAV:fork-ok in the
     * checkout request, then the corresponding flags are set. If
     * DAV:activity-set has been specified, then create_activity is set
     * if DAV:new was specified; otherwise, the DAV:href elements' CDATA
     * (the actual href text) is passed in the "activities" array (each
     * element of the array is a const char *). activities will be NULL
     * no DAV:activity-set was provided or when create_activity is set.
     */
    dav_error * (*checkout)(dav_resource *resource,
                            int auto_checkout,
                            int is_unreserved, int is_fork_ok,
                            int create_activity,
                            apr_array_header_t *activities,
                            dav_resource **working_resource);

    /* Uncheckout a checked-out resource. If successful, the resource
     * object state is updated appropriately.
     */
    dav_error * (*uncheckout)(dav_resource *resource);

    /* Checkin a checked-out resource. If successful, the resource
     * object state is updated appropriately, and the
     * version_resource descriptor will refer to the new version.
     * The version_resource argument can be NULL if the caller
     * is not interested in the new version resource.
     *
     * If the client has specified DAV:keep-checked-out in the checkin
     * request, then the keep_checked_out flag is set. The provider
     * should create a new version, but keep the resource in the
     * checked-out state.
     */
    dav_error * (*checkin)(dav_resource *resource,
                           int keep_checked_out,
                           dav_resource **version_resource);

    /*
    ** Return the set of reports available at this resource.
    **
    ** An array of report elements should be returned, with an end-marker
    ** element containing namespace==NULL. The value of the
    ** DAV:supported-report-set property will be constructed and
    ** returned.
    */
    dav_error * (*avail_reports)(const dav_resource *resource,
                                 const dav_report_elem **reports);

    /*
    ** Determine whether a Label header can be used
    ** with a particular report. The dav_xml_doc structure
    ** contains the parsed report request body.
    ** Returns 0 if the Label header is not allowed.
    */
    int (*report_label_header_allowed)(const apr_xml_doc *doc);

    /*
    ** Generate a report on a resource. Since a provider is free
    ** to define its own reports, and the value of request headers
    ** may affect the interpretation of a report, the request record
    ** must be passed to this routine.
    **
    ** The dav_xml_doc structure contains the parsed report request
    ** body. The report response should be generated into the specified
    ** output filter.
    **
    ** If an error occurs, and a response has not yet been generated,
    ** then an error can be returned from this function. mod_dav will
    ** construct an appropriate error response. Once some output has
    ** been placed into the filter, however, the provider should not
    ** return an error -- there is no way that mod_dav can deliver it
    ** properly.
    **
    ** ### maybe we need a way to signal an error anyways, and then
    ** ### apache can abort the connection?
    */
    dav_error * (*deliver_report)(request_rec *r,
                                  const dav_resource *resource,
                                  const apr_xml_doc *doc,
                                  ap_filter_t *output);

    /*
    ** OPTIONAL HOOKS
    ** The following hooks are optional; if not defined, then the
    ** corresponding protocol methods will be unsupported.
    */

    /*
    ** Set the state of a checked-in version-controlled resource.
    **
    ** If the request specified a version, the version resource
    ** represents that version. If the request specified a label,
    ** then "version" is NULL, and "label" is the label.
    **
    ** The depth argument is ignored for a file, and can be 0, 1, or
    ** DAV_INFINITY for a collection. The depth argument only applies
    ** with a label, not a version.
    **
    ** If an error occurs in a child resource, then the return value is
    ** non-NULL, and *response is set to a multistatus response.
    **
    ** This hook is optional; if not defined, then the UPDATE method
    ** will not be supported.
    */
    dav_error * (*update)(const dav_resource *resource,
                          const dav_resource *version,
                          const char *label,
                          int depth,
                          dav_response **response);

    /*
    ** Add a label to a version. The resource is either a specific
    ** version, or a version selector, in which case the label should
    ** be added to the current target of the version selector. The
    ** version selector cannot be checked out.
    **
    ** If replace != 0, any existing label by the same name is
    ** effectively deleted first. Otherwise, it is an error to
    ** attempt to add a label which already exists on some version
    ** of the same history resource.
    **
    ** This hook is optional; if not defined, then the LABEL method
    ** will not be supported. If it is defined, then the remove_label
    ** hook must be defined also.
    */
    dav_error * (*add_label)(const dav_resource *resource,
                             const char *label,
                             int replace);

    /*
    ** Remove a label from a version. The resource is either a specific
    ** version, or a version selector, in which case the label should
    ** be added to the current target of the version selector. The
    ** version selector cannot be checked out.
    **
    ** It is an error if no such label exists on the specified version.
    **
    ** This hook is optional, but if defined, the add_label hook
    ** must be defined also.
    */
    dav_error * (*remove_label)(const dav_resource *resource,
                                const char *label);

    /*
    ** Determine whether a null resource can be created as a workspace.
    ** The provider may restrict workspaces to certain locations.
    ** Returns 0 if the resource cannot be a workspace.
    **
    ** This hook is optional; if the provider does not support workspaces,
    ** it should be set to NULL.
    */
    int (*can_be_workspace)(const dav_resource *resource);

    /*
    ** Create a workspace resource. The resource must not already
    ** exist. Any <DAV:mkworkspace> element is passed to the provider
    ** in the "doc" structure; it may be empty.
    **
    ** If workspace creation is successful, the state of the resource
    ** object is updated appropriately.
    **
    ** This hook is optional; if the provider does not support workspaces,
    ** it should be set to NULL.
    */
    dav_error * (*make_workspace)(dav_resource *resource,
                                  apr_xml_doc *doc);

    /*
    ** Determine whether a null resource can be created as an activity.
    ** The provider may restrict activities to certain locations.
    ** Returns 0 if the resource cannot be an activity.
    **
    ** This hook is optional; if the provider does not support activities,
    ** it should be set to NULL.
    */
    int (*can_be_activity)(const dav_resource *resource);

    /*
    ** Create an activity resource. The resource must not already
    ** exist.
    **
    ** If activity creation is successful, the state of the resource
    ** object is updated appropriately.
    **
    ** This hook is optional; if the provider does not support activities,
    ** it should be set to NULL.
    */
    dav_error * (*make_activity)(dav_resource *resource);

    /*
    ** Merge a resource (tree) into target resource (tree).
    **
    ** ### more doc...
    **
    ** This hook is optional; if the provider does not support merging,
    ** then this should be set to NULL.
    */
    dav_error * (*merge)(dav_resource *target, dav_resource *source,
                         int no_auto_merge, int no_checkout,
                         apr_xml_elem *prop_elem,
                         ap_filter_t *output);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;
};


/* --------------------------------------------------------------------
**
** BINDING FUNCTIONS
*/

/* binding provider hooks */
struct dav_hooks_binding {

    /* Determine whether a resource can be the target of a binding.
     * Returns 0 if the resource cannot be a binding target.
     */
    int (*is_bindable)(const dav_resource *resource);

    /* Create a binding to a resource.
     * The resource argument is the target of the binding;
     * the binding argument must be a resource which does not already
     * exist.
     */
    dav_error * (*bind_resource)(const dav_resource *resource,
                                 dav_resource *binding);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;

};


/* --------------------------------------------------------------------
**
** SEARCH(DASL) FUNCTIONS
*/

/* search provider hooks */
struct dav_hooks_search {
    /* Set header for a OPTION method
     * An error may be returned.
     * To set a hadder, this function might call
     * apr_table_setn(r->headers_out, "DASL", dasl_optin1);
     *
     * Examples:
     * DASL: <DAV:basicsearch>
     * DASL: <http://foo.bar.com/syntax1>
     * DASL: <http://akuma.com/syntax2>
     */
    dav_error * (*set_option_head)(request_rec *r);

    /* Search resources
     * An error may be returned. *response will contain multistatus
     * responses (if any) suitable for the body of the error. It is also
     * possible to return NULL, yet still have multistatus responses.
     * In this case, typically the caller should return a 207 (Multistatus)
     * and the responses (in the body) as the HTTP response.
     */
    dav_error * (*search_resource)(request_rec *r,
                                   dav_response **response);

    /*
    ** If a provider needs a context to associate with this hooks structure,
    ** then this field may be used. In most cases, it will just be NULL.
    */
    void *ctx;

};


/* --------------------------------------------------------------------
**
** MISCELLANEOUS STUFF
*/

typedef struct {
    int propid;                          /* live property ID */
    const dav_hooks_liveprop *provider;  /* the provider defining this prop */
} dav_elem_private;

/* --------------------------------------------------------------------
**
** DAV OPTIONS
*/
#define DAV_OPTIONS_EXTENSION_GROUP "dav_options"

typedef struct dav_options_provider
{
    dav_error* (*dav_header)(request_rec *r,
                             const dav_resource *resource,
                             apr_text_header *phdr);

    dav_error* (*dav_method)(request_rec *r,
                             const dav_resource *resource,
                             apr_text_header *phdr);

    void *ctx;
} dav_options_provider;

extern DAV_DECLARE(const dav_options_provider *) dav_get_options_providers(const char *name);

extern DAV_DECLARE(void) dav_options_provider_register(apr_pool_t *p,
                               const char *name,
                               const dav_options_provider *provider);

/* --------------------------------------------------------------------
**
** DAV RESOURCE TYPE HOOKS
*/

typedef struct dav_resource_type_provider
{
    int (*get_resource_type)(const dav_resource *resource,
                  const char **name,
                  const char **uri);
} dav_resource_type_provider;

#define DAV_RESOURCE_TYPE_GROUP "dav_resource_type"

DAV_DECLARE(void) dav_resource_type_provider_register(apr_pool_t *p,
                                        const char *name,
                                    const dav_resource_type_provider *provider);

DAV_DECLARE(const dav_resource_type_provider *) dav_get_resource_type_providers(const char *name);

#ifdef __cplusplus
}
#endif

#endif /* _MOD_DAV_H_ */
/** @} */

