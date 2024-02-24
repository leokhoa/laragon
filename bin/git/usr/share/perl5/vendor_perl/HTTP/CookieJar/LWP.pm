use 5.008001;
use strict;
use warnings;

package HTTP::CookieJar::LWP;
# ABSTRACT: LWP adapter for HTTP::CookieJar
our $VERSION = '0.014';

use parent 'HTTP::CookieJar';

sub add_cookie_header {
    my ( $self, $request ) = @_;

    my $url = _get_url( $request, $request->uri );
    return unless ( $url->scheme =~ /^https?\z/ );

    my $header = $self->cookie_header($url);
    $request->header( Cookie => $header );

    return $request;
}

sub extract_cookies {
    my ( $self, $response ) = @_;

    my $request = $response->request
      or return;

    my $url = _get_url( $request, $request->uri );

    $self->add( $url, $_ ) for $response->_header("Set-Cookie");

    return $response;
}

#--------------------------------------------------------------------------#
# helper subroutines
#--------------------------------------------------------------------------#

sub _get_url {
    my ( $request, $url ) = @_;
    my $new_url = $url->clone;
    if ( my $h = $request->header("Host") ) {
        $h =~ s/:\d+$//; # might have a port as well
        $new_url->host($h);
    }
    return $new_url;
}

sub _url_path {
    my $url = shift;
    my $path;
    if ( $url->can('epath') ) {
        $path = $url->epath; # URI::URL method
    }
    else {
        $path = $url->path;  # URI::_generic method
    }
    $path = "/" unless length $path;
    $path;
}

sub _normalize_path          # so that plain string compare can be used
{
    my $x;
    $_[0] =~ s/%([0-9a-fA-F][0-9a-fA-F])/
             $x = uc($1);
                 $x eq "2F" || $x eq "25" ? "%$x" :
                                            pack("C", hex($x));
              /eg;
    $_[0] =~ s/([\0-\x20\x7f-\xff])/sprintf("%%%02X",ord($1))/eg;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::CookieJar::LWP - LWP adapter for HTTP::CookieJar

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  use LWP::UserAgent;
  use HTTP::CookieJar::LWP;

  my $ua = LWP::UserAgent->new(
    cookie_jar => HTTP::CookieJar::LWP->new
  );

=head1 DESCRIPTION

This module is an experimental adapter to make L<HTTP::CookieJar> work with
L<LWP>.  It implements the two methods that C<LWP> calls from L<HTTP::Cookies>.

It is not a general-purpose drop-in replacement for C<HTTP::Cookies> in any
other way.

=for Pod::Coverage method_names_here
add_cookie_header
extract_cookies

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
