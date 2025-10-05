# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1774 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/do_httpx3.al)"
sub do_httpx3 {
    my ($method, $usessl, $site, $port, $path, $headers,
	$content, $mime_type, $crt_path, $key_path) = @_;
    my ($response, $page, $h,$v);

    my $len = blength($content);
    if ($len) {
	$mime_type = "application/x-www-form-urlencoded" unless $mime_type;
	$content = "Content-Type: $mime_type$CRLF"
	    . "Content-Length: $len$CRLF$CRLF$content";
    } else {
	$content = "$CRLF$CRLF";
    }
    my $req = "$method $path HTTP/1.0$CRLF";
    unless (defined $headers && $headers =~ /^Host:/m) {
        $req .= "Host: $site";
        unless (($port == 80 && !$usessl) || ($port == 443 && $usessl)) {
            $req .= ":$port";
        }
        $req .= $CRLF;
	}
    $req .= (defined $headers ? $headers : '') . "Accept: */*$CRLF$content";

    warn "do_httpx3($method,$usessl,$site:$port)" if $trace;
    my ($http, $errs, $server_cert)
	= httpx_cat($usessl, $site, $port, $req, $crt_path, $key_path);
    return (undef, "HTTP/1.0 900 NET OR SSL ERROR$CRLF$CRLF$errs") if $errs;

    $http = '' if !defined $http;
    ($headers, $page) = split /\s?\n\s?\n/, $http, 2;
    warn "headers >$headers< page >>$page<< http >>>$http<<<" if $trace>1;
    ($response, $headers) = split /\s?\n/, $headers, 2;
    return ($page, $response, $headers, $server_cert);
}

# end of Net::SSLeay::do_httpx3
1;
