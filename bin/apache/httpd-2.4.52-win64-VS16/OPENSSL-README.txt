
 Apache HTTP Server 2.4 Limited OpenSSL Distribution

 This binary installation of OpenSSL is a limited distribution of the
 files derived from the OpenSSL project:

   LICENSE.txt (includes openssl LICENSE)
   OPENSSL-NEWS.txt
   OPENSSL-README.txt
   conf\openssl.cnf
   bin\libeay32.dll
   bin\ssleay32.dll
   bin\openssl.exe

 These are the minimal libraries and tools required to use mod_ssl as 
 distributed with Apache HTTP Server version 2.4.  No library link files, 
 headers or sources are distributed with this binary distribution.  Please 
 refer to the <http://www.openssl.org/> site for complete source or binary 
 distributions.

 These OpenSSL binaries were built for distribution from the U.S. without 
 support for the patented encryption methods IDEA, MDC-2 or RC5.

 The Apache HTTP Project only supports the binary distribution of these files
 and development of the mod_ssl module.  We cannot provide support assistance
 for using or configuring the OpenSSL package or these modules.  Please refer
 all installation and configuration questions to the appropriate forum,
 such as the user supported lists, <http://httpd.apache.org/userslist.html> 
 the Apache HTTP Server user's list or <http://www.openssl.org/support/> the
 OpenSSL support page.

--------------------------------------------------------------------------------


 OpenSSL 1.1.1m 14 Dec 2021

 Copyright (c) 1998-2021 The OpenSSL Project
 Copyright (c) 1995-1998 Eric A. Young, Tim J. Hudson
 All rights reserved.

 DESCRIPTION
 -----------

 The OpenSSL Project is a collaborative effort to develop a robust,
 commercial-grade, fully featured, and Open Source toolkit implementing the
 Transport Layer Security (TLS) protocols (including SSLv3) as well as a
 full-strength general purpose cryptographic library.

 OpenSSL is descended from the SSLeay library developed by Eric A. Young
 and Tim J. Hudson.  The OpenSSL toolkit is licensed under a dual-license (the
 OpenSSL license plus the SSLeay license), which means that you are free to
 get and use it for commercial and non-commercial purposes as long as you
 fulfill the conditions of both licenses.

 OVERVIEW
 --------

 The OpenSSL toolkit includes:

 libssl (with platform specific naming):
     Provides the client and server-side implementations for SSLv3 and TLS.

 libcrypto (with platform specific naming):
     Provides general cryptographic and X.509 support needed by SSL/TLS but
     not logically part of it.

 openssl:
     A command line tool that can be used for:
        Creation of key parameters
        Creation of X.509 certificates, CSRs and CRLs
        Calculation of message digests
        Encryption and decryption
        SSL/TLS client and server tests
        Handling of S/MIME signed or encrypted mail
        And more...

 INSTALLATION
 ------------

 See the appropriate file:
        INSTALL         Linux, Unix, Windows, OpenVMS, ...
        NOTES.*         INSTALL addendums for different platforms

 SUPPORT
 -------

 See the OpenSSL website www.openssl.org for details on how to obtain
 commercial technical support. Free community support is available through the
 openssl-users email list (see
 https://www.openssl.org/community/mailinglists.html for further details).

 If you have any problems with OpenSSL then please take the following steps
 first:

    - Download the latest version from the repository
      to see if the problem has already been addressed
    - Configure with no-asm
    - Remove compiler optimization flags

 If you wish to report a bug then please include the following information
 and create an issue on GitHub:

    - OpenSSL version: output of 'openssl version -a'
    - Configuration data: output of 'perl configdata.pm --dump'
    - OS Name, Version, Hardware platform
    - Compiler Details (name, version)
    - Application Details (name, version)
    - Problem Description (steps that will reproduce the problem, if known)
    - Stack Traceback (if the application dumps core)

 Just because something doesn't work the way you expect does not mean it
 is necessarily a bug in OpenSSL. Use the openssl-users email list for this type
 of query.

 HOW TO CONTRIBUTE TO OpenSSL
 ----------------------------

 See CONTRIBUTING

 LEGALITIES
 ----------

 A number of nations restrict the use or export of cryptography. If you
 are potentially subject to such restrictions you should seek competent
 professional legal advice before attempting to develop or distribute
 cryptographic code.
