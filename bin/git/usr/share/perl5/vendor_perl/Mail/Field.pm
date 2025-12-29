# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Field;{
our $VERSION = '2.22';
}


use strict;

use Carp;
use Mail::Field::Generic;


sub _header_pkg_name
{   my $header = lc shift;
    $header    =~ s/((\b|_)\w)/\U$1/g;

    if(length($header) > 8)
    {   my @header = split /[-_]+/, $header;
        my $chars  = int((7 + @header) / @header) || 1;
        $header    = substr join('', map {substr $_,0,$chars} @header), 0, 8;
    }
    else
    {   $header =~ s/[-_]+//g;
    }

    'Mail::Field::' . $header;
}

sub _require_dir
{   my($class, $dir, $dir_sep) = @_;

    local *DIR;
    opendir DIR, $dir
        or return;

    my @inc;
    foreach my $f (readdir DIR)
    {   $f =~ /^([\w\-]+)/ or next;
        my $p = $1;
        my $n = "$dir$dir_sep$p";

        if(-d $n )
        {   _require_dir("${class}::$f", $n, $dir_sep);
        }
        else
        {   $p =~ s/-/_/go;
            eval "require ${class}::$p";

            # added next warning in 2.14, may be ignored for ancient code
            warn $@ if $@;
        }
    }
    closedir DIR;
}

sub import
{   my $class = shift;

    if(@_)
    {   local $_;
        eval "require " . _header_pkg_name($_) || die $@
            for @_;
        return;
    }

    my ($dir, $dir_sep);
    foreach my $f (grep defined $INC{$_}, keys %INC)
    {   next if $f !~ /^Mail(\W)Field\W/i;
        $dir_sep = $1;
# $dir = ($INC{$f} =~ /(.*Mail\W+Field)/i)[0] . $dir_sep;
        ($dir = $INC{$f}) =~ s/(Mail\W+Field).*/$1$dir_sep/;
        last;
    }

    _require_dir('Mail::Field', $dir, $dir_sep);
}

# register a header class, this creates a new method in Mail::Field
# which will call new on that class
sub register
{   my $thing  = shift;
    my $method = lc shift;
    my $class  = shift || ref($thing) || $thing;

    $method    =~ tr/-/_/;
    $class     = _header_pkg_name $method
	if $class eq "Mail::Field";

    croak "Re-register of $method"
	if Mail::Field->can($method);

    no strict 'refs';
    *{$method} = sub {
	shift;
	$class->can('stringify') or eval "require $class" or die $@;
	$class->_build(@_);
    };
}

# the *real* constructor
# if called with one argument then the `parse' method will be called
# otherwise the `create' method is called

sub _build
{   my $self = bless {}, shift;
    @_==1 ? $self->parse(@_) : $self->create(@_);
}

#-------------

sub new
{   my $class = shift;
    my $field = lc shift;
    $field =~ tr/-/_/;
    $class->$field(@_);
}


sub combine {confess "Combine not implemented" }

our $AUTOLOAD;
sub AUTOLOAD
{   my $method = $AUTOLOAD;
    $method    =~ s/.*:://;

    $method    =~ /^[^A-Z\x00-\x1f\x80-\xff :]+$/
        or croak "Undefined subroutine &$AUTOLOAD called";

    my $class = _header_pkg_name $method;

    unless(eval "require $class")
    {   my $tag = $method;
        $tag    =~ s/_/-/g;
        $tag    = join '-',
            map { /^[b-df-hj-np-tv-z]+$|^MIME$/i ? uc($_) : ucfirst(lc $_) }
                split /\-/, $tag;

        no strict;
        @{"${class}::ISA"} = qw(Mail::Field::Generic);
        *{"${class}::tag"} = sub { $tag };
    }

    Mail::Field->can($method)
        or $class->register($method);

    goto &$AUTOLOAD;
}


# Of course, the functionality should have been in the Mail::Header class
sub extract
{   my ($class, $tag, $head) = (shift, shift, shift);

    my $method = lc $tag;
    $method    =~ tr/-/_/;

    if(@_==0 && wantarray)
    {   my @ret;
        my $text;  # need real copy!
        foreach $text ($head->get($tag))
        {   chomp $text;
            push @ret, $class->$method($text);
        }
        return @ret;
    }

    my $idx  = shift || 0;
    my $text = $head->get($tag,$idx)
        or return undef;

    chomp $text;
    $class->$method($text);
}

#-------------

# before 2.00, this method could be called as class method, however
# not all extensions supported that.
sub create
{   my ($self, %arg) = @_;
    %$self = ();
    $self->set(\%arg);
}


# before 2.00, this method could be called as class method, however
# not all extensions supported that.
sub parse
{   my $class = ref shift;
    confess "parse() not implemented";
}

#-------------

sub stringify { confess "stringify() not implemented" } 


sub tag
{   my $thing = shift;
    my $tag   = ref($thing) || $thing;
    $tag =~ s/.*:://;
    $tag =~ s/_/-/g;

    join '-',
        map { /^[b-df-hj-np-tv-z]+$|^MIME$/i ? uc($_) : ucfirst(lc $_) }
            split /\-/, $tag;
}


sub set(@) { confess "set() not implemented" }

# prevent the calling of AUTOLOAD for DESTROY :-)
sub DESTROY {}

#-------------

sub text
{   my $self = shift;
    @_ ? $self->parse(@_) : $self->stringify;
}

#-------------

1;
