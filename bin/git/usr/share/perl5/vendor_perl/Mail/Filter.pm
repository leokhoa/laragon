# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Filter;{
our $VERSION = '2.22';
}


use strict;
use Carp;


sub new(@)
{   my $class = shift;
    bless { filters => [ @_ ] }, $class;
}

#------------

sub add(@)
{   my $self = shift;
    push @{$self->{filters}}, @_;
}

#------------

sub _filter($)
{   my ($self, $mail) = @_;

    foreach my $sub ( @{$self->{filters}} )
    {   my $mail
          = ref $sub eq 'CODE' ? $sub->($self,$mail)
	  : !ref $sub          ? $self->$sub($mail)
	  : carp "Cannot call filter '$sub', ignored";

	ref $mail or last;
    }

    $mail;
}

sub filter
{   my ($self, $obj) = @_;
    if($obj->isa('Mail::Folder'))
    {   $self->{folder} = $obj;
	foreach my $m ($obj->message_list)
	{   my $mail = $obj->get_message($m) or next;
	    $self->{msgnum} = $m;
	    $self->_filter($mail);
	}
	delete $self->{folder};
	delete $self->{msgnum};
    }
    elsif($obj->isa('Mail::Internet'))
    {   return $self->filter($obj);
    }
    else
    {   carp "Cannot process '$obj'";
	return undef;
    }
}


sub folder() {shift->{folder}}


sub msgnum() {shift->{msgnum}}

1;
