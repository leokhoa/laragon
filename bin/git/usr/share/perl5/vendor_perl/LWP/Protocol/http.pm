package LWP::Protocol::http;

use strict;

our $VERSION = '6.60';

require HTTP::Response;
require HTTP::Status;
require Net::HTTP;

use parent qw(LWP::Protocol);

our @EXTRA_SOCK_OPTS;
my $CRLF = "\015\012";

sub _new_socket
{
    my($self, $host, $port, $timeout) = @_;

    # IPv6 literal IP address should be [bracketed] to remove
    # ambiguity between ip address and port number.
    if ( ($host =~ /:/) && ($host !~ /^\[/) ) {
      $host = "[$host]";
    }

    local($^W) = 0;  # IO::Socket::INET can be noisy
    my $sock = $self->socket_class->new(PeerAddr => $host,
					PeerPort => $port,
					LocalAddr => $self->{ua}{local_address},
					Proto    => 'tcp',
					Timeout  => $timeout,
					KeepAlive => !!$self->{ua}{conn_cache},
					SendTE    => $self->{ua}{send_te},
					$self->_extra_sock_opts($host, $port),
				       );

    unless ($sock) {
	# IO::Socket::INET leaves additional error messages in $@
	my $status = "Can't connect to $host:$port";
	if ($@ =~ /\bconnect: (.*)/ ||
	    $@ =~ /\b(Bad hostname)\b/ ||
	    $@ =~ /\b(nodename nor servname provided, or not known)\b/ ||
	    $@ =~ /\b(certificate verify failed)\b/ ||
	    $@ =~ /\b(Crypt-SSLeay can't verify hostnames)\b/
	) {
	    $status .= " ($1)";
	} elsif ($@) {
	    $status .= " ($@)";
	}
	die "$status\n\n$@";
    }

    # perl 5.005's IO::Socket does not have the blocking method.
    eval { $sock->blocking(0); };

    $sock;
}

sub socket_type
{
    return "http";
}

sub socket_class
{
    my $self = shift;
    (ref($self) || $self) . "::Socket";
}

sub _extra_sock_opts  # to be overridden by subclass
{
    return @EXTRA_SOCK_OPTS;
}

sub _check_sock
{
    #my($self, $req, $sock) = @_;
}

sub _get_sock_info
{
    my($self, $res, $sock) = @_;
    if (defined(my $peerhost = $sock->peerhost)) {
        $res->header("Client-Peer" => "$peerhost:" . $sock->peerport);
    }
}

sub _fixup_header
{
    my($self, $h, $url, $proxy) = @_;

    # Extract 'Host' header
    my $hhost = $url->authority;
    if ($hhost =~ s/^([^\@]*)\@//) {  # get rid of potential "user:pass@"
	# add authorization header if we need them.  HTTP URLs do
	# not really support specification of user and password, but
	# we allow it.
	if (defined($1) && not $h->header('Authorization')) {
	    require URI::Escape;
	    $h->authorization_basic(map URI::Escape::uri_unescape($_),
				    split(":", $1, 2));
	}
    }
    $h->init_header('Host' => $hhost);

    if ($proxy && $url->scheme ne 'https') {
	# Check the proxy URI's userinfo() for proxy credentials
	# export http_proxy="http://proxyuser:proxypass@proxyhost:port".
	# For https only the initial CONNECT requests needs authorization.
	my $p_auth = $proxy->userinfo();
	if(defined $p_auth) {
	    require URI::Escape;
	    $h->proxy_authorization_basic(map URI::Escape::uri_unescape($_),
					  split(":", $p_auth, 2))
	}
    }
}

sub hlist_remove {
    my($hlist, $k) = @_;
    $k = lc $k;
    for (my $i = @$hlist - 2; $i >= 0; $i -= 2) {
	next unless lc($hlist->[$i]) eq $k;
	splice(@$hlist, $i, 2);
    }
}

sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;

    $size ||= 4096;

    # check method
    my $method = $request->method;
    unless ($method =~ /^[A-Za-z0-9_!\#\$%&\'*+\-.^\`|~]+$/) {  # HTTP token
	return HTTP::Response->new( HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'http:' URLs");
    }

    my $url = $request->uri;

    # Proxying SSL with a http proxy needs issues a CONNECT request to build a
    # tunnel and then upgrades the tunnel to SSL. But when doing keep-alive the
    # https request does not need to be the first request in the connection, so
    # we need to distinguish between
    # - not yet connected (create socket and ssl upgrade)
    # - connected but not inside ssl tunnel (ssl upgrade)
    # - inside ssl tunnel to the target - once we are in the tunnel to the
    #   target we cannot only reuse the tunnel for more https requests with the
    #   same target

    my $ssl_tunnel = $proxy && $url->scheme eq 'https'
	&& $url->host.":".$url->port;

    my ($host,$port) = $proxy
	? ($proxy->host,$proxy->port)
	: ($url->host,$url->port);
    my $fullpath =
	$method eq 'CONNECT' ? $url->host . ":" . $url->port :
	$proxy && ! $ssl_tunnel ? $url->as_string :
	do {
	    my $path = $url->path_query;
	    $path = "/$path" if $path !~m{^/};
	    $path
	};

    my $socket;
    my $conn_cache = $self->{ua}{conn_cache};
    my $cache_key;
    if ( $conn_cache ) {
	$cache_key = "$host:$port";
	# For https we reuse the socket immediately only if it has an established
	# tunnel to the target. Otherwise a CONNECT request followed by an SSL
	# upgrade need to be done first. The request itself might reuse an
	# existing non-ssl connection to the proxy
	$cache_key .= "!".$ssl_tunnel if $ssl_tunnel;
	if ( $socket = $conn_cache->withdraw($self->socket_type,$cache_key)) {
	    if ($socket->can_read(0)) {
		# if the socket is readable, then either the peer has closed the
		# connection or there are some garbage bytes on it.  In either
		# case we abandon it.
		$socket->close;
		$socket = undef;
	    } # else use $socket
	    else {
		$socket->timeout($timeout);
	    }
	}
    }

    if ( ! $socket && $ssl_tunnel ) {
	my $proto_https = LWP::Protocol::create('https',$self->{ua})
	    or die "no support for scheme https found";

	# only if ssl socket class is IO::Socket::SSL we can upgrade
	# a plain socket to SSL. In case of Net::SSL we fall back to
	# the old version
	if ( my $upgrade_sub = $proto_https->can('_upgrade_sock')) {
	    my $response = $self->request(
		HTTP::Request->new('CONNECT',"http://$ssl_tunnel"),
		$proxy,
		undef,$size,$timeout
	    );
	    $response->is_success or die
		"establishing SSL tunnel failed: ".$response->status_line;
	    $socket = $upgrade_sub->($proto_https,
		$response->{client_socket},$url)
		or die "SSL upgrade failed: $@";
	} else {
	    $socket = $proto_https->_new_socket($url->host,$url->port,$timeout);
	}
    }

    if ( ! $socket ) {
	# connect to remote site w/o reusing established socket
	$socket = $self->_new_socket($host, $port, $timeout );
    }

    my $http_version = "";
    if (my $proto = $request->protocol) {
	if ($proto =~ /^(?:HTTP\/)?(1.\d+)$/) {
	    $http_version = $1;
	    $socket->http_version($http_version);
	    $socket->send_te(0) if $http_version eq "1.0";
	}
    }

    $self->_check_sock($request, $socket);

    my @h;
    my $request_headers = $request->headers->clone;
    $self->_fixup_header($request_headers, $url, $proxy);

    $request_headers->scan(sub {
			       my($k, $v) = @_;
			       $k =~ s/^://;
			       $v =~ tr/\n/ /;
			       push(@h, $k, $v);
			   });

    my $content_ref = $request->content_ref;
    $content_ref = $$content_ref if ref($$content_ref);
    my $chunked;
    my $has_content;

    if (ref($content_ref) eq 'CODE') {
	my $clen = $request_headers->header('Content-Length');
	$has_content++ if $clen;
	unless (defined $clen) {
	    push(@h, "Transfer-Encoding" => "chunked");
	    $has_content++;
	    $chunked++;
	}
    }
    else {
	# Set (or override) Content-Length header
	my $clen = $request_headers->header('Content-Length');
	if (defined($$content_ref) && length($$content_ref)) {
	    $has_content = length($$content_ref);
	    if (!defined($clen) || $clen ne $has_content) {
		if (defined $clen) {
		    warn "Content-Length header value was wrong, fixed";
		    hlist_remove(\@h, 'Content-Length');
		}
		push(@h, 'Content-Length' => $has_content);
	    }
	}
	elsif ($clen) {
	    warn "Content-Length set when there is no content, fixed";
	    hlist_remove(\@h, 'Content-Length');
	}
    }

    my $write_wait = 0;
    $write_wait = 2
	if ($request_headers->header("Expect") || "") =~ /100-continue/;

    my $req_buf = $socket->format_request($method, $fullpath, @h);
    #print "------\n$req_buf\n------\n";

    if (!$has_content || $write_wait || $has_content > 8*1024) {
      WRITE:
        {
            # Since this just writes out the header block it should almost
            # always succeed to send the whole buffer in a single write call.
            my $n = $socket->syswrite($req_buf, length($req_buf));
            unless (defined $n) {
                redo WRITE if $!{EINTR};
                if ($!{EWOULDBLOCK} || $!{EAGAIN}) {
                    select(undef, undef, undef, 0.1);
                    redo WRITE;
                }
                die "write failed: $!";
            }
            if ($n) {
                substr($req_buf, 0, $n, "");
            }
            else {
                select(undef, undef, undef, 0.5);
            }
            redo WRITE if length $req_buf;
        }
    }

    my($code, $mess, @junk);
    my $drop_connection;

    if ($has_content) {
	my $eof;
	my $wbuf;
	my $woffset = 0;
      INITIAL_READ:
	if ($write_wait) {
	    # skip filling $wbuf when waiting for 100-continue
	    # because if the response is a redirect or auth required
	    # the request will be cloned and there is no way
	    # to reset the input stream
	    # return here via the label after the 100-continue is read
	}
	elsif (ref($content_ref) eq 'CODE') {
	    my $buf = &$content_ref();
	    $buf = "" unless defined($buf);
	    $buf = sprintf "%x%s%s%s", length($buf), $CRLF, $buf, $CRLF
		if $chunked;
	    substr($buf, 0, 0) = $req_buf if $req_buf;
	    $wbuf = \$buf;
	}
	else {
	    if ($req_buf) {
		my $buf = $req_buf . $$content_ref;
		$wbuf = \$buf;
	    }
	    else {
		$wbuf = $content_ref;
	    }
	    $eof = 1;
	}

	my $fbits = '';
	vec($fbits, fileno($socket), 1) = 1;

      WRITE:
	while ($write_wait || $woffset < length($$wbuf)) {

	    my $sel_timeout = $timeout;
	    if ($write_wait) {
		$sel_timeout = $write_wait if $write_wait < $sel_timeout;
	    }
	    my $time_before;
            $time_before = time if $sel_timeout;

	    my $rbits = $fbits;
	    my $wbits = $write_wait ? undef : $fbits;
            my $sel_timeout_before = $sel_timeout;
          SELECT:
            {
                my $nfound = select($rbits, $wbits, undef, $sel_timeout);
                if ($nfound < 0) {
                    if ($!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN}) {
                        if ($time_before) {
                            $sel_timeout = $sel_timeout_before - (time - $time_before);
                            $sel_timeout = 0 if $sel_timeout < 0;
                        }
                        redo SELECT;
                    }
                    die "select failed: $!";
                }
	    }

	    if ($write_wait) {
		$write_wait -= time - $time_before;
		$write_wait = 0 if $write_wait < 0;
	    }

	    if (defined($rbits) && $rbits =~ /[^\0]/) {
		# readable
		my $buf = $socket->_rbuf;
		my $n = $socket->sysread($buf, 1024, length($buf));
                unless (defined $n) {
                    die "read failed: $!" unless  $!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN};
                    # if we get here the rest of the block will do nothing
                    # and we will retry the read on the next round
                }
		elsif ($n == 0) {
                    # the server closed the connection before we finished
                    # writing all the request content.  No need to write any more.
                    $drop_connection++;
                    last WRITE;
		}
		$socket->_rbuf($buf);
		if (!$code && $buf =~ /\015?\012\015?\012/) {
		    # a whole response header is present, so we can read it without blocking
		    ($code, $mess, @h) = $socket->read_response_headers(laxed => 1,
									junk_out => \@junk,
								       );
		    if ($code eq "100") {
			$write_wait = 0;
			undef($code);
			goto INITIAL_READ;
		    }
		    else {
			$drop_connection++;
			last WRITE;
			# XXX should perhaps try to abort write in a nice way too
		    }
		}
	    }
	    if (defined($wbits) && $wbits =~ /[^\0]/) {
		my $n = $socket->syswrite($$wbuf, length($$wbuf), $woffset);
                unless (defined $n) {
                    die "write failed: $!" unless $!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN};
                    $n = 0;  # will retry write on the next round
                }
                elsif ($n == 0) {
		    die "write failed: no bytes written";
		}
		$woffset += $n;

		if (!$eof && $woffset >= length($$wbuf)) {
		    # need to refill buffer from $content_ref code
		    my $buf = &$content_ref();
		    $buf = "" unless defined($buf);
		    $eof++ unless length($buf);
		    $buf = sprintf "%x%s%s%s", length($buf), $CRLF, $buf, $CRLF
			if $chunked;
		    $wbuf = \$buf;
		    $woffset = 0;
		}
	    }
	} # WRITE
    }

    ($code, $mess, @h) = $socket->read_response_headers(laxed => 1, junk_out => \@junk)
	unless $code;
    ($code, $mess, @h) = $socket->read_response_headers(laxed => 1, junk_out => \@junk)
	if $code eq "100";

    my $response = HTTP::Response->new($code, $mess);
    my $peer_http_version = $socket->peer_http_version;
    $response->protocol("HTTP/$peer_http_version");
    {
	local $HTTP::Headers::TRANSLATE_UNDERSCORE;
	$response->push_header(@h);
    }
    $response->push_header("Client-Junk" => \@junk) if @junk;

    $response->request($request);
    $self->_get_sock_info($response, $socket);

    if ($method eq "CONNECT") {
	$response->{client_socket} = $socket;  # so it can be picked up
	return $response;
    }

    if (my @te = $response->remove_header('Transfer-Encoding')) {
	$response->push_header('Client-Transfer-Encoding', \@te);
    }
    $response->push_header('Client-Response-Num', scalar $socket->increment_response_count);

    my $complete;
    $response = $self->collect($arg, $response, sub {
	my $buf = ""; #prevent use of uninitialized value in SSLeay.xs
	my $n;
      READ:
	{
	    $n = $socket->read_entity_body($buf, $size);
            unless (defined $n) {
                redo READ if $!{EINTR} || $!{EWOULDBLOCK} || $!{EAGAIN} || $!{ENOTTY};
                die "read failed: $!";
            }
	    redo READ if $n == -1;
	}
	$complete++ if !$n;
        return \$buf;
    } );
    $drop_connection++ unless $complete;

    @h = $socket->get_trailers;
    if (@h) {
	local $HTTP::Headers::TRANSLATE_UNDERSCORE;
	$response->push_header(@h);
    }

    # keep-alive support
    unless ($drop_connection) {
	if ($cache_key) {
	    my %connection = map { (lc($_) => 1) }
		             split(/\s*,\s*/, ($response->header("Connection") || ""));
	    if (($peer_http_version eq "1.1" && !$connection{close}) ||
		$connection{"keep-alive"})
	    {
		$conn_cache->deposit($self->socket_type, $cache_key, $socket);
	    }
	}
    }

    $response;
}


#-----------------------------------------------------------
package # hide from PAUSE
    LWP::Protocol::http::SocketMethods;

sub ping {
    my $self = shift;
    !$self->can_read(0);
}

sub increment_response_count {
    my $self = shift;
    return ++${*$self}{'myhttp_response_count'};
}

#-----------------------------------------------------------
package # hide from PAUSE
    LWP::Protocol::http::Socket;

use parent -norequire, qw(LWP::Protocol::http::SocketMethods Net::HTTP);

1;
