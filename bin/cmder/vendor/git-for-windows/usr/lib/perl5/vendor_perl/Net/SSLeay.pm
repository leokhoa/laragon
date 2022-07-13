# Net::SSLeay.pm - Perl module for using Eric Young's implementation of SSL
#
# Copyright (c) 1996-2003 Sampo Kellomäki <sampo@iki.fi>
# Copyright (c) 2005-2010 Florian Ragwitz <rafl@debian.org>
# Copyright (c) 2005-2018 Mike McCauley <mikem@airspayce.com>
# Copyright (c) 2018- Chris Novakovic <chris@chrisn.me.uk>
# Copyright (c) 2018- Tuure Vartiainen <vartiait@radiatorsoftware.com>
# Copyright (c) 2018- Heikki Vatiainen <hvn@radiatorsoftware.com>
#
# All rights reserved.
#
# This module is released under the terms of the Artistic License 2.0. For
# details, see the LICENSE file distributed with Net-SSLeay's source code.

package Net::SSLeay;

use 5.8.1;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD $CRLF);
use Socket;
use Errno;

require Exporter;
use AutoLoader;

# 0=no warns, 1=only errors, 2=ciphers, 3=progress, 4=dump data
$Net::SSLeay::trace = 0;  # Do not change here, use
                          # $Net::SSLeay::trace = [1-4]  in caller

# 2 = insist on v2 SSL protocol
# 3 = insist on v3 SSL
# 10 = insist on TLSv1
# 11 = insist on TLSv1.1
# 12 = insist on TLSv1.2
# 13 = insist on TLSv1.3
# 0 or undef = guess (v23)
#
$Net::SSLeay::ssl_version = 0;  # don't change here, use
                                # Net::SSLeay::version=[2,3,0] in caller

#define to enable the "cat /proc/$$/stat" stuff
$Net::SSLeay::linux_debug = 0;

# Number of seconds to sleep after sending message and before half
# closing connection. Useful with antiquated broken servers.
$Net::SSLeay::slowly = 0;

# RANDOM NUMBER INITIALIZATION
#
# Edit to your taste. Using /dev/random would be more secure, but may
# block if randomness is not available, thus the default is
# /dev/urandom. $how_random determines how many bits of randomness to take
# from the device. You should take enough (read SSLeay/doc/rand), but
# beware that randomness is limited resource so you should not waste
# it either or you may end up with randomness depletion (situation where
# /dev/random would block and /dev/urandom starts to return predictable
# numbers).
#
# N.B. /dev/urandom does not exist on all systems, such as Solaris 2.6. In that
#      case you should get a third party package that emulates /dev/urandom
#      (e.g. via named pipe) or supply a random number file. Some such
#      packages are documented in Caveat section of the POD documentation.

$Net::SSLeay::random_device = '/dev/urandom';
$Net::SSLeay::how_random = 512;

# When updating this, also update $VERSION in the following files:
#   inc/Test/Net/SSLeay.pm
#   inc/Test/Net/SSLeay/Socket.pm
#   lib/Net/SSLeay/Handle.pm
$VERSION = '1.90';

@ISA = qw(Exporter);

#BEWARE:
# 3-columns part of @EXPORT_OK related to constants is the output of command:
# perl helper_script/regen_openssl_constants.pl -gen-pod
# if you add/remove any constant you need to update it manually

@EXPORT_OK = qw(
 ASN1_STRFLGS_ESC_CTRL           NID_netscape                              R_UNKNOWN_REMOTE_ERROR_TYPE
 ASN1_STRFLGS_ESC_MSB            NID_netscape_base_url                     R_UNKNOWN_STATE
 ASN1_STRFLGS_ESC_QUOTE          NID_netscape_ca_policy_url                R_X509_LIB
 ASN1_STRFLGS_RFC2253            NID_netscape_ca_revocation_url            SENT_SHUTDOWN
 CB_ACCEPT_EXIT                  NID_netscape_cert_extension               SESSION_ASN1_VERSION
 CB_ACCEPT_LOOP                  NID_netscape_cert_sequence                SESS_CACHE_BOTH
 CB_ALERT                        NID_netscape_cert_type                    SESS_CACHE_CLIENT
 CB_CONNECT_EXIT                 NID_netscape_comment                      SESS_CACHE_NO_AUTO_CLEAR
 CB_CONNECT_LOOP                 NID_netscape_data_type                    SESS_CACHE_NO_INTERNAL
 CB_EXIT                         NID_netscape_renewal_url                  SESS_CACHE_NO_INTERNAL_LOOKUP
 CB_HANDSHAKE_DONE               NID_netscape_revocation_url               SESS_CACHE_NO_INTERNAL_STORE
 CB_HANDSHAKE_START              NID_netscape_ssl_server_name              SESS_CACHE_OFF
 CB_LOOP                         NID_ns_sgc                                SESS_CACHE_SERVER
 CB_READ                         NID_organizationName                      SSL3_VERSION
 CB_READ_ALERT                   NID_organizationalUnitName                SSLEAY_BUILT_ON
 CB_WRITE                        NID_pbeWithMD2AndDES_CBC                  SSLEAY_CFLAGS
 CB_WRITE_ALERT                  NID_pbeWithMD2AndRC2_CBC                  SSLEAY_DIR
 ERROR_NONE                      NID_pbeWithMD5AndCast5_CBC                SSLEAY_PLATFORM
 ERROR_SSL                       NID_pbeWithMD5AndDES_CBC                  SSLEAY_VERSION
 ERROR_SYSCALL                   NID_pbeWithMD5AndRC2_CBC                  ST_ACCEPT
 ERROR_WANT_ACCEPT               NID_pbeWithSHA1AndDES_CBC                 ST_BEFORE
 ERROR_WANT_CONNECT              NID_pbeWithSHA1AndRC2_CBC                 ST_CONNECT
 ERROR_WANT_READ                 NID_pbe_WithSHA1And128BitRC2_CBC          ST_INIT
 ERROR_WANT_WRITE                NID_pbe_WithSHA1And128BitRC4              ST_OK
 ERROR_WANT_X509_LOOKUP          NID_pbe_WithSHA1And2_Key_TripleDES_CBC    ST_READ_BODY
 ERROR_ZERO_RETURN               NID_pbe_WithSHA1And3_Key_TripleDES_CBC    ST_READ_HEADER
 EVP_PKS_DSA                     NID_pbe_WithSHA1And40BitRC2_CBC           TLS1_1_VERSION
 EVP_PKS_EC                      NID_pbe_WithSHA1And40BitRC4               TLS1_2_VERSION
 EVP_PKS_RSA                     NID_pbes2                                 TLS1_3_VERSION
 EVP_PKT_ENC                     NID_pbmac1                                TLS1_VERSION
 EVP_PKT_EXCH                    NID_pkcs                                  TLSEXT_STATUSTYPE_ocsp
 EVP_PKT_EXP                     NID_pkcs3                                 VERIFY_CLIENT_ONCE
 EVP_PKT_SIGN                    NID_pkcs7                                 VERIFY_FAIL_IF_NO_PEER_CERT
 EVP_PK_DH                       NID_pkcs7_data                            VERIFY_NONE
 EVP_PK_DSA                      NID_pkcs7_digest                          VERIFY_PEER
 EVP_PK_EC                       NID_pkcs7_encrypted                       VERIFY_POST_HANDSHAKE
 EVP_PK_RSA                      NID_pkcs7_enveloped                       V_OCSP_CERTSTATUS_GOOD
 FILETYPE_ASN1                   NID_pkcs7_signed                          V_OCSP_CERTSTATUS_REVOKED
 FILETYPE_PEM                    NID_pkcs7_signedAndEnveloped              V_OCSP_CERTSTATUS_UNKNOWN
 F_CLIENT_CERTIFICATE            NID_pkcs8ShroudedKeyBag                   WRITING
 F_CLIENT_HELLO                  NID_pkcs9                                 X509_CHECK_FLAG_ALWAYS_CHECK_SUBJECT
 F_CLIENT_MASTER_KEY             NID_pkcs9_challengePassword               X509_CHECK_FLAG_MULTI_LABEL_WILDCARDS
 F_D2I_SSL_SESSION               NID_pkcs9_contentType                     X509_CHECK_FLAG_NEVER_CHECK_SUBJECT
 F_GET_CLIENT_FINISHED           NID_pkcs9_countersignature                X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS
 F_GET_CLIENT_HELLO              NID_pkcs9_emailAddress                    X509_CHECK_FLAG_NO_WILDCARDS
 F_GET_CLIENT_MASTER_KEY         NID_pkcs9_extCertAttributes               X509_CHECK_FLAG_SINGLE_LABEL_SUBDOMAINS
 F_GET_SERVER_FINISHED           NID_pkcs9_messageDigest                   X509_FILETYPE_ASN1
 F_GET_SERVER_HELLO              NID_pkcs9_signingTime                     X509_FILETYPE_DEFAULT
 F_GET_SERVER_VERIFY             NID_pkcs9_unstructuredAddress             X509_FILETYPE_PEM
 F_I2D_SSL_SESSION               NID_pkcs9_unstructuredName                X509_LOOKUP
 F_READ_N                        NID_private_key_usage_period              X509_PURPOSE_ANY
 F_REQUEST_CERTIFICATE           NID_rc2_40_cbc                            X509_PURPOSE_CRL_SIGN
 F_SERVER_HELLO                  NID_rc2_64_cbc                            X509_PURPOSE_NS_SSL_SERVER
 F_SSL_CERT_NEW                  NID_rc2_cbc                               X509_PURPOSE_OCSP_HELPER
 F_SSL_GET_NEW_SESSION           NID_rc2_cfb64                             X509_PURPOSE_SMIME_ENCRYPT
 F_SSL_NEW                       NID_rc2_ecb                               X509_PURPOSE_SMIME_SIGN
 F_SSL_READ                      NID_rc2_ofb64                             X509_PURPOSE_SSL_CLIENT
 F_SSL_RSA_PRIVATE_DECRYPT       NID_rc4                                   X509_PURPOSE_SSL_SERVER
 F_SSL_RSA_PUBLIC_ENCRYPT        NID_rc4_40                                X509_PURPOSE_TIMESTAMP_SIGN
 F_SSL_SESSION_NEW               NID_rc5_cbc                               X509_TRUST_COMPAT
 F_SSL_SESSION_PRINT_FP          NID_rc5_cfb64                             X509_TRUST_EMAIL
 F_SSL_SET_FD                    NID_rc5_ecb                               X509_TRUST_OBJECT_SIGN
 F_SSL_SET_RFD                   NID_rc5_ofb64                             X509_TRUST_OCSP_REQUEST
 F_SSL_SET_WFD                   NID_ripemd160                             X509_TRUST_OCSP_SIGN
 F_SSL_USE_CERTIFICATE           NID_ripemd160WithRSA                      X509_TRUST_SSL_CLIENT
 F_SSL_USE_CERTIFICATE_ASN1      NID_rle_compression                       X509_TRUST_SSL_SERVER
 F_SSL_USE_CERTIFICATE_FILE      NID_rsa                                   X509_TRUST_TSA
 F_SSL_USE_PRIVATEKEY            NID_rsaEncryption                         X509_V_ERR_AKID_ISSUER_SERIAL_MISMATCH
 F_SSL_USE_PRIVATEKEY_ASN1       NID_rsadsi                                X509_V_ERR_AKID_SKID_MISMATCH
 F_SSL_USE_PRIVATEKEY_FILE       NID_safeContentsBag                       X509_V_ERR_APPLICATION_VERIFICATION
 F_SSL_USE_RSAPRIVATEKEY         NID_sdsiCertificate                       X509_V_ERR_CA_KEY_TOO_SMALL
 F_SSL_USE_RSAPRIVATEKEY_ASN1    NID_secretBag                             X509_V_ERR_CA_MD_TOO_WEAK
 F_SSL_USE_RSAPRIVATEKEY_FILE    NID_serialNumber                          X509_V_ERR_CERT_CHAIN_TOO_LONG
 F_WRITE_PENDING                 NID_server_auth                           X509_V_ERR_CERT_HAS_EXPIRED
 GEN_DIRNAME                     NID_sha                                   X509_V_ERR_CERT_NOT_YET_VALID
 GEN_DNS                         NID_sha1                                  X509_V_ERR_CERT_REJECTED
 GEN_EDIPARTY                    NID_sha1WithRSA                           X509_V_ERR_CERT_REVOKED
 GEN_EMAIL                       NID_sha1WithRSAEncryption                 X509_V_ERR_CERT_SIGNATURE_FAILURE
 GEN_IPADD                       NID_shaWithRSAEncryption                  X509_V_ERR_CERT_UNTRUSTED
 GEN_OTHERNAME                   NID_stateOrProvinceName                   X509_V_ERR_CRL_HAS_EXPIRED
 GEN_RID                         NID_subject_alt_name                      X509_V_ERR_CRL_NOT_YET_VALID
 GEN_URI                         NID_subject_key_identifier                X509_V_ERR_CRL_PATH_VALIDATION_ERROR
 GEN_X400                        NID_surname                               X509_V_ERR_CRL_SIGNATURE_FAILURE
 LIBRESSL_VERSION_NUMBER         NID_sxnet                                 X509_V_ERR_DANE_NO_MATCH
 MBSTRING_ASC                    NID_time_stamp                            X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT
 MBSTRING_BMP                    NID_title                                 X509_V_ERR_DIFFERENT_CRL_SCOPE
 MBSTRING_FLAG                   NID_undef                                 X509_V_ERR_EE_KEY_TOO_SMALL
 MBSTRING_UNIV                   NID_uniqueIdentifier                      X509_V_ERR_EMAIL_MISMATCH
 MBSTRING_UTF8                   NID_x509Certificate                       X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD
 MIN_RSA_MODULUS_LENGTH_IN_BYTES NID_x509Crl                               X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD
 MODE_ACCEPT_MOVING_WRITE_BUFFER NID_zlib_compression                      X509_V_ERR_ERROR_IN_CRL_LAST_UPDATE_FIELD
 MODE_AUTO_RETRY                 NOTHING                                   X509_V_ERR_ERROR_IN_CRL_NEXT_UPDATE_FIELD
 MODE_ENABLE_PARTIAL_WRITE       OCSP_RESPONSE_STATUS_INTERNALERROR        X509_V_ERR_EXCLUDED_VIOLATION
 MODE_RELEASE_BUFFERS            OCSP_RESPONSE_STATUS_MALFORMEDREQUEST     X509_V_ERR_HOSTNAME_MISMATCH
 NID_OCSP_sign                   OCSP_RESPONSE_STATUS_SIGREQUIRED          X509_V_ERR_INVALID_CA
 NID_SMIMECapabilities           OCSP_RESPONSE_STATUS_SUCCESSFUL           X509_V_ERR_INVALID_CALL
 NID_X500                        OCSP_RESPONSE_STATUS_TRYLATER             X509_V_ERR_INVALID_EXTENSION
 NID_X509                        OCSP_RESPONSE_STATUS_UNAUTHORIZED         X509_V_ERR_INVALID_NON_CA
 NID_ad_OCSP                     OPENSSL_BUILT_ON                          X509_V_ERR_INVALID_POLICY_EXTENSION
 NID_ad_ca_issuers               OPENSSL_CFLAGS                            X509_V_ERR_INVALID_PURPOSE
 NID_algorithm                   OPENSSL_DIR                               X509_V_ERR_IP_ADDRESS_MISMATCH
 NID_authority_key_identifier    OPENSSL_ENGINES_DIR                       X509_V_ERR_KEYUSAGE_NO_CERTSIGN
 NID_basic_constraints           OPENSSL_PLATFORM                          X509_V_ERR_KEYUSAGE_NO_CRL_SIGN
 NID_bf_cbc                      OPENSSL_VERSION                           X509_V_ERR_KEYUSAGE_NO_DIGITAL_SIGNATURE
 NID_bf_cfb64                    OPENSSL_VERSION_NUMBER                    X509_V_ERR_NO_EXPLICIT_POLICY
 NID_bf_ecb                      OP_ALL                                    X509_V_ERR_NO_VALID_SCTS
 NID_bf_ofb64                    OP_ALLOW_NO_DHE_KEX                       X509_V_ERR_OCSP_CERT_UNKNOWN
 NID_cast5_cbc                   OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION      X509_V_ERR_OCSP_VERIFY_FAILED
 NID_cast5_cfb64                 OP_CIPHER_SERVER_PREFERENCE               X509_V_ERR_OCSP_VERIFY_NEEDED
 NID_cast5_ecb                   OP_CISCO_ANYCONNECT                       X509_V_ERR_OUT_OF_MEM
 NID_cast5_ofb64                 OP_COOKIE_EXCHANGE                        X509_V_ERR_PATH_LENGTH_EXCEEDED
 NID_certBag                     OP_CRYPTOPRO_TLSEXT_BUG                   X509_V_ERR_PATH_LOOP
 NID_certificate_policies        OP_DONT_INSERT_EMPTY_FRAGMENTS            X509_V_ERR_PERMITTED_VIOLATION
 NID_client_auth                 OP_ENABLE_MIDDLEBOX_COMPAT                X509_V_ERR_PROXY_CERTIFICATES_NOT_ALLOWED
 NID_code_sign                   OP_EPHEMERAL_RSA                          X509_V_ERR_PROXY_PATH_LENGTH_EXCEEDED
 NID_commonName                  OP_LEGACY_SERVER_CONNECT                  X509_V_ERR_PROXY_SUBJECT_NAME_VIOLATION
 NID_countryName                 OP_MICROSOFT_BIG_SSLV3_BUFFER             X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN
 NID_crlBag                      OP_MICROSOFT_SESS_ID_BUG                  X509_V_ERR_STORE_LOOKUP
 NID_crl_distribution_points     OP_MSIE_SSLV2_RSA_PADDING                 X509_V_ERR_SUBJECT_ISSUER_MISMATCH
 NID_crl_number                  OP_NETSCAPE_CA_DN_BUG                     X509_V_ERR_SUBTREE_MINMAX
 NID_crl_reason                  OP_NETSCAPE_CHALLENGE_BUG                 X509_V_ERR_SUITE_B_CANNOT_SIGN_P_384_WITH_P_256
 NID_delta_crl                   OP_NETSCAPE_DEMO_CIPHER_CHANGE_BUG        X509_V_ERR_SUITE_B_INVALID_ALGORITHM
 NID_des_cbc                     OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG       X509_V_ERR_SUITE_B_INVALID_CURVE
 NID_des_cfb64                   OP_NON_EXPORT_FIRST                       X509_V_ERR_SUITE_B_INVALID_SIGNATURE_ALGORITHM
 NID_des_ecb                     OP_NO_ANTI_REPLAY                         X509_V_ERR_SUITE_B_INVALID_VERSION
 NID_des_ede                     OP_NO_CLIENT_RENEGOTIATION                X509_V_ERR_SUITE_B_LOS_NOT_ALLOWED
 NID_des_ede3                    OP_NO_COMPRESSION                         X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY
 NID_des_ede3_cbc                OP_NO_ENCRYPT_THEN_MAC                    X509_V_ERR_UNABLE_TO_DECRYPT_CERT_SIGNATURE
 NID_des_ede3_cfb64              OP_NO_QUERY_MTU                           X509_V_ERR_UNABLE_TO_DECRYPT_CRL_SIGNATURE
 NID_des_ede3_ofb64              OP_NO_RENEGOTIATION                       X509_V_ERR_UNABLE_TO_GET_CRL
 NID_des_ede_cbc                 OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION X509_V_ERR_UNABLE_TO_GET_CRL_ISSUER
 NID_des_ede_cfb64               OP_NO_SSL_MASK                            X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT
 NID_des_ede_ofb64               OP_NO_SSLv2                               X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY
 NID_des_ofb64                   OP_NO_SSLv3                               X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE
 NID_description                 OP_NO_TICKET                              X509_V_ERR_UNHANDLED_CRITICAL_CRL_EXTENSION
 NID_desx_cbc                    OP_NO_TLSv1                               X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION
 NID_dhKeyAgreement              OP_NO_TLSv1_1                             X509_V_ERR_UNNESTED_RESOURCE
 NID_dnQualifier                 OP_NO_TLSv1_2                             X509_V_ERR_UNSPECIFIED
 NID_dsa                         OP_NO_TLSv1_3                             X509_V_ERR_UNSUPPORTED_CONSTRAINT_SYNTAX
 NID_dsaWithSHA                  OP_PKCS1_CHECK_1                          X509_V_ERR_UNSUPPORTED_CONSTRAINT_TYPE
 NID_dsaWithSHA1                 OP_PKCS1_CHECK_2                          X509_V_ERR_UNSUPPORTED_EXTENSION_FEATURE
 NID_dsaWithSHA1_2               OP_PRIORITIZE_CHACHA                      X509_V_ERR_UNSUPPORTED_NAME_SYNTAX
 NID_dsa_2                       OP_SAFARI_ECDHE_ECDSA_BUG                 X509_V_FLAG_ALLOW_PROXY_CERTS
 NID_email_protect               OP_SINGLE_DH_USE                          X509_V_FLAG_CB_ISSUER_CHECK
 NID_ext_key_usage               OP_SINGLE_ECDH_USE                        X509_V_FLAG_CHECK_SS_SIGNATURE
 NID_ext_req                     OP_SSLEAY_080_CLIENT_DH_BUG               X509_V_FLAG_CRL_CHECK
 NID_friendlyName                OP_SSLREF2_REUSE_CERT_TYPE_BUG            X509_V_FLAG_CRL_CHECK_ALL
 NID_givenName                   OP_TLSEXT_PADDING                         X509_V_FLAG_EXPLICIT_POLICY
 NID_hmacWithSHA1                OP_TLS_BLOCK_PADDING_BUG                  X509_V_FLAG_EXTENDED_CRL_SUPPORT
 NID_id_ad                       OP_TLS_D5_BUG                             X509_V_FLAG_IGNORE_CRITICAL
 NID_id_ce                       OP_TLS_ROLLBACK_BUG                       X509_V_FLAG_INHIBIT_ANY
 NID_id_kp                       READING                                   X509_V_FLAG_INHIBIT_MAP
 NID_id_pbkdf2                   RECEIVED_SHUTDOWN                         X509_V_FLAG_NOTIFY_POLICY
 NID_id_pe                       RSA_3                                     X509_V_FLAG_NO_ALT_CHAINS
 NID_id_pkix                     RSA_F4                                    X509_V_FLAG_NO_CHECK_TIME
 NID_id_qt_cps                   R_BAD_AUTHENTICATION_TYPE                 X509_V_FLAG_PARTIAL_CHAIN
 NID_id_qt_unotice               R_BAD_CHECKSUM                            X509_V_FLAG_POLICY_CHECK
 NID_idea_cbc                    R_BAD_MAC_DECODE                          X509_V_FLAG_POLICY_MASK
 NID_idea_cfb64                  R_BAD_RESPONSE_ARGUMENT                   X509_V_FLAG_SUITEB_128_LOS
 NID_idea_ecb                    R_BAD_SSL_FILETYPE                        X509_V_FLAG_SUITEB_128_LOS_ONLY
 NID_idea_ofb64                  R_BAD_SSL_SESSION_ID_LENGTH               X509_V_FLAG_SUITEB_192_LOS
 NID_info_access                 R_BAD_STATE                               X509_V_FLAG_TRUSTED_FIRST
 NID_initials                    R_BAD_WRITE_RETRY                         X509_V_FLAG_USE_CHECK_TIME
 NID_invalidity_date             R_CHALLENGE_IS_DIFFERENT                  X509_V_FLAG_USE_DELTAS
 NID_issuer_alt_name             R_CIPHER_TABLE_SRC_ERROR                  X509_V_FLAG_X509_STRICT
 NID_keyBag                      R_INVALID_CHALLENGE_LENGTH                X509_V_OK
 NID_key_usage                   R_NO_CERTIFICATE_SET                      XN_FLAG_COMPAT
 NID_localKeyID                  R_NO_CERTIFICATE_SPECIFIED                XN_FLAG_DN_REV
 NID_localityName                R_NO_CIPHER_LIST                          XN_FLAG_DUMP_UNKNOWN_FIELDS
 NID_md2                         R_NO_CIPHER_MATCH                         XN_FLAG_FN_ALIGN
 NID_md2WithRSAEncryption        R_NO_PRIVATEKEY                           XN_FLAG_FN_LN
 NID_md5                         R_NO_PUBLICKEY                            XN_FLAG_FN_MASK
 NID_md5WithRSA                  R_NULL_SSL_CTX                            XN_FLAG_FN_NONE
 NID_md5WithRSAEncryption        R_PEER_DID_NOT_RETURN_A_CERTIFICATE       XN_FLAG_FN_OID
 NID_md5_sha1                    R_PEER_ERROR                              XN_FLAG_FN_SN
 NID_mdc2                        R_PEER_ERROR_CERTIFICATE                  XN_FLAG_MULTILINE
 NID_mdc2WithRSA                 R_PEER_ERROR_NO_CIPHER                    XN_FLAG_ONELINE
 NID_ms_code_com                 R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE XN_FLAG_RFC2253
 NID_ms_code_ind                 R_PUBLIC_KEY_ENCRYPT_ERROR                XN_FLAG_SEP_COMMA_PLUS
 NID_ms_ctl_sign                 R_PUBLIC_KEY_IS_NOT_RSA                   XN_FLAG_SEP_CPLUS_SPC
 NID_ms_efs                      R_READ_WRONG_PACKET_TYPE                  XN_FLAG_SEP_MASK
 NID_ms_ext_req                  R_SHORT_READ                              XN_FLAG_SEP_MULTILINE
 NID_ms_sgc                      R_SSL_SESSION_ID_IS_DIFFERENT             XN_FLAG_SEP_SPLUS_SPC
 NID_name                        R_UNABLE_TO_EXTRACT_PUBLIC_KEY            XN_FLAG_SPC_EQ
    BIO_eof
    BIO_f_ssl
    BIO_free
    BIO_new
    BIO_new_file
    BIO_pending
    BIO_read
    BIO_s_mem
    BIO_wpending
    BIO_write
    CTX_free
    CTX_get_cert_store
    CTX_new
    CTX_use_RSAPrivateKey_file
    CTX_use_certificate_file
    CTX_v23_new
    CTX_v2_new
    CTX_v3_new
    ERR_error_string
    ERR_get_error
    ERR_load_RAND_strings
    ERR_load_SSL_strings
    PEM_read_bio_X509_CRL
    RSA_free
    RSA_generate_key
    SESSION
    SESSION_free
    SESSION_get_master_key
    SESSION_new
    SESSION_print
    X509_NAME_get_text_by_NID
    X509_NAME_oneline
    X509_STORE_CTX_set_flags
    X509_STORE_add_cert
    X509_STORE_add_crl
    X509_check_email
    X509_check_host
    X509_check_ip
    X509_check_ip_asc
    X509_free
    X509_get_issuer_name
    X509_get_subject_name
    X509_load_cert_crl_file
    X509_load_cert_file
    X509_load_crl_file
    accept
    add_session
    clear
    clear_error
    connect
    copy_session_id
    d2i_SSL_SESSION
    die_if_ssl_error
    die_now
    do_https
    dump_peer_certificate
    err
    flush_sessions
    free
    get_cipher
    get_cipher_list
    get_client_random
    get_fd
    get_http
    get_http4
    get_https
    get_https3
    get_https4
    get_httpx
    get_httpx4
    get_peer_certificate
    get_peer_cert_chain
    get_rbio
    get_read_ahead
    get_server_random
    get_shared_ciphers
    get_time
    get_timeout
    get_wbio
    i2d_SSL_SESSION
    load_error_strings
    make_form
    make_headers
    new
    peek
    pending
    post_http
    post_http4
    post_https
    post_https3
    post_https4
    post_httpx
    post_httpx4
    print_errs
    read
    remove_session
    rstate_string
    rstate_string_long
    set_bio
    set_cert_and_key
    set_cipher_list
    set_fd
    set_read_ahead
    set_rfd
    set_server_cert_and_key
    set_session
    set_time
    set_timeout
    set_verify
    set_wfd
    ssl_read_CRLF
    ssl_read_all
    ssl_read_until
    ssl_write_CRLF
    ssl_write_all
    sslcat
    state_string
    state_string_long
    tcp_read_CRLF
    tcp_read_all
    tcp_read_until
    tcp_write_CRLF
    tcp_write_all
    tcpcat
    tcpxcat
    use_PrivateKey
    use_PrivateKey_ASN1
    use_PrivateKey_file
    use_RSAPrivateKey
    use_RSAPrivateKey_ASN1
    use_RSAPrivateKey_file
    use_certificate
    use_certificate_ASN1
    use_certificate_file
    write
    d2i_OCSP_RESPONSE
    i2d_OCSP_RESPONSE
    OCSP_RESPONSE_free
    d2i_OCSP_REQUEST
    i2d_OCSP_REQUEST
    OCSP_REQUEST_free
    OCSP_cert2ids
    OCSP_ids2req
    OCSP_response_status
    OCSP_response_status_str
    OCSP_response_verify
    OCSP_response_results
    OCSP_RESPONSE_STATUS_INTERNALERROR
    OCSP_RESPONSE_STATUS_MALFORMEDREQUEST
    OCSP_RESPONSE_STATUS_SIGREQUIRED
    OCSP_RESPONSE_STATUS_SUCCESSFUL
    OCSP_RESPONSE_STATUS_TRYLATER
    OCSP_RESPONSE_STATUS_UNAUTHORIZED
    TLSEXT_STATUSTYPE_ocsp
    V_OCSP_CERTSTATUS_GOOD
    V_OCSP_CERTSTATUS_REVOKED
    V_OCSP_CERTSTATUS_UNKNOWN
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname);
    if ($! != 0) {
	if ($! =~ /((Invalid)|(not valid))/i || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	  croak "Your vendor has not defined SSLeay macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

eval {
	require XSLoader;
	XSLoader::load('Net::SSLeay', $VERSION);
	1;
} or do {
	require DynaLoader;
	push @ISA, 'DynaLoader';
	bootstrap Net::SSLeay $VERSION;
};

# Preloaded methods go here.

$CRLF = "\x0d\x0a";  # because \r\n is not fully portable

### Print SSLeay error stack

sub print_errs {
    my ($msg) = @_;
    my ($count, $err, $errs, $e) = (0,0,'');
    while ($err = ERR_get_error()) {
        $count ++;
	$e = "$msg $$: $count - " . ERR_error_string($err) . "\n";
	$errs .= $e;
	warn $e if $Net::SSLeay::trace;
    }
    return $errs;
}

# Death is conditional to SSLeay errors existing, i.e. this function checks
# for errors and only dies in affirmative.
# usage: Net::SSLeay::write($ssl, "foo") or die_if_ssl_error("SSL write ($!)");

sub die_if_ssl_error {
    my ($msg) = @_;
    die "$$: $msg\n" if print_errs($msg);
}

# Unconditional death. Used to print SSLeay errors before dying.
# usage: Net::SSLeay::connect($ssl) or die_now("Failed SSL connect ($!)");

sub die_now {
    my ($msg) = @_;
    print_errs($msg);
    die "$$: $msg\n";
}

# Perl 5.6.* unicode support causes that length() no longer reliably
# reflects the byte length of a string. This eval is to fix that.
# Thanks to Sean Burke for the snippet.

BEGIN{
eval 'use bytes; sub blength ($) { defined $_[0] ? length $_[0] : 0  }';
$@ and eval '    sub blength ($) { defined $_[0] ? length $_[0] : 0 }' ;
}

# Autoload methods go after __END__, and are processed by the autosplit program.


1;
__END__

### Some methods that are macros in C

sub want_nothing { want(shift) == 1 }
sub want_read { want(shift) == 2 }
sub want_write { want(shift) == 3 }
sub want_X509_lookup { want(shift) == 4 }

###
### Open TCP stream to given host and port, looking up the details
### from system databases or DNS.
###

sub open_tcp_connection {
    my ($dest_serv, $port) = @_;
    my ($errs);

    $port = getservbyname($port, 'tcp') unless $port =~ /^\d+$/;
    my $dest_serv_ip = gethostbyname($dest_serv);
    unless (defined($dest_serv_ip)) {
	$errs = "$0 $$: open_tcp_connection: destination host not found:"
            . " `$dest_serv' (port $port) ($!)\n";
	warn $errs if $trace;
        return wantarray ? (0, $errs) : 0;
    }
    my $sin = sockaddr_in($port, $dest_serv_ip);

    warn "Opening connection to $dest_serv:$port (" .
	inet_ntoa($dest_serv_ip) . ")" if $trace>2;

    my $proto = &Socket::IPPROTO_TCP; # getprotobyname('tcp') not available on android
    if (socket (SSLCAT_S, &PF_INET(), &SOCK_STREAM(), $proto)) {
        warn "next connect" if $trace>3;
        if (CORE::connect (SSLCAT_S, $sin)) {
            my $old_out = select (SSLCAT_S); $| = 1; select ($old_out);
            warn "connected to $dest_serv, $port" if $trace>3;
            return wantarray ? (1, undef) : 1; # Success
        }
    }
    $errs = "$0 $$: open_tcp_connection: failed `$dest_serv', $port ($!)\n";
    warn $errs if $trace;
    close SSLCAT_S;
    return wantarray ? (0, $errs) : 0; # Fail
}

### Open connection via standard web proxy, if one was defined
### using set_proxy().

sub open_proxy_tcp_connection {
    my ($dest_serv, $port) = @_;
    return open_tcp_connection($dest_serv, $port) if !$proxyhost;

    warn "Connect via proxy: $proxyhost:$proxyport" if $trace>2;
    my ($ret, $errs) = open_tcp_connection($proxyhost, $proxyport);
    return wantarray ? (0, $errs) : 0 if !$ret;  # Connection fail

    warn "Asking proxy to connect to $dest_serv:$port" if $trace>2;
    #print SSLCAT_S "CONNECT $dest_serv:$port HTTP/1.0$proxyauth$CRLF$CRLF";
    #my $line = <SSLCAT_S>;   # *** bug? Mixing stdio with syscall read?
    ($ret, $errs) =
	tcp_write_all("CONNECT $dest_serv:$port HTTP/1.0$proxyauth$CRLF$CRLF");
    return wantarray ? (0,$errs) : 0 if $errs;
    ($line, $errs) = tcp_read_until($CRLF . $CRLF, 1024);
    warn "Proxy response: $line" if $trace>2;
    return wantarray ? (0,$errs) : 0 if $errs;
    return wantarray ? (1,'') : 1;  # Success
}

###
### read and write helpers that block
###

sub debug_read {
    my ($replyr, $gotr) = @_;
    my $vm = $trace>2 && $linux_debug ?
	(split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
    warn "  got " . blength($$gotr) . ':'
	. blength($$replyr) . " bytes (VM=$vm).\n" if $trace == 3;
    warn "  got `$$gotr' (" . blength($$gotr) . ':'
	. blength($$replyr) . " bytes, VM=$vm)\n" if $trace>3;
}

sub ssl_read_all {
    my ($ssl,$how_much) = @_;
    $how_much = 2000000000 unless $how_much;
    my ($got, $rv, $errs);
    my $reply = '';

    while ($how_much > 0) {
        ($got, $rv) = Net::SSLeay::read($ssl,
                ($how_much > 32768) ? 32768 : $how_much
        );
	if (! defined $got) {
	    my $err = Net::SSLeay::get_error($ssl, $rv);
	    if ($err != Net::SSLeay::ERROR_WANT_READ() and
		$err != Net::SSLeay::ERROR_WANT_WRITE()) {
                $errs = print_errs('SSL_read');
                last;
            }
            next;
        }
        $how_much -= blength($got);
        debug_read(\$reply, \$got) if $trace>1;
        last if $got eq '';  # EOF
        $reply .= $got;
    }

    return wantarray ? ($reply, $errs) : $reply;
}

sub tcp_read_all {
    my ($how_much) = @_;
    $how_much = 2000000000 unless $how_much;
    my ($n, $got, $errs);
    my $reply = '';

    my $bsize = 0x10000;
    while ($how_much > 0) {
	$n = sysread(SSLCAT_S,$got, (($bsize < $how_much) ? $bsize : $how_much));
	warn "Read error: $! ($n,$how_much)" unless defined $n;
	last if !$n;  # EOF
	$how_much -= $n;
	debug_read(\$reply, \$got) if $trace>1;
	$reply .= $got;
    }
    return wantarray ? ($reply, $errs) : $reply;
}

sub ssl_write_all {
    my $ssl = $_[0];
    my ($data_ref, $errs);
    if (ref $_[1]) {
	$data_ref = $_[1];
    } else {
	$data_ref = \$_[1];
    }
    my ($wrote, $written, $to_write) = (0,0, blength($$data_ref));
    my $vm = $trace>2 && $linux_debug ?
	(split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
    warn "  write_all VM at entry=$vm\n" if $trace>2;
    while ($to_write) {
	#sleep 1; # *** DEBUG
	warn "partial `$$data_ref'\n" if $trace>3;
	$wrote = write_partial($ssl, $written, $to_write, $$data_ref);
	if (defined $wrote && ($wrote > 0)) {  # write_partial can return -1
	    $written += $wrote;
	    $to_write -= $wrote;
	} else {
	  if (defined $wrote) {
	    # check error conditions via SSL_get_error per man page
	    if ( my $sslerr = get_error($ssl, $wrote) ) {
	      my $errstr = ERR_error_string($sslerr);
	      my $errname = '';
	      SWITCH: {
		$sslerr == constant("ERROR_NONE") && do {
		  # according to map page SSL_get_error(3ssl):
		  #  The TLS/SSL I/O operation completed.
		  #  This result code is returned if and only if ret > 0
                  # so if we received it here complain...
		  warn "ERROR_NONE unexpected with invalid return value!"
		    if $trace;
		  $errname = "SSL_ERROR_NONE";
		};
		$sslerr == constant("ERROR_WANT_READ") && do {
		  # operation did not complete, call again later, so do not
		  # set errname and empty err_que since this is a known
		  # error that is expected but, we should continue to try
		  # writing the rest of our data with same io call and params.
		  warn "ERROR_WANT_READ (TLS/SSL Handshake, will continue)\n"
		    if $trace;
		  print_errs('SSL_write(want read)');
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_WRITE") && do {
		  # operation did not complete, call again later, so do not
		  # set errname and empty err_que since this is a known
		  # error that is expected but, we should continue to try
		  # writing the rest of our data with same io call and params.
		  warn "ERROR_WANT_WRITE (TLS/SSL Handshake, will continue)\n"
		    if $trace;
		  print_errs('SSL_write(want write)');
		  last SWITCH;
		};
		$sslerr == constant("ERROR_ZERO_RETURN") && do {
		  # valid protocol closure from other side, no longer able to
		  # write, since there is no longer a session...
		  warn "ERROR_ZERO_RETURN($wrote): TLS/SSLv3 Closure alert\n"
		    if $trace;
		  $errname = "SSL_ERROR_ZERO_RETURN";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_SSL") && do {
		  # library/protocol error
		  warn "ERROR_SSL($wrote): Library/Protocol error occured\n"
		    if $trace;
		  $errname = "SSL_ERROR_SSL";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_CONNECT") && do {
		  # according to man page, should never happen on call to
		  # SSL_write, so complain, but handle as known error type
		  warn "ERROR_WANT_CONNECT: Unexpected error for SSL_write\n"
		    if $trace;
		  $errname = "SSL_ERROR_WANT_CONNECT";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_ACCEPT") && do {
		  # according to man page, should never happen on call to
		  # SSL_write, so complain, but handle as known error type
		  warn "ERROR_WANT_ACCEPT: Unexpected error for SSL_write\n"
		    if $trace;
		  $errname = "SSL_ERROR_WANT_ACCEPT";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_X509_LOOKUP") && do {
		  # operation did not complete: waiting on call back,
		  # call again later, so do not set errname and empty err_que
		  # since this is a known error that is expected but, we should
		  # continue to try writing the rest of our data with same io
		  # call parameter.
		  warn "ERROR_WANT_X509_LOOKUP: (Cert Callback asked for in ".
		    "SSL_write will contine)\n" if $trace;
		  print_errs('SSL_write(want x509');
		  last SWITCH;
		};
		$sslerr == constant("ERROR_SYSCALL") && do {
		  # some IO error occured. According to man page:
		  # Check retval, ERR, fallback to errno
		  if ($wrote==0) { # EOF
		    warn "ERROR_SYSCALL($wrote): EOF violates protocol.\n"
		      if $trace;
		    $errname = "SSL_ERROR_SYSCALL(EOF)";
		  } else { # -1 underlying BIO error reported.
		    # check error que for details, don't set errname since we
		    # are directly appending to errs
		    my $chkerrs = print_errs('SSL_write (syscall)');
		    if ($chkerrs) {
		      warn "ERROR_SYSCALL($wrote): Have errors\n" if $trace;
		      $errs .= "ssl_write_all $$: 1 - ERROR_SYSCALL($wrote,".
			"$sslerr,$errstr,$!)\n$chkerrs";
		    } else { # que was empty, use errno
		      warn "ERROR_SYSCALL($wrote): errno($!)\n" if $trace;
		      $errs .= "ssl_write_all $$: 1 - ERROR_SYSCALL($wrote,".
			"$sslerr) : $!\n";
		    }
		  }
		  last SWITCH;
		};
		warn "Unhandled val $sslerr from SSL_get_error(SSL,$wrote)\n"
		  if $trace;
		$errname = "SSL_ERROR_?($sslerr)";
	      } # end of SWITCH block
	      if ($errname) { # if we had an errname set add the error
		$errs .= "ssl_write_all $$: 1 - $errname($wrote,$sslerr,".
		  "$errstr,$!)\n";
	      }
	    } # endif on have SSL_get_error val
	  } # endif on $wrote defined
	} # endelse on $wrote > 0
	$vm = $trace>2 && $linux_debug ?
	    (split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
	warn "  written so far $wrote:$written bytes (VM=$vm)\n" if $trace>2;
	# append remaining errors in que and report if errs exist
	$errs .= print_errs('SSL_write');
	return (wantarray ? (undef, $errs) : undef) if $errs;
    }
    return wantarray ? ($written, $errs) : $written;
}

sub tcp_write_all {
    my ($data_ref, $errs);
    if (ref $_[0]) {
	$data_ref = $_[0];
    } else {
	$data_ref = \$_[0];
    }
    my ($wrote, $written, $to_write) = (0,0, blength($$data_ref));
    my $vm = $trace>2 && $linux_debug ?
	(split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
    warn "  write_all VM at entry=$vm to_write=$to_write\n" if $trace>2;
    while ($to_write) {
	warn "partial `$$data_ref'\n" if $trace>3;
	$wrote = syswrite(SSLCAT_S, $$data_ref, $to_write, $written);
	if (defined $wrote && ($wrote > 0)) {  # write_partial can return -1
	    $written += $wrote;
	    $to_write -= $wrote;
	} elsif (!defined($wrote)) {
	    warn "tcp_write_all: $!";
	    return (wantarray ? (undef, "$!") : undef);
	}
	$vm = $trace>2 && $linux_debug ?
	    (split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
	warn "  written so far $wrote:$written bytes (VM=$vm)\n" if $trace>2;
    }
    return wantarray ? ($written, '') : $written;
}

### from patch by Clinton Wong <clintdw@netcom.com>

# ssl_read_until($ssl [, $delimit [, $max_length]])
#  if $delimit missing, use $/ if it exists, otherwise use \n
#  read until delimiter reached, up to $max_length chars if defined

sub ssl_read_until ($;$$) {
    my ($ssl,$delim, $max_length) = @_;

    # guess the delim string if missing
    if ( ! defined $delim ) {
      if ( defined $/ && length $/  ) { $delim = $/ }
      else { $delim = "\n" }      # Note: \n,$/ value depends on the platform
    }
    my $len_delim = length $delim;

    my ($got);
    my $reply = '';

    # If we have OpenSSL 0.9.6a or later, we can use SSL_peek to
    # speed things up.
    # N.B. 0.9.6a has security problems, so the support for
    #      anything earlier than 0.9.6e will be dropped soon.
    if (&Net::SSLeay::OPENSSL_VERSION_NUMBER >= 0x0090601f) {
	$max_length = 2000000000 unless (defined $max_length);
	my ($pending, $peek_length, $found, $done);
	while (blength($reply) < $max_length and !$done) {
	    #Block if necessary until we get some data
	    $got = Net::SSLeay::peek($ssl,1);
	    last if print_errs('SSL_peek');

	    $pending = Net::SSLeay::pending($ssl) + blength($reply);
	    $peek_length = ($pending > $max_length) ? $max_length : $pending;
	    $peek_length -= blength($reply);
	    $got = Net::SSLeay::peek($ssl, $peek_length);
	    last if print_errs('SSL_peek');
	    $peek_length = blength($got);

	    #$found = index($got, $delim);  # Old and broken

	    # the delimiter may be split across two gets, so we prepend
	    # a little from the last get onto this one before we check
	    # for a match
	    my $match;
	    if(blength($reply) >= blength($delim) - 1) {
		#if what we've read so far is greater or equal
		#in length of what we need to prepatch
		$match = substr $reply, blength($reply) - blength($delim) + 1;
	    } else {
		$match = $reply;
	    }

	    $match .= $got;
	    $found = index($match, $delim);

	    if ($found > -1) {
		#$got = Net::SSLeay::ssl_read_all($ssl, $found+$len_delim);
		#read up to the end of the delimiter
		$got = Net::SSLeay::ssl_read_all($ssl,
					 $found + $len_delim
					 - ((blength($match)) - (blength($got))));
		$done = 1;
	    } else {
		$got = Net::SSLeay::ssl_read_all($ssl, $peek_length);
		$done = 1 if ($peek_length == $max_length - blength($reply));
	    }

	    last if print_errs('SSL_read');
	    debug_read(\$reply, \$got) if $trace>1;
	    last if $got eq '';
	    $reply .= $got;
	}
    } else {
	while (!defined $max_length || length $reply < $max_length) {
	    $got = Net::SSLeay::ssl_read_all($ssl,1);  # one by one
	    last if print_errs('SSL_read');
	    debug_read(\$reply, \$got) if $trace>1;
	    last if $got eq '';
	    $reply .= $got;
	    last if $len_delim
		&& substr($reply, blength($reply)-$len_delim) eq $delim;
	}
    }
    return $reply;
}

sub tcp_read_until {
    my ($delim, $max_length) = @_;

    # guess the delim string if missing
    if ( ! defined $delim ) {
      if ( defined $/ && length $/  ) { $delim = $/ }
      else { $delim = "\n" }      # Note: \n,$/ value depends on the platform
    }
    my $len_delim = length $delim;

    my ($n,$got);
    my $reply = '';

    while (!defined $max_length || length $reply < $max_length) {
	$n = sysread(SSLCAT_S, $got, 1);  # one by one
	warn "tcp_read_until: $!" if !defined $n;
	debug_read(\$reply, \$got) if $trace>1;
	last if !$n;  # EOF
	$reply .= $got;
	last if $len_delim
	    && substr($reply, blength($reply)-$len_delim) eq $delim;
    }
    return $reply;
}

# ssl_read_CRLF($ssl [, $max_length])
sub ssl_read_CRLF ($;$) { ssl_read_until($_[0], $CRLF, $_[1]) }
sub tcp_read_CRLF { tcp_read_until($CRLF, $_[0]) }

# ssl_write_CRLF($ssl, $message) writes $message and appends CRLF
sub ssl_write_CRLF ($$) {
  # the next line uses less memory but might use more network packets
  return ssl_write_all($_[0], $_[1]) + ssl_write_all($_[0], $CRLF);

  # the next few lines do the same thing at the expense of memory, with
  # the chance that it will use less packets, since CRLF is in the original
  # message and won't be sent separately.

  #my $data_ref;
  #if (ref $_[1]) { $data_ref = $_[1] }
  # else { $data_ref = \$_[1] }
  #my $message = $$data_ref . $CRLF;
  #return ssl_write_all($_[0], \$message);
}

sub tcp_write_CRLF {
  # the next line uses less memory but might use more network packets
  return tcp_write_all($_[0]) + tcp_write_all($CRLF);

  # the next few lines do the same thing at the expense of memory, with
  # the chance that it will use less packets, since CRLF is in the original
  # message and won't be sent separately.

  #my $data_ref;
  #if (ref $_[1]) { $data_ref = $_[1] }
  # else { $data_ref = \$_[1] }
  #my $message = $$data_ref . $CRLF;
  #return tcp_write_all($_[0], \$message);
}

### Quickly print out with whom we're talking

sub dump_peer_certificate ($) {
    my ($ssl) = @_;
    my $cert = get_peer_certificate($ssl);
    return if print_errs('get_peer_certificate');
    print "no cert defined\n" if !defined($cert);
    # Cipher=NONE with empty cert fix
    if (!defined($cert) || ($cert == 0)) {
	warn "cert = `$cert'\n" if $trace;
	return "Subject Name: undefined\nIssuer  Name: undefined\n";
    } else {
	my $x = 'Subject Name: '
	    . X509_NAME_oneline(X509_get_subject_name($cert)) . "\n"
		. 'Issuer  Name: '
		    . X509_NAME_oneline(X509_get_issuer_name($cert))  . "\n";
	Net::SSLeay::X509_free($cert);
	return $x;
    }
}

### Arrange some randomness for eay PRNG

sub randomize (;$$$) {
    my ($rn_seed_file, $seed, $egd_path) = @_;
    my $rnsf = defined($rn_seed_file) && -r $rn_seed_file;

	$egd_path = '';
    $egd_path = $ENV{'EGD_PATH'} if $ENV{'EGD_PATH'};

    RAND_seed(rand() + $$);  # Stir it with time and pid

    unless ($rnsf || -r $Net::SSLeay::random_device || $seed || -S $egd_path) {
	my $poll_retval = Net::SSLeay::RAND_poll();
	warn "Random number generator not seeded!!!" if $trace && !$poll_retval;
    }

    RAND_load_file($rn_seed_file, -s _) if $rnsf;
    RAND_seed($seed) if $seed;
    RAND_seed($ENV{RND_SEED}) if $ENV{RND_SEED};
    RAND_load_file($Net::SSLeay::random_device, $Net::SSLeay::how_random/8)
	if -r $Net::SSLeay::random_device;
}

sub new_x_ctx {
    if ($ssl_version == 2)  {
	unless (exists &Net::SSLeay::CTX_v2_new) {
	    warn "ssl_version has been set to 2, but this version of OpenSSL has been compiled without SSLv2 support";
	    return undef;
	}
	$ctx = CTX_v2_new();
    }
    elsif ($ssl_version == 3)  { $ctx = CTX_v3_new(); }
    elsif ($ssl_version == 10) { $ctx = CTX_tlsv1_new(); }
    elsif ($ssl_version == 11) {
	unless (exists &Net::SSLeay::CTX_tlsv1_1_new) {
	    warn "ssl_version has been set to 11, but this version of OpenSSL has been compiled without TLSv1.1 support";
	    return undef;
	}
        $ctx = CTX_tlsv1_1_new;
    }
    elsif ($ssl_version == 12) {
	unless (exists &Net::SSLeay::CTX_tlsv1_2_new) {
	    warn "ssl_version has been set to 12, but this version of OpenSSL has been compiled without TLSv1.2 support";
	    return undef;
	}
        $ctx = CTX_tlsv1_2_new;
    }
    elsif ($ssl_version == 13) {
	unless (eval { Net::SSLeay::TLS1_3_VERSION(); } ) {
	    warn "ssl_version has been set to 13, but this version of OpenSSL has been compiled without TLSv1.3 support";
	    return undef;
	}
        $ctx = CTX_new();
        unless(Net::SSLeay::CTX_set_min_proto_version($ctx, Net::SSLeay::TLS1_3_VERSION())) {
            warn "CTX_set_min_proto failed for TLSv1.3";
            return undef;
        }
        unless(Net::SSLeay::CTX_set_max_proto_version($ctx, Net::SSLeay::TLS1_3_VERSION())) {
            warn "CTX_set_max_proto failed for TLSv1.3";
            return undef;
        }
    }
    else                       { $ctx = CTX_new(); }
    return $ctx;
}

###
### Standard initialisation. Initialise the ssl library in the usual way
###  at most once. Override this if you need differnet initialisation
###  SSLeay_add_ssl_algorithms is also protected against multiple runs in SSLeay.xs
###  and is also mutex protected in threading perls
###

my $library_initialised;
sub initialize
{
    if (!$library_initialised)
    {
	load_error_strings();         # Some bloat, but I'm after ease of use
	SSLeay_add_ssl_algorithms();  # and debuggability.
	randomize();
	$library_initialised++;
    }
}

###
### Basic request - response primitive (don't use for https)
###

sub sslcat { # address, port, message, $crt, $key --> reply / (reply,errs,cert)
    my ($dest_serv, $port, $out_message, $crt_path, $key_path) = @_;
    my ($ctx, $ssl, $got, $errs, $written);

    ($got, $errs) = open_proxy_tcp_connection($dest_serv, $port);
    return (wantarray ? (undef, $errs) : undef) unless $got;

    ### Do SSL negotiation stuff

    warn "Creating SSL $ssl_version context...\n" if $trace>2;
    initialize(); # Will init at most once

    $ctx = new_x_ctx();
    goto cleanup2 if $errs = print_errs('CTX_new') or !$ctx;

    CTX_set_options($ctx, &OP_ALL);
    goto cleanup2 if $errs = print_errs('CTX_set_options');

    warn "Cert `$crt_path' given without key" if $crt_path && !$key_path;
    set_cert_and_key($ctx, $crt_path, $key_path) if $crt_path;

    warn "Creating SSL connection (context was '$ctx')...\n" if $trace>2;
    $ssl = new($ctx);
    goto cleanup if $errs = print_errs('SSL_new') or !$ssl;

    warn "Setting fd (ctx $ctx, con $ssl)...\n" if $trace>2;
    set_fd($ssl, fileno(SSLCAT_S));
    goto cleanup if $errs = print_errs('set_fd');

    warn "Entering SSL negotiation phase...\n" if $trace>2;

    if ($trace>2) {
	my $i = 0;
	my $p = '';
	my $cipher_list = 'Cipher list: ';
	$p=Net::SSLeay::get_cipher_list($ssl,$i);
	$cipher_list .= $p if $p;
	do {
	    $i++;
	    $cipher_list .= ', ' . $p if $p;
	    $p=Net::SSLeay::get_cipher_list($ssl,$i);
	} while $p;
	$cipher_list .= '\n';
	warn $cipher_list;
    }

    $got = Net::SSLeay::connect($ssl);
    warn "SSLeay connect returned $got\n" if $trace>2;
    goto cleanup if $errs = print_errs('SSL_connect');

    my $server_cert = get_peer_certificate($ssl);
    print_errs('get_peer_certificate');
    if ($trace>1) {
	warn "Cipher `" . get_cipher($ssl) . "'\n";
	print_errs('get_ciper');
	warn dump_peer_certificate($ssl);
    }

    ### Connected. Exchange some data (doing repeated tries if necessary).

    warn "sslcat $$: sending " . blength($out_message) . " bytes...\n"
	if $trace==3;
    warn "sslcat $$: sending `$out_message' (" . blength($out_message)
	. " bytes)...\n" if $trace>3;
    ($written, $errs) = ssl_write_all($ssl, $out_message);
    goto cleanup unless $written;

    sleep $slowly if $slowly;  # Closing too soon can abort broken servers
    Net::SSLeay::shutdown($ssl); # Useful starting with OpenSSL 1.1.1e
    CORE::shutdown SSLCAT_S, 1;  # Half close --> No more output, send EOF to server

    warn "waiting for reply...\n" if $trace>2;
    ($got, $errs) = ssl_read_all($ssl);
    warn "Got " . blength($got) . " bytes.\n" if $trace==3;
    warn "Got `$got' (" . blength($got) . " bytes)\n" if $trace>3;

cleanup:
    free ($ssl);
    $errs .= print_errs('SSL_free');
cleanup2:
    CTX_free ($ctx);
    $errs .= print_errs('CTX_free');
    close SSLCAT_S;
    return wantarray ? ($got, $errs, $server_cert) : $got;
}

sub tcpcat { # address, port, message, $crt, $key --> reply / (reply,errs,cert)
    my ($dest_serv, $port, $out_message) = @_;
    my ($got, $errs, $written);

    ($got, $errs) = open_proxy_tcp_connection($dest_serv, $port);
    return (wantarray ? (undef, $errs) : undef) unless $got;

    ### Connected. Exchange some data (doing repeated tries if necessary).

    warn "tcpcat $$: sending " . blength($out_message) . " bytes...\n"
	if $trace==3;
    warn "tcpcat $$: sending `$out_message' (" . blength($out_message)
	. " bytes)...\n" if $trace>3;
    ($written, $errs) = tcp_write_all($out_message);
    goto cleanup unless $written;

    sleep $slowly if $slowly;  # Closing too soon can abort broken servers
    CORE::shutdown SSLCAT_S, 1;  # Half close --> No more output, send EOF to server

    warn "waiting for reply...\n" if $trace>2;
    ($got, $errs) = tcp_read_all();
    warn "Got " . blength($got) . " bytes.\n" if $trace==3;
    warn "Got `$got' (" . blength($got) . " bytes)\n" if $trace>3;

cleanup:
    close SSLCAT_S;
    return wantarray ? ($got, $errs) : $got;
}

sub tcpxcat {
    my ($usessl, $site, $port, $req, $crt_path, $key_path) = @_;
    if ($usessl) {
	return sslcat($site, $port, $req, $crt_path, $key_path);
    } else {
	return tcpcat($site, $port, $req);
    }
}

###
### Basic request - response primitive, this is different from sslcat
###                 because this does not shutdown the connection.
###

sub https_cat { # address, port, message --> returns reply / (reply,errs,cert)
    my ($dest_serv, $port, $out_message, $crt_path, $key_path) = @_;
    my ($ctx, $ssl, $got, $errs, $written);

    ($got, $errs) = open_proxy_tcp_connection($dest_serv, $port);
    return (wantarray ? (undef, $errs) : undef) unless $got;

    ### Do SSL negotiation stuff

    warn "Creating SSL $ssl_version context...\n" if $trace>2;
    initialize();

    $ctx = new_x_ctx();
    goto cleanup2 if $errs = print_errs('CTX_new') or !$ctx;

    CTX_set_options($ctx, &OP_ALL);
    goto cleanup2 if $errs = print_errs('CTX_set_options');

    warn "Cert `$crt_path' given without key" if $crt_path && !$key_path;
    set_cert_and_key($ctx, $crt_path, $key_path) if $crt_path;

    warn "Creating SSL connection (context was '$ctx')...\n" if $trace>2;
    $ssl = new($ctx);
    goto cleanup if $errs = print_errs('SSL_new') or !$ssl;

    warn "Setting fd (ctx $ctx, con $ssl)...\n" if $trace>2;
    set_fd($ssl, fileno(SSLCAT_S));
    goto cleanup if $errs = print_errs('set_fd');

    warn "Entering SSL negotiation phase...\n" if $trace>2;

    if ($trace>2) {
	my $i = 0;
	my $p = '';
	my $cipher_list = 'Cipher list: ';
	$p=Net::SSLeay::get_cipher_list($ssl,$i);
	$cipher_list .= $p if $p;
	do {
	    $i++;
	    $cipher_list .= ', ' . $p if $p;
	    $p=Net::SSLeay::get_cipher_list($ssl,$i);
	} while $p;
	$cipher_list .= '\n';
	warn $cipher_list;
    }

    $got = Net::SSLeay::connect($ssl);
    warn "SSLeay connect failed" if $trace>2 && $got==0;
    goto cleanup if $errs = print_errs('SSL_connect');

    my $server_cert = get_peer_certificate($ssl);
    print_errs('get_peer_certificate');
    if ($trace>1) {
	warn "Cipher `" . get_cipher($ssl) . "'\n";
	print_errs('get_ciper');
	warn dump_peer_certificate($ssl);
    }

    ### Connected. Exchange some data (doing repeated tries if necessary).

    warn "https_cat $$: sending " . blength($out_message) . " bytes...\n"
	if $trace==3;
    warn "https_cat $$: sending `$out_message' (" . blength($out_message)
	. " bytes)...\n" if $trace>3;
    ($written, $errs) = ssl_write_all($ssl, $out_message);
    goto cleanup unless $written;

    warn "waiting for reply...\n" if $trace>2;
    ($got, $errs) = ssl_read_all($ssl);
    warn "Got " . blength($got) . " bytes.\n" if $trace==3;
    warn "Got `$got' (" . blength($got) . " bytes)\n" if $trace>3;

cleanup:
    free ($ssl);
    $errs .= print_errs('SSL_free');
cleanup2:
    CTX_free ($ctx);
    $errs .= print_errs('CTX_free');
    close SSLCAT_S;
    return wantarray ? ($got, $errs, $server_cert) : $got;
}

sub http_cat { # address, port, message --> returns reply / (reply,errs,cert)
    my ($dest_serv, $port, $out_message) = @_;
    my ($got, $errs, $written);

    ($got, $errs) = open_proxy_tcp_connection($dest_serv, $port);
    return (wantarray ? (undef, $errs) : undef) unless $got;

    ### Connected. Exchange some data (doing repeated tries if necessary).

    warn "http_cat $$: sending " . blength($out_message) . " bytes...\n"
	if $trace==3;
    warn "http_cat $$: sending `$out_message' (" . blength($out_message)
	. " bytes)...\n" if $trace>3;
    ($written, $errs) = tcp_write_all($out_message);
    goto cleanup unless $written;

    warn "waiting for reply...\n" if $trace>2;
    ($got, $errs) = tcp_read_all();
    warn "Got " . blength($got) . " bytes.\n" if $trace==3;
    warn "Got `$got' (" . blength($got) . " bytes)\n" if $trace>3;

cleanup:
    close SSLCAT_S;
    return wantarray ? ($got, $errs) : $got;
}

sub httpx_cat {
    my ($usessl, $site, $port, $req, $crt_path, $key_path) = @_;
    warn "httpx_cat: usessl=$usessl ($site:$port)" if $trace;
    if ($usessl) {
	return https_cat($site, $port, $req, $crt_path, $key_path);
    } else {
	return http_cat($site, $port, $req);
    }
}

###
### Easy set up of private key and certificate
###

sub set_cert_and_key ($$$) {
    my ($ctx, $cert_path, $key_path) = @_;
    my $errs = '';
    # Following will ask password unless private key is not encrypted
    CTX_use_PrivateKey_file( $ctx, $key_path, &FILETYPE_PEM ) == 1
        or $errs .= print_errs("private key `$key_path' ($!)");
    CTX_use_certificate_file ($ctx, $cert_path, &FILETYPE_PEM) == 1
        or $errs .= print_errs("certificate `$cert_path' ($!)");
    return wantarray ? (undef, $errs) : ($errs eq '');
}

### Old deprecated API

sub set_server_cert_and_key ($$$) { &set_cert_and_key }

### Set up to use web proxy

sub set_proxy ($$;**) {
    ($proxyhost, $proxyport, $proxyuser, $proxypass) = @_;
    require MIME::Base64 if $proxyuser;
    $proxyauth = $proxyuser
         ? $CRLF . 'Proxy-authorization: Basic '
	 . MIME::Base64::encode("$proxyuser:$proxypass", '')
	 : '';
}

###
### Easy https manipulation routines
###

sub make_form {
    my (@fields) = @_;
    my $form;
    while (@fields) {
	my ($name, $data) = (shift(@fields), shift(@fields));
	$data =~ s/([^\w\-.\@\$ ])/sprintf("%%%2.2x",ord($1))/gse;
    	$data =~ tr[ ][+];
	$form .= "$name=$data&";
    }
    chop $form;
    return $form;
}

sub make_headers {
    my (@headers) = @_;
    my $headers;
    while (@headers) {
	my $header = shift(@headers);
	my $value = shift(@headers);
	$header =~ s/:$//;
	$value =~ s/\x0d?\x0a$//; # because we add it soon, see below
	$headers .= "$header: $value$CRLF";
    }
    return $headers;
}

sub do_httpx3 {
    my ($method, $usessl, $site, $port, $path, $headers,
	$content, $mime_type, $crt_path, $key_path) = @_;
    my ($response, $page, $h,$v);

    my $len = blength($content);
    if ($len) {
	$mime_type = "application/x-www-form-urlencoded" unless $mime_type;
	$content = "Content-Type: $mime_type$CRLF"
	    . "Content-Length: $len$CRLF$CRLF$content";
    } else {
	$content = "$CRLF$CRLF";
    }
    my $req = "$method $path HTTP/1.0$CRLF";
    unless (defined $headers && $headers =~ /^Host:/m) {
        $req .= "Host: $site";
        unless (($port == 80 && !$usessl) || ($port == 443 && $usessl)) {
            $req .= ":$port";
        }
        $req .= $CRLF;
	}
    $req .= (defined $headers ? $headers : '') . "Accept: */*$CRLF$content";

    warn "do_httpx3($method,$usessl,$site:$port)" if $trace;
    my ($http, $errs, $server_cert)
	= httpx_cat($usessl, $site, $port, $req, $crt_path, $key_path);
    return (undef, "HTTP/1.0 900 NET OR SSL ERROR$CRLF$CRLF$errs") if $errs;

    $http = '' if !defined $http;
    ($headers, $page) = split /\s?\n\s?\n/, $http, 2;
    warn "headers >$headers< page >>$page<< http >>>$http<<<" if $trace>1;
    ($response, $headers) = split /\s?\n/, $headers, 2;
    return ($page, $response, $headers, $server_cert);
}

sub do_https3 { splice(@_,1,0) = 1; do_httpx3; }  # Legacy undocumented

### do_https2() is a legacy version in the sense that it is unable
### to return all instances of duplicate headers.

sub do_httpx2 {
    my ($page, $response, $headers, $server_cert) = &do_httpx3;
    X509_free($server_cert) if defined $server_cert;
    return ($page, $response, defined $headers ?
	    map( { ($h,$v)=/^(\S+)\:\s*(.*)$/; (uc($h),$v); }
		split(/\s?\n/, $headers)
		) : ()
	    );
}

sub do_https2 { splice(@_,1,0) = 1; do_httpx2; }  # Legacy undocumented

### Returns headers as a hash where multiple instances of same header
### are handled correctly.

sub do_httpx4 {
    my ($page, $response, $headers, $server_cert) = &do_httpx3;
    my %hr = ();
    for my $hh (split /\s?\n/, $headers) {
	my ($h,$v) = ($hh =~ /^(\S+)\:\s*(.*)$/);
	push @{$hr{uc($h)}}, $v;
    }
    return ($page, $response, \%hr, $server_cert);
}

sub do_https4 { splice(@_,1,0) = 1; do_httpx4; }  # Legacy undocumented

# https

sub get_https  { do_httpx2(GET  => 1, @_) }
sub post_https { do_httpx2(POST => 1, @_) }
sub put_https  { do_httpx2(PUT  => 1, @_) }
sub head_https { do_httpx2(HEAD => 1, @_) }

sub get_https3  { do_httpx3(GET  => 1, @_) }
sub post_https3 { do_httpx3(POST => 1, @_) }
sub put_https3  { do_httpx3(PUT  => 1, @_) }
sub head_https3 { do_httpx3(HEAD => 1, @_) }

sub get_https4  { do_httpx4(GET  => 1, @_) }
sub post_https4 { do_httpx4(POST => 1, @_) }
sub put_https4  { do_httpx4(PUT  => 1, @_) }
sub head_https4 { do_httpx4(HEAD => 1, @_) }

# http

sub get_http  { do_httpx2(GET  => 0, @_) }
sub post_http { do_httpx2(POST => 0, @_) }
sub put_http  { do_httpx2(PUT  => 0, @_) }
sub head_http { do_httpx2(HEAD => 0, @_) }

sub get_http3  { do_httpx3(GET  => 0, @_) }
sub post_http3 { do_httpx3(POST => 0, @_) }
sub put_http3  { do_httpx3(PUT  => 0, @_) }
sub head_http3 { do_httpx3(HEAD => 0, @_) }

sub get_http4  { do_httpx4(GET  => 0, @_) }
sub post_http4 { do_httpx4(POST => 0, @_) }
sub put_http4  { do_httpx4(PUT  => 0, @_) }
sub head_http4 { do_httpx4(HEAD => 0, @_) }

# Either https or http

sub get_httpx  { do_httpx2(GET  => @_) }
sub post_httpx { do_httpx2(POST => @_) }
sub put_httpx  { do_httpx2(PUT  => @_) }
sub head_httpx { do_httpx2(HEAD => @_) }

sub get_httpx3  { do_httpx3(GET  => @_) }
sub post_httpx3 { do_httpx3(POST => @_) }
sub put_httpx3  { do_httpx3(PUT  => @_) }
sub head_httpx3 { do_httpx3(HEAD => @_) }

sub get_httpx4  { do_httpx4(GET  => @_) }
sub post_httpx4 { do_httpx4(POST => @_) }
sub put_httpx4  { do_httpx4(PUT  => @_) }
sub head_httpx4 { do_httpx4(HEAD => @_) }

### Legacy, don't use
# ($page, $respone_or_err, %headers) = do_https(...);

sub do_https {
    my ($site, $port, $path, $method, $headers,
	$content, $mime_type, $crt_path, $key_path) = @_;

    do_https2($method, $site, $port, $path, $headers,
	     $content, $mime_type, $crt_path, $key_path);
}

1;
__END__

