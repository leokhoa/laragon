# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1714 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/set_cert_and_key.al)"
###
### Easy set up of private key and certificate
###

sub set_cert_and_key ($$$) {
    my ($ctx, $cert_path, $key_path) = @_;
    my $errs = '';
    # Following will ask password unless private key is not encrypted
    CTX_use_PrivateKey_file( $ctx, $key_path, &FILETYPE_PEM ) == 1
        or $errs .= print_errs("private key `$key_path' ($!)");
    CTX_use_certificate_file ($ctx, $cert_path, &FILETYPE_PEM) == 1
        or $errs .= print_errs("certificate `$cert_path' ($!)");
    return wantarray ? (undef, $errs) : ($errs eq '');
}

# end of Net::SSLeay::set_cert_and_key
1;
