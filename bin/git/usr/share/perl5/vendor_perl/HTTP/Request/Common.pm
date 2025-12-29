package HTTP::Request::Common;

use strict;
use warnings;

our $VERSION = '7.01';

our $DYNAMIC_FILE_UPLOAD ||= 0;  # make it defined (don't know why)
our $READ_BUFFER_SIZE      = 8192;

use Exporter 5.57 'import';

our @EXPORT =qw(GET HEAD PUT PATCH POST OPTIONS);
our @EXPORT_OK = qw($DYNAMIC_FILE_UPLOAD DELETE);

require HTTP::Request;
use Carp();
use File::Spec;

my $CRLF = "\015\012";   # "\r\n" is not portable

sub GET  { _simple_req('GET',  @_); }
sub HEAD { _simple_req('HEAD', @_); }
sub DELETE { _simple_req('DELETE', @_); }
sub PATCH { request_type_with_data('PATCH', @_); }
sub POST { request_type_with_data('POST', @_); }
sub PUT { request_type_with_data('PUT', @_); }
sub OPTIONS { request_type_with_data('OPTIONS', @_); }

sub request_type_with_data
{
    my $type = shift;
    my $url  = shift;
    my $req = HTTP::Request->new($type => $url);
    my $content;
    $content = shift if @_ and ref $_[0];
    my($k, $v);
    while (($k,$v) = splice(@_, 0, 2)) {
	if (lc($k) eq 'content') {
	    $content = $v;
	}
	else {
	    $req->push_header($k, $v);
	}
    }
    my $ct = $req->header('Content-Type');
    unless ($ct) {
	$ct = 'application/x-www-form-urlencoded';
    }
    elsif ($ct eq 'form-data') {
	$ct = 'multipart/form-data';
    }

    if (ref $content) {
	if ($ct =~ m,^multipart/form-data\s*(;|$),i) {
	    require HTTP::Headers::Util;
	    my @v = HTTP::Headers::Util::split_header_words($ct);
	    Carp::carp("Multiple Content-Type headers") if @v > 1;
	    @v = @{$v[0]};

	    my $boundary;
	    my $boundary_index;
	    for (my @tmp = @v; @tmp;) {
		my($k, $v) = splice(@tmp, 0, 2);
		if ($k eq "boundary") {
		    $boundary = $v;
		    $boundary_index = @v - @tmp - 1;
		    last;
		}
	    }

	    ($content, $boundary) = form_data($content, $boundary, $req);

	    if ($boundary_index) {
		$v[$boundary_index] = $boundary;
	    }
	    else {
		push(@v, boundary => $boundary);
	    }

	    $ct = HTTP::Headers::Util::join_header_words(@v);
	}
	else {
	    # We use a temporary URI object to format
	    # the application/x-www-form-urlencoded content.
	    require URI;
	    my $url = URI->new('http:');
	    $url->query_form(ref($content) eq "HASH" ? %$content : @$content);
	    $content = $url->query;
	}
    }

    $req->header('Content-Type' => $ct);  # might be redundant
    if (defined($content)) {
	$req->header('Content-Length' =>
		     length($content)) unless ref($content);
	$req->content($content);
    }
    else {
        $req->header('Content-Length' => 0);
    }
    $req;
}


sub _simple_req
{
    my($method, $url) = splice(@_, 0, 2);
    my $req = HTTP::Request->new($method => $url);
    my($k, $v);
    my $content;
    while (($k,$v) = splice(@_, 0, 2)) {
	if (lc($k) eq 'content') {
	    $req->add_content($v);
            $content++;
	}
	else {
	    $req->push_header($k, $v);
	}
    }
    if ($content && !defined($req->header("Content-Length"))) {
        $req->header("Content-Length", length(${$req->content_ref}));
    }
    $req;
}


sub form_data   # RFC1867
{
    my($data, $boundary, $req) = @_;
    my @data = ref($data) eq "HASH" ? %$data : @$data;  # copy
    my $fhparts;
    my @parts;
    while (my ($k,$v) = splice(@data, 0, 2)) {
	if (!ref($v)) {
	    $k =~ s/([\\\"])/\\$1/g;  # escape quotes and backslashes
            no warnings 'uninitialized';
	    push(@parts,
		 qq(Content-Disposition: form-data; name="$k"$CRLF$CRLF$v));
	}
	else {
	    my($file, $usename, @headers) = @$v;
	    unless (defined $usename) {
		$usename = $file;
		$usename = (File::Spec->splitpath($usename))[-1] if defined($usename);
	    }
            $k =~ s/([\\\"])/\\$1/g;
	    my $disp = qq(form-data; name="$k");
            if (defined($usename) and length($usename)) {
                $usename =~ s/([\\\"])/\\$1/g;
                $disp .= qq(; filename="$usename");
            }
	    my $content = "";
	    my $h = HTTP::Headers->new(@headers);
	    if ($file) {
		open(my $fh, "<", $file) or Carp::croak("Can't open file $file: $!");
		binmode($fh);
		if ($DYNAMIC_FILE_UPLOAD) {
		    # will read file later, close it now in order to
                    # not accumulate to many open file handles
                    close($fh);
		    $content = \$file;
		}
		else {
		    local($/) = undef; # slurp files
		    $content = <$fh>;
		    close($fh);
		}
		unless ($h->header("Content-Type")) {
		    require LWP::MediaTypes;
		    LWP::MediaTypes::guess_media_type($file, $h);
		}
	    }
	    if ($h->header("Content-Disposition")) {
		# just to get it sorted first
		$disp = $h->header("Content-Disposition");
		$h->remove_header("Content-Disposition");
	    }
	    if ($h->header("Content")) {
		$content = $h->header("Content");
		$h->remove_header("Content");
	    }
	    my $head = join($CRLF, "Content-Disposition: $disp",
			           $h->as_string($CRLF),
			           "");
	    if (ref $content) {
		push(@parts, [$head, $$content]);
		$fhparts++;
	    }
	    else {
		push(@parts, $head . $content);
	    }
	}
    }
    return ("", "none") unless @parts;

    my $content;
    if ($fhparts) {
	$boundary = boundary(10) # hopefully enough randomness
	    unless $boundary;

	# add the boundaries to the @parts array
	for (1..@parts-1) {
	    splice(@parts, $_*2-1, 0, "$CRLF--$boundary$CRLF");
	}
	unshift(@parts, "--$boundary$CRLF");
	push(@parts, "$CRLF--$boundary--$CRLF");

	# See if we can generate Content-Length header
	my $length = 0;
	for (@parts) {
	    if (ref $_) {
	 	my ($head, $f) = @$_;
		my $file_size;
		unless ( -f $f && ($file_size = -s _) ) {
		    # The file is either a dynamic file like /dev/audio
		    # or perhaps a file in the /proc file system where
		    # stat may return a 0 size even though reading it
		    # will produce data.  So we cannot make
		    # a Content-Length header.
		    undef $length;
		    last;
		}
	    	$length += $file_size + length $head;
	    }
	    else {
		$length += length;
	    }
        }
        $length && $req->header('Content-Length' => $length);

	# set up a closure that will return content piecemeal
	$content = sub {
	    for (;;) {
		unless (@parts) {
		    defined $length && $length != 0 &&
		    	Carp::croak "length of data sent did not match calculated Content-Length header.  Probably because uploaded file changed in size during transfer.";
		    return;
		}
		my $p = shift @parts;
		unless (ref $p) {
		    $p .= shift @parts while @parts && !ref($parts[0]);
		    defined $length && ($length -= length $p);
		    return $p;
		}
		my($buf, $fh) = @$p;
                unless (ref($fh)) {
                    my $file = $fh;
                    undef($fh);
                    open($fh, "<", $file) || Carp::croak("Can't open file $file: $!");
                    binmode($fh);
                }
		my $buflength = length $buf;
		my $n = read($fh, $buf, $READ_BUFFER_SIZE, $buflength);
		if ($n) {
		    $buflength += $n;
		    unshift(@parts, ["", $fh]);
		}
		else {
		    close($fh);
		}
		if ($buflength) {
		    defined $length && ($length -= $buflength);
		    return $buf
	    	}
	    }
	};

    }
    else {
	$boundary = boundary() unless $boundary;

	my $bno = 0;
      CHECK_BOUNDARY:
	{
	    for (@parts) {
		if (index($_, $boundary) >= 0) {
		    # must have a better boundary
		    $boundary = boundary(++$bno);
		    redo CHECK_BOUNDARY;
		}
	    }
	    last;
	}
	$content = "--$boundary$CRLF" .
	           join("$CRLF--$boundary$CRLF", @parts) .
		   "$CRLF--$boundary--$CRLF";
    }

    wantarray ? ($content, $boundary) : $content;
}


sub boundary
{
    my $size = shift || return "xYzZY";
    require MIME::Base64;
    my $b = MIME::Base64::encode(join("", map chr(rand(256)), 1..$size*3), "");
    $b =~ s/[\W]/X/g;  # ensure alnum only
    $b;
}

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Request::Common - Construct common HTTP::Request objects

=head1 VERSION

version 7.01

=head1 SYNOPSIS

  use HTTP::Request::Common;
  $ua = LWP::UserAgent->new;
  $ua->request(GET 'http://www.sn.no/');
  $ua->request(POST 'http://somewhere/foo', foo => bar, bar => foo);
  $ua->request(PATCH 'http://somewhere/foo', foo => bar, bar => foo);
  $ua->request(PUT 'http://somewhere/foo', foo => bar, bar => foo);
  $ua->request(OPTIONS 'http://somewhere/foo', foo => bar, bar => foo);

=head1 DESCRIPTION

This module provides functions that return newly created C<HTTP::Request>
objects.  These functions are usually more convenient to use than the
standard C<HTTP::Request> constructor for the most common requests.

Note that L<LWP::UserAgent> has several convenience methods, including
C<get>, C<head>, C<delete>, C<post> and C<put>.

The following functions are provided:

=over 4

=item GET $url

=item GET $url, Header => Value,...

The C<GET> function returns an L<HTTP::Request> object initialized with
the "GET" method and the specified URL.  It is roughly equivalent to the
following call

  HTTP::Request->new(
     GET => $url,
     HTTP::Headers->new(Header => Value,...),
  )

but is less cluttered.  What is different is that a header named
C<Content> will initialize the content part of the request instead of
setting a header field.  Note that GET requests should normally not
have a content, so this hack makes more sense for the C<PUT>, C<PATCH>
 and C<POST> functions described below.

The C<get(...)> method of L<LWP::UserAgent> exists as a shortcut for
C<< $ua->request(GET ...) >>.

=item HEAD $url

=item HEAD $url, Header => Value,...

Like GET() but the method in the request is "HEAD".

The C<head(...)>  method of L<LWP::UserAgent> exists as a shortcut for
C<< $ua->request(HEAD ...) >>.

=item DELETE $url

=item DELETE $url, Header => Value,...

Like C<GET> but the method in the request is C<DELETE>.  This function
is not exported by default.

=item PATCH $url

=item PATCH $url, Header => Value,...

=item PATCH $url, $form_ref, Header => Value,...

=item PATCH $url, Header => Value,..., Content => $form_ref

=item PATCH $url, Header => Value,..., Content => $content

The same as C<POST> below, but the method in the request is C<PATCH>.

=item PUT $url

=item PUT $url, Header => Value,...

=item PUT $url, $form_ref, Header => Value,...

=item PUT $url, Header => Value,..., Content => $form_ref

=item PUT $url, Header => Value,..., Content => $content

The same as C<POST> below, but the method in the request is C<PUT>

=item OPTIONS $url

=item OPTIONS $url, Header => Value,...

=item OPTIONS $url, $form_ref, Header => Value,...

=item OPTIONS $url, Header => Value,..., Content => $form_ref

=item OPTIONS $url, Header => Value,..., Content => $content

The same as C<POST> below, but the method in the request is C<OPTIONS>

This was added in version 6.21, so you should require that in your code:

 use HTTP::Request::Common 6.21;

=item POST $url

=item POST $url, Header => Value,...

=item POST $url, $form_ref, Header => Value,...

=item POST $url, Header => Value,..., Content => $form_ref

=item POST $url, Header => Value,..., Content => $content

C<POST>, C<PATCH> and C<PUT> all work with the same parameters.

  %data = ( title => 'something', body => something else' );
  $ua = LWP::UserAgent->new();
  $request = HTTP::Request::Common::POST( $url, [ %data ] );
  $response = $ua->request($request);

They take a second optional array or hash reference
parameter C<$form_ref>.  The content can also be specified
directly using the C<Content> pseudo-header, and you may also provide
the C<$form_ref> this way.

The C<Content> pseudo-header steals a bit of the header field namespace as
there is no way to directly specify a header that is actually called
"Content".  If you really need this you must update the request
returned in a separate statement.

The C<$form_ref> argument can be used to pass key/value pairs for the
form content.  By default we will initialize a request using the
C<application/x-www-form-urlencoded> content type.  This means that
you can emulate an HTML E<lt>form> POSTing like this:

  POST 'http://www.perl.org/survey.cgi',
       [ name   => 'Gisle Aas',
         email  => 'gisle@aas.no',
         gender => 'M',
         born   => '1964',
         perc   => '3%',
       ];

This will create an L<HTTP::Request> object that looks like this:

  POST http://www.perl.org/survey.cgi
  Content-Length: 66
  Content-Type: application/x-www-form-urlencoded

  name=Gisle%20Aas&email=gisle%40aas.no&gender=M&born=1964&perc=3%25

Multivalued form fields can be specified by either repeating the field
name or by passing the value as an array reference.

The POST method also supports the C<multipart/form-data> content used
for I<Form-based File Upload> as specified in RFC 1867.  You trigger
this content format by specifying a content type of C<'form-data'> as
one of the request headers.  If one of the values in the C<$form_ref> is
an array reference, then it is treated as a file part specification
with the following interpretation:

  [ $file, $filename, Header => Value... ]
  [ undef, $filename, Header => Value,..., Content => $content ]

The first value in the array ($file) is the name of a file to open.
This file will be read and its content placed in the request.  The
routine will croak if the file can't be opened.  Use an C<undef> as
$file value if you want to specify the content directly with a
C<Content> header.  The $filename is the filename to report in the
request.  If this value is undefined, then the basename of the $file
will be used.  You can specify an empty string as $filename if you
want to suppress sending the filename when you provide a $file value.

If a $file is provided by no C<Content-Type> header, then C<Content-Type>
and C<Content-Encoding> will be filled in automatically with the values
returned by C<LWP::MediaTypes::guess_media_type()>

Sending my F<~/.profile> to the survey used as example above can be
achieved by this:

  POST 'http://www.perl.org/survey.cgi',
       Content_Type => 'form-data',
       Content      => [ name  => 'Gisle Aas',
                         email => 'gisle@aas.no',
                         gender => 'M',
                         born   => '1964',
                         init   => ["$ENV{HOME}/.profile"],
                       ]

This will create an L<HTTP::Request> object that almost looks this (the
boundary and the content of your F<~/.profile> is likely to be
different):

  POST http://www.perl.org/survey.cgi
  Content-Length: 388
  Content-Type: multipart/form-data; boundary="6G+f"

  --6G+f
  Content-Disposition: form-data; name="name"

  Gisle Aas
  --6G+f
  Content-Disposition: form-data; name="email"

  gisle@aas.no
  --6G+f
  Content-Disposition: form-data; name="gender"

  M
  --6G+f
  Content-Disposition: form-data; name="born"

  1964
  --6G+f
  Content-Disposition: form-data; name="init"; filename=".profile"
  Content-Type: text/plain

  PATH=/local/perl/bin:$PATH
  export PATH

  --6G+f--

If you set the C<$DYNAMIC_FILE_UPLOAD> variable (exportable) to some TRUE
value, then you get back a request object with a subroutine closure as
the content attribute.  This subroutine will read the content of any
files on demand and return it in suitable chunks.  This allow you to
upload arbitrary big files without using lots of memory.  You can even
upload infinite files like F</dev/audio> if you wish; however, if
the file is not a plain file, there will be no C<Content-Length> header
defined for the request.  Not all servers (or server
applications) like this.  Also, if the file(s) change in size between
the time the C<Content-Length> is calculated and the time that the last
chunk is delivered, the subroutine will C<Croak>.

The C<post(...)>  method of L<LWP::UserAgent> exists as a shortcut for
C<< $ua->request(POST ...) >>.

=back

=head1 SEE ALSO

L<HTTP::Request>, L<LWP::UserAgent>

Also, there are some examples in L<HTTP::Request/"EXAMPLES"> that you might
find useful. For example, batch requests are explained there.

=head1 AUTHOR

Gisle Aas <gisle@activestate.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1994 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


#ABSTRACT: Construct common HTTP::Request objects
