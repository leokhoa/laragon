# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 950 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/dump_peer_certificate.al)"
### Quickly print out with whom we're talking

sub dump_peer_certificate ($) {
    my ($ssl) = @_;
    my $cert = get_peer_certificate($ssl);
    return if print_errs('get_peer_certificate');
    print "no cert defined\n" if !defined($cert);
    # Cipher=NONE with empty cert fix
    if (!defined($cert) || ($cert == 0)) {
	warn "cert = `$cert'\n" if $trace;
	return "Subject Name: undefined\nIssuer  Name: undefined\n";
    } else {
	my $x = 'Subject Name: '
	    . X509_NAME_oneline(X509_get_subject_name($cert)) . "\n"
		. 'Issuer  Name: '
		    . X509_NAME_oneline(X509_get_issuer_name($cert))  . "\n";
	Net::SSLeay::X509_free($cert);
	return $x;
    }
}

# end of Net::SSLeay::dump_peer_certificate
1;
