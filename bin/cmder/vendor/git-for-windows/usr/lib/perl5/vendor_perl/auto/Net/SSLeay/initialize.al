# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1037 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/initialize.al)"
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

# end of Net::SSLeay::initialize
1;
