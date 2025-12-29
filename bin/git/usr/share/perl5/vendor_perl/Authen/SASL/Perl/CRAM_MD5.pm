# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::Perl::CRAM_MD5 2.1900;

use strict;
use warnings;
use vars qw(@ISA);
use Digest::HMAC_MD5 qw(hmac_md5_hex);

warnings::warnif(
    'deprecated',
    'The CRAM-MD5 SASL mechanism is effectively deprecated by RFC8314 and should no longer be used'
    );

@ISA     = qw(Authen::SASL::Perl);

my %secflags = (
	noplaintext => 1,
	noanonymous => 1,
);

sub _order { 2 }
sub _secflags {
  shift;
  scalar grep { $secflags{$_} } @_;
}

sub mechanism { 'CRAM-MD5' }

sub client_start {
  '';
}

sub client_step {
  my ($self, $string) = @_;
  my ($user, $pass) = map {
    my $v = $self->_call($_);
    defined($v) ? $v : ''
  } qw(user pass);

  $user . " " . hmac_md5_hex($string,$pass);
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::CRAM_MD5 - (DEPRECATED) CRAM MD5 Authentication class

=head1 VERSION

version 2.1900

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'CRAM-MD5',
    callback  => {
      user => $user,
      pass => $pass
    },
  );

=head1 DESCRIPTION

This method implements the client part of the CRAM-MD5 SASL algorithm,
as described in RFC 2195 resp. in IETF Draft draft-ietf-sasl-crammd5-XX.txt.

Please note that this mechanism has been moved to the "LIMITED" use section of
the L<mechanism registry|https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml>
and is effectively deprecated per L<RFC8314|https://www.rfc-editor.org/rfc/rfc8314.html> (see
section 5; security considerations).

=head2 CALLBACK

The callbacks used are:

=over 4

=item user

The username to be used for authentication

=item pass

The user's password to be used for authentication

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
