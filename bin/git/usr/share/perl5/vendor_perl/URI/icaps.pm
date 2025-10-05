package URI::icaps;

use strict;
use warnings;
use base qw(URI::icap);

our $VERSION = '5.29';

sub secure { return 1 }

1;
__END__

=head1 NAME

URI::icaps - URI scheme for ICAPS Identifiers

=head1 VERSION

Version 5.20

=head1 SYNOPSIS

    use URI::icaps;

    my $uri = URI->new('icaps://icap-proxy.example.com/');

=head1 DESCRIPTION

This module implements the C<icaps:> URI scheme defined in L<RFC 3507|http://tools.ietf.org/html/rfc3507>, for the L<Internet Content Adaptation Protocol|https://en.wikipedia.org/wiki/Internet_Content_Adaptation_Protocol>.

=head1 SUBROUTINES/METHODS

This module inherits the behaviour of L<URI::icap|URI::icap> and overrides the L<secure|URI#$uri->secure> method.

=head2 secure

returns 1 as icaps is a secure protocol

=head1 DIAGNOSTICS

See L<URI::icap|URI::icap>

=head1 CONFIGURATION AND ENVIRONMENT

See L<URI::icap|URI::icap>

=head1 DEPENDENCIES

None

=head1 INCOMPATIBILITIES

None reported

=head1 BUGS AND LIMITATIONS

See L<URI::icap|URI::icap>

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
