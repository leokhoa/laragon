# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Send;{
our $VERSION = '2.22';
}


use strict;

use Mail::Mailer ();

sub Version { our $VERSION }

#------------------

sub new(@)
{   my ($class, %attr) = @_;
    my $self = bless {}, $class;

    while(my($key, $value) = each %attr)
    {	$key = lc $key;
        $self->$key($value);
    }

    $self;
}

#---------------

sub set($@)
{   my ($self, $hdr, @values) = @_;
    $self->{$hdr} = [ @values ] if @values;
    @{$self->{$hdr} || []};	# return new (or original) values
}


sub add($@)
{   my ($self, $hdr, @values) = @_;
    push @{$self->{$hdr}}, @values;
}


sub delete($)
{   my($self, $hdr) = @_;
    delete $self->{$hdr};
}


sub to		{ my $self=shift; $self->set('To', @_); }
sub cc		{ my $self=shift; $self->set('Cc', @_); }
sub bcc		{ my $self=shift; $self->set('Bcc', @_); }
sub subject	{ my $self=shift; $self->set('Subject', join (' ', @_)); }

#---------------

sub open(@)
{   my $self = shift;
    Mail::Mailer->new(@_)->open($self);
}

1;
