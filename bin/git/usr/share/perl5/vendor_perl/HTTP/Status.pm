package HTTP::Status;

use strict;
use warnings;

our $VERSION = '6.45';

use Exporter 5.57 'import';

our @EXPORT = qw(is_info is_success is_redirect is_error status_message);
our @EXPORT_OK = qw(is_client_error is_server_error is_cacheable_by_default status_constant_name status_codes);

# Note also addition of mnemonics to @EXPORT below

# Unmarked codes are from RFC 7231 (2017-12-20)
# See also:
# https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml

my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518: WebDAV
    103 => 'Early Hints',                     # RFC 8297: Indicating Hints
#   104 .. 199
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',                 # RFC 7233: Range Requests
    207 => 'Multi-Status',                    # RFC 4918: WebDAV
    208 => 'Already Reported',                # RFC 5842: WebDAV bindings
#   209 .. 225
    226 => 'IM Used',                         # RFC 3229: Delta encoding
#   227 .. 299
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',                    # RFC 7232: Conditional Request
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    308 => 'Permanent Redirect',              # RFC 7528: Permanent Redirect
#   309 .. 399
    400 => 'Bad Request',
    401 => 'Unauthorized',                    # RFC 7235: Authentication
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',   # RFC 7235: Authentication
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',             # RFC 7232: Conditional Request
    413 => 'Payload Too Large',
    414 => 'URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Range Not Satisfiable',           # RFC 7233: Range Requests
    417 => 'Expectation Failed',
#   418 .. 420
    421 => 'Misdirected Request',             # RFC 7540: HTTP/2
    422 => 'Unprocessable Entity',            # RFC 4918: WebDAV
    423 => 'Locked',                          # RFC 4918: WebDAV
    424 => 'Failed Dependency',               # RFC 4918: WebDAV
    425 => 'Too Early',                       # RFC 8470: Using Early Data in HTTP
    426 => 'Upgrade Required',
#   427
    428 => 'Precondition Required',           # RFC 6585: Additional Codes
    429 => 'Too Many Requests',               # RFC 6585: Additional Codes
#   430
    431 => 'Request Header Fields Too Large', # RFC 6585: Additional Codes
#   432 .. 450
    451 => 'Unavailable For Legal Reasons',   # RFC 7725: Legal Obstacles
#   452 .. 499
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295: Transparant Ngttn
    507 => 'Insufficient Storage',            # RFC 4918: WebDAV
    508 => 'Loop Detected',                   # RFC 5842: WebDAV bindings
#   509
    510 => 'Not Extended',                    # RFC 2774: Extension Framework
    511 => 'Network Authentication Required', # RFC 6585: Additional Codes
);

my %StatusCodeName;

# keep some unofficial codes that used to be in this distribution
%StatusCode = (
    %StatusCode,
    418 => 'I\'m a teapot',                   # RFC 2324: HTCPC/1.0  1-april
    449 => 'Retry with',                      #           microsoft
    509 => 'Bandwidth Limit Exceeded',        #           Apache / cPanel
);

my $mnemonicCode = '';
my ($code, $message);
while (($code, $message) = each %StatusCode) {
    # create mnemonic subroutines
    $message =~ s/I'm/I am/;
    $message =~ tr/a-z \-/A-Z__/;
    my $constant_name = "HTTP_".$message;
    $mnemonicCode .= "sub $constant_name () { $code }\n";
    $mnemonicCode .= "*RC_$message = \\&HTTP_$message;\n";  # legacy
    $mnemonicCode .= "push(\@EXPORT_OK, 'HTTP_$message');\n";
    $mnemonicCode .= "push(\@EXPORT, 'RC_$message');\n";
    $StatusCodeName{$code} = $constant_name
}
eval $mnemonicCode; # only one eval for speed
die if $@;

# backwards compatibility
*RC_MOVED_TEMPORARILY = \&RC_FOUND;  # 302 was renamed in the standard
push(@EXPORT, "RC_MOVED_TEMPORARILY");

my %compat = (
    REQUEST_ENTITY_TOO_LARGE      => \&HTTP_PAYLOAD_TOO_LARGE,
    REQUEST_URI_TOO_LARGE         => \&HTTP_URI_TOO_LONG,
    REQUEST_RANGE_NOT_SATISFIABLE => \&HTTP_RANGE_NOT_SATISFIABLE,
    NO_CODE                       => \&HTTP_TOO_EARLY,
    UNORDERED_COLLECTION          => \&HTTP_TOO_EARLY,
);

foreach my $name (keys %compat) {
    push(@EXPORT, "RC_$name");
    push(@EXPORT_OK, "HTTP_$name");
    no strict 'refs';
    *{"RC_$name"} = $compat{$name};
    *{"HTTP_$name"} = $compat{$name};
}

our %EXPORT_TAGS = (
   constants => [grep /^HTTP_/, @EXPORT_OK],
   is => [grep /^is_/, @EXPORT, @EXPORT_OK],
);


sub status_message  ($) { $StatusCode{$_[0]}; }
sub status_constant_name ($) {
    exists($StatusCodeName{$_[0]}) ? $StatusCodeName{$_[0]} : undef;
}

sub is_info                 ($) { $_[0] && $_[0] >= 100 && $_[0] < 200; }
sub is_success              ($) { $_[0] && $_[0] >= 200 && $_[0] < 300; }
sub is_redirect             ($) { $_[0] && $_[0] >= 300 && $_[0] < 400; }
sub is_error                ($) { $_[0] && $_[0] >= 400 && $_[0] < 600; }
sub is_client_error         ($) { $_[0] && $_[0] >= 400 && $_[0] < 500; }
sub is_server_error         ($) { $_[0] && $_[0] >= 500 && $_[0] < 600; }
sub is_cacheable_by_default ($) { $_[0] && ( $_[0] == 200 # OK
                                          || $_[0] == 203 # Non-Authoritative Information
                                          || $_[0] == 204 # No Content
                                          || $_[0] == 206 # Not Acceptable
                                          || $_[0] == 300 # Multiple Choices
                                          || $_[0] == 301 # Moved Permanently
                                          || $_[0] == 308 # Permanent Redirect
                                          || $_[0] == 404 # Not Found
                                          || $_[0] == 405 # Method Not Allowed
                                          || $_[0] == 410 # Gone
                                          || $_[0] == 414 # Request-URI Too Large
                                          || $_[0] == 451 # Unavailable For Legal Reasons
                                          || $_[0] == 501 # Not Implemented
                                            );
}

sub status_codes         { %StatusCode; }

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Status - HTTP Status code processing

=head1 VERSION

version 6.45

=head1 SYNOPSIS

 use HTTP::Status qw(:constants :is status_message);

 if ($rc != HTTP_OK) {
     print status_message($rc), "\n";
 }

 if (is_success($rc)) { ... }
 if (is_error($rc)) { ... }
 if (is_redirect($rc)) { ... }

=head1 DESCRIPTION

I<HTTP::Status> is a library of routines for defining and
classifying HTTP status codes for libwww-perl.  Status codes are
used to encode the overall outcome of an HTTP response message.  Codes
correspond to those defined in RFC 2616 and RFC 2518.

=head1 CONSTANTS

The following constant functions can be used as mnemonic status code
names.  None of these are exported by default.  Use the C<:constants>
tag to import them all.

   HTTP_CONTINUE                        (100)
   HTTP_SWITCHING_PROTOCOLS             (101)
   HTTP_PROCESSING                      (102)
   HTTP_EARLY_HINTS                     (103)

   HTTP_OK                              (200)
   HTTP_CREATED                         (201)
   HTTP_ACCEPTED                        (202)
   HTTP_NON_AUTHORITATIVE_INFORMATION   (203)
   HTTP_NO_CONTENT                      (204)
   HTTP_RESET_CONTENT                   (205)
   HTTP_PARTIAL_CONTENT                 (206)
   HTTP_MULTI_STATUS                    (207)
   HTTP_ALREADY_REPORTED                (208)

   HTTP_IM_USED                         (226)

   HTTP_MULTIPLE_CHOICES                (300)
   HTTP_MOVED_PERMANENTLY               (301)
   HTTP_FOUND                           (302)
   HTTP_SEE_OTHER                       (303)
   HTTP_NOT_MODIFIED                    (304)
   HTTP_USE_PROXY                       (305)
   HTTP_TEMPORARY_REDIRECT              (307)
   HTTP_PERMANENT_REDIRECT              (308)

   HTTP_BAD_REQUEST                     (400)
   HTTP_UNAUTHORIZED                    (401)
   HTTP_PAYMENT_REQUIRED                (402)
   HTTP_FORBIDDEN                       (403)
   HTTP_NOT_FOUND                       (404)
   HTTP_METHOD_NOT_ALLOWED              (405)
   HTTP_NOT_ACCEPTABLE                  (406)
   HTTP_PROXY_AUTHENTICATION_REQUIRED   (407)
   HTTP_REQUEST_TIMEOUT                 (408)
   HTTP_CONFLICT                        (409)
   HTTP_GONE                            (410)
   HTTP_LENGTH_REQUIRED                 (411)
   HTTP_PRECONDITION_FAILED             (412)
   HTTP_PAYLOAD_TOO_LARGE               (413)
   HTTP_URI_TOO_LONG                    (414)
   HTTP_UNSUPPORTED_MEDIA_TYPE          (415)
   HTTP_RANGE_NOT_SATISFIABLE           (416)
   HTTP_EXPECTATION_FAILED              (417)
   HTTP_MISDIRECTED REQUEST             (421)
   HTTP_UNPROCESSABLE_ENTITY            (422)
   HTTP_LOCKED                          (423)
   HTTP_FAILED_DEPENDENCY               (424)
   HTTP_TOO_EARLY                       (425)
   HTTP_UPGRADE_REQUIRED                (426)
   HTTP_PRECONDITION_REQUIRED           (428)
   HTTP_TOO_MANY_REQUESTS               (429)
   HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE (431)
   HTTP_UNAVAILABLE_FOR_LEGAL_REASONS   (451)

   HTTP_INTERNAL_SERVER_ERROR           (500)
   HTTP_NOT_IMPLEMENTED                 (501)
   HTTP_BAD_GATEWAY                     (502)
   HTTP_SERVICE_UNAVAILABLE             (503)
   HTTP_GATEWAY_TIMEOUT                 (504)
   HTTP_HTTP_VERSION_NOT_SUPPORTED      (505)
   HTTP_VARIANT_ALSO_NEGOTIATES         (506)
   HTTP_INSUFFICIENT_STORAGE            (507)
   HTTP_LOOP_DETECTED                   (508)
   HTTP_NOT_EXTENDED                    (510)
   HTTP_NETWORK_AUTHENTICATION_REQUIRED (511)

=head1 FUNCTIONS

The following additional functions are provided.  Most of them are
exported by default.  The C<:is> import tag can be used to import all
the classification functions.

=over 4

=item status_message( $code )

The status_message() function will translate status codes to human
readable strings. The string is the same as found in the constant
names above.
For example, C<status_message(303)> will return C<"Not Found">.

If the $code is not registered in the L<list of IANA HTTP Status
Codes|https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>
then C<undef> is returned.

=item status_constant_name( $code )

The status_constant_name() function will translate a status code
to a string which has the name of the constant for that status code.
For example, C<status_constant_name(404)> will return C<"HTTP_NOT_FOUND">.

If the C<$code> is not registered in the L<list of IANA HTTP Status
Codes|https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>
then C<undef> is returned.

=item is_info( $code )

Return TRUE if C<$code> is an I<Informational> status code (1xx).  This
class of status code indicates a provisional response which can't have
any content.

=item is_success( $code )

Return TRUE if C<$code> is a I<Successful> status code (2xx).

=item is_redirect( $code )

Return TRUE if C<$code> is a I<Redirection> status code (3xx). This class of
status code indicates that further action needs to be taken by the
user agent in order to fulfill the request.

=item is_error( $code )

Return TRUE if C<$code> is an I<Error> status code (4xx or 5xx).  The function
returns TRUE for both client and server error status codes.

=item is_client_error( $code )

Return TRUE if C<$code> is a I<Client Error> status code (4xx). This class
of status code is intended for cases in which the client seems to have
erred.

This function is B<not> exported by default.

=item is_server_error( $code )

Return TRUE if C<$code> is a I<Server Error> status code (5xx). This class
of status codes is intended for cases in which the server is aware
that it has erred or is incapable of performing the request.

This function is B<not> exported by default.

=item is_cacheable_by_default( $code )

Return TRUE if C<$code> indicates that a response is cacheable by default, and
it can be reused by a cache with heuristic expiration. All other status codes
are not cacheable by default. See L<RFC 7231 - HTTP/1.1 Semantics and Content,
Section 6.1. Overview of Status Codes|https://tools.ietf.org/html/rfc7231#section-6.1>.

This function is B<not> exported by default.

=item status_codes

Returns a hash mapping numerical HTTP status code (e.g. 200) to text status messages (e.g. "OK")

This function is B<not> exported by default.

=back

=head1 SEE ALSO

L<IANA HTTP Status Codes|https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>

=head1 BUGS

For legacy reasons all the C<HTTP_> constants are exported by default
with the prefix C<RC_>.  It's recommended to use explicit imports and
the C<:constants> tag instead of relying on this.

=head1 AUTHOR

Gisle Aas <gisle@activestate.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1994 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


#ABSTRACT: HTTP Status code processing
