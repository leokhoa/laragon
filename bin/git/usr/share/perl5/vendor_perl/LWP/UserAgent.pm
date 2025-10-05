package LWP::UserAgent;

use strict;

use parent qw(LWP::MemberMixin);

use Carp ();
use File::Copy ();
use HTTP::Request ();
use HTTP::Response ();
use HTTP::Date ();

use LWP ();
use HTTP::Status ();
use LWP::Protocol ();
use Module::Load qw( load );

use Scalar::Util qw(blessed openhandle);
use Try::Tiny qw(try catch);

our $VERSION = '6.77';

sub new
{
    # Check for common user mistake
    Carp::croak("Options to LWP::UserAgent should be key/value pairs, not hash reference")
        if ref($_[1]) eq 'HASH';

    my($class, %cnf) = @_;

    my $agent = delete $cnf{agent};
    my $from  = delete $cnf{from};
    my $def_headers = delete $cnf{default_headers};
    my $timeout = delete $cnf{timeout};
    $timeout = 3*60 unless defined $timeout;
    my $local_address = delete $cnf{local_address};
    my $ssl_opts = delete $cnf{ssl_opts} || {};
    unless (exists $ssl_opts->{verify_hostname}) {
	# The processing of HTTPS_CA_* below is for compatibility with Crypt::SSLeay
	if (exists $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}) {
	    $ssl_opts->{verify_hostname} = $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME};
	}
	elsif ($ENV{HTTPS_CA_FILE} || $ENV{HTTPS_CA_DIR}) {
	    # Crypt-SSLeay compatibility (verify peer certificate; but not the hostname)
	    $ssl_opts->{verify_hostname} = 0;
	    $ssl_opts->{SSL_verify_mode} = 1;
	}
	else {
	    $ssl_opts->{verify_hostname} = 1;
	}
    }
    unless (exists $ssl_opts->{SSL_ca_file}) {
	if (my $ca_file = $ENV{PERL_LWP_SSL_CA_FILE} || $ENV{HTTPS_CA_FILE}) {
	    $ssl_opts->{SSL_ca_file} = $ca_file;
	}
    }
    unless (exists $ssl_opts->{SSL_ca_path}) {
	if (my $ca_path = $ENV{PERL_LWP_SSL_CA_PATH} || $ENV{HTTPS_CA_DIR}) {
	    $ssl_opts->{SSL_ca_path} = $ca_path;
	}
    }
    my $use_eval = delete $cnf{use_eval};
    $use_eval = 1 unless defined $use_eval;
    my $parse_head = delete $cnf{parse_head};
    $parse_head = 1 unless defined $parse_head;
    my $send_te = delete $cnf{send_te};
    $send_te = 1 unless defined $send_te;
    my $show_progress = delete $cnf{show_progress};
    my $max_size = delete $cnf{max_size};
    my $max_redirect = delete $cnf{max_redirect};
    $max_redirect = 7 unless defined $max_redirect;
    my $env_proxy = exists $cnf{env_proxy} ? delete $cnf{env_proxy} : $ENV{PERL_LWP_ENV_PROXY};
    my $no_proxy = exists $cnf{no_proxy} ? delete $cnf{no_proxy} : [];
    Carp::croak(qq{no_proxy must be an arrayref, not $no_proxy!}) if ref $no_proxy ne 'ARRAY';

    my $cookie_jar = delete $cnf{cookie_jar};
    my $conn_cache = delete $cnf{conn_cache};
    my $keep_alive = delete $cnf{keep_alive};

    Carp::croak("Can't mix conn_cache and keep_alive")
	  if $conn_cache && $keep_alive;

    my $protocols_allowed   = delete $cnf{protocols_allowed};
    my $protocols_forbidden = delete $cnf{protocols_forbidden};

    my $requests_redirectable = delete $cnf{requests_redirectable};
    $requests_redirectable = ['GET', 'HEAD']
      unless defined $requests_redirectable;

    my $cookie_jar_class = delete $cnf{cookie_jar_class};
    $cookie_jar_class = 'HTTP::Cookies'
      unless defined $cookie_jar_class;

    # Actually ""s are just as good as 0's, but for concision we'll just say:
    Carp::croak("protocols_allowed has to be an arrayref or 0, not \"$protocols_allowed\"!")
      if $protocols_allowed and ref($protocols_allowed) ne 'ARRAY';
    Carp::croak("protocols_forbidden has to be an arrayref or 0, not \"$protocols_forbidden\"!")
      if $protocols_forbidden and ref($protocols_forbidden) ne 'ARRAY';
    Carp::croak("requests_redirectable has to be an arrayref or 0, not \"$requests_redirectable\"!")
      if $requests_redirectable and ref($requests_redirectable) ne 'ARRAY';

    if (%cnf && $^W) {
	Carp::carp("Unrecognized LWP::UserAgent options: @{[sort keys %cnf]}");
    }

    my $self = bless {
        def_headers           => $def_headers,
        timeout               => $timeout,
        local_address         => $local_address,
        ssl_opts              => $ssl_opts,
        use_eval              => $use_eval,
        show_progress         => $show_progress,
        max_size              => $max_size,
        max_redirect          => $max_redirect,
        # We set proxy later as we do validation on the values
        proxy                 => {},
        no_proxy              => [ @{ $no_proxy } ],
        protocols_allowed     => $protocols_allowed,
        protocols_forbidden   => $protocols_forbidden,
        requests_redirectable => $requests_redirectable,
        send_te               => $send_te,
        cookie_jar_class      => $cookie_jar_class,
    }, $class;

    $self->agent(defined($agent) ? $agent : $class->_agent)
        if defined($agent) || !$def_headers || !$def_headers->header("User-Agent");
    $self->from($from) if $from;
    $self->cookie_jar($cookie_jar) if $cookie_jar;
    $self->parse_head($parse_head);
    $self->env_proxy if $env_proxy;

    if (exists $cnf{proxy}) {
        Carp::croak(qq{proxy must be an arrayref, not $cnf{proxy}!})
            if ref $cnf{proxy} ne 'ARRAY';
        $self->proxy($cnf{proxy});
    }

    $self->protocols_allowed(  $protocols_allowed  ) if $protocols_allowed;
    $self->protocols_forbidden($protocols_forbidden) if $protocols_forbidden;

    if ($keep_alive) {
	$conn_cache ||= { total_capacity => $keep_alive };
    }
    $self->conn_cache($conn_cache) if $conn_cache;

    return $self;
}


sub send_request
{
    my($self, $request, $arg, $size) = @_;
    my($method, $url) = ($request->method, $request->uri);
    my $scheme = $url->scheme;

    local($SIG{__DIE__});  # protect against user defined die handlers

    $self->progress("begin", $request);

    my $response = $self->run_handlers("request_send", $request);

    unless ($response) {
        my $protocol;

        {
            # Honor object-specific restrictions by forcing protocol objects
            #  into class LWP::Protocol::nogo.
            my $x;
            if($x = $self->protocols_allowed) {
                if (grep lc($_) eq $scheme, @$x) {
                }
                else {
                    require LWP::Protocol::nogo;
                    $protocol = LWP::Protocol::nogo->new;
                }
            }
            elsif ($x = $self->protocols_forbidden) {
                if(grep lc($_) eq $scheme, @$x) {
                    require LWP::Protocol::nogo;
                    $protocol = LWP::Protocol::nogo->new;
                }
            }
            # else fall thru and create the protocol object normally
        }

        # Locate protocol to use
        my $proxy = $request->{proxy};
        if ($proxy) {
            $scheme = $proxy->scheme;
        }

        unless ($protocol) {
            try {
                $protocol = LWP::Protocol::create($scheme, $self);
            }
            catch {
                my $error = $_;
                $error =~ s/ at .* line \d+.*//s;  # remove file/line number
                $response =  _new_response($request, HTTP::Status::RC_NOT_IMPLEMENTED, $error);
                if ($scheme eq "https") {
                    $response->message($response->message . " (LWP::Protocol::https not installed)");
                    $response->content_type("text/plain");
                    $response->content(<<EOT);
LWP will support https URLs if the LWP::Protocol::https module
is installed.
EOT
                }
            };
        }

        if (!$response && $self->{use_eval}) {
            # we eval, and turn dies into responses below
            try {
                $response = $protocol->request($request, $proxy, $arg, $size, $self->{timeout}) || die "No response returned by $protocol";
            }
            catch {
                my $error = $_;
                if (blessed($error) && $error->isa("HTTP::Response")) {
                    $response = $error;
                    $response->request($request);
                }
                else {
                    my $full = $error;
                    (my $status = $error) =~ s/\n.*//s;
                    $status =~ s/ at .* line \d+.*//s;  # remove file/line number
                    my $code = ($status =~ s/^(\d\d\d)\s+//) ? $1 : HTTP::Status::RC_INTERNAL_SERVER_ERROR;
                    $response = _new_response($request, $code, $status, $full);
                }
            };
        }
        elsif (!$response) {
            $response = $protocol->request($request, $proxy,
                                           $arg, $size, $self->{timeout});
            # XXX: Should we die unless $response->is_success ???
        }
    }

    $response->request($request);  # record request for reference
    $response->header("Client-Date" => HTTP::Date::time2str(time));

    $self->run_handlers("response_done", $response);

    $self->progress("end", $response);
    return $response;
}


sub prepare_request
{
    my($self, $request) = @_;
    die "Method missing" unless $request->method;
    my $url = $request->uri;
    die "URL missing" unless $url;
    die "URL must be absolute" unless $url->scheme;

    $self->run_handlers("request_preprepare", $request);

    if (my $def_headers = $self->{def_headers}) {
	for my $h ($def_headers->header_field_names) {
	    $request->init_header($h => [$def_headers->header($h)]);
	}
    }

    $self->run_handlers("request_prepare", $request);

    return $request;
}


sub simple_request
{
    my($self, $request, $arg, $size) = @_;

    # sanity check the request passed in
    if (defined $request) {
	if (ref $request) {
	    Carp::croak("You need a request object, not a " . ref($request) . " object")
	      if ref($request) eq 'ARRAY' or ref($request) eq 'HASH' or
		 !$request->can('method') or !$request->can('uri');
	}
	else {
	    Carp::croak("You need a request object, not '$request'");
	}
    }
    else {
        Carp::croak("No request object passed in");
    }

    my $error;
    try {
        $request = $self->prepare_request($request);
    }
    catch {
        $error = $_;
        $error =~ s/ at .* line \d+.*//s;  # remove file/line number
    };

    if ($error) {
        return _new_response($request, HTTP::Status::RC_BAD_REQUEST, $error);
    }
    return $self->send_request($request, $arg, $size);
}


sub request {
    my ($self, $request, $arg, $size, $previous) = @_;

    my $response = $self->simple_request($request, $arg, $size);
    $response->previous($previous) if $previous;

    if ($response->redirects >= $self->{max_redirect}) {
        if ($response->header('Location')) {
            $response->header("Client-Warning" =>
                "Redirect loop detected (max_redirect = $self->{max_redirect})"
            );
        }
        return $response;
    }

    if (my $req = $self->run_handlers("response_redirect", $response)) {
        return $self->request($req, $arg, $size, $response);
    }

    my $code = $response->code;

    if (   $code == HTTP::Status::RC_MOVED_PERMANENTLY
        or $code == HTTP::Status::RC_FOUND
        or $code == HTTP::Status::RC_SEE_OTHER
        or $code == HTTP::Status::RC_TEMPORARY_REDIRECT
        or $code == HTTP::Status::RC_PERMANENT_REDIRECT)
    {
        my $referral = $request->clone;

        # These headers should never be forwarded
        $referral->remove_header('Host', 'Cookie');

        if (   $referral->header('Referer')
            && $request->uri->scheme eq 'https'
            && $referral->uri->scheme eq 'http')
        {
            # RFC 2616, section 15.1.3.
            # https -> http redirect, suppressing Referer
            $referral->remove_header('Referer');
        }

        if (   $code == HTTP::Status::RC_SEE_OTHER
            || $code == HTTP::Status::RC_FOUND)
        {
            my $method = uc($referral->method);
            unless ($method eq "GET" || $method eq "HEAD") {
                $referral->method("GET");
                $referral->content("");
                $referral->remove_content_headers;
            }
        }

        # And then we update the URL based on the Location:-header.
        my $referral_uri = $response->header('Location');
        {
            # Some servers erroneously return a relative URL for redirects,
            # so make it absolute if it not already is.
            local $URI::ABS_ALLOW_RELATIVE_SCHEME = 1;
            my $base = $response->base;
            $referral_uri = "" unless defined $referral_uri;
            $referral_uri
                = $HTTP::URI_CLASS->new($referral_uri, $base)->abs($base);
        }
        $referral->uri($referral_uri);

        return $response unless $self->redirect_ok($referral, $response);
        return $self->request($referral, $arg, $size, $response);

    }
    elsif ($code == HTTP::Status::RC_UNAUTHORIZED
        || $code == HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED)
    {
        my $proxy = ($code == HTTP::Status::RC_PROXY_AUTHENTICATION_REQUIRED);
        my $ch_header
            = $proxy || $request->method eq 'CONNECT'
            ? "Proxy-Authenticate"
            : "WWW-Authenticate";
        my @challenges = $response->header($ch_header);
        unless (@challenges) {
            $response->header(
                "Client-Warning" => "Missing Authenticate header");
            return $response;
        }

        require HTTP::Headers::Util;
        CHALLENGE: for my $challenge (@challenges) {
            $challenge =~ tr/,/;/;    # "," is used to separate auth-params!!
            ($challenge) = HTTP::Headers::Util::split_header_words($challenge);
            my $scheme = shift(@$challenge);
            shift(@$challenge);       # no value
            $challenge = {@$challenge};    # make rest into a hash

            unless ($scheme =~ /^([a-z]+(?:-[a-z]+)*)$/) {
                $response->header(
                    "Client-Warning" => "Bad authentication scheme '$scheme'");
                return $response;
            }
            $scheme = $1;                  # untainted now
            my $class = "LWP::Authen::\u$scheme";
            $class =~ tr/-/_/;

            no strict 'refs';
            unless (%{"$class\::"}) {
                # try to load it
                my $error;
                try {
                    (my $req = $class) =~ s{::}{/}g;
                    $req .= '.pm' unless $req =~ /\.pm$/;
                    require $req;
                }
                catch {
                    $error = $_;
                };
                if ($error) {
                    if ($error =~ /^Can\'t locate/) {
                        $response->header("Client-Warning" =>
                                "Unsupported authentication scheme '$scheme'");
                    }
                    else {
                        $response->header("Client-Warning" => $error);
                    }
                    next CHALLENGE;
                }
            }
            unless ($class->can("authenticate")) {
                $response->header("Client-Warning" =>
                        "Unsupported authentication scheme '$scheme'");
                next CHALLENGE;
            }
            my $re = $class->authenticate($self, $proxy, $challenge, $response,
                $request, $arg, $size);

            next CHALLENGE if $re->code == HTTP::Status::RC_UNAUTHORIZED;
            return $re;
        }
        return $response;
    }
    return $response;
}

#
# Now the shortcuts...
#
sub get {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::GET( @parameters ), @suff );
}

sub _maybe_copy_default_content_type {
    my $self = shift;
    my $req  = shift;

    my $default_ct = $self->default_header('Content-Type');
    return unless defined $default_ct;

    # drop url
    shift;

    # adapted from HTTP::Request::Common::request_type_with_data
    my $content;
    $content = shift if @_ and ref $_[0];

    # We only care about the final value, really
    my $ct;

    my ($k, $v);
    while (($k, $v) = splice(@_, 0, 2)) {
        if (lc($k) eq 'content') {
            $content = $v;
        }
        elsif (lc($k) eq 'content-type') {
            $ct = $v;
        }
    }

    # Content-type provided and truthy? skip
    return if $ct;

    # Content is not just a string? Then it must be x-www-form-urlencoded
    return if defined $content && ref($content);

    # Provide default
    $req->header('Content-Type' => $default_ct);
}

sub post {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    my $req = HTTP::Request::Common::POST(@parameters);
    $self->_maybe_copy_default_content_type($req, @parameters);
    return $self->request($req, @suff);
}


sub head {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::HEAD( @parameters ), @suff );
}

sub patch {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));

    # this work-around is in place as HTTP::Request::Common
    # did not implement a patch convenience method until
    # version 6.12. Once we can bump the prereq to at least
    # that version, we can use ::PATCH instead of this hack
    my $req = HTTP::Request::Common::PUT(@parameters);
    $req->method('PATCH');

    $self->_maybe_copy_default_content_type($req, @parameters);
    return $self->request($req, @suff);
}

sub put {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters, (ref($parameters[1]) ? 2 : 1));
    my $req = HTTP::Request::Common::PUT(@parameters);
    $self->_maybe_copy_default_content_type($req, @parameters);
    return $self->request($req, @suff);
}


sub delete {
    require HTTP::Request::Common;
    my($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,1);
    return $self->request( HTTP::Request::Common::DELETE( @parameters ), @suff );
}


sub _process_colonic_headers {
    # Process :content_cb / :content_file / :read_size_hint headers.
    my($self, $args, $start_index) = @_;

    my($arg, $size);
    for(my $i = $start_index; $i < @$args; $i += 2) {
	next unless defined $args->[$i];

	#printf "Considering %s => %s\n", $args->[$i], $args->[$i + 1];

	if($args->[$i] eq ':content_cb') {
	    # Some sanity-checking...
	    $arg = $args->[$i + 1];
	    Carp::croak("A :content_cb value can't be undef") unless defined $arg;
	    Carp::croak("A :content_cb value must be a coderef")
		unless ref $arg and UNIVERSAL::isa($arg, 'CODE');

	}
	elsif ($args->[$i] eq ':content_file') {
	    $arg = $args->[$i + 1];

	    # Some sanity-checking...
	    Carp::croak("A :content_file value can't be undef")
		unless defined $arg;

	    unless ( defined openhandle($arg) ) {
		    Carp::croak("A :content_file value can't be a reference")
			if ref $arg;
		    Carp::croak("A :content_file value can't be \"\"")
			unless length $arg;
	    }
	}
	elsif ($args->[$i] eq ':read_size_hint') {
	    $size = $args->[$i + 1];
	    # Bother checking it?

	}
	else {
	    next;
	}
	splice @$args, $i, 2;
	$i -= 2;
    }

    # And return a suitable suffix-list for request(REQ,...)

    return             unless defined $arg;
    return $arg, $size if     defined $size;
    return $arg;
}


sub is_online {
    my $self = shift;
    return 1 if $self->get("http://www.msftncsi.com/ncsi.txt")->content eq "Microsoft NCSI";
    return 1 if $self->get("http://www.apple.com")->content =~ m,<title>Apple</title>,;
    return 0;
}


my @ANI = qw(- \ | /);

sub progress {
    my($self, $status, $m) = @_;
    return unless $self->{show_progress};

    local($,, $\);
    if ($status eq "begin") {
        print STDERR "** ", $m->method, " ", $m->uri, " ==> ";
        $self->{progress_start} = time;
        $self->{progress_lastp} = "";
        $self->{progress_ani} = 0;
    }
    elsif ($status eq "end") {
        delete $self->{progress_lastp};
        delete $self->{progress_ani};
        print STDERR $m->status_line;
        my $t = time - delete $self->{progress_start};
        print STDERR " (${t}s)" if $t;
        print STDERR "\n";
    }
    elsif ($status eq "tick") {
        print STDERR "$ANI[$self->{progress_ani}++]\b";
        $self->{progress_ani} %= @ANI;
    }
    else {
        my $p = sprintf "%3.0f%%", $status * 100;
        return if $p eq $self->{progress_lastp};
        print STDERR "$p\b\b\b\b";
        $self->{progress_lastp} = $p;
    }
    STDERR->flush;
}


#
# This whole allow/forbid thing is based on man 1 at's way of doing things.
#
sub is_protocol_supported
{
    my($self, $scheme) = @_;
    if (ref $scheme) {
	# assume we got a reference to an URI object
	$scheme = $scheme->scheme;
    }
    else {
	Carp::croak("Illegal scheme '$scheme' passed to is_protocol_supported")
	    if $scheme =~ /\W/;
	$scheme = lc $scheme;
    }

    my $x;
    if(ref($self) and $x       = $self->protocols_allowed) {
      return 0 unless grep lc($_) eq $scheme, @$x;
    }
    elsif (ref($self) and $x = $self->protocols_forbidden) {
      return 0 if grep lc($_) eq $scheme, @$x;
    }

    local($SIG{__DIE__});  # protect against user defined die handlers
    $x = LWP::Protocol::implementor($scheme);
    return 1 if $x and $x ne 'LWP::Protocol::nogo';
    return 0;
}


sub protocols_allowed      { shift->_elem('protocols_allowed'    , @_) }
sub protocols_forbidden    { shift->_elem('protocols_forbidden'  , @_) }
sub requests_redirectable  { shift->_elem('requests_redirectable', @_) }


sub redirect_ok
{
    # RFC 2616, section 10.3.2 and 10.3.3 say:
    #  If the 30[12] status code is received in response to a request other
    #  than GET or HEAD, the user agent MUST NOT automatically redirect the
    #  request unless it can be confirmed by the user, since this might
    #  change the conditions under which the request was issued.

    # Note that this routine used to be just:
    #  return 0 if $_[1]->method eq "POST";  return 1;

    my($self, $new_request, $response) = @_;
    my $method = $response->request->method;
    return 0 unless grep $_ eq $method,
      @{ $self->requests_redirectable || [] };

    if ($new_request->uri->scheme eq 'file') {
      $response->header("Client-Warning" =>
			"Can't redirect to a file:// URL!");
      return 0;
    }

    # Otherwise it's apparently okay...
    return 1;
}

sub credentials {
    my $self   = shift;
    my $netloc = lc(shift || '');
    my $realm  = shift || "";
    my $old    = $self->{basic_authentication}{$netloc}{$realm};
    if (@_) {
        $self->{basic_authentication}{$netloc}{$realm} = [@_];
    }
    return unless $old;
    return @$old if wantarray;
    return join(":", @$old);
}

sub get_basic_credentials
{
    my($self, $realm, $uri, $proxy) = @_;
    return if $proxy;
    return $self->credentials($uri->host_port, $realm);
}


sub timeout
{
    my $self = shift;
    my $old = $self->{timeout};
    if (@_) {
        $self->{timeout} = shift;
        if (my $conn_cache = $self->conn_cache) {
            for my $conn ($conn_cache->get_connections) {
                $conn->timeout($self->{timeout});
            }
        }
    }
    return $old;
}

sub local_address{ shift->_elem('local_address',@_); }
sub max_size     { shift->_elem('max_size',     @_); }
sub max_redirect { shift->_elem('max_redirect', @_); }
sub show_progress{ shift->_elem('show_progress', @_); }
sub send_te      { shift->_elem('send_te',      @_); }

sub ssl_opts {
    my $self = shift;
    if (@_ == 1) {
	my $k = shift;
	return $self->{ssl_opts}{$k};
    }
    if (@_) {
	my $old;
	while (@_) {
	    my($k, $v) = splice(@_, 0, 2);
	    $old = $self->{ssl_opts}{$k} unless @_;
	    if (defined $v) {
		$self->{ssl_opts}{$k} = $v;
	    }
	    else {
		delete $self->{ssl_opts}{$k};
	    }
	}
	%{$self->{ssl_opts}} = (%{$self->{ssl_opts}}, @_);
	return $old;
    }

    my @opts= sort keys %{$self->{ssl_opts}};
    return @opts;
}

sub parse_head {
    my $self = shift;
    if (@_) {
        my $flag = shift;
        my $parser;
        my $old = $self->set_my_handler("response_header", $flag ? sub {
               my($response, $ua) = @_;
               require HTML::HeadParser;
               $parser = HTML::HeadParser->new;
               $parser->xml_mode(1) if $response->content_is_xhtml;
               $parser->utf8_mode(1) if $HTML::Parser::VERSION >= 3.40;

               push(@{$response->{handlers}{response_data}}, {
		   callback => sub {
		       return unless $parser;
		       unless ($parser->parse($_[3])) {
			   my $h = $parser->header;
			   my $r = $_[0];
			   for my $f ($h->header_field_names) {
			       $r->init_header($f, [$h->header($f)]);
			   }
			   undef($parser);
		       }
		   },
	       });

            } : undef,
            m_media_type => "html",
        );
        return !!$old;
    }
    else {
        return !!$self->get_my_handler("response_header");
    }
}

sub cookie_jar {
    my $self = shift;
    my $old = $self->{cookie_jar};

    return $old unless @_;

    my $jar = shift;
    if (ref($jar) eq "HASH") {
        my $class = $self->{cookie_jar_class};
        try {
            load($class);
            $jar = $class->new(%$jar);
        }
        catch {
            my $error = $_;
            if ($error =~ /Can't locate/) {
                die "cookie_jar_class '$class' not found\n";
            }
            else {
                die "$error\n";
            }
        };
    }
    $self->{cookie_jar} = $jar;
    $self->set_my_handler("request_prepare",
        $jar ? sub {
            return if $_[0]->header("Cookie");
            $jar->add_cookie_header($_[0]);
        } : undef,
    );
    $self->set_my_handler("response_done",
        $jar ? sub { $jar->extract_cookies($_[0]); } : undef,
    );

    return $old;
}

sub default_headers {
    my $self = shift;
    my $old = $self->{def_headers} ||= HTTP::Headers->new;
    if (@_) {
	Carp::croak("default_headers not set to HTTP::Headers compatible object")
	    unless @_ == 1 && $_[0]->can("header_field_names");
	$self->{def_headers} = shift;
    }
    return $old;
}

sub default_header {
    my $self = shift;
    return $self->default_headers->header(@_);
}

sub _agent { "libwww-perl/$VERSION" }

sub agent {
    my $self = shift;
    if (@_) {
	my $agent = shift;
        if ($agent) {
            $agent .= $self->_agent if $agent =~ /\s+$/;
        }
        else {
            undef($agent)
        }
        return $self->default_header("User-Agent", $agent);
    }
    return $self->default_header("User-Agent");
}

sub from {  # legacy
    my $self = shift;
    return $self->default_header("From", @_);
}


sub conn_cache {
    my $self = shift;
    my $old  = $self->{conn_cache};
    if (@_) {
        my $cache = shift;
        if ( ref($cache) eq "HASH" ) {
            require LWP::ConnCache;
            $cache = LWP::ConnCache->new(%$cache);
        }
        elsif ( defined $cache)  {
            for my $conn ( $cache->get_connections ) {
                $conn->timeout( $self->timeout );
            }
        }
        $self->{conn_cache} = $cache;
    }
    return $old;
}


sub add_handler {
    my($self, $phase, $cb, %spec) = @_;
    $spec{line} ||= join(":", (caller)[1,2]);
    my $conf = $self->{handlers}{$phase} ||= do {
        require HTTP::Config;
        HTTP::Config->new;
    };
    $conf->add(%spec, callback => $cb);
}

sub set_my_handler {
    my($self, $phase, $cb, %spec) = @_;
    $spec{owner} = (caller(1))[3] unless exists $spec{owner};
    $self->remove_handler($phase, %spec);
    $spec{line} ||= join(":", (caller)[1,2]);
    $self->add_handler($phase, $cb, %spec) if $cb;
}

sub get_my_handler {
    my $self = shift;
    my $phase = shift;
    my $init = pop if @_ % 2;
    my %spec = @_;
    my $conf = $self->{handlers}{$phase};
    unless ($conf) {
        return unless $init;
        require HTTP::Config;
        $conf = $self->{handlers}{$phase} = HTTP::Config->new;
    }
    $spec{owner} = (caller(1))[3] unless exists $spec{owner};
    my @h = $conf->find(%spec);
    if (!@h && $init) {
        if (ref($init) eq "CODE") {
            $init->(\%spec);
        }
        elsif (ref($init) eq "HASH") {
            $spec{$_}= $init->{$_}
                for keys %$init;
        }
        $spec{callback} ||= sub {};
        $spec{line} ||= join(":", (caller)[1,2]);
        $conf->add(\%spec);
        return \%spec;
    }
    return wantarray ? @h : $h[0];
}

sub remove_handler {
    my($self, $phase, %spec) = @_;
    if ($phase) {
        my $conf = $self->{handlers}{$phase} || return;
        my @h = $conf->remove(%spec);
        delete $self->{handlers}{$phase} if $conf->empty;
        return @h;
    }

    return unless $self->{handlers};
    return map $self->remove_handler($_), sort keys %{$self->{handlers}};
}

sub handlers {
    my($self, $phase, $o) = @_;
    my @h;
    if ($o->{handlers} && $o->{handlers}{$phase}) {
        push(@h, @{$o->{handlers}{$phase}});
    }
    if (my $conf = $self->{handlers}{$phase}) {
        push(@h, $conf->matching($o));
    }
    return @h;
}

sub run_handlers {
    my($self, $phase, $o) = @_;

    # here we pass $_[2] to the callbacks, instead of $o, so that they
    # can assign to it; e.g. request_prepare is documented to allow
    # that
    if (defined(wantarray)) {
        for my $h ($self->handlers($phase, $o)) {
            my $ret = $h->{callback}->($_[2], $self, $h);
            return $ret if $ret;
        }
        return undef;
    }

    for my $h ($self->handlers($phase, $o)) {
        $h->{callback}->($_[2], $self, $h);
    }
}


# deprecated
sub use_eval   { shift->_elem('use_eval',  @_); }
sub use_alarm
{
    Carp::carp("LWP::UserAgent->use_alarm(BOOL) is a no-op")
	if @_ > 1 && $^W;
    "";
}


sub clone
{
    my $self = shift;
    my $copy = bless { %$self }, ref $self;  # copy most fields

    delete $copy->{handlers};
    delete $copy->{conn_cache};

    # copy any plain arrays and hashes; known not to need recursive copy
    for my $k (qw(proxy no_proxy requests_redirectable ssl_opts)) {
        next unless $copy->{$k};
        if (ref($copy->{$k}) eq "ARRAY") {
            $copy->{$k} = [ @{$copy->{$k}} ];
        }
        elsif (ref($copy->{$k}) eq "HASH") {
            $copy->{$k} = { %{$copy->{$k}} };
        }
    }

    if ($self->{def_headers}) {
        $copy->{def_headers} = $self->{def_headers}->clone;
    }

    # re-enable standard handlers
    $copy->parse_head($self->parse_head);

    # no easy way to clone the cookie jar; so let's just remove it for now
    $copy->cookie_jar(undef);

    $copy;
}


sub mirror
{
    my($self, $url, $file) = @_;

    die "Local file name is missing" unless defined $file && length $file;

    my $request = HTTP::Request->new('GET', $url);

    # If the file exists, add a cache-related header
    if ( -e $file ) {
        my ($mtime) = ( stat($file) )[9];
        if ($mtime) {
            $request->header( 'If-Modified-Since' => HTTP::Date::time2str($mtime) );
        }
    }

    require File::Temp;
    my ($tmpfh, $tmpfile) = File::Temp::tempfile("$file-XXXXXX");
    close($tmpfh) or die "Could not close tmpfile '$tmpfile': $!";

    my $response = $self->request($request, $tmpfile);
    if ( $response->header('X-Died') ) {
        unlink($tmpfile);
        die $response->header('X-Died');
    }

    # Only fetching a fresh copy of the file would be considered success.
    # If the file was not modified, "304" would returned, which
    # is considered by HTTP::Status to be a "redirect", /not/ "success"
    if ( $response->is_success ) {
        my @stat        = stat($tmpfile) or die "Could not stat tmpfile '$tmpfile': $!";
        my $file_length = $stat[7];
        my ($content_length) = $response->header('Content-length');

        if ( defined $content_length and $file_length < $content_length ) {
            unlink($tmpfile);
            die "Transfer truncated: only $file_length out of $content_length bytes received\n";
        }
        elsif ( defined $content_length and $file_length > $content_length ) {
            unlink($tmpfile);
            die "Content-length mismatch: expected $content_length bytes, got $file_length\n";
        }
        # The file was the expected length.
        else {
            # Replace the stale file with a fresh copy
            # File::Copy will attempt to do it atomically,
            # and fall back to a delete + copy if that fails.
            File::Copy::move( $tmpfile, $file )
                or die "Cannot rename '$tmpfile' to '$file': $!\n";

            # Set standard file permissions if umask is supported.
            # If not, leave what File::Temp created in effect.
            if ( defined(my $umask = umask()) ) {
                my $mode = 0666 &~ $umask;
                chmod $mode, $file
                    or die sprintf("Cannot chmod %o '%s': %s\n", $mode, $file, $!);
            }

            # make sure the file has the same last modification time
            if ( my $lm = $response->last_modified ) {
                utime $lm, $lm, $file
                    or warn "Cannot update modification time of '$file': $!\n";
            }
        }
    }
    # The local copy is fresh enough, so just delete the temp file
    else {
        unlink($tmpfile);
    }
    return $response;
}


sub _need_proxy {
    my($req, $ua) = @_;
    return if exists $req->{proxy};
    my $proxy = $ua->{proxy}{$req->uri->scheme} || return;
    if ($ua->{no_proxy}) {
        if (my $host = eval { $req->uri->host }) {
            for my $domain (@{$ua->{no_proxy}}) {
                $domain =~ s/^\.//;
                return if $host =~ /(?:^|\.)\Q$domain\E$/;
            }
        }
    }
    $req->{proxy} = $HTTP::URI_CLASS->new($proxy);
}


sub proxy {
    my $self = shift;
    my $key  = shift;
    if (!@_ && ref $key eq 'ARRAY') {
        die 'odd number of items in proxy arrayref!' unless @{$key} % 2 == 0;

        # This map reads the elements of $key 2 at a time
        return
            map { $self->proxy($key->[2 * $_], $key->[2 * $_ + 1]) }
            (0 .. @{$key} / 2 - 1);
    }
    return map { $self->proxy($_, @_) } @$key if ref $key;

    Carp::croak("'$key' is not a valid URI scheme") unless $key =~ /^$URI::scheme_re\z/;
    my $old = $self->{'proxy'}{$key};
    if (@_) {
        my $url = shift;
        if (defined($url) && length($url)) {
            Carp::croak("Proxy must be specified as absolute URI; '$url' is not") unless $url =~ /^$URI::scheme_re:/;
            Carp::croak("Bad http proxy specification '$url'") if $url =~ /^https?:/ && $url !~ m,^https?://[\w[],;
        }
        $self->{proxy}{$key} = $url;
        $self->set_my_handler("request_preprepare", \&_need_proxy)
    }
    return $old;
}


sub env_proxy {
    my ($self) = @_;
    require Encode;
    require Encode::Locale;
    my $env_request_method= $ENV{REQUEST_METHOD};
    my %seen;
    foreach my $k (sort keys %ENV) {
        my $real_key= $k;
        my $v= $ENV{$k}
            or next;
        if ( $env_request_method ) {
            # Need to be careful when called in the CGI environment, as
            # the HTTP_PROXY variable is under control of that other guy.
            next if $k =~ /^HTTP_/;
            $k = "HTTP_PROXY" if $k eq "CGI_HTTP_PROXY";
        }
	$k = lc($k);
        if (my $from_key= $seen{$k}) {
            warn "Environment contains multiple differing definitions for '$k'.\n".
                 "Using value from '$from_key' ($ENV{$from_key}) and ignoring '$real_key' ($v)"
                if $v ne $ENV{$from_key};
            next;
        } else {
            $seen{$k}= $real_key;
        }

	next unless $k =~ /^(.*)_proxy$/;
	$k = $1;
	if ($k eq 'no') {
	    $self->no_proxy(split(/\s*,\s*/, $v));
	}
	else {
            # Ignore random _proxy variables, allow only valid schemes
            next unless $k =~ /^$URI::scheme_re\z/;
            # Ignore xxx_proxy variables if xxx isn't a supported protocol
            next unless LWP::Protocol::implementor($k);
	    $self->proxy($k, Encode::decode(locale => $v));
	}
    }
}


sub no_proxy {
    my($self, @no) = @_;
    if (@no) {
	push(@{ $self->{'no_proxy'} }, @no);
    }
    else {
	$self->{'no_proxy'} = [];
    }
}


sub _new_response {
    my($request, $code, $message, $content) = @_;
    $message ||= HTTP::Status::status_message($code);
    my $response = HTTP::Response->new($code, $message);
    $response->request($request);
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    $response->header("Client-Warning" => "Internal response");
    $response->header("Content-Type" => "text/plain");
    $response->content($content || "$code $message\n");
    return $response;
}


1;

__END__

=pod

=head1 NAME

LWP::UserAgent - Web user agent class

=head1 SYNOPSIS

    use strict;
    use warnings;

    use LWP::UserAgent ();

    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->env_proxy;

    my $response = $ua->get('http://example.com');

    if ($response->is_success) {
        print $response->decoded_content;
    }
    else {
        die $response->status_line;
    }

Extra layers of security (note the C<cookie_jar> and C<protocols_allowed>):

    use strict;
    use warnings;

    use HTTP::CookieJar::LWP ();
    use LWP::UserAgent       ();

    my $jar = HTTP::CookieJar::LWP->new;
    my $ua  = LWP::UserAgent->new(
        cookie_jar        => $jar,
        protocols_allowed => ['http', 'https'],
        timeout           => 10,
    );

    $ua->env_proxy;

    my $response = $ua->get('http://example.com');

    if ($response->is_success) {
        print $response->decoded_content;
    }
    else {
        die $response->status_line;
    }

=head1 DESCRIPTION

The L<LWP::UserAgent> is a class implementing a web user agent.
L<LWP::UserAgent> objects can be used to dispatch web requests.

In normal use the application creates an L<LWP::UserAgent> object, and
then configures it with values for timeouts, proxies, name, etc. It
then creates an instance of L<HTTP::Request> for the request that
needs to be performed. This request is then passed to one of the
request method the UserAgent, which dispatches it using the relevant
protocol, and returns a L<HTTP::Response> object.  There are
convenience methods for sending the most common request types:
L<LWP::UserAgent/get>, L<LWP::UserAgent/head>, L<LWP::UserAgent/post>,
L<LWP::UserAgent/put> and L<LWP::UserAgent/delete>.  When using these
methods, the creation of the request object is hidden as shown in the
synopsis above.

The basic approach of the library is to use HTTP-style communication
for all protocol schemes.  This means that you will construct
L<HTTP::Request> objects and receive L<HTTP::Response> objects even
for non-HTTP resources like I<gopher> and I<ftp>.  In order to achieve
even more similarity to HTTP-style communications, I<gopher> menus and
file directories are converted to HTML documents.

=head1 CONSTRUCTOR METHODS

The following constructor methods are available:

=head2 clone

    my $ua2 = $ua->clone;

Returns a copy of the L<LWP::UserAgent> object.

B<CAVEAT>: Please be aware that the clone method does not copy or clone your
C<cookie_jar> attribute. Due to the limited restrictions on what can be used
for your cookie jar, there is no way to clone the attribute. The C<cookie_jar>
attribute will be C<undef> in the new object instance.

=head2 new

    my $ua = LWP::UserAgent->new( %options )

This method constructs a new L<LWP::UserAgent> object and returns it.
Key/value pair arguments may be provided to set up the initial state.
The following options correspond to attribute methods described below:

   KEY                     DEFAULT
   -----------             --------------------
   agent                   "libwww-perl/#.###"
   conn_cache              undef
   cookie_jar              undef
   cookie_jar_class        HTTP::Cookies
   default_headers         HTTP::Headers->new
   from                    undef
   local_address           undef
   max_redirect            7
   max_size                undef
   no_proxy                []
   parse_head              1
   protocols_allowed       undef
   protocols_forbidden     undef
   proxy                   {}
   requests_redirectable   ['GET', 'HEAD']
   send_te                 1
   show_progress           undef
   ssl_opts                { verify_hostname => 1 }
   timeout                 180

The following additional options are also accepted: If the C<env_proxy> option
is passed in with a true value, then proxy settings are read from environment
variables (see L<LWP::UserAgent/env_proxy>). If C<env_proxy> isn't provided, the
C<PERL_LWP_ENV_PROXY> environment variable controls if
L<LWP::UserAgent/env_proxy> is called during initialization.  If the
C<keep_alive> option value is defined and non-zero, then an C<LWP::ConnCache> is set up (see
L<LWP::UserAgent/conn_cache>).  The C<keep_alive> value is passed on as the
C<total_capacity> for the connection cache.

C<proxy> must be set as an arrayref of key/value pairs. C<no_proxy> takes an
arrayref of domains.

=head1 ATTRIBUTES

The settings of the configuration attributes modify the behaviour of the
L<LWP::UserAgent> when it dispatches requests.  Most of these can also
be initialized by options passed to the constructor method.

The following attribute methods are provided.  The attribute value is
left unchanged if no argument is given.  The return value from each
method is the old attribute value.

=head2 agent

    my $agent = $ua->agent;
    $ua->agent('Checkbot/0.4 ');    # append the default to the end
    $ua->agent('Mozilla/5.0');
    $ua->agent("");                 # don't identify

Get/set the product token that is used to identify the user agent on
the network. The agent value is sent as the C<User-Agent> header in
the requests.

The default is a string of the form C<libwww-perl/#.###>, where C<#.###> is
substituted with the version number of this library.

If the provided string ends with space, the default C<libwww-perl/#.###>
string is appended to it.

The user agent string should be one or more simple product identifiers
with an optional version number separated by the C</> character.

=head2 conn_cache

    my $cache_obj = $ua->conn_cache;
    $ua->conn_cache( $cache_obj );

Get/set the L<LWP::ConnCache> object to use.  See L<LWP::ConnCache>
for details.

=head2 cookie_jar

    my $jar = $ua->cookie_jar;
    $ua->cookie_jar( $cookie_jar_obj );

Get/set the cookie jar object to use.  The only requirement is that
the cookie jar object must implement the C<extract_cookies($response)> and
C<add_cookie_header($request)> methods.  These methods will then be
invoked by the user agent as requests are sent and responses are
received.  Normally this will be a L<HTTP::Cookies> object or some
subclass.  You are, however, encouraged to use L<HTTP::CookieJar::LWP>
instead.  See L</"BEST PRACTICES"> for more information.

    use HTTP::CookieJar::LWP ();

    my $jar = HTTP::CookieJar::LWP->new;
    my $ua = LWP::UserAgent->new( cookie_jar => $jar );

    # or after object creation
    $ua->cookie_jar( $cookie_jar );

The default is to have no cookie jar, i.e. never automatically add
C<Cookie> headers to the requests.

If C<$jar> contains an unblessed hash reference, a new cookie jar object is
created for you automatically. The object is of the class set with the
C<cookie_jar_class> constructor argument, which defaults to L<HTTP::Cookies>.

  $ua->cookie_jar({ file => "$ENV{HOME}/.cookies.txt" });

is really just a shortcut for:

  require HTTP::Cookies;
  $ua->cookie_jar(HTTP::Cookies->new(file => "$ENV{HOME}/.cookies.txt"));

As described above and in L</"BEST PRACTICES">, you should set
C<cookie_jar_class> to C<"HTTP::CookieJar::LWP"> to get a safer cookie jar.

  my $ua = LWP::UserAgent->new( cookie_jar_class => 'HTTP::CookieJar::LWP' );
  $ua->cookie_jar({}); # HTTP::CookieJar::LWP takes no args

These can also be combined into the constructor, so a jar is created at
instantiation.

  my $ua = LWP::UserAgent->new(
    cookie_jar_class => 'HTTP::CookieJar::LWP',
    cookie_jar       =>  {},
  );

=head2 credentials

    my $creds = $ua->credentials();
    $ua->credentials( $netloc, $realm );
    $ua->credentials( $netloc, $realm, $uname, $pass );
    $ua->credentials("www.example.com:80", "Some Realm", "foo", "secret");

Get/set the user name and password to be used for a realm.

The C<$netloc> is a string of the form C<< <host>:<port> >>.  The username and
password will only be passed to this server.

=head2 default_header

    $ua->default_header( $field );
    $ua->default_header( $field => $value );
    $ua->default_header('Accept-Encoding' => scalar HTTP::Message::decodable());
    $ua->default_header('Accept-Language' => "no, en");

This is just a shortcut for
C<< $ua->default_headers->header( $field => $value ) >>.

=head2 default_headers

    my $headers = $ua->default_headers;
    $ua->default_headers( $headers_obj );

Get/set the headers object that will provide default header values for
any requests sent.  By default this will be an empty L<HTTP::Headers>
object.

=head2 from

    my $from = $ua->from;
    $ua->from('foo@bar.com');

Get/set the email address for the human user who controls
the requesting user agent.  The address should be machine-usable, as
defined in L<RFC2822|https://tools.ietf.org/html/rfc2822>. The C<from> value
is sent as the C<From> header in the requests.

The default is to not send a C<From> header.  See
L<LWP::UserAgent/default_headers> for the more general interface that allow
any header to be defaulted.


=head2 local_address

    my $address = $ua->local_address;
    $ua->local_address( $address );

Get/set the local interface to bind to for network connections.  The interface
can be specified as a hostname or an IP address.  This value is passed as the
C<LocalAddr> argument to L<IO::Socket::INET>.

=head2 max_redirect

    my $max = $ua->max_redirect;
    $ua->max_redirect( $n );

This reads or sets the object's limit of how many times it will obey
redirection responses in a given request cycle.

By default, the value is C<7>. This means that if you call L<LWP::UserAgent/request>
and the response is a redirect elsewhere which is in turn a
redirect, and so on seven times, then LWP gives up after that seventh
request.

=head2 max_size

    my $size = $ua->max_size;
    $ua->max_size( $bytes );

Get/set the size limit for response content.  The default is C<undef>,
which means that there is no limit.  If the returned response content
is only partial, because the size limit was exceeded, then a
C<Client-Aborted> header will be added to the response.  The content
might end up longer than C<max_size> as we abort once appending a
chunk of data makes the length exceed the limit.  The C<Content-Length>
header, if present, will indicate the length of the full content and
will normally not be the same as C<< length($res->content) >>.

=head2 parse_head

    my $bool = $ua->parse_head;
    $ua->parse_head( $boolean );

Get/set a value indicating whether we should initialize response
headers from the E<lt>head> section of HTML documents. The default is
true. I<Do not turn this off> unless you know what you are doing.

=head2 protocols_allowed

    my $aref = $ua->protocols_allowed;      # get allowed protocols
    $ua->protocols_allowed( \@protocols );  # allow ONLY these
    $ua->protocols_allowed(undef);          # delete the list
    $ua->protocols_allowed(['http',]);      # ONLY allow http

By default, an object has neither a C<protocols_allowed> list, nor a
L<LWP::UserAgent/protocols_forbidden> list.

This reads (or sets) this user agent's list of protocols that the
request methods will exclusively allow.  The protocol names are case
insensitive.

For example: C<< $ua->protocols_allowed( [ 'http', 'https'] ); >>
means that this user agent will I<allow only> those protocols,
and attempts to use this user agent to access URLs with any other
schemes (like C<ftp://...>) will result in a 500 error.

Note that having a C<protocols_allowed> list causes any
L<LWP::UserAgent/protocols_forbidden> list to be ignored.

=head2 protocols_forbidden

    my $aref = $ua->protocols_forbidden;    # get the forbidden list
    $ua->protocols_forbidden(\@protocols);  # do not allow these
    $ua->protocols_forbidden(['http',]);    # All http reqs get a 500
    $ua->protocols_forbidden(undef);        # delete the list

This reads (or sets) this user agent's list of protocols that the
request method will I<not> allow. The protocol names are case
insensitive.

For example: C<< $ua->protocols_forbidden( [ 'file', 'mailto'] ); >>
means that this user agent will I<not> allow those protocols, and
attempts to use this user agent to access URLs with those schemes
will result in a 500 error.

=head2 requests_redirectable

    my $aref = $ua->requests_redirectable;
    $ua->requests_redirectable( \@requests );
    $ua->requests_redirectable(['GET', 'HEAD',]); # the default

This reads or sets the object's list of request names that
L<LWP::UserAgent/redirect_ok> will allow redirection for. By default, this
is C<['GET', 'HEAD']>, as per L<RFC 2616|https://tools.ietf.org/html/rfc2616>.
To change to include C<POST>, consider:

   push @{ $ua->requests_redirectable }, 'POST';

=head2 send_te

    my $bool = $ua->send_te;
    $ua->send_te( $boolean );

If true, will send a C<TE> header along with the request. The default is
true. Set it to false to disable the C<TE> header for systems who can't
handle it.

=head2 show_progress

    my $bool = $ua->show_progress;
    $ua->show_progress( $boolean );

Get/set a value indicating whether a progress bar should be displayed
on the terminal as requests are processed. The default is false.

=head2 ssl_opts

    my @keys = $ua->ssl_opts;
    my $val = $ua->ssl_opts( $key );
    $ua->ssl_opts( $key => $value );

Get/set the options for SSL connections.  Without argument return the list
of options keys currently set.  With a single argument return the current
value for the given option.  With 2 arguments set the option value and return
the old.  Setting an option to the value C<undef> removes this option.

The options that LWP relates to are:

=over

=item C<verify_hostname> => $bool

When TRUE LWP will for secure protocol schemes ensure it connects to servers
that have a valid certificate matching the expected hostname.  If FALSE no
checks are made and you can't be sure that you communicate with the expected peer.
The no checks behaviour was the default for libwww-perl-5.837 and earlier releases.

This option is initialized from the C<PERL_LWP_SSL_VERIFY_HOSTNAME> environment
variable.  If this environment variable isn't set; then C<verify_hostname>
defaults to 1.

Please note that that recently the overall effect of this option with regards to
SSL handling has changed. As of version 6.11 of L<LWP::Protocol::https>, which is an
external module, SSL certificate verification was harmonized to behave in sync with
L<IO::Socket::SSL>. With this change, setting this option no longer disables all SSL
certificate verification, only the hostname checks. To disable all verification,
use the C<SSL_verify_mode> option in the C<ssl_opts> attribute. For example:
C<$ua->ssl_opts(SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE);>

=item C<SSL_ca_file> => $path

The path to a file containing Certificate Authority certificates.
A default setting for this option is provided by checking the environment
variables C<PERL_LWP_SSL_CA_FILE> and C<HTTPS_CA_FILE> in order.

=item C<SSL_ca_path> => $path

The path to a directory containing files containing Certificate Authority
certificates.
A default setting for this option is provided by checking the environment
variables C<PERL_LWP_SSL_CA_PATH> and C<HTTPS_CA_DIR> in order.

=back

Other options can be set and are processed directly by the SSL Socket implementation
in use.  See L<IO::Socket::SSL> or L<Net::SSL> for details.

The libwww-perl core no longer bundles protocol plugins for SSL.  You will need
to install L<LWP::Protocol::https> separately to enable support for processing
https-URLs.

=head2 timeout

    my $secs = $ua->timeout;
    $ua->timeout( $secs );

Get/set the timeout value in seconds. The default value is
180 seconds, i.e. 3 minutes.

The request is aborted if no activity on the connection to the server
is observed for C<timeout> seconds.  This means that the time it takes
for the complete transaction and the L<LWP::UserAgent/request> method to
actually return might be longer.

When a request times out, a response object is still returned.  The response
will have a standard HTTP Status Code (500).  This response will have the
"Client-Warning" header set to the value of "Internal response".  See the
L<LWP::UserAgent/get> method description below for further details.

=head1 PROXY ATTRIBUTES

The following methods set up when requests should be passed via a
proxy server.

=head2 env_proxy

    $ua->env_proxy;

Load proxy settings from C<*_proxy> environment variables.  You might
specify proxies like this (sh-syntax):

  gopher_proxy=http://proxy.my.place/
  wais_proxy=http://proxy.my.place/
  no_proxy="localhost,example.com"
  export gopher_proxy wais_proxy no_proxy

csh or tcsh users should use the C<setenv> command to define these
environment variables.

On systems with case insensitive environment variables there exists a
name clash between the CGI environment variables and the C<HTTP_PROXY>
environment variable normally picked up by C<env_proxy>.  Because of
this C<HTTP_PROXY> is not honored for CGI scripts.  The
C<CGI_HTTP_PROXY> environment variable can be used instead.

=head2 no_proxy

    $ua->no_proxy( @domains );
    $ua->no_proxy('localhost', 'example.com');
    $ua->no_proxy(); # clear the list

Do not proxy requests to the given domains, including subdomains.
Calling C<no_proxy> without any domains clears the list of domains.

=head2 proxy

    $ua->proxy(\@schemes, $proxy_url)
    $ua->proxy(['http', 'ftp'], 'http://proxy.sn.no:8001/');

    # For a single scheme:
    $ua->proxy($scheme, $proxy_url)
    $ua->proxy('gopher', 'http://proxy.sn.no:8001/');

    # To set multiple proxies at once:
    $ua->proxy([
        ftp => 'http://ftp.example.com:8001/',
        [ 'http', 'https' ] => 'http://http.example.com:8001/',
    ]);

Set/retrieve proxy URL for a scheme.

The first form specifies that the URL is to be used as a proxy for
access methods listed in the list in the first method argument,
i.e. C<http> and C<ftp>.

The second form shows a shorthand form for specifying
proxy URL for a single access scheme.

The third form demonstrates setting multiple proxies at once. This is also
the only form accepted by the constructor.

=head1 HANDLERS

Handlers are code that injected at various phases during the
processing of requests.  The following methods are provided to manage
the active handlers:

=head2 add_handler

    $ua->add_handler( $phase => \&cb, %matchspec )

Add handler to be invoked in the given processing phase.  For how to
specify C<%matchspec> see L<HTTP::Config/"Matching">.

The possible values C<$phase> and the corresponding callback signatures are as
follows.  Note that the handlers are documented in the order in which they will
be run, which is:

    request_preprepare
    request_prepare
    request_send
    response_header
    response_data
    response_done
    response_redirect

=over

=item request_preprepare => sub { my($request, $ua, $handler) = @_; ... }

The handler is called before the C<request_prepare> and other standard
initialization of the request.  This can be used to set up headers
and attributes that the C<request_prepare> handler depends on.  Proxy
initialization should take place here; but in general don't register
handlers for this phase.

=item request_prepare => sub { my($request, $ua, $handler) = @_; ... }

The handler is called before the request is sent and can modify the
request any way it see fit.  This can for instance be used to add
certain headers to specific requests.

The method can assign a new request object to C<$_[0]> to replace the
request that is sent fully.

The return value from the callback is ignored.  If an exception is
raised it will abort the request and make the request method return a
"400 Bad request" response.

=item request_send => sub { my($request, $ua, $handler) = @_; ... }

This handler gets a chance of handling requests before they're sent to the
protocol handlers.  It should return an L<HTTP::Response> object if it
wishes to terminate the processing; otherwise it should return nothing.

The C<response_header> and C<response_data> handlers will not be
invoked for this response, but the C<response_done> will be.

=item response_header => sub { my($response, $ua, $handler) = @_; ... }

This handler is called right after the response headers have been
received, but before any content data.  The handler might set up
handlers for data and might croak to abort the request.

The handler might set the C<< $response->{default_add_content} >> value to
control if any received data should be added to the response object
directly.  This will initially be false if the C<< $ua->request() >> method
was called with a C<$content_file> or C<$content_cb argument>; otherwise true.

=item response_data => sub { my($response, $ua, $handler, $data) = @_; ... }

This handler is called for each chunk of data received for the
response.  The handler might croak to abort the request.

This handler needs to return a TRUE value to be called again for
subsequent chunks for the same request.

=item response_done => sub { my($response, $ua, $handler) = @_; ... }

The handler is called after the response has been fully received, but
before any redirect handling is attempted.  The handler can be used to
extract information or modify the response.

=item response_redirect => sub { my($response, $ua, $handler) = @_; ... }

The handler is called in C<< $ua->request >> after C<response_done>.  If the
handler returns an L<HTTP::Request> object we'll start over with processing
this request instead.

=back

For all of these, C<$handler> is a code reference to the handler that
is currently being run.

=head2 get_my_handler

    $ua->get_my_handler( $phase, %matchspec );
    $ua->get_my_handler( $phase, %matchspec, $init );

Will retrieve the matching handler as hash ref.

If C<$init> is passed as a true value, create and add the
handler if it's not found.  If C<$init> is a subroutine reference, then
it's called with the created handler hash as argument.  This sub might
populate the hash with extra fields; especially the callback.  If
C<$init> is a hash reference, merge the hashes.

=head2 handlers

    $ua->handlers( $phase, $request )
    $ua->handlers( $phase, $response )

Returns the handlers that apply to the given request or response at
the given processing phase.

=head2 remove_handler

    $ua->remove_handler( undef, %matchspec );
    $ua->remove_handler( $phase, %matchspec );
    $ua->remove_handler(); # REMOVE ALL HANDLERS IN ALL PHASES

Remove handlers that match the given C<%matchspec>.  If C<$phase> is not
provided, remove handlers from all phases.

Be careful as calling this function with C<%matchspec> that is not
specific enough can remove handlers not owned by you.  It's probably
better to use the L<LWP::UserAgent/set_my_handler> method instead.

The removed handlers are returned.

=head2 set_my_handler

    $ua->set_my_handler( $phase, $cb, %matchspec );
    $ua->set_my_handler($phase, undef); # remove handler for phase

Set handlers private to the executing subroutine.  Works by defaulting
an C<owner> field to the C<%matchspec> that holds the name of the called
subroutine.  You might pass an explicit C<owner> to override this.

If C<$cb> is passed as C<undef>, remove the handler.

=head1 REQUEST METHODS

The methods described in this section are used to dispatch requests
via the user agent.  The following request methods are provided:

=head2 delete

    my $res = $ua->delete( $url );
    my $res = $ua->delete( $url, $field_name => $value, ... );

This method will dispatch a C<DELETE> request on the given URL.  Additional
headers and content options are the same as for the L<LWP::UserAgent/get>
method.

This method will use the C<DELETE()> function from L<HTTP::Request::Common>
to build the request.  See L<HTTP::Request::Common> for a details on
how to pass form content and other advanced features.

=head2 get

    my $res = $ua->get( $url );
    my $res = $ua->get( $url , $field_name => $value, ... );

This method will dispatch a C<GET> request on the given URL.  Further
arguments can be given to initialize the headers of the request. These
are given as separate name/value pairs.  The return value is a
response object.  See L<HTTP::Response> for a description of the
interface it provides.

There will still be a response object returned when LWP can't connect to the
server specified in the URL or when other failures in protocol handlers occur.
These internal responses use the standard HTTP status codes, so the responses
can't be differentiated by testing the response status code alone.  Error
responses that LWP generates internally will have the "Client-Warning" header
set to the value "Internal response".  If you need to differentiate these
internal responses from responses that a remote server actually generates, you
need to test this header value.

Fields names that start with ":" are special.  These will not
initialize headers of the request but will determine how the response
content is treated.  The following special field names are recognized:

    ':content_file'   => $filename # or $filehandle
    ':content_cb'     => \&callback
    ':read_size_hint' => $bytes

If a C<$filename> or C<$filehandle> is provided with the C<:content_file>
option, then the response content will be saved here instead of in
the response object.  The C<$filehandle> may also be an object with
an open file descriptor, such as a L<File::Temp> object.
If a callback is provided with the C<:content_cb> option then
this function will be called for each chunk of the response content as
it is received from the server.  If neither of these options are
given, then the response content will accumulate in the response
object itself.  This might not be suitable for very large response
bodies.  Only one of C<:content_file> or C<:content_cb> can be
specified.  The content of unsuccessful responses will always
accumulate in the response object itself, regardless of the
C<:content_file> or C<:content_cb> options passed in.  Note that errors
writing to the content file (for example due to permission denied
or the filesystem being full) will be reported via the C<Client-Aborted>
or C<X-Died> response headers, and not the C<is_success> method.

The C<:read_size_hint> option is passed to the protocol module which
will try to read data from the server in chunks of this size.  A
smaller value for the C<:read_size_hint> will result in a higher
number of callback invocations.

The callback function is called with 3 arguments: a chunk of data, a
reference to the response object, and a reference to the protocol
object.  The callback can abort the request by invoking C<die()>.  The
exception message will show up as the "X-Died" header field in the
response returned by the C<< $ua->get() >> method.

=head2 head

    my $res = $ua->head( $url );
    my $res = $ua->head( $url , $field_name => $value, ... );

This method will dispatch a C<HEAD> request on the given URL.
Otherwise it works like the L<LWP::UserAgent/get> method described above.

=head2 is_protocol_supported

    my $bool = $ua->is_protocol_supported( $scheme );

You can use this method to test whether this user agent object supports the
specified C<scheme>.  (The C<scheme> might be a string (like C<http> or
C<ftp>) or it might be an L<URI> object reference.)

Whether a scheme is supported is determined by the user agent's
C<protocols_allowed> or C<protocols_forbidden> lists (if any), and by
the capabilities of LWP.  I.e., this will return true only if LWP
supports this protocol I<and> it's permitted for this particular
object.

=head2 is_online

    my $bool = $ua->is_online;

Tries to determine if you have access to the Internet. Returns C<1> (true)
if the built-in heuristics determine that the user agent is
able to access the Internet (over HTTP) or C<0> (false).

See also L<LWP::Online>.

=head2 mirror

    my $res = $ua->mirror( $url, $filename );

This method will get the document identified by URL and store it in
file called C<$filename>.  If the file already exists, then the request
will contain an C<If-Modified-Since> header matching the modification
time of the file.  If the document on the server has not changed since
this time, then nothing happens.  If the document has been updated, it
will be downloaded again.  The modification time of the file will be
forced to match that of the server.

Uses L<File::Copy/move> to attempt to atomically replace the C<$filename>.

The return value is an L<HTTP::Response> object.

=head2 patch

    # Any version of HTTP::Message works with this form:
    my $res = $ua->patch( $url, $field_name => $value, Content => $content );

    # Using hash or array references requires HTTP::Message >= 6.12
    use HTTP::Request 6.12;
    my $res = $ua->patch( $url, \%form );
    my $res = $ua->patch( $url, \@form );
    my $res = $ua->patch( $url, \%form, $field_name => $value, ... );
    my $res = $ua->patch( $url, $field_name => $value, Content => \%form );
    my $res = $ua->patch( $url, $field_name => $value, Content => \@form );

This method will dispatch a C<PATCH> request on the given URL, with
C<%form> or C<@form> providing the key/value pairs for the fill-in form
content. Additional headers and content options are the same as for
the L<LWP::UserAgent/get> method.

CAVEAT:

This method can only accept content that is in key-value pairs when using
L<HTTP::Request::Common> prior to version C<6.12>. Any use of hash or array
references will result in an error prior to version C<6.12>.

This method will use the C<PATCH> function from L<HTTP::Request::Common>
to build the request.  See L<HTTP::Request::Common> for a details on
how to pass form content and other advanced features.

=head2 post

    my $res = $ua->post( $url, \%form );
    my $res = $ua->post( $url, \@form );
    my $res = $ua->post( $url, \%form, $field_name => $value, ... );
    my $res = $ua->post( $url, $field_name => $value, Content => \%form );
    my $res = $ua->post( $url, $field_name => $value, Content => \@form );
    my $res = $ua->post( $url, $field_name => $value, Content => $content );

This method will dispatch a C<POST> request on the given URL, with
C<%form> or C<@form> providing the key/value pairs for the fill-in form
content. Additional headers and content options are the same as for
the L<LWP::UserAgent/get> method.

This method will use the C<POST> function from L<HTTP::Request::Common>
to build the request.  See L<HTTP::Request::Common> for a details on
how to pass form content and other advanced features.

=head2 put

    # Any version of HTTP::Message works with this form:
    my $res = $ua->put( $url, $field_name => $value, Content => $content );

    # Using hash or array references requires HTTP::Message >= 6.07
    use HTTP::Request 6.07;
    my $res = $ua->put( $url, \%form );
    my $res = $ua->put( $url, \@form );
    my $res = $ua->put( $url, \%form, $field_name => $value, ... );
    my $res = $ua->put( $url, $field_name => $value, Content => \%form );
    my $res = $ua->put( $url, $field_name => $value, Content => \@form );

This method will dispatch a C<PUT> request on the given URL, with
C<%form> or C<@form> providing the key/value pairs for the fill-in form
content. Additional headers and content options are the same as for
the L<LWP::UserAgent/get> method.

CAVEAT:

This method can only accept content that is in key-value pairs when using
L<HTTP::Request::Common> prior to version C<6.07>. Any use of hash or array
references will result in an error prior to version C<6.07>.

This method will use the C<PUT> function from L<HTTP::Request::Common>
to build the request.  See L<HTTP::Request::Common> for a details on
how to pass form content and other advanced features.

=head2 request

    my $res = $ua->request( $request );
    my $res = $ua->request( $request, $content_file );
    my $res = $ua->request( $request, $content_cb );
    my $res = $ua->request( $request, $content_cb, $read_size_hint );

This method will dispatch the given C<$request> object. Normally this
will be an instance of the L<HTTP::Request> class, but any object with
a similar interface will do. The return value is an L<HTTP::Response> object.

The C<request> method will process redirects and authentication
responses transparently. This means that it may actually send several
simple requests via the L<LWP::UserAgent/simple_request> method described below.

The request methods described above; L<LWP::UserAgent/get>, L<LWP::UserAgent/head>,
L<LWP::UserAgent/post> and L<LWP::UserAgent/mirror> will all dispatch the request
they build via this method. They are convenience methods that simply hide the
creation of the request object for you.

The C<$content_file>, C<$content_cb> and C<$read_size_hint> all correspond to
options described with the L<LWP::UserAgent/get> method above. Note that errors
writing to the content file (for example due to permission denied
or the filesystem being full) will be reported via the C<Client-Aborted>
or C<X-Died> response headers, and not the C<is_success> method.

You are allowed to use a CODE reference as C<content> in the request
object passed in.  The C<content> function should return the content
when called.  The content can be returned in chunks.  The content
function will be invoked repeatedly until it return an empty string to
signal that there is no more content.

=head2 simple_request

    my $request = HTTP::Request->new( ... );
    my $res = $ua->simple_request( $request );
    my $res = $ua->simple_request( $request, $content_file );
    my $res = $ua->simple_request( $request, $content_cb );
    my $res = $ua->simple_request( $request, $content_cb, $read_size_hint );

This method dispatches a single request and returns the response
received.  Arguments are the same as for the L<LWP::UserAgent/request> described above.

The difference from L<LWP::UserAgent/request> is that C<simple_request> will not try to
handle redirects or authentication responses.  The L<LWP::UserAgent/request> method
will, in fact, invoke this method for each simple request it sends.

=head1 CALLBACK METHODS

The following methods will be invoked as requests are processed. These
methods are documented here because subclasses of L<LWP::UserAgent>
might want to override their behaviour.

=head2 get_basic_credentials

    # This checks wantarray and can either return an array:
    my ($user, $pass) = $ua->get_basic_credentials( $realm, $uri, $isproxy );
    # or a string that looks like "user:pass"
    my $creds = $ua->get_basic_credentials($realm, $uri, $isproxy);

This is called by L<LWP::UserAgent/request> to retrieve credentials for documents
protected by Basic or Digest Authentication.  The arguments passed in
is the C<$realm> provided by the server, the C<$uri> requested and a
C<boolean flag> to indicate if this is authentication against a proxy server.

The method should return a username and password.  It should return an
empty list to abort the authentication resolution attempt.  Subclasses
can override this method to prompt the user for the information. An
example of this can be found in C<lwp-request> program distributed
with this library.

The base implementation simply checks a set of pre-stored member
variables, set up with the L<LWP::UserAgent/credentials> method.

=head2 prepare_request

    $request = $ua->prepare_request( $request );

This method is invoked by L<LWP::UserAgent/simple_request>. Its task is
to modify the given C<$request> object by setting up various headers based
on the attributes of the user agent. The return value should normally be the
C<$request> object passed in.  If a different request object is returned
it will be the one actually processed.

The headers affected by the base implementation are; C<User-Agent>,
C<From>, C<Range> and C<Cookie>.

=head2 progress

    my $prog = $ua->progress( $status, $request_or_response );

This is called frequently as the response is received regardless of
how the content is processed.  The method is called with C<$status>
"begin" at the start of processing the request and with C<$state> "end"
before the request method returns.  In between these C<$status> will be
the fraction of the response currently received or the string "tick"
if the fraction can't be calculated.

When C<$status> is "begin" the second argument is the L<HTTP::Request> object,
otherwise it is the L<HTTP::Response> object.

=head2 redirect_ok

    my $bool = $ua->redirect_ok( $prospective_request, $response );

This method is called by L<LWP::UserAgent/request> before it tries to follow a
redirection to the request in C<$response>.  This should return a true
value if this redirection is permissible.  The C<$prospective_request>
will be the request to be sent if this method returns true.

The base implementation will return false unless the method
is in the object's C<requests_redirectable> list,
false if the proposed redirection is to a C<file://...>
URL, and true otherwise.

=head1 BEST PRACTICES

The default settings can get you up and running quickly, but there are settings
you can change in order to make your life easier.

=head2 Handling Cookies

You are encouraged to install L<Mozilla::PublicSuffix> and use
L<HTTP::CookieJar::LWP> as your cookie jar.  L<HTTP::CookieJar::LWP> provides a
better security model matching that of current Web browsers when
L<Mozilla::PublicSuffix> is installed.

    use HTTP::CookieJar::LWP ();

    my $jar = HTTP::CookieJar::LWP->new;
    my $ua = LWP::UserAgent->new( cookie_jar => $jar );

See L</"cookie_jar"> for more information.

=head2 Managing Protocols

C<protocols_allowed> gives you the ability to allow arbitrary protocols.

    my $ua = LWP::UserAgent->new(
        protocols_allowed => [ 'http', 'https' ]
    );

This will prevent you from inadvertently following URLs like
C<file:///etc/passwd>.  See L</"protocols_allowed">.

C<protocols_forbidden> gives you the ability to deny arbitrary protocols.

    my $ua = LWP::UserAgent->new(
        protocols_forbidden => [ 'file', 'mailto', 'ssh', ]
    );

This can also prevent you from inadvertently following URLs like
C<file:///etc/passwd>.  See L</protocols_forbidden>.

=head1 SEE ALSO

See L<LWP> for a complete overview of libwww-perl5.  See L<lwpcook>
and the scripts F<lwp-request> and F<lwp-download> for examples of
usage.

See L<HTTP::Request> and L<HTTP::Response> for a description of the
message objects dispatched and received.  See L<HTTP::Request::Common>
and L<HTML::Form> for other ways to build request objects.

See L<WWW::Mechanize> and L<WWW::Search> for examples of more
specialized user agents based on L<LWP::UserAgent>.

=head1 COPYRIGHT AND LICENSE

Copyright 1995-2009 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
