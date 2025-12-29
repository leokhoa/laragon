# Copyright (c) 1998-2002 Graham Barr <gbarr@pobox.com> and 2001 Chris Ridd
# <chris.ridd@isode.com>.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

package Authen::SASL::Perl::EXTERNAL 2.1900;

use strict;
use warnings;
use vars qw(@ISA);

@ISA	 = qw(Authen::SASL::Perl);

my %secflags = (
	noplaintext  => 1,
	nodictionary => 1,
	noanonymous  => 1,
);

sub _order { 2 }
sub _secflags {
  shift;
  grep { $secflags{$_} } @_;
}

sub mechanism { 'EXTERNAL' }

sub client_start {
  my $self = shift;
  my $v = $self->_call('user');
  defined($v) ? $v : ''
}

#sub client_step {
#  shift->_call('user');
#}

1;

__END__

=head1 NAME

Authen::SASL::Perl::EXTERNAL - External Authentication class

=head1 VERSION

version 2.1900

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'EXTERNAL',
    callback  => {
      user => $user
    },
  );

=head1 DESCRIPTION

This method implements the client part of the EXTERNAL SASL algorithm,
as described in RFC 2222.

=head2 CALLBACK

The callbacks used are:

=over 4

=item user

The username to be used for authentication

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

Copyright (c) 1998-2004 Graham Barr.
All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

Documentation Copyright (c) 2004 Peter Marschall.
All rights reserved.  This documentation is distributed,
and may be redistributed, under the same terms as Perl itself. 

=cut
