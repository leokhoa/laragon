# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::Perl::ANONYMOUS;
$Authen::SASL::Perl::ANONYMOUS::VERSION = '2.1700';
use strict;
use warnings;
use vars qw(@ISA);

@ISA	 = qw(Authen::SASL::Perl);

my %secflags = (
	noplaintext => 1,
);

sub _order { 0 }
sub _secflags {
  shift;
  grep { $secflags{$_} } @_;
}

sub mechanism { 'ANONYMOUS' }

sub client_start {
  shift->_call('authname')
}

sub client_step {
  shift->_call('authname')
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::ANONYMOUS - Anonymous Authentication class

=head1 VERSION

version 2.1700

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'ANONYMOUS',
    callback  => {
      authname => $mailaddress
    },
  );

=head1 DESCRIPTION

This method implements the client part of the ANONYMOUS SASL algorithm,
as described in RFC 2245 resp. in IETF Draft draft-ietf-sasl-anon-XX.txt.

=head2 CALLBACK

The callbacks used are:

=over 4

=item authname

email address or UTF-8 encoded string to be used as
trace information for the server

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

=cut
