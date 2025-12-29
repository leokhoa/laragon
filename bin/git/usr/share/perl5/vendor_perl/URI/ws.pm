package URI::ws;

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::http';

1;
__END__

=head1 NAME

URI::ws - URI scheme for WebSocket Identifiers

=head1 SYNOPSIS

    use URI::ws;

    my $uri = URI->new('ws://example.com/');

=head1 DESCRIPTION

This module implements the C<ws:> URI scheme defined in L<RFC 6455|http://tools.ietf.org/html/rfc6455>.

=head1 SUBROUTINES/METHODS

This module inherits the behaviour of L<URI::http|URI::http>.

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
