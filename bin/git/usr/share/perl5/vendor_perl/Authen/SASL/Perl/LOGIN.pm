# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::Perl::LOGIN;
$Authen::SASL::Perl::LOGIN::VERSION = '2.1700';
use strict;
use warnings;
use vars qw(@ISA);

@ISA	 = qw(Authen::SASL::Perl);

my %secflags = (
	noanonymous => 1,
);

sub _order { 1 }
sub _secflags {
  shift;
  scalar grep { $secflags{$_} } @_;
}

sub mechanism { 'LOGIN' }

sub client_start {
  my $self = shift;
  $self->{stage} = 0;
  '';
}

sub client_step {
  my ($self, $string) = @_;

  # XXX technically this is wrong. I might want to change that.
  # spec say it's "staged" and that the content of the challenge doesn't
  # matter
  # actually, let's try
  my $stage = ++$self->{stage};
  if ($stage == 1) {
      return $self->_call('user');
  }
  elsif ($stage == 2) {
      return $self->_call('pass');
  }
  elsif ($stage == 3) {
      $self->set_success;
      return;
  }
  else {
      return $self->set_error("Invalid sequence");
  }
}

sub server_start {
  my $self      = shift;
  my $response  = shift;
  my $user_cb   = shift || sub {};

  $self->{answer}    = {};
  $self->{stage}     = 0;
  $self->{need_step} = 1;
  $self->{error}     = undef;
  $user_cb->('Username:');
  return;
}

sub server_step {
  my $self      = shift;
  my $response  = shift;
  my $user_cb   = shift || sub {};

  my $stage = ++$self->{stage};

  if ($stage == 1) {
    unless (defined $response) {
        $self->set_error("Invalid sequence (empty username)");
        return $user_cb->();
    }
    $self->{answer}{user} = $response;
    return $user_cb->("Password:");
  }
  elsif ($stage == 2) {
    unless (defined $response) {
        $self->set_error("Invalid sequence (empty pass)");
        return $user_cb->();
    }
    $self->{answer}{pass} = $response;
  }
  else {
    $self->set_error("Invalid sequence (end)");
    return $user_cb->();
  }
  my $error = "Credentials don't match";
  my $answers = { user => $self->{answer}{user}, pass => $self->{answer}{pass} };
  if (my $checkpass = $self->{callback}{checkpass}) {
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
    $checkpass->($self => $answers => $cb );
    return;
  }
  elsif (my $getsecret = $self->{callback}{getsecret}) {
    my $cb = sub {
      my $good_pass = shift;
      if ($good_pass && $good_pass eq ($self->{answer}{pass} || "")) {
        $self->set_success;
      }
      else {
        $self->set_error($error);
      }
      $user_cb->();
    };
    $getsecret->($self => $answers => $cb );
    return;
  }
  else {
    $self->set_error($error);
    $user_cb->();
  }
  return;
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::LOGIN - Login Authentication class

=head1 VERSION

version 2.1700

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'LOGIN',
    callback  => {
      user => $user,
      pass => $pass
    },
  );

=head1 DESCRIPTION

This method implements the client and server part of the LOGIN SASL algorithm,
as described in IETF Draft draft-murchison-sasl-login-XX.txt.

=head2 CALLBACK

The callbacks used are:

=head3 Client

=over 4

=item user

The username to be used for authentication

=item pass

The user's password to be used for authentication

=back

=head3 Server

=over 4

=item getsecret(username)

returns the password associated with C<username>

=item checkpass(username, password)

returns true and false depending on the validity of the credentials passed
in arguments.

=back

=head1 SEE ALSO

L<Authen::SASL>,
L<Authen::SASL::Perl>

=head1 AUTHORS

Software written by Graham Barr <gbarr@pobox.com>,
documentation written by Peter Marschall <peter@adpm.de>.
Server support by Yann Kerherve <yannk@cpan.org>

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
