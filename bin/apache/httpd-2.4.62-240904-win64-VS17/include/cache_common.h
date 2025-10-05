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
 * @file cache_common.h
 * @brief Common Cache structs
 *
 * @defgroup Cache_cache  Cache Functions
 * @ingroup  MOD_CACHE
 * @{
 */

#ifndef CACHE_COMMON_H
#define CACHE_COMMON_H

/* a cache control header breakdown */
typedef struct cache_control {
    unsigned int parsed:1;
    unsigned int cache_control:1;
    unsigned int pragma:1;
    unsigned int no_cache:1;
    unsigned int no_cache_header:1; /* no cache by header match */
    unsigned int no_store:1;
    unsigned int max_age:1;
    unsigned int max_stale:1;
    unsigned int min_fresh:1;
    unsigned int no_transform:1;
    unsigned int only_if_cached:1;
    unsigned int public:1;
    unsigned int private:1;
    unsigned int private_header:1; /* private by header match */
    unsigned int must_revalidate:1;
    unsigned int proxy_revalidate:1;
    unsigned int s_maxage:1;
    unsigned int invalidated:1; /* has this entity been invalidated? */
    apr_int64_t max_age_value; /* if positive, then set */
    apr_int64_t max_stale_value; /* if positive, then set */
    apr_int64_t min_fresh_value; /* if positive, then set */
    apr_int64_t s_maxage_value; /* if positive, then set */
} cache_control_t;

#endif /* CACHE_COMMON_H */
/** @} */
