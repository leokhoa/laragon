# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Mailer::testfile;{
our $VERSION = '2.22';
}

use base 'Mail::Mailer::rfc822';

use strict;

use Mail::Util qw/mailaddress/;

my $num = 0;
sub can_cc() { 0 }

sub exec($$$)
{   my ($self, $exe, $args, $to) = @_;

    my $outfn = $Mail::Mailer::testfile::config{outfile} || 'mailer.testfile';
    open F, '>>', $outfn
        or die "Cannot append message to testfile $outfn: $!";

    print F "\n===\ntest ", ++$num, " ", (scalar localtime),
            "\nfrom: " . mailaddress(),
            "\nto: " . join(' ',@{$to}), "\n\n";
    close F;

    untie *$self if tied *$self;
    tie *$self, 'Mail::Mailer::testfile::pipe', $self;
    $self;
}

sub close { 1 }

package Mail::Mailer::testfile::pipe;{
our $VERSION = '2.22';
}


sub TIEHANDLE
{   my ($class, $self) = @_;
    bless \$self, $class;
}

sub PRINT
{   my $self = shift;
    open F, '>>', $Mail::Mailer::testfile::config{outfile} || 'mailer.testfile';
    print F @_;
    close F;
}

1;
