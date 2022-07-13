# Copyrights 1995-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Mailer::sendmail;
use vars '$VERSION';
$VERSION = '2.21';

use base 'Mail::Mailer::rfc822';

use strict;

sub exec($$$$)
{   my($self, $exe, $args, $to, $sender) = @_;
    # Fork and exec the mailer (no shell involved to avoid risks)

    # We should always use a -t on sendmail so that Cc: and Bcc: work
    #  Rumor: some sendmails may ignore or break with -t (AIX?)
    # Chopped out the @$to arguments, because -t means
    # they are sent in the body, and postfix complains if they
    # are also given on command line.

    exec( $exe, '-t', @$args );
}

1;
