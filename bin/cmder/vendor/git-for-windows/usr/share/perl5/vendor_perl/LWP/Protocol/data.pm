package LWP::Protocol::data;

# Implements access to data:-URLs as specified in RFC 2397

use strict;

our $VERSION = '6.57';

require HTTP::Response;
require HTTP::Status;

use base qw(LWP::Protocol);

use HTTP::Date qw(time2str);
require LWP;  # needs version number

sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    # check proxy
    if (defined $proxy)
    {
	return HTTP::Response->new( HTTP::Status::RC_BAD_REQUEST,
				  'You can not proxy with data');
    }

    # check method
    my $method = $request->method;
    unless ($method eq 'GET' || $method eq 'HEAD') {
	return HTTP::Response->new( HTTP::Status::RC_BAD_REQUEST,
				  'Library does not allow method ' .
				  "$method for 'data:' URLs");
    }

    my $url = $request->uri;
    my $response = HTTP::Response->new( HTTP::Status::RC_OK, "Document follows");

    my $media_type = $url->media_type;

    my $data = $url->data;
    $response->header('Content-Type'   => $media_type,
		      'Content-Length' => length($data),
		      'Date'           => time2str(time),
		      'Server'         => "libwww-perl-internal/$LWP::VERSION"
		     );

    $data = "" if $method eq "HEAD";
    return $self->collect_once($arg, $response, $data);
}

1;
