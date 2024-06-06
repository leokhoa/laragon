
                          Apache HTTP Server

  What is it?
  -----------

  The Apache HTTP Server is a powerful and flexible HTTP/1.1 compliant
  web server.  Originally designed as a replacement for the NCSA HTTP
  Server, it has grown to be the most popular web server on the
  Internet.  As a project of the Apache Software Foundation, the
  developers aim to collaboratively develop and maintain a robust,
  commercial-grade, standards-based server with freely available
  source code.

  The Latest Version
  ------------------

  Details of the latest version can be found on the Apache HTTP
  server project page under http://httpd.apache.org/.

  Documentation
  -------------

  The documentation available as of the date of this release is
  included in HTML format in the docs/manual/ directory.  The most
  up-to-date documentation can be found at
  http://httpd.apache.org/docs/2.4/.

  Installation
  ------------

  Please see the file called INSTALL.  Platform specific notes can be
  found in README.platforms.

  Licensing
  ---------

  Please see the file called LICENSE.

  Cryptographic Software Notice
  -----------------------------

  This distribution may include software that has been designed for use
  with cryptographic software.  The country in which you currently reside
  may have restrictions on the import, possession, use, and/or re-export
  to another country, of encryption software.  BEFORE using any encryption
  software, please check your country's laws, regulations and policies
  concerning the import, possession, or use, and re-export of encryption
  software, to see if this is permitted.  See <http://www.wassenaar.org/>
  for more information.

  The U.S. Government Department of Commerce, Bureau of Industry and
  Security (BIS), has classified this software as Export Commodity 
  Control Number (ECCN) 5D002.C.1, which includes information security
  software using or performing cryptographic functions with asymmetric
  algorithms.  The form and manner of this Apache Software Foundation
  distribution makes it eligible for export under the License Exception
  ENC Technology Software Unrestricted (TSU) exception (see the BIS 
  Export Administration Regulations, Section 740.13) for both object 
  code and source code.

  The following provides more details on the included files that
  may be subject to export controls on cryptographic software:

    Apache httpd 2.0 and later versions include the mod_ssl module under
       modules/ssl/
    for configuring and listening to connections over SSL encrypted
    network sockets by performing calls to a general-purpose encryption
    library, such as OpenSSL or the operating system's platform-specific
    SSL facilities.

    In addition, some versions of apr-util provide an abstract interface
    for symmetrical cryptographic functions that make use of a
    general-purpose encryption library, such as OpenSSL, NSS, or the
    operating system's platform-specific facilities. This interface is
    known as the apr_crypto interface, with implementation beneath the
    /crypto directory. The apr_crypto interface is used by the
    mod_session_crypto module available under
      modules/session
    for optional encryption of session information.

    Some object code distributions of Apache httpd, indicated with the
    word "crypto" in the package name, may include object code for the
    OpenSSL encryption library as distributed in open source form from
    <http://www.openssl.org/source/>.

  The above files are optional and may be removed if the cryptographic
  functionality is not desired or needs to be excluded from redistribution.
  Distribution packages of Apache httpd that include the word "nossl"
  in the package name have been created without the above files and are
  therefore not subject to this notice.

  Contacts
  --------

     o If you want to be informed about new code releases, bug fixes,
       security fixes, general news and information about the Apache server
       subscribe to the apache-announce mailing list as described under
       <http://httpd.apache.org/lists.html#http-announce>

     o If you want freely available support for running Apache please see the
       resources at <http://httpd.apache.org/support.html>

     o If you have a concrete bug report for Apache please see the instructions
       for bug reporting at <http://httpd.apache.org/bug_report.html>

     o If you want to participate in actively developing Apache please
       subscribe to the `dev@httpd.apache.org' mailing list as described at
       <http://httpd.apache.org/lists.html#http-dev>

