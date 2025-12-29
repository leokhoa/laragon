package Net::HTTP::Methods;
our $VERSION = '6.24';
use strict;
use warnings;
use URI;

my $CRLF = "\015\012";   # "\r\n" is not portable

*_bytes = defined(&utf8::downgrade) ?
    sub {
        unless (utf8::downgrade($_[0], 1)) {
            require Carp;
            Carp::croak("Wide character in HTTP request (bytes required)");
        }
        return $_[0];
    }
    :
    sub {
        return $_[0];
    };


sub new {
    my $class = shift;
    unshift(@_, "Host") if @_ == 1;
    my %cnf = @_;
    require Symbol;
    my $self = bless Symbol::gensym(), $class;
    return $self->http_configure(\%cnf);
}

sub http_configure {
    my($self, $cnf) = @_;

    die "Listen option not allowed" if $cnf->{Listen};
    my $explicit_host = (exists $cnf->{Host});
    my $host = delete $cnf->{Host};
    # All this because $cnf->{PeerAddr} = 0 is actually valid.
    my $peer;
    for my $key (qw{PeerAddr PeerHost}) {
	next if !defined($cnf->{$key}) || q{} eq $cnf->{$key};
	$peer = $cnf->{$key};
	last;
    }
    if (!defined $peer) {
	die "No Host option provided" unless $host;
	$cnf->{PeerAddr} = $peer = $host;
    }

    # CONNECTIONS
    # PREFER: port number from PeerAddr, then PeerPort, then http_default_port
    my $peer_uri = URI->new("http://$peer");
    $cnf->{"PeerPort"} =  $peer_uri->_port || $cnf->{PeerPort} ||  $self->http_default_port;
    $cnf->{"PeerAddr"} = $peer_uri->host;

    # HOST header:
    # If specified but blank, ignore.
    # If specified with a value, add the port number
    # If not specified, set to PeerAddr and port number
    # ALWAYS: If IPv6 address, use [brackets]  (thanks to the URI package)
    # ALWAYS: omit port number if http_default_port
    if (($host) || (! $explicit_host)) {
        my $uri =  ($explicit_host) ? URI->new("http://$host") : $peer_uri->clone;
        if (!$uri->_port) {
            # Always use *our*  $self->http_default_port  instead of URI's  (Covers HTTP, HTTPS)
            $uri->port( $cnf->{PeerPort} ||  $self->http_default_port);
        }
        my $host_port = $uri->host_port;               # Returns host:port or [ipv6]:port
        my $remove = ":" . $self->http_default_port;   # we want to remove the default port number
        if (substr($host_port,0-length($remove)) eq $remove) {
            substr($host_port,0-length($remove)) = "";
        }
        $host = $host_port;
    }

    $cnf->{Proto} = 'tcp';

    my $keep_alive = delete $cnf->{KeepAlive};
    my $http_version = delete $cnf->{HTTPVersion};
    $http_version = "1.1" unless defined $http_version;
    my $peer_http_version = delete $cnf->{PeerHTTPVersion};
    $peer_http_version = "1.0" unless defined $peer_http_version;
    my $send_te = delete $cnf->{SendTE};
    my $max_line_length = delete $cnf->{MaxLineLength};
    $max_line_length = 8*1024 unless defined $max_line_length;
    my $max_header_lines = delete $cnf->{MaxHeaderLines};
    $max_header_lines = 128 unless defined $max_header_lines;

    return undef unless $self->http_connect($cnf);

    $self->host($host);
    $self->keep_alive($keep_alive);
    $self->send_te($send_te);
    $self->http_version($http_version);
    $self->peer_http_version($peer_http_version);
    $self->max_line_length($max_line_length);
    $self->max_header_lines($max_header_lines);

    ${*$self}{'http_buf'} = "";

    return $self;
}

sub http_default_port {
    80;
}

# set up property accessors
for my $method (qw(host keep_alive send_te max_line_length max_header_lines peer_http_version)) {
    my $prop_name = "http_" . $method;
    no strict 'refs';
    *$method = sub {
	my $self = shift;
	my $old = ${*$self}{$prop_name};
	${*$self}{$prop_name} = shift if @_;
	return $old;
    };
}

# we want this one to be a bit smarter
sub http_version {
    my $self = shift;
    my $old = ${*$self}{'http_version'};
    if (@_) {
	my $v = shift;
	$v = "1.0" if $v eq "1";  # float
	unless ($v eq "1.0" or $v eq "1.1") {
	    require Carp;
	    Carp::croak("Unsupported HTTP version '$v'");
	}
	${*$self}{'http_version'} = $v;
    }
    $old;
}

sub format_request {
    my $self = shift;
    my $method = shift;
    my $uri = shift;

    my $content = (@_ % 2) ? pop : "";

    for ($method, $uri) {
	require Carp;
	Carp::croak("Bad method or uri") if /\s/ || !length;
    }

    push(@{${*$self}{'http_request_method'}}, $method);
    my $ver = ${*$self}{'http_version'};
    my $peer_ver = ${*$self}{'http_peer_http_version'} || "1.0";

    my @h;
    my @connection;
    my %given = (host => 0, "content-length" => 0, "te" => 0);
    while (@_) {
	my($k, $v) = splice(@_, 0, 2);
	my $lc_k = lc($k);
	if ($lc_k eq "connection") {
	    $v =~ s/^\s+//;
	    $v =~ s/\s+$//;
	    push(@connection, split(/\s*,\s*/, $v));
	    next;
	}
	if (exists $given{$lc_k}) {
	    $given{$lc_k}++;
	}
	push(@h, "$k: $v");
    }

    if (length($content) && !$given{'content-length'}) {
	push(@h, "Content-Length: " . length($content));
    }

    my @h2;
    if ($given{te}) {
	push(@connection, "TE") unless grep lc($_) eq "te", @connection;
    }
    elsif ($self->send_te && gunzip_ok()) {
	# gzip is less wanted since the IO::Uncompress::Gunzip interface for
	# it does not really allow chunked decoding to take place easily.
	push(@h2, "TE: deflate,gzip;q=0.3");
	push(@connection, "TE");
    }

    unless (grep lc($_) eq "close", @connection) {
	if ($self->keep_alive) {
	    if ($peer_ver eq "1.0") {
		# from looking at Netscape's headers
		push(@h2, "Keep-Alive: 300");
		unshift(@connection, "Keep-Alive");
	    }
	}
	else {
	    push(@connection, "close") if $ver ge "1.1";
	}
    }
    push(@h2, "Connection: " . join(", ", @connection)) if @connection;
    unless ($given{host}) {
	my $h = ${*$self}{'http_host'};
	push(@h2, "Host: $h") if $h;
    }

    return _bytes(join($CRLF, "$method $uri HTTP/$ver", @h2, @h, "", $content));
}


sub write_request {
    my $self = shift;
    $self->print($self->format_request(@_));
}

sub format_chunk {
    my $self = shift;
    return $_[0] unless defined($_[0]) && length($_[0]);
    return _bytes(sprintf("%x", length($_[0])) . $CRLF . $_[0] . $CRLF);
}

sub write_chunk {
    my $self = shift;
    return 1 unless defined($_[0]) && length($_[0]);
    $self->print(_bytes(sprintf("%x", length($_[0])) . $CRLF . $_[0] . $CRLF));
}

sub format_chunk_eof {
    my $self = shift;
    my @h;
    while (@_) {
	push(@h, sprintf "%s: %s$CRLF", splice(@_, 0, 2));
    }
    return _bytes(join("", "0$CRLF", @h, $CRLF));
}

sub write_chunk_eof {
    my $self = shift;
    $self->print($self->format_chunk_eof(@_));
}


sub my_read {
    die if @_ > 3;
    my $self = shift;
    my $len = $_[1];
    for (${*$self}{'http_buf'}) {
	if (length) {
	    $_[0] = substr($_, 0, $len, "");
	    return length($_[0]);
	}
	else {
	    die "read timeout" unless $self->can_read;
	    return $self->sysread($_[0], $len);
	}
    }
}


sub my_readline {
    my $self = shift;
    my $what = shift;
    for (${*$self}{'http_buf'}) {
	my $max_line_length = ${*$self}{'http_max_line_length'};
	my $pos;
	while (1) {
	    # find line ending
	    $pos = index($_, "\012");
	    last if $pos >= 0;
	    die "$what line too long (limit is $max_line_length)"
		if $max_line_length && length($_) > $max_line_length;

	    # need to read more data to find a line ending
            my $new_bytes = 0;

          READ:
            {   # wait until bytes start arriving
                $self->can_read
                     or die "read timeout";

                # consume all incoming bytes
                my $bytes_read = $self->sysread($_, 1024, length);
                if(defined $bytes_read) {
                    $new_bytes += $bytes_read;
                }
                elsif($!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK}) {
                    redo READ;
                }
                else {
                    # if we have already accumulated some data let's at
                    # least return that as a line
                    length or die "$what read failed: $!";
                }

                # no line-ending, no new bytes
                return length($_) ? substr($_, 0, length($_), "") : undef
                    if $new_bytes==0;
            }
	}
	die "$what line too long ($pos; limit is $max_line_length)"
	    if $max_line_length && $pos > $max_line_length;

	my $line = substr($_, 0, $pos+1, "");
	$line =~ s/(\015?\012)\z// || die "Assert";
	return wantarray ? ($line, $1) : $line;
    }
}


sub can_read {
    my $self = shift;
    return 1 unless defined(fileno($self));
    return 1 if $self->isa('IO::Socket::SSL') && $self->pending;
    return 1 if $self->isa('Net::SSL') && $self->can('pending') && $self->pending;

    # With no timeout, wait forever.  An explicit timeout of 0 can be
    # used to just check if the socket is readable without waiting.
    my $timeout = @_ ? shift : (${*$self}{io_socket_timeout} || undef);

    my $fbits = '';
    vec($fbits, fileno($self), 1) = 1;
  SELECT:
    {
        my $before;
        $before = time if $timeout;
        my $nfound = select($fbits, undef, undef, $timeout);
        if ($nfound < 0) {
            if ($!{EINTR} || $!{EAGAIN} || $!{EWOULDBLOCK}) {
                # don't really think EAGAIN/EWOULDBLOCK can happen here
                if ($timeout) {
                    $timeout -= time - $before;
                    $timeout = 0 if $timeout < 0;
                }
                redo SELECT;
            }
            die "select failed: $!";
        }
        return $nfound > 0;
    }
}


sub _rbuf {
    my $self = shift;
    if (@_) {
	for (${*$self}{'http_buf'}) {
	    my $old;
	    $old = $_ if defined wantarray;
	    $_ = shift;
	    return $old;
	}
    }
    else {
	return ${*$self}{'http_buf'};
    }
}

sub _rbuf_length {
    my $self = shift;
    return length ${*$self}{'http_buf'};
}


sub _read_header_lines {
    my $self = shift;
    my $junk_out = shift;

    my @headers;
    my $line_count = 0;
    my $max_header_lines = ${*$self}{'http_max_header_lines'};
    while (my $line = my_readline($self, 'Header')) {
	if ($line =~ /^(\S+?)\s*:\s*(.*)/s) {
	    push(@headers, $1, $2);
	}
	elsif (@headers && $line =~ s/^\s+//) {
	    $headers[-1] .= " " . $line;
	}
	elsif ($junk_out) {
	    push(@$junk_out, $line);
	}
	else {
	    die "Bad header: '$line'\n";
	}
	if ($max_header_lines) {
	    $line_count++;
	    if ($line_count >= $max_header_lines) {
		die "Too many header lines (limit is $max_header_lines)";
	    }
	}
    }
    return @headers;
}


sub read_response_headers {
    my($self, %opt) = @_;
    my $laxed = $opt{laxed};

    my($status, $eol) = my_readline($self, 'Status');
    unless (defined $status) {
	die "Server closed connection without sending any data back";
    }

    my($peer_ver, $code, $message) = split(/\s+/, $status, 3);
    if (!$peer_ver || $peer_ver !~ s,^HTTP/,, || $code !~ /^[1-5]\d\d$/) {
	die "Bad response status line: '$status'" unless $laxed;
	# assume HTTP/0.9
	${*$self}{'http_peer_http_version'} = "0.9";
	${*$self}{'http_status'} = "200";
	substr(${*$self}{'http_buf'}, 0, 0) = $status . ($eol || "");
	return 200 unless wantarray;
	return (200, "Assumed OK");
    };

    ${*$self}{'http_peer_http_version'} = $peer_ver;
    ${*$self}{'http_status'} = $code;

    my $junk_out;
    if ($laxed) {
	$junk_out = $opt{junk_out} || [];
    }
    my @headers = $self->_read_header_lines($junk_out);

    # pick out headers that read_entity_body might need
    my @te;
    my $content_length;
    for (my $i = 0; $i < @headers; $i += 2) {
	my $h = lc($headers[$i]);
	if ($h eq 'transfer-encoding') {
	    my $te = $headers[$i+1];
	    $te =~ s/^\s+//;
	    $te =~ s/\s+$//;
	    push(@te, $te) if length($te);
	}
	elsif ($h eq 'content-length') {
	    # ignore bogus and overflow values
	    if ($headers[$i+1] =~ /^\s*(\d{1,15})(?:\s|$)/) {
		$content_length = $1;
	    }
	}
    }
    ${*$self}{'http_te'} = join(",", @te);
    ${*$self}{'http_content_length'} = $content_length;
    ${*$self}{'http_first_body'}++;
    delete ${*$self}{'http_trailers'};
    return $code unless wantarray;
    return ($code, $message, @headers);
}


sub read_entity_body {
    my $self = shift;
    my $buf_ref = \$_[0];
    my $size = $_[1];
    die "Offset not supported yet" if $_[2];

    my $chunked;
    my $bytes;

    if (${*$self}{'http_first_body'}) {
	${*$self}{'http_first_body'} = 0;
	delete ${*$self}{'http_chunked'};
	delete ${*$self}{'http_bytes'};
	my $method = shift(@{${*$self}{'http_request_method'}});
	my $status = ${*$self}{'http_status'};
	if ($method eq "HEAD") {
	    # this response is always empty regardless of other headers
	    $bytes = 0;
	}
	elsif (my $te = ${*$self}{'http_te'}) {
	    my @te = split(/\s*,\s*/, lc($te));
	    die "Chunked must be last Transfer-Encoding '$te'"
		unless pop(@te) eq "chunked";
	    pop(@te) while @te && $te[-1] eq "chunked";  # ignore repeated chunked spec

	    for (@te) {
		if ($_ eq "deflate" && inflate_ok()) {
		    #require Compress::Raw::Zlib;
		    my ($i, $status) = Compress::Raw::Zlib::Inflate->new();
		    die "Can't make inflator: $status" unless $i;
		    $_ = sub { my $out; $i->inflate($_[0], \$out); $out }
		}
		elsif ($_ eq "gzip" && gunzip_ok()) {
		    #require IO::Uncompress::Gunzip;
		    my @buf;
		    $_ = sub {
			push(@buf, $_[0]);
			return "" unless $_[1];
			my $input = join("", @buf);
			my $output;
			IO::Uncompress::Gunzip::gunzip(\$input, \$output, Transparent => 0)
			    or die "Can't gunzip content: $IO::Uncompress::Gunzip::GunzipError";
			return \$output;
		    };
		}
		elsif ($_ eq "identity") {
		    $_ = sub { $_[0] };
		}
		else {
		    die "Can't handle transfer encoding '$te'";
		}
	    }

	    @te = reverse(@te);

	    ${*$self}{'http_te2'} = @te ? \@te : "";
	    $chunked = -1;
	}
	elsif (defined(my $content_length = ${*$self}{'http_content_length'})) {
	    $bytes = $content_length;
	}
        elsif ($status =~ /^(?:1|[23]04)/) {
            # RFC 2616 says that these responses should always be empty
            # but that does not appear to be true in practice [RT#17907]
            $bytes = 0;
        }
	else {
	    # XXX Multi-Part types are self delimiting, but RFC 2616 says we
	    # only has to deal with 'multipart/byteranges'

	    # Read until EOF
	}
    }
    else {
	$chunked = ${*$self}{'http_chunked'};
	$bytes   = ${*$self}{'http_bytes'};
    }

    if (defined $chunked) {
	# The state encoded in $chunked is:
	#   $chunked == 0:   read CRLF after chunk, then chunk header
        #   $chunked == -1:  read chunk header
	#   $chunked > 0:    bytes left in current chunk to read

	if ($chunked <= 0) {
	    my $line = my_readline($self, 'Entity body');
	    if ($chunked == 0) {
		die "Missing newline after chunk data: '$line'"
		    if !defined($line) || $line ne "";
		$line = my_readline($self, 'Entity body');
	    }
	    die "EOF when chunk header expected" unless defined($line);
	    my $chunk_len = $line;
	    $chunk_len =~ s/;.*//;  # ignore potential chunk parameters
	    unless ($chunk_len =~ /^([\da-fA-F]+)\s*$/) {
		die "Bad chunk-size in HTTP response: $line";
	    }
	    $chunked = hex($1);
	    ${*$self}{'http_chunked'} = $chunked;
	    if ($chunked == 0) {
		${*$self}{'http_trailers'} = [$self->_read_header_lines];
		$$buf_ref = "";

		my $n = 0;
		if (my $transforms = delete ${*$self}{'http_te2'}) {
		    for (@$transforms) {
			$$buf_ref = &$_($$buf_ref, 1);
		    }
		    $n = length($$buf_ref);
		}

		# in case somebody tries to read more, make sure we continue
		# to return EOF
		delete ${*$self}{'http_chunked'};
		${*$self}{'http_bytes'} = 0;

		return $n;
	    }
	}

	my $n = $chunked;
	$n = $size if $size && $size < $n;
	$n = my_read($self, $$buf_ref, $n);
	return undef unless defined $n;

	${*$self}{'http_chunked'} = $chunked - $n;

	if ($n > 0) {
	    if (my $transforms = ${*$self}{'http_te2'}) {
		for (@$transforms) {
		    $$buf_ref = &$_($$buf_ref, 0);
		}
		$n = length($$buf_ref);
		$n = -1 if $n == 0;
	    }
	}
	return $n;
    }
    elsif (defined $bytes) {
	unless ($bytes) {
	    $$buf_ref = "";
	    return 0;
	}
	my $n = $bytes;
	$n = $size if $size && $size < $n;
	$n = my_read($self, $$buf_ref, $n);
	${*$self}{'http_bytes'} = defined $n ? $bytes - $n : $bytes;
	return $n;
    }
    else {
	# read until eof
	$size ||= 8*1024;
	return my_read($self, $$buf_ref, $size);
    }
}

sub get_trailers {
    my $self = shift;
    @{${*$self}{'http_trailers'} || []};
}

BEGIN {
my $gunzip_ok;
my $inflate_ok;

sub gunzip_ok {
    return $gunzip_ok if defined $gunzip_ok;

    # Try to load IO::Uncompress::Gunzip.
    local $@;
    local $SIG{__DIE__};
    $gunzip_ok = 0;

    eval {
	require IO::Uncompress::Gunzip;
	$gunzip_ok++;
    };

    return $gunzip_ok;
}

sub inflate_ok {
    return $inflate_ok if defined $inflate_ok;

    # Try to load Compress::Raw::Zlib.
    local $@;
    local $SIG{__DIE__};
    $inflate_ok = 0;

    eval {
	require Compress::Raw::Zlib;
	$inflate_ok++;
    };

    return $inflate_ok;
}

} # BEGIN

1;

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Methods - Methods shared by Net::HTTP and Net::HTTPS

=head1 VERSION

version 6.24

=head1 AUTHOR

Gisle Aas <gisle@activestate.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Methods shared by Net::HTTP and Net::HTTPS
