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
 * @file  scoreboard.h
 * @brief Apache scoreboard library
 */

#ifndef APACHE_SCOREBOARD_H
#define APACHE_SCOREBOARD_H

#ifdef __cplusplus
extern "C" {
#endif

#if APR_HAVE_SYS_TIME_H
#include <sys/time.h>
#include <sys/times.h>
#endif

#include "ap_config.h"
#include "http_config.h"
#include "apr_thread_proc.h"
#include "apr_portable.h"
#include "apr_shm.h"
#include "apr_optional.h"

/* Scoreboard file, if there is one */
#ifndef DEFAULT_SCOREBOARD
#define DEFAULT_SCOREBOARD "logs/apache_runtime_status"
#endif

/* Scoreboard info on a process is, for now, kept very brief ---
 * just status value and pid (the latter so that the caretaker process
 * can properly update the scoreboard when a process dies).  We may want
 * to eventually add a separate set of long_score structures which would
 * give, for each process, the number of requests serviced, and info on
 * the current, or most recent, request.
 *
 * Status values:
 */

#define SERVER_DEAD 0
#define SERVER_STARTING 1       /* Server Starting up */
#define SERVER_READY 2          /* Waiting for connection (or accept() lock) */
#define SERVER_BUSY_READ 3      /* Reading a client request */
#define SERVER_BUSY_WRITE 4     /* Processing a client request */
#define SERVER_BUSY_KEEPALIVE 5 /* Waiting for more requests via keepalive */
#define SERVER_BUSY_LOG 6       /* Logging the request */
#define SERVER_BUSY_DNS 7       /* Looking up a hostname */
#define SERVER_CLOSING 8        /* Closing the connection */
#define SERVER_GRACEFUL 9       /* server is gracefully finishing request */
#define SERVER_IDLE_KILL 10     /* Server is cleaning up idle children. */
#define SERVER_NUM_STATUS 11    /* number of status settings */

/* Type used for generation indices.  Startup and every restart cause a
 * new generation of children to be spawned.  Children within the same
 * generation share the same configuration information -- pointers to stuff
 * created at config time in the parent are valid across children.  However,
 * this can't work effectively with non-forked architectures.  So while the
 * arrays in the scoreboard never change between the parent and forked
 * children, so they do not require shm storage, the contents of the shm
 * may contain no pointers.
 */
typedef int ap_generation_t;

/* Is the scoreboard shared between processes or not?
 * Set by the MPM when the scoreboard is created.
 */
typedef enum {
    SB_NOT_SHARED = 1,
    SB_SHARED = 2
} ap_scoreboard_e;

/* stuff which is worker specific */
typedef struct worker_score worker_score;
struct worker_score {
#if APR_HAS_THREADS
    apr_os_thread_t tid;
#endif
    int thread_num;
    /* With some MPMs (e.g., worker), a worker_score can represent
     * a thread in a terminating process which is no longer
     * represented by the corresponding process_score.  These MPMs
     * should set pid and generation fields in the worker_score.
     */
    pid_t pid;
    ap_generation_t generation;
    unsigned char status;
    unsigned short conn_count;
    apr_off_t     conn_bytes;
    unsigned long access_count;
    apr_off_t     bytes_served;
    unsigned long my_access_count;
    apr_off_t     my_bytes_served;
    apr_time_t start_time;
    apr_time_t stop_time;
    apr_time_t last_used;
#ifdef HAVE_TIMES
    struct tms times;
#endif
    char client[32];            /* DEPRECATED: Keep 'em small... */
    char request[64];           /* We just want an idea... */
    char vhost[32];             /* What virtual host is being accessed? */
    char protocol[16];          /* What protocol is used on the connection? */
    apr_time_t duration;
    char client64[64];
};

typedef struct {
    int             server_limit;
    int             thread_limit;
    ap_generation_t running_generation; /* the generation of children which
                                         * should still be serving requests.
                                         */
    apr_time_t restart_time;
#ifdef HAVE_TIMES
    struct tms times;
#endif
} global_score;

/* stuff which the parent generally writes and the children rarely read */
typedef struct process_score process_score;
struct process_score {
    pid_t pid;
    ap_generation_t generation; /* generation of this child */
    char quiescing;         /* the process whose pid is stored above is
                             * going down gracefully
                             */
    char not_accepting;     /* the process is busy and is not accepting more
                             * connections (for async MPMs)
                             */
    apr_uint32_t connections;       /* total connections (for async MPMs) */
    apr_uint32_t write_completion;  /* async connections doing write completion */
    apr_uint32_t lingering_close;   /* async connections in lingering close */
    apr_uint32_t keep_alive;        /* async connections in keep alive */
    apr_uint32_t suspended;         /* connections suspended by some module */
    int bucket;  /* Listener bucket used by this child; this field is DEPRECATED
                  * and no longer updated by the MPMs (i.e. always zero).
                  */
};

/* Scoreboard is now in 'local' memory, since it isn't updated once created,
 * even in forked architectures.  Child created-processes (non-fork) will
 * set up these indices into the (possibly relocated) shmem records.
 */
typedef struct {
    global_score *global;
    process_score *parent;
    worker_score **servers;
} scoreboard;

typedef struct ap_sb_handle_t ap_sb_handle_t;

/*
 * Creation and deletion (internal)
 */
int ap_create_scoreboard(apr_pool_t *p, ap_scoreboard_e t);
apr_status_t ap_cleanup_scoreboard(void *d);

/*
 * APIs for MPMs and other modules
 */
AP_DECLARE(int) ap_exists_scoreboard_image(void);
AP_DECLARE(void) ap_increment_counts(ap_sb_handle_t *sbh, request_rec *r);
AP_DECLARE(void) ap_set_conn_count(ap_sb_handle_t *sb, request_rec *r, unsigned short conn_count);

AP_DECLARE(apr_status_t) ap_reopen_scoreboard(apr_pool_t *p, apr_shm_t **shm, int detached);
AP_DECLARE(void) ap_init_scoreboard(void *shared_score);
AP_DECLARE(int) ap_calc_scoreboard_size(void);

AP_DECLARE(void) ap_create_sb_handle(ap_sb_handle_t **new_sbh, apr_pool_t *p,
                                     int child_num, int thread_num);
AP_DECLARE(void) ap_update_sb_handle(ap_sb_handle_t *sbh,
                                     int child_num, int thread_num);

AP_DECLARE(int) ap_find_child_by_pid(apr_proc_t *pid);
AP_DECLARE(int) ap_update_child_status(ap_sb_handle_t *sbh, int status, request_rec *r);
AP_DECLARE(int) ap_update_child_status_from_indexes(int child_num, int thread_num,
                                                    int status, request_rec *r);
AP_DECLARE(int) ap_update_child_status_from_conn(ap_sb_handle_t *sbh, int status, conn_rec *c);
AP_DECLARE(int) ap_update_child_status_from_server(ap_sb_handle_t *sbh, int status, 
                                                   conn_rec *c, server_rec *s);
AP_DECLARE(int) ap_update_child_status_descr(ap_sb_handle_t *sbh, int status, const char *descr);

AP_DECLARE(void) ap_time_process_request(ap_sb_handle_t *sbh, int status);

AP_DECLARE(int) ap_update_global_status(void);

AP_DECLARE(worker_score *) ap_get_scoreboard_worker(ap_sb_handle_t *sbh);

/** Return a pointer to the worker_score for a given child, thread pair.
 * @param child_num The child number.
 * @param thread_num The thread number.
 * @return A pointer to the worker_score structure.
 * @deprecated This function is deprecated, use ap_copy_scoreboard_worker instead. */
AP_DECLARE(worker_score *) ap_get_scoreboard_worker_from_indexes(int child_num,
                                                                int thread_num);

/** Copy the contents of a worker scoreboard entry.  The contents of
 * the worker_score structure are copied verbatim into the dest
 * structure.
 * @param dest Output parameter.
 * @param child_num The child number.
 * @param thread_num The thread number.
 */
AP_DECLARE(void) ap_copy_scoreboard_worker(worker_score *dest,
                                           int child_num, int thread_num);

AP_DECLARE(process_score *) ap_get_scoreboard_process(int x);
AP_DECLARE(global_score *) ap_get_scoreboard_global(void);

AP_DECLARE_DATA extern scoreboard *ap_scoreboard_image;
AP_DECLARE_DATA extern const char *ap_scoreboard_fname;
AP_DECLARE_DATA extern int ap_extended_status;
AP_DECLARE_DATA extern int ap_mod_status_reqtail;

/*
 * Command handlers [internal]
 */
const char *ap_set_scoreboard(cmd_parms *cmd, void *dummy, const char *arg);
const char *ap_set_extended_status(cmd_parms *cmd, void *dummy, int arg);
const char *ap_set_reqtail(cmd_parms *cmd, void *dummy, int arg);

/* Hooks */
/**
  * Hook for post scoreboard creation, pre mpm.
  * @param p       Apache pool to allocate from.
  * @param sb_type
  * @ingroup hooks
  * @return OK or DECLINE on success; anything else is a error
  */
AP_DECLARE_HOOK(int, pre_mpm, (apr_pool_t *p, ap_scoreboard_e sb_type))

/* for time_process_request() in http_main.c */
#define START_PREQUEST 1
#define STOP_PREQUEST  2

#ifdef __cplusplus
}
#endif

#endif  /* !APACHE_SCOREBOARD_H */
