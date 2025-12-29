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

#ifndef MOD_XML2ENC
#define MOD_XML2ENC

#define ENCIO_INPUT 0x01
#define ENCIO_OUTPUT 0x02
#define ENCIO_INPUT_CHECKS 0x04
#define ENCIO (ENCIO_INPUT|ENCIO_OUTPUT|ENCIO_INPUT_CHECKS)
#define ENCIO_SKIPTO 0x10

/* declarations to deal with WIN32 compile-flag-in-source-code crap */
#if !defined(WIN32)
#define XML2ENC_DECLARE(type)            type
#define XML2ENC_DECLARE_NONSTD(type)     type
#define XML2ENC_DECLARE_DATA
#elif defined(XML2ENC_DECLARE_STATIC)
#define XML2ENC_DECLARE(type)            type __stdcall
#define XML2ENC_DECLARE_NONSTD(type)     type
#define XML2ENC_DECLARE_DATA
#elif defined(XML2ENC_DECLARE_EXPORT)
#define XML2ENC_DECLARE(type)            __declspec(dllexport) type __stdcall
#define XML2ENC_DECLARE_NONSTD(type)     __declspec(dllexport) type
#define XML2ENC_DECLARE_DATA             __declspec(dllexport)
#else
#define XML2ENC_DECLARE(type)            __declspec(dllimport) type __stdcall
#define XML2ENC_DECLARE_NONSTD(type)     __declspec(dllimport) type
#define XML2ENC_DECLARE_DATA             __declspec(dllimport)
#endif

APR_DECLARE_OPTIONAL_FN(apr_status_t, xml2enc_charset,
                        (request_rec* r, xmlCharEncoding* enc,
                         const char** cenc));

APR_DECLARE_OPTIONAL_FN(apr_status_t, xml2enc_filter,
                        (request_rec* r, const char* enc, unsigned int mode));

APR_DECLARE_EXTERNAL_HOOK(xml2enc, XML2ENC, int, preprocess,
                          (ap_filter_t *f, char** bufp, apr_size_t* bytesp))

#endif
