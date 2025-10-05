# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1322 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/ssl_read_CRLF.al)"
# ssl_read_CRLF($ssl [, $max_length])
sub ssl_read_CRLF ($;$) { ssl_read_until($_[0], $CRLF, $_[1]) }
# end of Net::SSLeay::ssl_read_CRLF
1;
