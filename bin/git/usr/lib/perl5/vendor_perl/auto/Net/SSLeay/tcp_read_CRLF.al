# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1324 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/tcp_read_CRLF.al)"
sub tcp_read_CRLF { tcp_read_until($CRLF, $_[0]) }

# ssl_write_CRLF($ssl, $message) writes $message and appends CRLF
# end of Net::SSLeay::tcp_read_CRLF
1;
