# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1327 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/ssl_write_CRLF.al)"
sub ssl_write_CRLF ($$) {
  # the next line uses less memory but might use more network packets
  return ssl_write_all($_[0], $_[1]) + ssl_write_all($_[0], $CRLF);

  # the next few lines do the same thing at the expense of memory, with
  # the chance that it will use less packets, since CRLF is in the original
  # message and won't be sent separately.

  #my $data_ref;
  #if (ref $_[1]) { $data_ref = $_[1] }
  # else { $data_ref = \$_[1] }
  #my $message = $$data_ref . $CRLF;
  #return ssl_write_all($_[0], \$message);
}

# end of Net::SSLeay::ssl_write_CRLF
1;
