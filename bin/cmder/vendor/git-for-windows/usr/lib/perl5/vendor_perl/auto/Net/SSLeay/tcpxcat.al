# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1175 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/tcpxcat.al)"
sub tcpxcat {
    my ($usessl, $site, $port, $req, $crt_path, $key_path) = @_;
    if ($usessl) {
	return sslcat($site, $port, $req, $crt_path, $key_path);
    } else {
	return tcpcat($site, $port, $req);
    }
}

# end of Net::SSLeay::tcpxcat
1;
