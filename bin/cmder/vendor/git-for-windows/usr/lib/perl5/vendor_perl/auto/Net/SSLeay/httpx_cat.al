# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1297 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/httpx_cat.al)"
sub httpx_cat {
    my ($usessl, $site, $port, $req, $crt_path, $key_path) = @_;
    warn "httpx_cat: usessl=$usessl ($site:$port)" if $trace;
    if ($usessl) {
	return https_cat($site, $port, $req, $crt_path, $key_path);
    } else {
	return http_cat($site, $port, $req);
    }
}

# end of Net::SSLeay::httpx_cat
1;
