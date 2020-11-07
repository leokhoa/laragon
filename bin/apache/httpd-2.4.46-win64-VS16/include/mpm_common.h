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

/* The purpose of this file is to store the code that MOST mpm's will need
 * this does not mean a function only goes into this file if every MPM needs
 * it.  It means that if a function is needed by more than one MPM, and
 * future maintenance would be served by making the code common, then the
 * function belongs here.
 *
 * This is going in src/main because it is not platform specific, it is
 * specific to multi-process servers, but NOT to Unix.  Which is why it
 * does not belong in src/os/unix
 */

/**
 * @file  mpm_common.h
 * @brief Multi-Processing Modules functions
 *
 * @defgroup APACHE_MPM Multi-Processing Modules
 * @ingroup  APACHE
 * @{
 */

#ifndef APACHE_MPM_COMMON_H
#define APACHE_MPM_COMMON_H

#include "ap_config.h"
#include "ap_mpm.h"
#include "scoreboard.h"

#if APR_HAVE_NETINET_TCP_H
#include <netinet/tcp.h>    /* for TCP_NODELAY */
#endif

#include "apr_proc_mutex.h"

#ifdef __cplusplus
extern "C" {
#endif

/* The maximum length of the queue of pending connections, as defined
 * by listen(2).  Under some systems, it should be increased if you
 * are experiencing a heavy TCP SYN flood attack.
 *
 * It defaults to 511 instead of 512 because some systems store it
 * as an 8-bit datatype; 512 truncated to 8-bits is 0, while 511 is
 * 255 when truncated.
 */
#ifndef DEFAULT_LISTENBACKLOG
#define DEFAULT_LISTENBACKLOG 511
#endif

/* Signal used to gracefully restart */
#define AP_SIG_GRACEFUL SIGUSR1

/* Signal used to gracefully restart (without SIG prefix) */
#define AP_SIG_GRACEFUL_SHORT USR1

/* Signal used to gracefully restart (as a quoted string) */
#define AP_SIG_GRACEFUL_STRING "SIGUSR1"

/* Signal used to gracefully stop */
#define AP_SIG_GRACEFUL_STOP SIGWINCH

/* Signal used to gracefully stop (without SIG prefix) */
#define AP_SIG_GRACEFUL_STOP_SHORT WINCH

/* Signal used to gracefully stop (as a quoted string) */
#define AP_SIG_GRACEFUL_STOP_STRING "SIGWINCH"

/**
 * Callback function used for ap_reclaim_child_processes() and
 * ap_relieve_child_processes().  The callback function will be
 * called for each terminated child process.
 */
typedef void ap_reclaim_callback_fn_t(int childnum, pid_t pid,
                                      ap_generation_t gen);

#if (!defined(WIN32) && !defined(NETWARE)) || defined(DOXYGEN)
/**
 * Make sure all child processes that have been spawned by the parent process
 * have died.  This includes process registered as "other_children".
 *
 * @param terminate Either 1 or 0.  If 1, send the child processes SIGTERM
 *        each time through the loop.  If 0, give the process time to die
 *        on its own before signalling it.
 * @param mpm_callback Callback invoked for each dead child process
 *
 * @note The MPM child processes which are reclaimed are those listed
 * in the scoreboard as well as those currently registered via
 * ap_register_extra_mpm_process().
 */
AP_DECLARE(void) ap_reclaim_child_processes(int terminate,
                                            ap_reclaim_callback_fn_t *mpm_callback);

/**
 * Catch any child processes that have been spawned by the parent process
 * which have exited. This includes processes registered as "other_children".
 *
 * @param mpm_callback Callback invoked for each dead child process

 * @note The MPM child processes which are relieved are those listed
 * in the scoreboard as well as those currently registered via
 * ap_register_extra_mpm_process().
 */
AP_DECLARE(void) ap_relieve_child_processes(ap_reclaim_callback_fn_t *mpm_callback);

/**
 * Tell ap_reclaim_child_processes() and ap_relieve_child_processes() about
 * an MPM child process which has no entry in the scoreboard.
 * @param pid The process id of an MPM child process which should be
 * reclaimed when ap_reclaim_child_processes() is called.
 * @param gen The generation of this MPM child process.
 *
 * @note If an extra MPM child process terminates prior to calling
 * ap_reclaim_child_processes(), remove it from the list of such processes
 * by calling ap_unregister_extra_mpm_process().
 */
AP_DECLARE(void) ap_register_extra_mpm_process(pid_t pid, ap_generation_t gen);

/**
 * Unregister an MPM child process which was previously registered by a
 * call to ap_register_extra_mpm_process().
 * @param pid The process id of an MPM child process which no longer needs to
 * be reclaimed.
 * @param old_gen Set to the server generation of the process, if found.
 * @return 1 if the process was found and removed, 0 otherwise
 */
AP_DECLARE(int) ap_unregister_extra_mpm_process(pid_t pid, ap_generation_t *old_gen);

/**
 * Safely signal an MPM child process, if the process is in the
 * current process group.  Otherwise fail.
 * @param pid the process id of a child process to signal
 * @param sig the signal number to send
 * @return APR_SUCCESS if signal is sent, otherwise an error as per kill(3);
 * APR_EINVAL is returned if passed either an invalid (< 1) pid, or if
 * the pid is not in the current process group
 */
AP_DECLARE(apr_status_t) ap_mpm_safe_kill(pid_t pid, int sig);

/**
 * Log why a child died to the error log, if the child died without the
 * parent signalling it.
 * @param pid The child that has died
 * @param why The return code of the child process
 * @param status The status returned from ap_wait_or_timeout
 * @return 0 on success, APEXIT_CHILDFATAL if MPM should terminate
 */
AP_DECLARE(int) ap_process_child_status(apr_proc_t *pid, apr_exit_why_e why, int status);

AP_DECLARE(apr_status_t) ap_fatal_signal_setup(server_rec *s, apr_pool_t *in_pconf);
AP_DECLARE(apr_status_t) ap_fatal_signal_child_setup(server_rec *s);

#endif /* (!WIN32 && !NETWARE) || DOXYGEN */

/**
 * Pool cleanup for end-generation hook implementation
 * (core httpd function)
 */
apr_status_t ap_mpm_end_gen_helper(void *unused);

/**
 * Run the monitor hook (once every ten calls), determine if any child
 * process has died and, if none died, sleep one second.
 * @param status The return code if a process has died
 * @param exitcode The returned exit status of the child, if a child process
 *                 dies, or the signal that caused the child to die.
 * @param ret The process id of the process that died
 * @param p The pool to allocate out of
 * @param s The server_rec to pass
 */
AP_DECLARE(void) ap_wait_or_timeout(apr_exit_why_e *status, int *exitcode,
                                    apr_proc_t *ret, apr_pool_t *p, 
                                    server_rec *s);

#if defined(TCP_NODELAY)
/**
 * Turn off the nagle algorithm for the specified socket.  The nagle algorithm
 * says that we should delay sending partial packets in the hopes of getting
 * more data.  There are bad interactions between persistent connections and
 * Nagle's algorithm that have severe performance penalties.
 * @param s The socket to disable nagle for.
 */
void ap_sock_disable_nagle(apr_socket_t *s);
#else
#define ap_sock_disable_nagle(s)        /* NOOP */
#endif

#ifdef HAVE_GETPWNAM
/**
 * Convert a username to a numeric ID
 * @param name The name to convert
 * @return The user id corresponding to a name
 * @fn uid_t ap_uname2id(const char *name)
 */
AP_DECLARE(uid_t) ap_uname2id(const char *name);
#endif

#ifdef HAVE_GETGRNAM
/**
 * Convert a group name to a numeric ID
 * @param name The name to convert
 * @return The group id corresponding to a name
 * @fn gid_t ap_gname2id(const char *name)
 */
AP_DECLARE(gid_t) ap_gname2id(const char *name);
#endif

#ifndef HAVE_INITGROUPS
/**
 * The initgroups() function initializes the group access list by reading the
 * group database /etc/group and using all groups of which user is a member.
 * The additional group basegid is also added to the list.
 * @param name The user name - must be non-NULL
 * @param basegid The basegid to add
 * @return returns 0 on success
 * @fn int initgroups(const char *name, gid_t basegid)
 */
int initgroups(const char *name, gid_t basegid);
#endif

#if (!defined(WIN32) && !defined(NETWARE)) || defined(DOXYGEN)

typedef struct ap_pod_t ap_pod_t;

struct ap_pod_t {
    apr_file_t *pod_in;
    apr_file_t *pod_out;
    apr_pool_t *p;
};

/**
 * Open the pipe-of-death.  The pipe of death is used to tell all child
 * processes that it is time to die gracefully.
 * @param p The pool to use for allocating the pipe
 * @param pod the pipe-of-death that is created.
 */
AP_DECLARE(apr_status_t) ap_mpm_pod_open(apr_pool_t *p, ap_pod_t **pod);

/**
 * Check the pipe to determine if the process has been signalled to die.
 */
AP_DECLARE(apr_status_t) ap_mpm_pod_check(ap_pod_t *pod);

/**
 * Close the pipe-of-death
 *
 * @param pod the pipe-of-death to close.
 */
AP_DECLARE(apr_status_t) ap_mpm_pod_close(ap_pod_t *pod);

/**
 * Write data to the pipe-of-death, signalling that one child process
 * should die.
 * @param pod the pipe-of-death to write to.
 */
AP_DECLARE(apr_status_t) ap_mpm_pod_signal(ap_pod_t *pod);

/**
 * Write data to the pipe-of-death, signalling that all child process
 * should die.
 * @param pod The pipe-of-death to write to.
 * @param num The number of child processes to kill
 */
AP_DECLARE(void) ap_mpm_pod_killpg(ap_pod_t *pod, int num);

#define AP_MPM_PODX_RESTART_CHAR '$'
#define AP_MPM_PODX_GRACEFUL_CHAR '!'

typedef enum { AP_MPM_PODX_NORESTART, AP_MPM_PODX_RESTART, AP_MPM_PODX_GRACEFUL } ap_podx_restart_t;

/**
 * Open the extended pipe-of-death.
 * @param p The pool to use for allocating the pipe
 * @param pod The pipe-of-death that is created.
 */
AP_DECLARE(apr_status_t) ap_mpm_podx_open(apr_pool_t *p, ap_pod_t **pod);

/**
 * Check the extended pipe to determine if the process has been signalled to die.
 */
AP_DECLARE(int) ap_mpm_podx_check(ap_pod_t *pod);

/**
 * Close the pipe-of-death
 *
 * @param pod The pipe-of-death to close.
 */
AP_DECLARE(apr_status_t) ap_mpm_podx_close(ap_pod_t *pod);

/**
 * Write data to the extended pipe-of-death, signalling that one child process
 * should die.
 * @param pod the pipe-of-death to write to.
 * @param graceful restart-type
 */
AP_DECLARE(apr_status_t) ap_mpm_podx_signal(ap_pod_t *pod,
                                            ap_podx_restart_t graceful);

/**
 * Write data to the extended pipe-of-death, signalling that all child process
 * should die.
 * @param pod The pipe-of-death to write to.
 * @param num The number of child processes to kill
 * @param graceful restart-type
 */
AP_DECLARE(void) ap_mpm_podx_killpg(ap_pod_t *pod, int num,
                                    ap_podx_restart_t graceful);

#endif /* (!WIN32 && !NETWARE) || DOXYGEN */

/**
 * Check that exactly one MPM is loaded
 * Returns NULL if yes, error string if not.
 */
AP_DECLARE(const char *) ap_check_mpm(void);

/*
 * These data members are common to all mpms. Each new mpm
 * should either use the appropriate ap_mpm_set_* function
 * in their command table or create their own for custom or
 * OS specific needs. These should work for most.
 */

/**
 * The maximum number of requests each child thread or
 * process handles before dying off
 */
AP_DECLARE_DATA extern int ap_max_requests_per_child;
const char *ap_mpm_set_max_requests(cmd_parms *cmd, void *dummy,
                                    const char *arg);

/**
 * The filename used to store the process id.
 */
AP_DECLARE_DATA extern const char *ap_pid_fname;
const char *ap_mpm_set_pidfile(cmd_parms *cmd, void *dummy,
                               const char *arg);
void ap_mpm_dump_pidfile(apr_pool_t *p, apr_file_t *out);

/*
 * The directory that the server changes directory to dump core.
 */
AP_DECLARE_DATA extern char ap_coredump_dir[MAX_STRING_LEN];
AP_DECLARE_DATA extern int ap_coredumpdir_configured;
const char *ap_mpm_set_coredumpdir(cmd_parms *cmd, void *dummy,
                                   const char *arg);

/**
 * Set the timeout period for a graceful shutdown.
 */
AP_DECLARE_DATA extern int ap_graceful_shutdown_timeout;
AP_DECLARE(const char *)ap_mpm_set_graceful_shutdown(cmd_parms *cmd, void *dummy,
                                         const char *arg);
#define AP_GRACEFUL_SHUTDOWN_TIMEOUT_COMMAND \
AP_INIT_TAKE1("GracefulShutdownTimeout", ap_mpm_set_graceful_shutdown, NULL, \
              RSRC_CONF, "Maximum time in seconds to wait for child "        \
              "processes to complete transactions during shutdown")


int ap_signal_server(int *, apr_pool_t *);
void ap_mpm_rewrite_args(process_rec *);

AP_DECLARE_DATA extern apr_uint32_t ap_max_mem_free;
extern const char *ap_mpm_set_max_mem_free(cmd_parms *cmd, void *dummy,
                                           const char *arg);

AP_DECLARE_DATA extern apr_size_t ap_thread_stacksize;
extern const char *ap_mpm_set_thread_stacksize(cmd_parms *cmd, void *dummy,
                                               const char *arg);

/* core's implementation of child_status hook */
extern void ap_core_child_status(server_rec *s, pid_t pid, ap_generation_t gen,
                                 int slot, mpm_child_status status);

#if defined(AP_ENABLE_EXCEPTION_HOOK) && AP_ENABLE_EXCEPTION_HOOK
extern const char *ap_mpm_set_exception_hook(cmd_parms *cmd, void *dummy,
                                             const char *arg);
#endif

AP_DECLARE_HOOK(int,monitor,(apr_pool_t *p, server_rec *s))

/* register modules that undertake to manage system security */
AP_DECLARE(int) ap_sys_privileges_handlers(int inc);
AP_DECLARE_HOOK(int, drop_privileges, (apr_pool_t * pchild, server_rec * s))

/* implement the ap_mpm_query() function
 * The MPM should return OK+APR_ENOTIMPL for any unimplemented query codes;
 * modules which intercede for specific query codes should DECLINE for others.
 */
AP_DECLARE_HOOK(int, mpm_query, (int query_code, int *result, apr_status_t *rv))

/* register the specified callback */
AP_DECLARE_HOOK(apr_status_t, mpm_register_timed_callback,
                (apr_time_t t, ap_mpm_callback_fn_t *cbfn, void *baton))

/* get MPM name (e.g., "prefork" or "event") */
AP_DECLARE_HOOK(const char *,mpm_get_name,(void))

/**
 * Notification that connection handling is suspending (disassociating from the
 * current thread)
 * @param c The current connection
 * @param r The current request, or NULL if there is no active request
 * @ingroup hooks
 * @see ap_hook_resume_connection
 * @note This hook is not implemented by MPMs like Prefork and Worker which 
 * handle all processing of a particular connection on the same thread.
 * @note This hook will be called on the thread that was previously
 * processing the connection.
 * @note This hook is not called at the end of connection processing.  This
 * hook only notifies a module when processing of an active connection is
 * suspended.
 * @note Resumption and subsequent suspension of a connection solely to perform
 * I/O by the MPM, with no execution of non-MPM code, may not necessarily result
 * in a call to this hook.
 */
AP_DECLARE_HOOK(void, suspend_connection,
                (conn_rec *c, request_rec *r))

/**
 * Notification that connection handling is resuming (associating with a thread)
 * @param c The current connection
 * @param r The current request, or NULL if there is no active request
 * @ingroup hooks
 * @see ap_hook_suspend_connection
 * @note This hook is not implemented by MPMs like Prefork and Worker which 
 * handle all processing of a particular connection on the same thread.
 * @note This hook will be called on the thread that will resume processing
 * the connection.
 * @note This hook is not called at the beginning of connection processing.
 * This hook only notifies a module when processing resumes for a
 * previously-suspended connection.
 * @note Resumption and subsequent suspension of a connection solely to perform
 * I/O by the MPM, with no execution of non-MPM code, may not necessarily result
 * in a call to this hook.
 */
AP_DECLARE_HOOK(void, resume_connection,
                (conn_rec *c, request_rec *r))

/* mutex type string for accept mutex, if any; MPMs should use the
 * same mutex type for ease of configuration
 */
#define AP_ACCEPT_MUTEX_TYPE "mpm-accept"

/* internal pre-config logic for MPM-related settings, callable only from
 * core's pre-config hook
 */
void mpm_common_pre_config(apr_pool_t *pconf);

#ifdef __cplusplus
}
#endif

#endif /* !APACHE_MPM_COMMON_H */
/** @} */
