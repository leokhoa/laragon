package URI::smb;

use strict;
use warnings;

use parent 'URI::_login';

our $VERSION = '5.34';

sub default_port { 445 }

sub user {
    my $self = shift;
    my $new = shift;
    my ($user, $authdomain) = _parse_user($self->SUPER::user());
    if ($new) {
        $self->SUPER::user($authdomain ? "$authdomain;$new" : $new);
        $user = $new;
    }
    return $user;
}

sub authdomain {
    my $self = shift;
    my $new = shift;
    my ($user, $authdomain) = _parse_user($self->SUPER::user());

    # it must not be possible to set authdomain without user
    if ($user && $new) {
        $self->SUPER::user("$new;$user");
        $authdomain = $new;
    }
    return $authdomain;
}

sub sharename {
    return (shift->path_segments)[1];
}

sub _parse_user {
    my $input = shift or return;
    my ($authdomain, $user) = split ';', $input, 2; 
    return $user ? ($user, $authdomain) : $authdomain;
}

1;
__END__

=head1 NAME

URI::smb - Samba/CIFS URI scheme

=head1 SYNOPSIS

    my $uri = URI->new('smb://authdomain;user:password@server/share/path');

=head1 DESCRIPTION

This module implements the (unofficial) C<smb:> URI scheme described in L<http://www.ubiqx.org/cifs/Appendix-D.html>.

=head1 SUBROUTINES/METHODS

=head2 default_port

The default port for accessing Samba/Windows File Servers is 445

=head2 user

Get or set the user part of the URI (without the authdomain)

=head2 authdomain

Get or set the authentication authdomain part of the URI. This value is only available if the user is already set.

=head2 sharename

Helper method to get the share name from path

=head1 DEPENDENCIES

None

=head1 BUGS AND LIMITATIONS

See L<URI|URI#BUGS>

=head1 SEE ALSO

L<http://www.ubiqx.org/cifs/Appendix-D.html>

=head1 AUTHOR

I. M. Bur <github@lty.cz>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
