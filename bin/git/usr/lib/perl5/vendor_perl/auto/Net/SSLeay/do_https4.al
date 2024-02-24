# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1839 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/do_https4.al)"
sub do_https4 { splice(@_,1,0) = 1; do_httpx4; }  # Legacy undocumented

# https

# end of Net::SSLeay::do_https4
1;
