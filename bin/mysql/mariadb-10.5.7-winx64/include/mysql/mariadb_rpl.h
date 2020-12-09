/* Copyright (C) 2018 MariaDB Corporation AB 

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
 
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
 
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02111-1301, USA */
#ifndef _mariadb_rpl_h_
#define _mariadb_rpl_h_

#ifdef	__cplusplus
extern "C" {
#endif

#include <stdint.h>

#define MARIADB_RPL_VERSION 0x0001
#define MARIADB_RPL_REQUIRED_VERSION 0x0001

/* Protocol flags */
#define MARIADB_RPL_BINLOG_DUMP_NON_BLOCK 1
#define MARIADB_RPL_BINLOG_SEND_ANNOTATE_ROWS 2
#define MARIADB_RPL_IGNORE_HEARTBEAT (1 << 17)

#define EVENT_HEADER_OFS 20

#define FL_GROUP_COMMIT_ID 2
#define FL_STMT_END 1

#define LOG_EVENT_ARTIFICIAL_F 0x20


/* Options */
enum mariadb_rpl_option {
  MARIADB_RPL_FILENAME,       /* Filename and length */
  MARIADB_RPL_START,          /* Start position */
  MARIADB_RPL_SERVER_ID,      /* Server ID */
  MARIADB_RPL_FLAGS,          /* Protocol flags */
  MARIADB_RPL_GTID_CALLBACK,  /* GTID callback function */
  MARIADB_RPL_GTID_DATA,      /* GTID data */
  MARIADB_RPL_BUFFER
};

/* Event types: From MariaDB Server sql/log_event.h */
enum mariadb_rpl_event {
  UNKNOWN_EVENT= 0,
  START_EVENT_V3= 1,
  QUERY_EVENT= 2,
  STOP_EVENT= 3,
  ROTATE_EVENT= 4,
  INTVAR_EVENT= 5,
  LOAD_EVENT= 6,
  SLAVE_EVENT= 7,
  CREATE_FILE_EVENT= 8,
  APPEND_BLOCK_EVENT= 9,
  EXEC_LOAD_EVENT= 10,
  DELETE_FILE_EVENT= 11,
  NEW_LOAD_EVENT= 12,
  RAND_EVENT= 13,
  USER_VAR_EVENT= 14,
  FORMAT_DESCRIPTION_EVENT= 15,
  XID_EVENT= 16,
  BEGIN_LOAD_QUERY_EVENT= 17,
  EXECUTE_LOAD_QUERY_EVENT= 18,
  TABLE_MAP_EVENT = 19,

  PRE_GA_WRITE_ROWS_EVENT = 20, /* deprecated */
  PRE_GA_UPDATE_ROWS_EVENT = 21, /* deprecated */
  PRE_GA_DELETE_ROWS_EVENT = 22, /* deprecated */

  WRITE_ROWS_EVENT_V1 = 23,
  UPDATE_ROWS_EVENT_V1 = 24,
  DELETE_ROWS_EVENT_V1 = 25,
  INCIDENT_EVENT= 26,
  HEARTBEAT_LOG_EVENT= 27,
  IGNORABLE_LOG_EVENT= 28,
  ROWS_QUERY_LOG_EVENT= 29,
  WRITE_ROWS_EVENT = 30,
  UPDATE_ROWS_EVENT = 31,
  DELETE_ROWS_EVENT = 32,
  GTID_LOG_EVENT= 33,
  ANONYMOUS_GTID_LOG_EVENT= 34,
  PREVIOUS_GTIDS_LOG_EVENT= 35,
  TRANSACTION_CONTEXT_EVENT= 36,
  VIEW_CHANGE_EVENT= 37,
  XA_PREPARE_LOG_EVENT= 38,

  /*
    Add new events here - right above this comment!
    Existing events (except ENUM_END_EVENT) should never change their numbers
  */

  /* New MySQL/Sun events are to be added right above this comment */
  MYSQL_EVENTS_END,

  MARIA_EVENTS_BEGIN= 160,
  ANNOTATE_ROWS_EVENT= 160,
  BINLOG_CHECKPOINT_EVENT= 161,
  GTID_EVENT= 162,
  GTID_LIST_EVENT= 163,
  START_ENCRYPTION_EVENT= 164,
  QUERY_COMPRESSED_EVENT = 165,
  WRITE_ROWS_COMPRESSED_EVENT_V1 = 166,
  UPDATE_ROWS_COMPRESSED_EVENT_V1 = 167,
  DELETE_ROWS_COMPRESSED_EVENT_V1 = 168,
  WRITE_ROWS_COMPRESSED_EVENT = 169,
  UPDATE_ROWS_COMPRESSED_EVENT = 170,
  DELETE_ROWS_COMPRESSED_EVENT = 171,

  /* Add new MariaDB events here - right above this comment!  */

  ENUM_END_EVENT /* end marker */
};

typedef struct {
  char *str;
  size_t length;
} MARIADB_STRING;

enum mariadb_row_event_type {
  WRITE_ROWS= 0,
  UPDATE_ROWS= 1,
  DELETE_ROWS= 2
};

/* Global transaction id */
typedef struct st_mariadb_gtid {
  unsigned int domain_id;
  unsigned int server_id;
  unsigned long long sequence_nr;
} MARIADB_GTID;

/* Generic replication handle */
typedef struct st_mariadb_rpl {
  unsigned int version;
  MYSQL *mysql;
  char *filename;
  uint32_t filename_length;
  unsigned char *buffer;
  unsigned long buffer_size;
  uint32_t server_id;
  unsigned long start_position;
  uint32_t flags;
  uint8_t fd_header_len; /* header len from last format description event */
  uint8_t use_checksum;
} MARIADB_RPL;

/* Event header */
struct st_mariadb_rpl_rotate_event {
  unsigned long long position;
  MARIADB_STRING filename;
};

struct st_mariadb_rpl_query_event {
  uint32_t thread_id;
  uint32_t seconds;
  MARIADB_STRING database;
  uint32_t errornr;
  MARIADB_STRING status;
  MARIADB_STRING statement;
};

struct st_mariadb_rpl_gtid_list_event {
  uint32_t gtid_cnt;
  MARIADB_GTID *gtid;
};

struct st_mariadb_rpl_format_description_event
{
  uint16_t format;
  char *server_version;
  uint32_t timestamp;
  uint8_t header_len;
};

struct st_mariadb_rpl_checkpoint_event {
  MARIADB_STRING filename;
};

struct st_mariadb_rpl_xid_event {
  uint64_t transaction_nr;
};

struct st_mariadb_rpl_gtid_event {
  uint64_t sequence_nr;
  uint32_t domain_id;
  uint8_t flags;
  uint64_t commit_id;
};

struct st_mariadb_rpl_annotate_rows_event {
  MARIADB_STRING statement;
};

struct st_mariadb_rpl_table_map_event {
  unsigned long long table_id;
  MARIADB_STRING database;
  MARIADB_STRING table;
  unsigned int column_count;
  MARIADB_STRING column_types;
  MARIADB_STRING metadata;
  char *null_indicator;
};

struct st_mariadb_rpl_rand_event {
  unsigned long long first_seed;
  unsigned long long second_seed;
};

struct st_mariadb_rpl_encryption_event {
  char scheme;
  unsigned int key_version;
  char *nonce;
};

struct st_mariadb_rpl_intvar_event {
  char type;
  unsigned long long value;
};

struct st_mariadb_rpl_uservar_event {
  MARIADB_STRING name;
  uint8_t is_null;
  uint8_t type;
  uint32_t charset_nr;
  MARIADB_STRING value;
  uint8_t flags;
};

struct st_mariadb_rpl_rows_event {
  enum mariadb_row_event_type type;
  uint64_t table_id;
  uint16_t flags;
  uint32_t column_count;
  char *column_bitmap;
  char *column_update_bitmap;
  size_t row_data_size;
  void *row_data;
};

struct st_mariadb_rpl_heartbeat_event {
  uint32_t timestamp;
  uint32_t next_position;
  uint8_t type;
  uint16_t flags;
};

typedef struct st_mariadb_rpl_event
{
  /* common header */
  MA_MEM_ROOT memroot;
  unsigned int checksum;
  char ok;
  enum mariadb_rpl_event event_type;
  unsigned int timestamp;
  unsigned int server_id;
  unsigned int event_length;
  unsigned int next_event_pos;
  unsigned short flags;
  /****************/
  union {
    struct st_mariadb_rpl_rotate_event rotate;
    struct st_mariadb_rpl_query_event query;
    struct st_mariadb_rpl_format_description_event format_description;
    struct st_mariadb_rpl_gtid_list_event gtid_list;
    struct st_mariadb_rpl_checkpoint_event checkpoint;
    struct st_mariadb_rpl_xid_event xid;
    struct st_mariadb_rpl_gtid_event gtid;
    struct st_mariadb_rpl_annotate_rows_event annotate_rows;
    struct st_mariadb_rpl_table_map_event table_map;
    struct st_mariadb_rpl_rand_event rand;
    struct st_mariadb_rpl_encryption_event encryption;
    struct st_mariadb_rpl_intvar_event intvar;
    struct st_mariadb_rpl_uservar_event uservar;
    struct st_mariadb_rpl_rows_event rows;
    struct st_mariadb_rpl_heartbeat_event heartbeat;
  } event;
} MARIADB_RPL_EVENT;

#define mariadb_rpl_init(a) mariadb_rpl_init_ex((a), MARIADB_RPL_VERSION)

/* Function prototypes */
MARIADB_RPL * STDCALL mariadb_rpl_init_ex(MYSQL *mysql, unsigned int version);

int mariadb_rpl_optionsv(MARIADB_RPL *rpl, enum mariadb_rpl_option, ...);
int mariadb_rpl_get_optionsv(MARIADB_RPL *rpl, enum mariadb_rpl_option, ...);

int STDCALL mariadb_rpl_open(MARIADB_RPL *rpl);
void STDCALL mariadb_rpl_close(MARIADB_RPL *rpl);
MARIADB_RPL_EVENT * STDCALL mariadb_rpl_fetch(MARIADB_RPL *rpl, MARIADB_RPL_EVENT *event);
void STDCALL mariadb_free_rpl_event(MARIADB_RPL_EVENT *event);

#ifdef	__cplusplus
}
#endif
#endif
