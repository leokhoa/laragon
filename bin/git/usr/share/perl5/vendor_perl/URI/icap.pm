package URI::icap;

use strict;
use warnings;
use base qw(URI::http);

our $VERSION = '5.29';

sub default_port { return 1344 }

1;
__END__

=head1 NAME

URI::icap - URI scheme for ICAP Identifiers

=head1 VERSION

Version 5.20

=head1 SYNOPSIS

    use URI::icap;

    my $uri = URI->new('icap://icap-proxy.example.com/');

=head1 DESCRIPTION

This module implements the C<icap:> URI scheme defined in L<RFC 3507|http://tools.ietf.org/html/rfc3507>, for the L<Internet Content Adaptation Protocol|https://en.wikipedia.org/wiki/Internet_Content_Adaptation_Protocol>.

=head1 SUBROUTINES/METHODS

This module inherits the behaviour of L<URI::http|URI::http> and overrides the L<default_port|URI#$uri->default_port> method.

=head2 default_port

The default port for icap servers is 1344

=head1 DIAGNOSTICS

See L<URI|URI>

=head1 CONFIGURATION AND ENVIRONMENT

See L<URI|URI#CONFIGURATION-VARIABLES> and L<URI|URI#ENVIRONMENT-VARIABLES>

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

See L<URI|URI#BUGS>

=head1 SEE ALSO

L<RFC 3507|http://tools.ietf.org/html/rfc3507>

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
