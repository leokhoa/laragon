# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 589 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/ssl_read_all.al)"
sub ssl_read_all {
    my ($ssl,$how_much) = @_;
    $how_much = 2000000000 unless $how_much;
    my ($got, $rv, $errs);
    my $reply = '';

    while ($how_much > 0) {
        ($got, $rv) = Net::SSLeay::read($ssl,
                ($how_much > 32768) ? 32768 : $how_much
        );
	if (! defined $got) {
	    my $err = Net::SSLeay::get_error($ssl, $rv);
	    if ($err != Net::SSLeay::ERROR_WANT_READ() and
		$err != Net::SSLeay::ERROR_WANT_WRITE()) {
                $errs = print_errs('SSL_read');
                last;
            }
            next;
        }
        $how_much -= blength($got);
        debug_read(\$reply, \$got) if $trace>1;
        last if $got eq '';  # EOF
        $reply .= $got;
    }

    return wantarray ? ($reply, $errs) : $reply;
}

# end of Net::SSLeay::ssl_read_all
1;
