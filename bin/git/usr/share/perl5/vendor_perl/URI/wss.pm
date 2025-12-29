package URI::wss;

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::https';

1;
__END__

=head1 NAME

URI::wss - URI scheme for WebSocket Identifiers

=head1 VERSION

Version 5.33

=head1 SYNOPSIS

    use URI::wss;

    my $uri = URI->new('wss://example.com/');

=head1 DESCRIPTION

This module implements the C<wss:> URI scheme defined in L<RFC 6455|http://tools.ietf.org/html/rfc6455>.

=head1 SUBROUTINES/METHODS

This module inherits the behaviour of L<URI::https|URI::https>.

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

L<RFC 6455|http://tools.ietf.org/html/rfc6455>

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
