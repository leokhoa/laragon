package HTTP::Request;

use strict;
use warnings;

our $VERSION = '6.45';

use parent 'HTTP::Message';

sub new
{
    my($class, $method, $uri, $header, $content) = @_;
    my $self = $class->SUPER::new($header, $content);
    $self->method($method);
    $self->uri($uri);
    $self;
}


sub parse
{
    my($class, $str) = @_;
    Carp::carp('Undefined argument to parse()') if $^W && ! defined $str;
    my $request_line;
    if (defined $str && $str =~ s/^(.*)\n//) {
	$request_line = $1;
    }
    else {
	$request_line = $str;
	$str = "";
    }

    my $self = $class->SUPER::parse($str);
    if (defined $request_line) {
        my($method, $uri, $protocol) = split(' ', $request_line);
        $self->method($method);
        $self->uri($uri) if defined($uri);
        $self->protocol($protocol) if $protocol;
    }
    $self;
}


sub clone
{
    my $self = shift;
    my $clone = bless $self->SUPER::clone, ref($self);
    $clone->method($self->method);
    $clone->uri($self->uri);
    $clone;
}


sub method
{
    shift->_elem('_method', @_);
}


sub uri
{
    my $self = shift;
    my $old = $self->{'_uri'};
    if (@_) {
	my $uri = shift;
	if (!defined $uri) {
	    # that's ok
	}
	elsif (ref $uri) {
	    Carp::croak("A URI can't be a " . ref($uri) . " reference")
		if ref($uri) eq 'HASH' or ref($uri) eq 'ARRAY';
	    Carp::croak("Can't use a " . ref($uri) . " object as a URI")
		unless $uri->can('scheme') && $uri->can('canonical');
	    $uri = $uri->clone;
	    unless ($HTTP::URI_CLASS eq "URI") {
		# Argh!! Hate this... old LWP legacy!
		eval { local $SIG{__DIE__}; $uri = $uri->abs; };
		die $@ if $@ && $@ !~ /Missing base argument/;
	    }
	}
	else {
	    $uri = $HTTP::URI_CLASS->new($uri);
	}
	$self->{'_uri'} = $uri;
        delete $self->{'_uri_canonical'};
    }
    $old;
}

*url = \&uri;  # legacy

sub uri_canonical
{
    my $self = shift;

    my $uri = $self->{_uri};

    if (defined (my $canon = $self->{_uri_canonical})) {
        # early bailout if these are the exact same string;
        # rely on stringification of the URI objects
        return $canon if $canon eq $uri;
    }

    # otherwise we need to refresh the memoized value
    $self->{_uri_canonical} = $uri->canonical;
}


sub accept_decodable
{
    my $self = shift;
    $self->header("Accept-Encoding", scalar($self->decodable));
}

sub as_string
{
    my $self = shift;
    my($eol) = @_;
    $eol = "\n" unless defined $eol;

    my $req_line = $self->method || "-";
    my $uri = $self->uri;
    $uri = (defined $uri) ? $uri->as_string : "-";
    $req_line .= " $uri";
    my $proto = $self->protocol;
    $req_line .= " $proto" if $proto;

    return join($eol, $req_line, $self->SUPER::as_string(@_));
}

sub dump
{
    my $self = shift;
    my @pre = ($self->method || "-", $self->uri || "-");
    if (my $prot = $self->protocol) {
	push(@pre, $prot);
    }

    return $self->SUPER::dump(
        preheader => join(" ", @pre),
	@_,
    );
}


1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Request - HTTP style request message

=head1 VERSION

version 6.45

=head1 SYNOPSIS

 require HTTP::Request;
 $request = HTTP::Request->new(GET => 'http://www.example.com/');

and usually used like this:

 $ua = LWP::UserAgent->new;
 $response = $ua->request($request);

=head1 DESCRIPTION

C<HTTP::Request> is a class encapsulating HTTP style requests,
consisting of a request line, some headers, and a content body. Note
that the LWP library uses HTTP style requests even for non-HTTP
protocols.  Instances of this class are usually passed to the
request() method of an C<LWP::UserAgent> object.

C<HTTP::Request> is a subclass of C<HTTP::Message> and therefore
inherits its methods.  The following additional methods are available:

=over 4

=item $r = HTTP::Request->new( $method, $uri )

=item $r = HTTP::Request->new( $method, $uri, $header )

=item $r = HTTP::Request->new( $method, $uri, $header, $content )

Constructs a new C<HTTP::Request> object describing a request on the
object $uri using method $method.  The $method argument must be a
string.  The $uri argument can be either a string, or a reference to a
C<URI> object.  The optional $header argument should be a reference to
an C<HTTP::Headers> object or a plain array reference of key/value
pairs.  The optional $content argument should be a string of bytes.

=item $r = HTTP::Request->parse( $str )

This constructs a new request object by parsing the given string.

=item $r->method

=item $r->method( $val )

This is used to get/set the method attribute.  The method should be a
short string like "GET", "HEAD", "PUT", "PATCH" or "POST".

=item $r->uri

=item $r->uri( $val )

This is used to get/set the uri attribute.  The $val can be a
reference to a URI object or a plain string.  If a string is given,
then it should be parsable as an absolute URI.

=item $r->header( $field )

=item $r->header( $field => $value )

This is used to get/set header values and it is inherited from
C<HTTP::Headers> via C<HTTP::Message>.  See L<HTTP::Headers> for
details and other similar methods that can be used to access the
headers.

=item $r->accept_decodable

This will set the C<Accept-Encoding> header to the list of encodings
that decoded_content() can decode.

=item $r->content

=item $r->content( $bytes )

This is used to get/set the content and it is inherited from the
C<HTTP::Message> base class.  See L<HTTP::Message> for details and
other methods that can be used to access the content.

Note that the content should be a string of bytes.  Strings in perl
can contain characters outside the range of a byte.  The C<Encode>
module can be used to turn such strings into a string of bytes.

=item $r->as_string

=item $r->as_string( $eol )

Method returning a textual representation of the request.

=back

=head1 EXAMPLES

Creating requests to be sent with L<LWP::UserAgent> or others can be easy. Here
are a few examples.

=head2 Simple POST

Here, we'll create a simple POST request that could be used to send JSON data
to an endpoint.

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use HTTP::Request ();
    use JSON::MaybeXS qw(encode_json);

    my $url = 'https://www.example.com/api/user/123';
    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];
    my $data = {foo => 'bar', baz => 'quux'};
    my $encoded_data = encode_json($data);

    my $r = HTTP::Request->new('POST', $url, $header, $encoded_data);
    # at this point, we could send it via LWP::UserAgent
    # my $ua = LWP::UserAgent->new();
    # my $res = $ua->request($r);

=head2 Batch POST Request

Some services, like Google, allow multiple requests to be sent in one batch.
L<https://developers.google.com/drive/v3/web/batch> for example. Using the
C<add_part> method from L<HTTP::Message> makes this simple.

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use HTTP::Request ();
    use JSON::MaybeXS qw(encode_json);

    my $auth_token = 'auth_token';
    my $batch_url = 'https://www.googleapis.com/batch';
    my $url = 'https://www.googleapis.com/drive/v3/files/fileId/permissions?fields=id';
    my $url_no_email = 'https://www.googleapis.com/drive/v3/files/fileId/permissions?fields=id&sendNotificationEmail=false';

    # generate a JSON post request for one of the batch entries
    my $req1 = build_json_request($url, {
        emailAddress => 'example@appsrocks.com',
        role => "writer",
        type => "user",
    });

    # generate a JSON post request for one of the batch entries
    my $req2 = build_json_request($url_no_email, {
        domain => "appsrocks.com",
        role => "reader",
        type => "domain",
    });

    # generate a multipart request to send all of the other requests
    my $r = HTTP::Request->new('POST', $batch_url, [
        'Accept-Encoding' => 'gzip',
        # if we don't provide a boundary here, HTTP::Message will generate
        # one for us. We could use UUID::uuid() here if we wanted.
        'Content-Type' => 'multipart/mixed; boundary=END_OF_PART'
    ]);

    # add the two POST requests to the main request
    $r->add_part($req1, $req2);
    # at this point, we could send it via LWP::UserAgent
    # my $ua = LWP::UserAgent->new();
    # my $res = $ua->request($r);
    exit();

    sub build_json_request {
        my ($url, $href) = @_;
        my $header = ['Authorization' => "Bearer $auth_token", 'Content-Type' => 'application/json; charset=UTF-8'];
        return HTTP::Request->new('POST', $url, $header, encode_json($href));
    }

=head1 SEE ALSO

L<HTTP::Headers>, L<HTTP::Message>, L<HTTP::Request::Common>,
L<HTTP::Response>

=head1 AUTHOR

Gisle Aas <gisle@activestate.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1994 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


#ABSTRACT: HTTP style request message
