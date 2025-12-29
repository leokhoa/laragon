# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1895 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/do_https.al)"
sub do_https {
    my ($site, $port, $path, $method, $headers,
	$content, $mime_type, $crt_path, $key_path) = @_;

    do_https2($method, $site, $port, $path, $headers,
	     $content, $mime_type, $crt_path, $key_path);
}

1;
__END__

1;
# end of Net::SSLeay::do_https
