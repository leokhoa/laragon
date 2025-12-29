# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Mailer;{
our $VERSION = '2.22';
}

use base 'IO::Handle';

use strict;
use POSIX qw/_exit/;

use Carp;
use Config;

#--------------


sub is_exe($);

sub Version { our $VERSION }

our @Mailers =
  ( sendmail => '/usr/lib/sendmail;/usr/sbin/sendmail;/usr/ucblib/sendmail'
  , smtp     => undef
  , smtps    => undef
  , qmail    => '/usr/sbin/qmail-inject;/var/qmail/bin/qmail-inject'
  , testfile => undef
  );

push @Mailers, map { split /\:/, $_, 2 }
                   split /$Config{path_sep}/, $ENV{PERL_MAILERS}
    if $ENV{PERL_MAILERS};

our %Mailers = @Mailers;
our $MailerType;
our $MailerBinary;

# does this really need to be done? or should a default mailer be specified?

$Mailers{sendmail} = 'sendmail'
    if $^O eq 'os2' && ! is_exe $Mailers{sendmail};

if($^O =~ m/MacOS|VMS|MSWin|os2|NetWare/i )
{   $MailerType   = 'smtp';
    $MailerBinary = $Mailers{$MailerType};
}
else
{   for(my $i = 0 ; $i < @Mailers ; $i += 2)
    {   $MailerType = $Mailers[$i];
        if(my $binary = is_exe $Mailers{$MailerType})
        {   $MailerBinary = $binary;
            last;
        }
    }
}

sub import
{   shift;  # class
    @_ or return;

    my $type = shift;
    my $exe  = shift || $Mailers{$type};

    is_exe $exe
        or carp "Cannot locate '$exe'";

    $MailerType = $type;
    $Mailers{$MailerType} = $exe;
}

sub to_array($)
{   my ($self, $thing) = @_;
    ref $thing ? @$thing : $thing;
}

sub is_exe($)
{   my $exe = shift || '';

    foreach my $cmd (split /\;/, $exe)
    {   $cmd =~ s/^\s+//;

        # remove any options
        my $name = ($cmd =~ /^(\S+)/)[0];

        # check for absolute or relative path
        return $cmd
            if -x $name && ! -d $name && $name =~ m![\\/]!;

        if(defined $ENV{PATH})
        {   foreach my $dir (split /$Config{path_sep}/, $ENV{PATH})
            {   return "$dir/$cmd"
                   if -x "$dir/$name" && ! -d "$dir/$name";
            }
        }
    }
    0;
}


sub new($@)
{   my ($class, $type, @args) = @_;

    unless($type)
    {   $MailerType or croak "No MailerType specified";

        warn "No real MTA found, using '$MailerType'"
             if $MailerType eq 'testfile';

        $type = $MailerType;
    }

    my $exe = $Mailers{$type};

    if(defined $exe)
    {   $exe   = is_exe $exe
            if defined $type;

        $exe ||= $MailerBinary
            or croak "No mailer type specified (and no default available), thus can not find executable program.";
    }

    $class = "Mail::Mailer::$type";
    eval "require $class" or die $@;

    my $glob = $class->SUPER::new;   # object is a GLOB!
    %{*$glob} = (Exe => $exe, Args => [ @args ]);
    $glob;
}


sub open($)
{   my ($self, $hdrs) = @_;
    my $exe    = *$self->{Exe};   # no exe, then direct smtp
    my $args   = *$self->{Args};

    my @to     = $self->who_to($hdrs);
    my $sender = $self->who_sender($hdrs);
    
    $self->close;	# just in case;

    if(defined $exe)
    {   # Fork and start a mailer
        my $child = open $self, '|-';
        defined $child or die "Failed to send: $!";

        if($child==0)
        {   # Child process will handle sending, but this is not real exec()
            # this is a setup!!!
            unless($self->exec($exe, $args, \@to, $sender))
            {   warn $!;     # setup failed
                _exit(1);    # no DESTROY(), keep it for parent
            }
        }
    }
    else
    {   # Sending is handled by a subclass
        $self->exec(undef, $args, \@to)
            or die $!;    
    }

    $self->set_headers($hdrs);
    $self;
}

sub _cleanup_hdrs($)
{   foreach my $h (values %{(shift)})
    {   foreach (ref $h ? @$h : $h)
        {   s/\n\s*/ /g;
            s/\s+$//;
        }
    }
}

sub exec($$$$)
{   my($self, $exe, $args, $to, $sender) = @_;

    # Fork and exec the mailer (no shell involved to avoid risks)
    my @exe = split /\s+/, $exe;
    exec @exe, @$args, @$to;
}

sub can_cc { 1 }	# overridden in subclass for mailer that can't

sub who_to($)
{   my($self, $hdrs) = @_;
    my @to = $self->to_array($hdrs->{To});
    unless($self->can_cc)  # Can't cc/bcc so add them to @to
    {   push @to, $self->to_array($hdrs->{Cc} ) if $hdrs->{Cc};
        push @to, $self->to_array($hdrs->{Bcc}) if $hdrs->{Bcc};
    }
    @to;
}

sub who_sender($)
{   my ($self, $hdrs) = @_;
    ($self->to_array($hdrs->{Sender} || $hdrs->{From}))[0];
}

sub epilogue {
    # This could send a .signature, also see ::smtp subclass
}

sub close(@)
{   my $self = shift;
    fileno $self or return;

    $self->epilogue;
    CORE::close $self;
}

sub DESTROY { shift->close }

#--------------

1;
