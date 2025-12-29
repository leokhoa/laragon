# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Field::Date;{
our $VERSION = '2.22';
}

use base 'Mail::Field';

use strict;

use Date::Format qw(time2str);
use Date::Parse  qw(str2time);

(bless [])->register('Date');


sub set()
{   my $self = shift;
    my $arg = @_ == 1 ? shift : { @_ };

    foreach my $s (qw(Time TimeStr))
    {   if(exists $arg->{$s})
             { $self->{$s} = $arg->{$s} }
        else { delete $self->{$s} }
    }

    $self;
}

sub parse($)
{   my $self = shift;
    delete $self->{Time};
    $self->{TimeStr} = shift;
    $self;
}


sub time(;$)
{   my $self = shift;

    if(@_)
    {   delete $self->{TimeStr};
        return $self->{Time} = shift;
    }

    $self->{Time} ||= str2time $self->{TimeStr};
}

sub stringify
{   my $self = shift;
    $self->{TimeStr} ||= time2str("%a, %e %b %Y %T %z", $self->time);
}

sub reformat
{   my $self = shift;
    $self->time($self->time);
    $self->stringify;
}

1;
