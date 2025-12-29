# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Cap;{
our $VERSION = '2.22';
}


use strict;

sub Version { our $VERSION }


our $useCache = 1;  # don't evaluate tests every time

my @path;
if($^O eq "MacOS")
{   @path = split /\,/, $ENV{MAILCAPS} || "$ENV{HOME}mailcap";
}
else
{   @path = split /\:/
      , ( $ENV{MAILCAPS} || (defined $ENV{HOME} ? "$ENV{HOME}/.mailcap:" : '')
        . '/etc/mailcap:/usr/etc/mailcap:/usr/local/etc/mailcap'
        );   # this path is specified under RFC1524 appendix A 
}

#--------

sub new
{   my $class = shift;
    
    unshift @_, 'filename' if @_ % 2;
    my %args  = @_;

    my $take_all = $args{take} && uc $args{take} eq 'ALL';

    my $self  = bless {_count => 0}, $class;

    $self->_process_file($args{filename})
        if defined $args{filename} && -r $args{filename};

    if(!defined $args{filename} || $take_all)
    {   foreach my $fname (@path)
        {   -r $fname or next;

            $self->_process_file($fname);
            last unless $take_all;
        }
    }

    unless($self->{_count})
    {   # Set up default mailcap
        $self->{'audio/*'} = [{'view' => "showaudio %s"}];
        $self->{'image/*'} = [{'view' => "xv %s"}];
        $self->{'message/rfc822'} = [{'view' => "xterm -e metamail %s"}];
    }

    $self;
}

sub _process_file
{   my $self = shift;
    my $file = shift or return;

    local *MAILCAP;
    open MAILCAP, $file
        or return;

    $self->{_file} = $file;

    local $_;
    while(<MAILCAP>)
    {   next if /^\s*#/; # comment
        next if /^\s*$/; # blank line
        $_ .= <MAILCAP>  # continuation line
           while s/(^|[^\\])((?:\\\\)*)\\\s*$/$1$2/;
        chomp;
        s/\0//g;              # ensure no NULs in the line
        s/(^|[^\\]);/$1\0/g;  # make field separator NUL
        my ($type, $view, @parts) = split /\s*\0\s*/;

        $type    .= "/*" if $type !~ m[/];
        $view     =~ s/\\;/;/g;
        $view     =~ s/\\\\/\\/g;
        my %field = (view => $view);

        foreach (@parts)
        {   my($key, $val) = split /\s*\=\s*/, $_, 2;
            if(defined $val)
            {   $val =~ s/\\;/;/g;
                $val =~ s/\\\\/\\/g;
                $field{$key} = $val;
            }
            else
            {   $field{$key} = 1;
            }
        }

        if(my $test = $field{test})
        {   unless ($test =~ /\%/)
            {   # No parameters in test, can perform it right away
                system $test;
                next if $?;
            }
        }

        # record this entry
        unless(exists $self->{$type})
        {   $self->{$type} = [];
            $self->{_count}++; 
        }
        push @{$self->{$type}}, \%field;
    }

    close MAILCAP;
}

#------------------

sub view    { my $self = shift; $self->_run($self->viewCmd(@_))    }
sub compose { my $self = shift; $self->_run($self->composeCmd(@_)) }
sub edit    { my $self = shift; $self->_run($self->editCmd(@_))    }
sub print   { my $self = shift; $self->_run($self->printCmd(@_))   }

sub _run($)
{   my ($self, $cmd) = @_;
    defined $cmd or return 0;

    system $cmd;
    1;
}

#------------------

sub viewCmd    { shift->_createCommand(view    => @_) }
sub composeCmd { shift->_createCommand(compose => @_) }
sub editCmd    { shift->_createCommand(edit    => @_) }
sub printCmd   { shift->_createCommand(print   => @_) }

sub _createCommand($$$)
{   my ($self, $method, $type, $file) = @_;
    my $entry = $self->getEntry($type, $file);

    $entry && exists $entry->{$method}
        or return undef;

    $self->expandPercentMacros($entry->{$method}, $type, $file);
}

sub makeName($$)
{   my ($self, $type, $basename) = @_;
    my $template = $self->nametemplate($type)
        or return $basename;

    $template =~ s/%s/$basename/g;
    $template;
}

#------------------

sub field($$)
{   my($self, $type, $field) = @_;
    my $entry = $self->getEntry($type);
    $entry->{$field};
}


sub description     { shift->field(shift, 'description');     }
sub textualnewlines { shift->field(shift, 'textualnewlines'); }
sub x11_bitmap      { shift->field(shift, 'x11-bitmap');      }
sub nametemplate    { shift->field(shift, 'nametemplate');    }

sub getEntry
{   my($self, $origtype, $file) = @_;

    return $self->{_cache}{$origtype}
        if $useCache && exists $self->{_cache}{$origtype};

    my ($fulltype, @params) = split /\s*;\s*/, $origtype;
    my ($type, $subtype)    = split m[/], $fulltype, 2;
    $subtype ||= '';

    my $entry;
    foreach (@{$self->{"$type/$subtype"}}, @{$self->{"$type/*"}})
    {   if(exists $_->{'test'})
        {   # must run test to see if it applies
            my $test = $self->expandPercentMacros($_->{'test'},
        					  $origtype, $file);
            system $test;
            next if $?;
        }
        $entry = { %$_ };  # make copy
        last;
    }
    $self->{_cache}{$origtype} = $entry if $useCache;
    $entry;
}

sub expandPercentMacros
{   my ($self, $text, $type, $file) = @_;
    defined $type or return $text;
    defined $file or $file = "";

    my ($fulltype, @params) = split /\s*;\s*/, $type;
    ($type, my $subtype)    = split m[/], $fulltype, 2;

    my %params;
    foreach (@params)
    {   my($key, $val) = split /\s*=\s*/, $_, 2;
        $params{$key} = $val;
    }
    $text =~ s/\\%/\0/g;        # hide all escaped %'s
    $text =~ s/%t/$fulltype/g;  # expand %t
    $text =~ s/%s/$file/g;      # expand %s
    {   # expand %{field}
        local $^W = 0;  # avoid warnings when expanding %params
        $text =~ s/%\{\s*(.*?)\s*\}/$params{$1}/g;
    }
    $text =~ s/\0/%/g;
    $text;
}

# This following procedures can be useful for debugging purposes

sub dumpEntry
{   my($hash, $prefix) = @_;
    defined $prefix or $prefix = "";
    print "$prefix$_ = $hash->{$_}\n"
        for sort keys %$hash;
}

sub dump
{   my $self = shift;
    foreach (keys %$self)
    {   next if /^_/;
        print "$_\n";
        foreach (@{$self->{$_}})
        {   dumpEntry($_, "\t");
            print "\n";
        }
    }

    if(exists $self->{_cache})
    {   print "Cached types\n";
        print "\t$_\n"
            for keys %{$self->{_cache}};
    }
}

1;
