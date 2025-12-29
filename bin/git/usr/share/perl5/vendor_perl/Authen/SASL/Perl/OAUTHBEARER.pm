# Copyright (c) 2025 Aditya Garg <gargaditya08@live.com>
# Copyright (c) 2025 Julian Swagemakers <julian@swagemakers.org>
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::Perl::OAUTHBEARER 2.1900;

use strict;
use vars qw(@ISA);
use JSON::PP;

@ISA     = qw(Authen::SASL::Perl);

my %secflags = (
    noanonymous => 1,
);

sub _order { 1 }

sub _secflags {
    shift;
    scalar grep { $secflags{$_} } @_;
}

sub mechanism { 'OAUTHBEARER' }

sub client_start {
    my $self = shift;
    $self->{stage} = 0;

    # This will generate the oauthbearer string used for authentication.
    #
    # "n,a=" {User} ",^Ahost=" {Host} "^Aport=" {Port} "^Aauth=Bearer " {Access Token} "^A^A
    #
    # The first part `n,a=" {User} ",` is the gs2 header described in RFC5801.
    # * gs2-cb-flag `n` -> client does not support CB
    # * gs2-authzid `a=" {User} "`
    #
    # The second part are key value pairs containing host, port and auth as
    # described in RFC7628.
    #
    # https://datatracker.ietf.org/doc/html/rfc5801
    # https://datatracker.ietf.org/doc/html/rfc7628
    my $username = $self->_call('user');
    my $token    = $self->_call('pass'); # OAuth 2.0 access token
    my $auth_string = "n,a=$username,\001auth=Bearer $token\001\001";

    return $auth_string;
}

sub client_step {
    my ($self, $challenge) = @_;
    my $json = JSON::PP->new;
    my $payload = $json->decode( $challenge );
    $self->set_error( $payload );
    # Send dummy request on authentication failure according to rfc7628.
    # https://datatracker.ietf.org/doc/html/rfc7628#section-3.2.3
    return "\001";
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::OAUTHBEARER - OAUTHBEARER Authentication class

=head1 VERSION

version 2.1900

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'OAUTHBEARER',
    callback  => {
      user => $user,
      pass => $access_token
    },
  );

=head1 DESCRIPTION

This module implements the client side of the OAUTHBEARER SASL mechanism,
which is used for OAuth 2.0-based authentication.

=head2 CALLBACK

The callbacks used are:

=head3 Client

=over 4

=item user

The username to be used for authentication.

=item pass

The OAuth 2.0 access token to be used for authentication.

=back

=head1 SEE ALSO

L<Authen::SASL>,
L<Authen::SASL::Perl>

=head1 AUTHORS

Written by Aditya Garg and Julian Swagemakers.

=head1 COPYRIGHT

Copyright (c) 2025 Aditya Garg.

Copyright (c) 2025 Julian Swagemakers.

All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.
=cut
