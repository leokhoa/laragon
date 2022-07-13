# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 513 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/want_X509_lookup.al)"
sub want_X509_lookup { want(shift) == 4 }

###
### Open TCP stream to given host and port, looking up the details
### from system databases or DNS.
###

# end of Net::SSLeay::want_X509_lookup
1;
