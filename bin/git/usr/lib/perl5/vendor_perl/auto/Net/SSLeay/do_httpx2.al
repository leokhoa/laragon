# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1814 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/do_httpx2.al)"
sub do_httpx2 {
    my ($page, $response, $headers, $server_cert) = &do_httpx3;
    X509_free($server_cert) if defined $server_cert;
    return ($page, $response, defined $headers ?
	    map( { ($h,$v)=/^(\S+)\:\s*(.*)$/; (uc($h),$v); }
		split(/\s?\n/, $headers)
		) : ()
	    );
}

# end of Net::SSLeay::do_httpx2
1;
