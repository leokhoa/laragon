# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1735 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/set_proxy.al)"
sub set_proxy ($$;**) {
    ($proxyhost, $proxyport, $proxyuser, $proxypass) = @_;
    require MIME::Base64 if $proxyuser;
    $proxyauth = $proxyuser
         ? $CRLF . 'Proxy-authorization: Basic '
	 . MIME::Base64::encode("$proxyuser:$proxypass", '')
	 : '';
}

# end of Net::SSLeay::set_proxy
1;
