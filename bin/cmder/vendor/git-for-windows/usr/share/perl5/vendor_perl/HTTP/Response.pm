package HTTP::Response;

use strict;
use warnings;

our $VERSION = '6.33';

use base 'HTTP::Message';

use HTTP::Status ();


sub new
{
    my($class, $rc, $msg, $header, $content) = @_;
    my $self = $class->SUPER::new($header, $content);
    $self->code($rc);
    $self->message($msg);
    $self;
}


sub parse
{
    my($class, $str) = @_;
    Carp::carp('Undefined argument to parse()') if $^W && ! defined $str;
    my $status_line;
    if (defined $str && $str =~ s/^(.*)\n//) {
	$status_line = $1;
    }
    else {
	$status_line = $str;
	$str = "";
    }

    $status_line =~ s/\r\z// if defined $status_line;

    my $self = $class->SUPER::parse($str);
    if (defined $status_line) {
        my($protocol, $code, $message);
        if ($status_line =~ /^\d{3} /) {
           # Looks like a response created by HTTP::Response->new
           ($code, $message) = split(' ', $status_line, 2);
        } else {
           ($protocol, $code, $message) = split(' ', $status_line, 3);
        }
        $self->protocol($protocol) if $protocol;
        $self->code($code) if defined($code);
        $self->message($message) if defined($message);
    }
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->SUPER::clone, ref($self);
    $clone->code($self->code);
    $clone->message($self->message);
    $clone->request($self->request->clone) if $self->request;
    # we don't clone previous
    $clone;
}


sub code      { shift->_elem('_rc',      @_); }
sub message   { shift->_elem('_msg',     @_); }
sub previous  { shift->_elem('_previous',@_); }
sub request   { shift->_elem('_request', @_); }


sub status_line
{
    my $self = shift;
    my $code = $self->{'_rc'}  || "000";
    my $mess = $self->{'_msg'} || HTTP::Status::status_message($code) || "Unknown code";
    return "$code $mess";
}


sub base
{
    my $self = shift;
    my $base = (
	$self->header('Content-Base'),        # used to be HTTP/1.1
	$self->header('Content-Location'),    # HTTP/1.1
	$self->header('Base'),                # HTTP/1.0
    )[0];
    if ($base && $base =~ /^$URI::scheme_re:/o) {
	# already absolute
	return $HTTP::URI_CLASS->new($base);
    }

    my $req = $self->request;
    if ($req) {
        # if $base is undef here, the return value is effectively
        # just a copy of $self->request->uri.
        return $HTTP::URI_CLASS->new_abs($base, $req->uri);
    }

    # can't find an absolute base
    return undef;
}


sub redirects {
    my $self = shift;
    my @r;
    my $r = $self;
    while (my $p = $r->previous) {
        push(@r, $p);
        $r = $p;
    }
    return @r unless wantarray;
    return reverse @r;
}


sub filename
{
    my $self = shift;
    my $file;

    my $cd = $self->header('Content-Disposition');
    if ($cd) {
	require HTTP::Headers::Util;
	if (my @cd = HTTP::Headers::Util::split_header_words($cd)) {
	    my ($disposition, undef, %cd_param) = @{$cd[-1]};
	    $file = $cd_param{filename};

	    # RFC 2047 encoded?
	    if ($file && $file =~ /^=\?(.+?)\?(.+?)\?(.+)\?=$/) {
		my $charset = $1;
		my $encoding = uc($2);
		my $encfile = $3;

		if ($encoding eq 'Q' || $encoding eq 'B') {
		    local($SIG{__DIE__});
		    eval {
			if ($encoding eq 'Q') {
			    $encfile =~ s/_/ /g;
			    require MIME::QuotedPrint;
			    $encfile = MIME::QuotedPrint::decode($encfile);
			}
			else { # $encoding eq 'B'
			    require MIME::Base64;
			    $encfile = MIME::Base64::decode($encfile);
			}

			require Encode;
			require Encode::Locale;
			Encode::from_to($encfile, $charset, "locale_fs");
		    };

		    $file = $encfile unless $@;
		}
	    }
	}
    }

    unless (defined($file) && length($file)) {
	my $uri;
	if (my $cl = $self->header('Content-Location')) {
	    $uri = URI->new($cl);
	}
	elsif (my $request = $self->request) {
	    $uri = $request->uri;
	}

	if ($uri) {
	    $file = ($uri->path_segments)[-1];
	}
    }

    if ($file) {
	$file =~ s,.*[\\/],,;  # basename
    }

    if ($file && !length($file)) {
	$file = undef;
    }

    $file;
}


sub as_string
{
    my $self = shift;
    my($eol) = @_;
    $eol = "\n" unless defined $eol;

    my $status_line = $self->status_line;
    my $proto = $self->protocol;
    $status_line = "$proto $status_line" if $proto;

    return join($eol, $status_line, $self->SUPER::as_string(@_));
}


sub dump
{
    my $self = shift;

    my $status_line = $self->status_line;
    my $proto = $self->protocol;
    $status_line = "$proto $status_line" if $proto;

    return $self->SUPER::dump(
	preheader => $status_line,
        @_,
    );
}


sub is_info     { HTTP::Status::is_info     (shift->{'_rc'}); }
sub is_success  { HTTP::Status::is_success  (shift->{'_rc'}); }
sub is_redirect { HTTP::Status::is_redirect (shift->{'_rc'}); }
sub is_error    { HTTP::Status::is_error    (shift->{'_rc'}); }
sub is_client_error { HTTP::Status::is_client_error (shift->{'_rc'}); }
sub is_server_error { HTTP::Status::is_server_error (shift->{'_rc'}); }


sub error_as_HTML
{
    my $self = shift;
    my $title = 'An Error Occurred';
    my $body  = $self->status_line;
    $body =~ s/&/&amp;/g;
    $body =~ s/</&lt;/g;
    return <<EOM;
<html>
<head><title>$title</title></head>
<body>
<h1>$title</h1>
<p>$body</p>
</body>
</html>
EOM
}


sub current_age
{
    my $self = shift;
    my $time = shift;

    # Implementation of RFC 2616 section 13.2.3
    # (age calculations)
    my $response_time = $self->client_date;
    my $date = $self->date;

    my $age = 0;
    if ($response_time && $date) {
	$age = $response_time - $date;  # apparent_age
	$age = 0 if $age < 0;
    }

    my $age_v = $self->header('Age');
    if ($age_v && $age_v > $age) {
	$age = $age_v;   # corrected_received_age
    }

    if ($response_time) {
	my $request = $self->request;
	if ($request) {
	    my $request_time = $request->date;
	    if ($request_time && $request_time < $response_time) {
		# Add response_delay to age to get 'corrected_initial_age'
		$age += $response_time - $request_time;
	    }
	}
	$age += ($time || time) - $response_time;
    }
    return $age;
}


sub freshness_lifetime
{
    my($self, %opt) = @_;

    # First look for the Cache-Control: max-age=n header
    for my $cc ($self->header('Cache-Control')) {
	for my $cc_dir (split(/\s*,\s*/, $cc)) {
	    return $1 if $cc_dir =~ /^max-age\s*=\s*(\d+)/i;
	}
    }

    # Next possibility is to look at the "Expires" header
    my $date = $self->date || $self->client_date || $opt{time} || time;
    if (my $expires = $self->expires) {
	return $expires - $date;
    }

    # Must apply heuristic expiration
    return undef if exists $opt{heuristic_expiry} && !$opt{heuristic_expiry};

    # Default heuristic expiration parameters
    $opt{h_min} ||= 60;
    $opt{h_max} ||= 24 * 3600;
    $opt{h_lastmod_fraction} ||= 0.10; # 10% since last-mod suggested by RFC2616
    $opt{h_default} ||= 3600;

    # Should give a warning if more than 24 hours according to
    # RFC 2616 section 13.2.4.  Here we just make this the default
    # maximum value.

    if (my $last_modified = $self->last_modified) {
	my $h_exp = ($date - $last_modified) * $opt{h_lastmod_fraction};
	return $opt{h_min} if $h_exp < $opt{h_min};
	return $opt{h_max} if $h_exp > $opt{h_max};
	return $h_exp;
    }

    # default when all else fails
    return $opt{h_min} if $opt{h_min} > $opt{h_default};
    return $opt{h_default};
}


sub is_fresh
{
    my($self, %opt) = @_;
    $opt{time} ||= time;
    my $f = $self->freshness_lifetime(%opt);
    return undef unless defined($f);
    return $f > $self->current_age($opt{time});
}


sub fresh_until
{
    my($self, %opt) = @_;
    $opt{time} ||= time;
    my $f = $self->freshness_lifetime(%opt);
    return undef unless defined($f);
    return $f - $self->current_age($opt{time}) + $opt{time};
}

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Response - HTTP style response message

=head1 VERSION

version 6.33

=head1 SYNOPSIS

Response objects are returned by the request() method of the C<LWP::UserAgent>:

    # ...
    $response = $ua->request($request);
    if ($response->is_success) {
        print $response->decoded_content;
    }
    else {
        print STDERR $response->status_line, "\n";
    }

=head1 DESCRIPTION

The C<HTTP::Response> class encapsulates HTTP style responses.  A
response consists of a response line, some headers, and a content
body. Note that the LWP library uses HTTP style responses even for
non-HTTP protocol schemes.  Instances of this class are usually
created and returned by the request() method of an C<LWP::UserAgent>
object.

C<HTTP::Response> is a subclass of C<HTTP::Message> and therefore
inherits its methods.  The following additional methods are available:

=over 4

=item $r = HTTP::Response->new( $code )

=item $r = HTTP::Response->new( $code, $msg )

=item $r = HTTP::Response->new( $code, $msg, $header )

=item $r = HTTP::Response->new( $code, $msg, $header, $content )

Constructs a new C<HTTP::Response> object describing a response with
response code $code and optional message $msg.  The optional $header
argument should be a reference to an C<HTTP::Headers> object or a
plain array reference of key/value pairs.  The optional $content
argument should be a string of bytes.  The meanings of these arguments are
described below.

=item $r = HTTP::Response->parse( $str )

This constructs a new response object by parsing the given string.

=item $r->code

=item $r->code( $code )

This is used to get/set the code attribute.  The code is a 3 digit
number that encode the overall outcome of an HTTP response.  The
C<HTTP::Status> module provide constants that provide mnemonic names
for the code attribute.

=item $r->message

=item $r->message( $message )

This is used to get/set the message attribute.  The message is a short
human readable single line string that explains the response code.

=item $r->header( $field )

=item $r->header( $field => $value )

This is used to get/set header values and it is inherited from
C<HTTP::Headers> via C<HTTP::Message>.  See L<HTTP::Headers> for
details and other similar methods that can be used to access the
headers.

=item $r->content

=item $r->content( $bytes )

This is used to get/set the raw content and it is inherited from the
C<HTTP::Message> base class.  See L<HTTP::Message> for details and
other methods that can be used to access the content.

=item $r->decoded_content( %options )

This will return the content after any C<Content-Encoding> and
charsets have been decoded.  See L<HTTP::Message> for details.

=item $r->request

=item $r->request( $request )

This is used to get/set the request attribute.  The request attribute
is a reference to the request that caused this response.  It does
not have to be the same request passed to the $ua->request() method,
because there might have been redirects and authorization retries in
between.

=item $r->previous

=item $r->previous( $response )

This is used to get/set the previous attribute.  The previous
attribute is used to link together chains of responses.  You get
chains of responses if the first response is redirect or unauthorized.
The value is C<undef> if this is the first response in a chain.

Note that the method $r->redirects is provided as a more convenient
way to access the response chain.

=item $r->status_line

Returns the string "E<lt>code> E<lt>message>".  If the message attribute
is not set then the official name of E<lt>code> (see L<HTTP::Status>)
is substituted.

=item $r->base

Returns the base URI for this response.  The return value will be a
reference to a URI object.

The base URI is obtained from one the following sources (in priority
order):

=over 4

=item 1.

Embedded in the document content, for instance <BASE HREF="...">
in HTML documents.

=item 2.

A "Content-Base:" or a "Content-Location:" header in the response.

For backwards compatibility with older HTTP implementations we will
also look for the "Base:" header.

=item 3.

The URI used to request this response. This might not be the original
URI that was passed to $ua->request() method, because we might have
received some redirect responses first.

=back

If none of these sources provide an absolute URI, undef is returned.

When the LWP protocol modules produce the HTTP::Response object, then any base
URI embedded in the document (step 1) will already have initialized the
"Content-Base:" header. (See L<LWP::UserAgent/parse_head>).  This means that
this method only performs the last 2 steps (the content is not always available
either).

=item $r->filename

Returns a filename for this response.  Note that doing sanity checks
on the returned filename (eg. removing characters that cannot be used
on the target filesystem where the filename would be used, and
laundering it for security purposes) are the caller's responsibility;
the only related thing done by this method is that it makes a simple
attempt to return a plain filename with no preceding path segments.

The filename is obtained from one the following sources (in priority
order):

=over 4

=item 1.

A "Content-Disposition:" header in the response.  Proper decoding of
RFC 2047 encoded filenames requires the C<MIME::QuotedPrint> (for "Q"
encoding), C<MIME::Base64> (for "B" encoding), and C<Encode> modules.

=item 2.

A "Content-Location:" header in the response.

=item 3.

The URI used to request this response. This might not be the original
URI that was passed to $ua->request() method, because we might have
received some redirect responses first.

=back

If a filename cannot be derived from any of these sources, undef is
returned.

=item $r->as_string

=item $r->as_string( $eol )

Returns a textual representation of the response.

=item $r->is_info

=item $r->is_success

=item $r->is_redirect

=item $r->is_error

=item $r->is_client_error

=item $r->is_server_error

These methods indicate if the response was informational, successful, a
redirection, or an error.  See L<HTTP::Status> for the meaning of these.

=item $r->error_as_HTML

Returns a string containing a complete HTML document indicating what
error occurred.  This method should only be called when $r->is_error
is TRUE.

=item $r->redirects

Returns the list of redirect responses that lead up to this response
by following the $r->previous chain.  The list order is oldest first.

In scalar context return the number of redirect responses leading up
to this one.

=item $r->current_age

Calculates the "current age" of the response as specified by RFC 2616
section 13.2.3.  The age of a response is the time since it was sent
by the origin server.  The returned value is a number representing the
age in seconds.

=item $r->freshness_lifetime( %opt )

Calculates the "freshness lifetime" of the response as specified by
RFC 2616 section 13.2.4.  The "freshness lifetime" is the length of
time between the generation of a response and its expiration time.
The returned value is the number of seconds until expiry.

If the response does not contain an "Expires" or a "Cache-Control"
header, then this function will apply some simple heuristic based on
the "Last-Modified" header to determine a suitable lifetime.  The
following options might be passed to control the heuristics:

=over

=item heuristic_expiry => $bool

If passed as a FALSE value, don't apply heuristics and just return
C<undef> when "Expires" or "Cache-Control" is lacking.

=item h_lastmod_fraction => $num

This number represent the fraction of the difference since the
"Last-Modified" timestamp to make the expiry time.  The default is
C<0.10>, the suggested typical setting of 10% in RFC 2616.

=item h_min => $sec

This is the lower limit of the heuristic expiry age to use.  The
default is C<60> (1 minute).

=item h_max => $sec

This is the upper limit of the heuristic expiry age to use.  The
default is C<86400> (24 hours).

=item h_default => $sec

This is the expiry age to use when nothing else applies.  The default
is C<3600> (1 hour) or "h_min" if greater.

=back

=item $r->is_fresh( %opt )

Returns TRUE if the response is fresh, based on the values of
freshness_lifetime() and current_age().  If the response is no longer
fresh, then it has to be re-fetched or re-validated by the origin
server.

Options might be passed to control expiry heuristics, see the
description of freshness_lifetime().

=item $r->fresh_until( %opt )

Returns the time (seconds since epoch) when this entity is no longer fresh.

Options might be passed to control expiry heuristics, see the
description of freshness_lifetime().

=back

=head1 SEE ALSO

L<HTTP::Headers>, L<HTTP::Message>, L<HTTP::Status>, L<HTTP::Request>

=head1 AUTHOR

Gisle Aas <gisle@activestate.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1994 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


#ABSTRACT: HTTP style response message

