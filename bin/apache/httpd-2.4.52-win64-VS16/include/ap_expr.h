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
 * @file ap_expr.h
 * @brief Expression parser
 *
 * @defgroup AP_EXPR Expression parser
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef AP_EXPR_H
#define AP_EXPR_H

#include "httpd.h"
#include "http_config.h"
#include "ap_regex.h"

#ifdef __cplusplus
extern "C" {
#endif

/** A node in the expression parse tree */
typedef struct ap_expr_node ap_expr_t;

/** Struct describing a parsed expression */
typedef struct {
    /** The root of the actual expression parse tree */
    ap_expr_t *root_node;
    /** The filename where the expression has been defined (for logging).
     *  May be NULL
     */
    const char *filename;
    /** The line number where the expression has been defined (for logging). */
    unsigned int line_number;
    /** Flags relevant for the expression, see AP_EXPR_FLAG_* */
    unsigned int flags;
    /** The module that is used for loglevel configuration */
    int module_index;
} ap_expr_info_t;

/** Use ssl_expr compatibility mode (changes the meaning of the comparison
 * operators)
 */
#define AP_EXPR_FLAG_SSL_EXPR_COMPAT       1
/** Don't add significant request headers to the Vary response header */
#define AP_EXPR_FLAG_DONT_VARY             2
/** Don't allow functions/vars that bypass the current request's access
 *  restrictions or would otherwise leak confidential information.
 *  Used by e.g. mod_include.
 */
#define AP_EXPR_FLAG_RESTRICTED            4
/** Expression evaluates to a string, not to a bool */
#define AP_EXPR_FLAG_STRING_RESULT         8


/**
 * Evaluate a parse tree, simple interface
 * @param r The current request
 * @param expr The expression to be evaluated
 * @param err Where an error message should be stored
 * @return > 0 if expression evaluates to true, == 0 if false, < 0 on error
 * @note err will be set to NULL on success, or to an error message on error
 * @note request headers used during evaluation will be added to the Vary:
 *       response header, unless ::AP_EXPR_FLAG_DONT_VARY is set.
 */
AP_DECLARE(int) ap_expr_exec(request_rec *r, const ap_expr_info_t *expr,
                             const char **err);

/**
 * Evaluate a parse tree, with access to regexp backreference
 * @param r The current request
 * @param expr The expression to be evaluated
 * @param nmatch size of the regex match vector pmatch
 * @param pmatch information about regex matches
 * @param source the string that pmatch applies to
 * @param err Where an error message should be stored
 * @return > 0 if expression evaluates to true, == 0 if false, < 0 on error
 * @note err will be set to NULL on success, or to an error message on error
 * @note nmatch/pmatch/source can be used both to make previous matches
 *       available to ap_expr_exec_re and to use ap_expr_exec_re's matches
 *       later on.
 * @note request headers used during evaluation will be added to the Vary:
 *       response header, unless ::AP_EXPR_FLAG_DONT_VARY is set.
 */
AP_DECLARE(int) ap_expr_exec_re(request_rec *r, const ap_expr_info_t *expr,
                                apr_size_t nmatch, ap_regmatch_t *pmatch,
                                const char **source, const char **err);

/** Context used during evaluation of a parse tree, created by ap_expr_exec */
typedef struct {
    /** the current request */
    request_rec *r;
    /** the current connection */
    conn_rec *c;
    /** the current virtual host */
    server_rec *s;
    /** the pool to use */
    apr_pool_t *p;
    /** where to store the error string */
    const char **err;
    /** ap_expr_info_t for the expression */
    const ap_expr_info_t *info;
    /** regex match information for back references */
    ap_regmatch_t *re_pmatch;
    /** size of the vector pointed to by re_pmatch */
    apr_size_t re_nmatch;
    /** the string corresponding to the re_pmatch */
    const char **re_source;
    /** A string where the comma separated names of headers are stored
     * to be later added to the Vary: header. If NULL, the caller is not
     * interested in this information.
     */
    const char **vary_this;
    /** where to store the result string */
    const char **result_string;
    /** Arbitrary context data provided by the caller for custom functions */
    void *data;
    /** The current recursion level */
    int reclvl;
} ap_expr_eval_ctx_t;

/**
 * Evaluate a parse tree, full featured version
 * @param ctx The evaluation context with all data filled in
 * @return > 0 if expression evaluates to true, == 0 if false, < 0 on error
 * @note *ctx->err will be set to NULL on success, or to an error message on
 *       error
 * @note request headers used during evaluation will be added to the Vary:
 *       response header if ctx->vary_this is set.
 */
AP_DECLARE(int) ap_expr_exec_ctx(ap_expr_eval_ctx_t *ctx);

/**
 * Evaluate a parse tree of a string valued expression
 * @param r The current request
 * @param expr The expression to be evaluated
 * @param err Where an error message should be stored
 * @return The result string, NULL on error
 * @note err will be set to NULL on success, or to an error message on error
 * @note request headers used during evaluation will be added to the Vary:
 *       response header, unless ::AP_EXPR_FLAG_DONT_VARY is set.
 */
AP_DECLARE(const char *) ap_expr_str_exec(request_rec *r,
                                          const ap_expr_info_t *expr,
                                          const char **err);

/**
 * Evaluate a parse tree of a string valued expression
 * @param r The current request
 * @param expr The expression to be evaluated
 * @param nmatch size of the regex match vector pmatch
 * @param pmatch information about regex matches
 * @param source the string that pmatch applies to
 * @param err Where an error message should be stored
 * @return The result string, NULL on error
 * @note err will be set to NULL on success, or to an error message on error
 * @note nmatch/pmatch/source can be used both to make previous matches
 *       available to ap_expr_exec_re and to use ap_expr_exec_re's matches
 *       later on.
 * @note request headers used during evaluation will be added to the Vary:
 *       response header, unless ::AP_EXPR_FLAG_DONT_VARY is set.
 */
AP_DECLARE(const char *) ap_expr_str_exec_re(request_rec *r,
                                             const ap_expr_info_t *expr,
                                             apr_size_t nmatch,
                                             ap_regmatch_t *pmatch,
                                             const char **source,
                                             const char **err);


/**
 * The parser can be extended with variable lookup, functions, and
 * and operators.
 *
 * During parsing, the parser calls the lookup function to resolve a
 * name into a function pointer and an opaque context for the function.
 * If the argument to a function or operator is constant, the lookup function
 * may also parse that argument and store the parsed data in the context.
 *
 * The default lookup function is the hook ::ap_expr_lookup_default which just
 * calls ap_run_expr_lookup. Modules can use it to make functions and
 * variables generally available.
 *
 * An ap_expr consumer can also provide its own custom lookup function to
 * modify the set of variables and functions that are available. The custom
 * lookup function can in turn call 'ap_run_expr_lookup'.
 */

/** Unary operator, takes one string argument and returns a bool value.
 * The name must have the form '-z' (one letter only).
 * @param ctx The evaluation context
 * @param data An opaque context provided by the lookup hook function
 * @param arg The (right) operand
 * @return 0 or 1
 */
typedef int ap_expr_op_unary_t(ap_expr_eval_ctx_t *ctx, const void *data,
                               const char *arg);

/** Binary operator, takes two string arguments and returns a bool value.
 * The name must have the form '-cmp' (at least two letters).
 * @param ctx The evaluation context
 * @param data An opaque context provided by the lookup hook function
 * @param arg1 The left operand
 * @param arg2 The right operand
 * @return 0 or 1
 */
typedef int ap_expr_op_binary_t(ap_expr_eval_ctx_t *ctx, const void *data,
                                const char *arg1, const char *arg2);

/** String valued function, takes a string argument and returns a string
 * @param ctx The evaluation context
 * @param data An opaque context provided by the lookup hook function
 * @param arg The argument
 * @return The functions result string, may be NULL for 'empty string'
 */
typedef const char *(ap_expr_string_func_t)(ap_expr_eval_ctx_t *ctx,
                                            const void *data,
                                            const char *arg);

/** List valued function, takes a string argument and returns a list of strings
 * Can currently only be called following the builtin '-in' operator.
 * @param ctx The evaluation context
 * @param data An opaque context provided by the lookup hook function
 * @param arg The argument
 * @return The functions result list of strings, may be NULL for 'empty array'
 */
typedef apr_array_header_t *(ap_expr_list_func_t)(ap_expr_eval_ctx_t *ctx,
                                                  const void *data,
                                                  const char *arg);

/** Variable lookup function, takes no argument and returns a string
 * @param ctx The evaluation context
 * @param data An opaque context provided by the lookup hook function
 * @return The expanded variable
 */
typedef const char *(ap_expr_var_func_t)(ap_expr_eval_ctx_t *ctx,
                                         const void *data);

/** parameter struct passed to the lookup hook functions */
typedef struct {
    /** type of the looked up object */
    int type;
#define AP_EXPR_FUNC_VAR        0
#define AP_EXPR_FUNC_STRING     1
#define AP_EXPR_FUNC_LIST       2
#define AP_EXPR_FUNC_OP_UNARY   3
#define AP_EXPR_FUNC_OP_BINARY  4
    /** name of the looked up object */
    const char *name;

    int flags;

    apr_pool_t *pool;
    apr_pool_t *ptemp;

    /** where to store the function pointer */
    const void **func;
    /** where to store the function's context */
    const void **data;
    /** where to store the error message (if any) */
    const char **err;

    /** arg for pre-parsing (only if a simple string).
     *  For binary ops, this is the right argument. */
    const char *arg;
} ap_expr_lookup_parms;

/** Function for looking up the provider function for a variable, operator
 *  or function in an expression.
 *  @param parms The parameter struct, also determines where the result is
 *               stored.
 *  @return OK on success,
 *          !OK on failure,
 *          DECLINED if the requested name is not handled by this function
 */
typedef int (ap_expr_lookup_fn_t)(ap_expr_lookup_parms *parms);

/** Default lookup function which just calls ap_run_expr_lookup().
 *  ap_run_expr_lookup cannot be used directly because it has the wrong
 *  calling convention under Windows.
 */
AP_DECLARE_NONSTD(int) ap_expr_lookup_default(ap_expr_lookup_parms *parms);

AP_DECLARE_HOOK(int, expr_lookup, (ap_expr_lookup_parms *parms))

/**
 * Parse an expression into a parse tree
 * @param pool Pool
 * @param ptemp temp pool
 * @param info The ap_expr_info_t struct (with values filled in)
 * @param expr The expression string to parse
 * @param lookup_fn The lookup function to use, NULL for default
 * @return NULL on success, error message on error.
 *         A pointer to the resulting parse tree will be stored in
 *         info->root_node.
 */
AP_DECLARE(const char *) ap_expr_parse(apr_pool_t *pool, apr_pool_t *ptemp,
                                       ap_expr_info_t *info, const char *expr,
                                       ap_expr_lookup_fn_t *lookup_fn);

/**
 * High level interface to ap_expr_parse that also creates ap_expr_info_t and
 * uses info from cmd_parms to fill in most of it.
 * @param cmd The cmd_parms struct
 * @param expr The expression string to parse
 * @param flags The flags to use, see AP_EXPR_FLAG_*
 * @param err Set to NULL on success, error message on error
 * @param lookup_fn The lookup function used to lookup vars, functions, and
 *        operators
 * @param module_index The module_index to set for the expression
 * @return The parsed expression
 * @note Usually ap_expr_parse_cmd() should be used
 */
AP_DECLARE(ap_expr_info_t *) ap_expr_parse_cmd_mi(const cmd_parms *cmd,
                                                  const char *expr,
                                                  unsigned int flags,
                                                  const char **err,
                                                  ap_expr_lookup_fn_t *lookup_fn,
                                                  int module_index);

/**
 * Convenience wrapper for ap_expr_parse_cmd_mi() that sets
 * module_index = APLOG_MODULE_INDEX
 */
#define ap_expr_parse_cmd(cmd, expr, flags, err, lookup_fn) \
        ap_expr_parse_cmd_mi(cmd, expr, flags, err, lookup_fn, APLOG_MODULE_INDEX)

 /**
  * Internal initialisation of ap_expr (for httpd internal use)
  */
void ap_expr_init(apr_pool_t *pool);

#ifdef __cplusplus
}
#endif

#endif /* AP_EXPR_H */
/** @} */
