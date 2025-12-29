# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Mailer::rfc822;{
our $VERSION = '2.22';
}

use base 'Mail::Mailer';

use strict;

# Some fields are not allowed to repeat
my %max_once = map +($_ => 1), qw/from to cc bcc reply-to/;

sub set_headers
{   my ($self, $hdrs) = @_;
    local $\ = "";

    foreach my $f (grep /^[A-Z]/, keys %$hdrs)
    {   # s///r requires perl 5.12: too new :-)
        my @h = map { my $h = $_; $h =~ s/\n+\Z//; $h } $self->to_array($hdrs->{$f});
        @h = join ', ', @h if @h && $max_once{lc $f};
        print $self "$f: $_\n" for @h;
    }

    print $self "\n";  # end of headers
}

1;
