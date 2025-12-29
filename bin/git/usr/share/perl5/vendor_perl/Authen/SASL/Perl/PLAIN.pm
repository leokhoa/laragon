# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::Perl::PLAIN 2.1900;

use strict;
use warnings;
use vars qw(@ISA);

@ISA	 = qw(Authen::SASL::Perl);

my %secflags = (
	noanonymous => 1,
);

my @tokens = qw(authname user pass);

sub _order { 1 }
sub _secflags {
  shift;
  grep { $secflags{$_} } @_;
}

sub mechanism { 'PLAIN' }

sub client_start {
  my $self = shift;

  $self->{error}     = undef;
  $self->{need_step} = 0;

  my @parts = map {
    my $v = $self->_call($_);
    defined($v) ? $v : ''
  } @tokens;

  join("\0", @parts);
}

sub server_start {
  my $self      = shift;
  my $response  = shift;
  my $user_cb   = shift || sub {};

  $self->{error} = undef;
  return $self->set_error("No response: Credentials don't match")
    unless defined $response;

  my %parts;
  @parts{@tokens} = split "\0", $response, scalar @tokens;


  # I'm not entirely sure of what I am doing
  $self->{answer}{$_} = $parts{$_} for qw/authname user/;
  my $error = "Credentials don't match";

  ## checkpass
  if (my $checkpass = $self->callback('checkpass')) {
    my $cb = sub {
      my $result = shift;
      unless ($result) {
        $self->set_error($error);
      }
      else {
        $self->set_success;
      }
      $user_cb->();
    };
    $checkpass->($self => { %parts } => $cb );
    return;
  }

  ## getsecret
  elsif (my $getsecret = $self->callback('getsecret')) {
    my $cb = sub {
      my $good_pass = shift;
      if ($good_pass && $good_pass eq ($parts{pass} || "")) {
        $self->set_success;
      }
      else {
        $self->set_error($error);
      }
      $user_cb->();
    };
    $getsecret->( $self, { map { $_ => $parts{$_ } } qw/user authname/ }, $cb );
    return;
  }

  ## error by default
  else {
    $self->set_error($error);
    $user_cb->();
  }
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::PLAIN - Plain Login Authentication class

=head1 VERSION

version 2.1900

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'PLAIN',
    callback  => {
      user => $user,
      pass => $pass
    },
  );

=head1 DESCRIPTION

This method implements the client and server part of the PLAIN SASL algorithm,
as described in RFC 2595 resp. IETF Draft draft-ietf-sasl-plain-XX.txt

=head2 CALLBACK

The callbacks used are:

=head3 Client

=over 4

=item authname

The authorization id to use after successful authentication (client)

=item user

The username to be used for authentication (client)

=item pass

The user's password to be used for authentication.

=back

=head3 Server

=over 4

=item checkpass(username, password, realm)

returns true and false depending on the validity of the credentials passed
in arguments.

=back

=head1 SEE ALSO

L<Authen::SASL>,
L<Authen::SASL::Perl>

=head1 AUTHORS

Software written by Graham Barr <gbarr@pobox.com>,
documentation written by Peter Marschall <peter@adpm.de>.

Please report any bugs, or post any suggestions, to the perl-ldap mailing list
<perl-ldap@perl.org>

=head1 COPYRIGHT 

Copyright (c) 2002-2004 Graham Barr.
All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

Documentation Copyright (c) 2004 Peter Marschall.
All rights reserved.  This documentation is distributed,
and may be redistributed, under the same terms as Perl itself. 

Server support Copyright (c) 2009 Yann Kerherve.
All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
