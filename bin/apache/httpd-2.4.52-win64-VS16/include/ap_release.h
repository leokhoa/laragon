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
 * @file ap_release.h
 * @brief Version Release defines
 */

#ifndef AP_RELEASE_H
#define AP_RELEASE_H

#define AP_SERVER_COPYRIGHT \
  "Copyright 2021 The Apache Software Foundation."

/*
 * The below defines the base string of the Server: header. Additional
 * tokens can be added via the ap_add_version_component() API call.
 *
 * The tokens are listed in order of their significance for identifying the
 * application.
 *
 * "Product tokens should be short and to the point -- use of them for
 * advertizing or other non-essential information is explicitly forbidden."
 *
 * Example: "Apache/1.1.0 MrWidget/0.1-alpha"
 */
#define AP_SERVER_BASEVENDOR "Apache Software Foundation"
#define AP_SERVER_BASEPROJECT "Apache HTTP Server"
#define AP_SERVER_BASEPRODUCT "Apache"

#define AP_SERVER_MAJORVERSION_NUMBER 2
#define AP_SERVER_MINORVERSION_NUMBER 4
#define AP_SERVER_PATCHLEVEL_NUMBER   52
#define AP_SERVER_DEVBUILD_BOOLEAN    0

/* Synchronize the above with docs/manual/style/version.ent */

#if !AP_SERVER_DEVBUILD_BOOLEAN
#define AP_SERVER_ADD_STRING          ""
#else
#ifndef AP_SERVER_ADD_STRING
#define AP_SERVER_ADD_STRING          "-dev"
#endif
#endif

/* APR_STRINGIFY is defined here, and also in apr_general.h, so wrap it */
#ifndef APR_STRINGIFY
/** Properly quote a value as a string in the C preprocessor */
#define APR_STRINGIFY(n) APR_STRINGIFY_HELPER(n)
/** Helper macro for APR_STRINGIFY */
#define APR_STRINGIFY_HELPER(n) #n
#endif

/* keep old macros as well */
#define AP_SERVER_MAJORVERSION  APR_STRINGIFY(AP_SERVER_MAJORVERSION_NUMBER)
#define AP_SERVER_MINORVERSION  APR_STRINGIFY(AP_SERVER_MINORVERSION_NUMBER)
#define AP_SERVER_PATCHLEVEL    APR_STRINGIFY(AP_SERVER_PATCHLEVEL_NUMBER) \
                                AP_SERVER_ADD_STRING

#define AP_SERVER_MINORREVISION AP_SERVER_MAJORVERSION "." AP_SERVER_MINORVERSION
#define AP_SERVER_BASEREVISION  AP_SERVER_MINORREVISION "." AP_SERVER_PATCHLEVEL
#define AP_SERVER_BASEVERSION   AP_SERVER_BASEPRODUCT "/" AP_SERVER_BASEREVISION
#define AP_SERVER_VERSION       AP_SERVER_BASEVERSION

/* macro for Win32 .rc files using numeric csv representation */
#define AP_SERVER_PATCHLEVEL_CSV AP_SERVER_MAJORVERSION_NUMBER, \
                                 AP_SERVER_MINORVERSION_NUMBER, \
                                 AP_SERVER_PATCHLEVEL_NUMBER

#endif
