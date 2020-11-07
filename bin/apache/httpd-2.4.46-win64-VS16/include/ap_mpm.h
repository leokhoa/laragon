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
 * @file  ap_mpm.h
 * @brief Apache Multi-Processing Module library
 *
 * @defgroup APACHE_CORE_MPM Multi-Processing Module library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef AP_MPM_H
#define AP_MPM_H

#include "apr_thread_proc.h"
#include "httpd.h"
#include "scoreboard.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
    The MPM, "multi-processing model" provides an abstraction of the
    interface with the OS for distributing incoming connections to
    threads/process for processing.  http_main invokes the MPM, and
    the MPM runs until a shutdown/restart has been indicated.
    The MPM calls out to the apache core via the ap_process_connection
    function when a connection arrives.

    The MPM may or may not be multithreaded.  In the event that it is
    multithreaded, at any instant it guarantees a 1:1 mapping of threads
    ap_process_connection invocations.

    Note: In the future it will be possible for ap_process_connection
    to return to the MPM prior to finishing the entire connection; and
    the MPM will proceed with asynchronous handling for the connection;
    in the future the MPM may call ap_process_connection again -- but
    does not guarantee it will occur on the same thread as the first call.

    The MPM further guarantees that no asynchronous behaviour such as
    longjmps and signals will interfere with the user code that is
    invoked through ap_process_connection.  The MPM may reserve some
    signals for its use (i.e. SIGUSR1), but guarantees that these signals
    are ignored when executing outside the MPM code itself.  (This
    allows broken user code that does not handle EINTR to function
    properly.)

    The suggested server restart and stop behaviour will be "graceful".
    However the MPM may choose to terminate processes when the user
    requests a non-graceful restart/stop.  When this occurs, the MPM kills
    all threads with extreme prejudice, and destroys the pchild pool.
    User cleanups registered in the pchild apr_pool_t will be invoked at
    this point.  (This can pose some complications, the user cleanups
    are asynchronous behaviour not unlike longjmp/signal... but if the
    admin is asking for a non-graceful shutdown, how much effort should
    we put into doing it in a nice way?)

    unix/posix notes:
    - The MPM does not set a SIGALRM handler, user code may use SIGALRM.
        But the preferred method of handling timeouts is to use the
        timeouts provided by the BUFF abstraction.
    - The proper setting for SIGPIPE is SIG_IGN, if user code changes it
        for any of their own processing, it must be restored to SIG_IGN
        prior to executing or returning to any apache code.
    TODO: add SIGPIPE debugging check somewhere to make sure it's SIG_IGN
*/

/**
 * Pass control to the MPM for steady-state processing.  It is responsible
 * for controlling the parent and child processes.  It will run until a
 * restart/shutdown is indicated.
 * @param pconf the configuration pool, reset before the config file is read
 * @param plog the log pool, reset after the config file is read
 * @param server_conf the global server config.
 * @return DONE for shutdown OK otherwise.
 * @ingroup hooks
 */
AP_DECLARE_HOOK(int, mpm, (apr_pool_t *pconf, apr_pool_t *plog, server_rec *server_conf))

/**
 * Spawn a process with privileges that another module has requested
 * @param r The request_rec of the current request
 * @param newproc The resulting process handle.
 * @param progname The program to run
 * @param args the arguments to pass to the new program.  The first
 *                   one should be the program name.
 * @param env The new environment apr_table_t for the new process.  This
 *            should be a list of NULL-terminated strings.
 * @param attr the procattr we should use to determine how to create the new
 *         process
 * @param p The pool to use.
 */
AP_DECLARE(apr_status_t) ap_os_create_privileged_process(
    const request_rec *r,
    apr_proc_t *newproc,
    const char *progname,
    const char * const *args,
    const char * const *env,
    apr_procattr_t *attr,
    apr_pool_t *p);

/** @defgroup mpmq MPM query
 * @{
 */

/** @defgroup thrdfrk Subtypes/Values returned for AP_MPMQ_IS_THREADED and AP_MPMQ_IS_FORKED
 *  @ingroup mpmq
 *  @{
 */
#define AP_MPMQ_NOT_SUPPORTED      0  /**< This value specifies that an
                                       * MPM is not capable of
                                       * threading or forking.        */
#define AP_MPMQ_STATIC             1  /**< This value specifies that
                                       * an MPM is using a static
                                       * number of threads or daemons */
#define AP_MPMQ_DYNAMIC            2  /**< This value specifies that
                                       * an MPM is using a dynamic
                                       * number of threads or daemons */
/** @} */

/** @defgroup qstate Values returned for AP_MPMQ_MPM_STATE
 *  @ingroup mpmq
 *  @{
 */
#define AP_MPMQ_STARTING              0
#define AP_MPMQ_RUNNING               1
#define AP_MPMQ_STOPPING              2
/** @} */

/** @defgroup qcodes Query codes for ap_mpm_query()
 *  @ingroup mpmq
 *  @{
 */
/** Max # of daemons used so far */
#define AP_MPMQ_MAX_DAEMON_USED       1
/** MPM can do threading         */
#define AP_MPMQ_IS_THREADED           2
/** MPM can do forking           */
#define AP_MPMQ_IS_FORKED             3
/** The compiled max # daemons   */
#define AP_MPMQ_HARD_LIMIT_DAEMONS    4
/** The compiled max # threads   */
#define AP_MPMQ_HARD_LIMIT_THREADS    5
/** \# of threads/child by config */
#define AP_MPMQ_MAX_THREADS           6
/** Min # of spare daemons       */
#define AP_MPMQ_MIN_SPARE_DAEMONS     7
/** Min # of spare threads       */
#define AP_MPMQ_MIN_SPARE_THREADS     8
/** Max # of spare daemons       */
#define AP_MPMQ_MAX_SPARE_DAEMONS     9
/** Max # of spare threads       */
#define AP_MPMQ_MAX_SPARE_THREADS    10
/** Max # of requests per daemon */
#define AP_MPMQ_MAX_REQUESTS_DAEMON  11
/** Max # of daemons by config   */
#define AP_MPMQ_MAX_DAEMONS          12
/** starting, running, stopping  */
#define AP_MPMQ_MPM_STATE            13
/** MPM can process async connections  */
#define AP_MPMQ_IS_ASYNC             14
/** MPM generation */
#define AP_MPMQ_GENERATION           15
/** MPM can drive serf internally  */
#define AP_MPMQ_HAS_SERF             16
/** @} */

/**
 * Query a property of the current MPM.
 * @param query_code One of AP_MPMQ_*
 * @param result A location to place the result of the query
 * @return APR_EGENERAL if an mpm-query hook has not been registered;
 * APR_SUCCESS or APR_ENOTIMPL otherwise
 * @remark The MPM doesn't register the implementing hook until the
 * register_hooks hook is called, so modules cannot use ap_mpm_query()
 * until after that point.
 * @fn int ap_mpm_query(int query_code, int *result)
 */
AP_DECLARE(apr_status_t) ap_mpm_query(int query_code, int *result);

/** @} */

typedef void (ap_mpm_callback_fn_t)(void *baton);

/* only added support in the Event MPM....  check for APR_ENOTIMPL */
AP_DECLARE(apr_status_t) ap_mpm_register_timed_callback(apr_time_t t,
                                                       ap_mpm_callback_fn_t *cbfn,
                                                       void *baton);

typedef enum mpm_child_status {
    MPM_CHILD_STARTED,
    MPM_CHILD_EXITED,
    MPM_CHILD_LOST_SLOT
} mpm_child_status;

/**
 * Allow a module to remain aware of MPM child process state changes,
 * along with the generation and scoreboard slot of the process changing
 * state.
 *
 * With some MPMs (event and worker), an active MPM child process may lose
 * its scoreboard slot if the child process is exiting and the scoreboard
 * slot is needed by other processes.  When this occurs, the hook will be
 * called with the MPM_CHILD_LOST_SLOT state.
 *
 * @param s The main server_rec.
 * @param pid The id of the MPM child process.
 * @param gen The server generation of that child process.
 * @param slot The scoreboard slot number, or -1.  It will be -1 when an
 * MPM child process exits, and that child had previously lost its
 * scoreboard slot.
 * @param state One of the mpm_child_status values.  Modules should ignore
 * unrecognized values.
 * @ingroup hooks
 */
AP_DECLARE_HOOK(void,child_status,(server_rec *s, pid_t pid, ap_generation_t gen,
                                   int slot, mpm_child_status state))

/**
 * Allow a module to be notified when the last child process of a generation
 * exits.
 *
 * @param s The main server_rec.
 * @param gen The server generation which is now completely finished.
 * @ingroup hooks
 */
AP_DECLARE_HOOK(void,end_generation,(server_rec *s, ap_generation_t gen))

/* Defining GPROF when compiling uses the moncontrol() function to
 * disable gprof profiling in the parent, and enable it only for
 * request processing in children (or in one_process mode).  It's
 * absolutely required to get useful gprof results under linux
 * because the profile itimers and such are disabled across a
 * fork().  It's probably useful elsewhere as well.
 */
#ifdef GPROF
extern void moncontrol(int);
#define AP_MONCONTROL(x) moncontrol(x)
#else
#define AP_MONCONTROL(x)
#endif

#ifdef AP_ENABLE_EXCEPTION_HOOK
typedef struct ap_exception_info_t {
    int sig;
    pid_t pid;
} ap_exception_info_t;

/**
 * Run the fatal_exception hook for each module; this hook is run
 * from some MPMs in the event of a child process crash, if the
 * server was built with --enable-exception-hook and the
 * EnableExceptionHook directive is On.
 * @param ei information about the exception
 * @ingroup hooks
 */
AP_DECLARE_HOOK(int,fatal_exception,(ap_exception_info_t *ei))
#endif /*AP_ENABLE_EXCEPTION_HOOK*/

#ifdef __cplusplus
}
#endif

#endif
/** @} */
