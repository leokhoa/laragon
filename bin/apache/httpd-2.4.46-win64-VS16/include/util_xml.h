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
 * @file  util_xml.h
 * @brief Apache XML library
 *
 * @defgroup APACHE_CORE_XML XML Library
 * @ingroup  APACHE_CORE
 * @{
 */

#ifndef UTIL_XML_H
#define UTIL_XML_H

#include "apr_xml.h"

#include "httpd.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Get XML post data and parse it.
 * @param   r       The current request
 * @param   pdoc    The XML post data
 * @return HTTP status code
 */
AP_DECLARE(int) ap_xml_parse_input(request_rec *r, apr_xml_doc **pdoc);


#ifdef __cplusplus
}
#endif

#endif /* UTIL_XML_H */
/** @} */
