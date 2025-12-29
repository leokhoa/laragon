# Copyrights 1995-2024 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Header;{
our $VERSION = '2.22';
}


use strict;
use Carp;

my $MAIL_FROM = 'KEEP';
my %HDR_LENGTHS = ();

our $FIELD_NAME = '[^\x00-\x1f\x7f-\xff :]+:';


##
## Private functions
##

sub _error { warn @_; () }

# tidy up internal hash table and list

sub _tidy_header
{   my $self    = shift;
    my $deleted = 0;

    for(my $i = 0 ; $i < @{$self->{mail_hdr_list}}; $i++)
    {   next if defined $self->{mail_hdr_list}[$i];

        splice @{$self->{mail_hdr_list}}, $i, 1;
        $deleted++;
        $i--;
    }

    if($deleted)
    {   local $_;
        my @del;

        while(my ($key,$ref) = each %{$self->{mail_hdr_hash}} )
        {   push @del, $key
	       unless @$ref = grep { ref $_ && defined $$_ } @$ref;
        }

        delete $self->{'mail_hdr_hash'}{$_} for @del;
    }
}

# fold the line to the given length

my %STRUCTURE = map { (lc $_ => undef) }
  qw{ To Cc Bcc From Date Reply-To Sender
      Resent-Date Resent-From Resent-Sender Resent-To Return-Path
      list-help list-post list-unsubscribe Mailing-List
      Received References Message-ID In-Reply-To
      Content-Length Content-Type Content-Disposition
      Delivered-To
      Lines
      MIME-Version
      Precedence
      Status
    };

sub _fold_line
{   my($ln,$maxlen) = @_;

    $maxlen = 20
       if $maxlen < 20;

    my $max = int($maxlen - 5);         # 4 for leading spcs + 1 for [\,\;]
    my $min = int($maxlen * 4 / 5) - 4;

    $_[0] =~ s/[\r\n]+//og;        # Remove new-lines
    $_[0] =~ s/\s*\Z/\n/so;        # End line with an EOLN

    return if $_[0] =~ /^From\s/io;

    if(length($_[0]) > $maxlen)
    {   if($_[0] =~ /^([-\w]+)/ && exists $STRUCTURE{ lc $1 } )
        {   #Split the line up
            # first bias towards splitting at a , or a ; >4/5 along the line
            # next split a whitespace
            # else we are looking at a single word and probably don't want to split
            my $x = "";
            $x .= "$1\n " while $_[0] =~
                s/^\s*
                   ( [^"]{$min,$max} [,;]
                   | [^"]{1,$max}    [,;\s]
                   | [^\s"]*(?:"[^"]*"[ \t]?[^\s"]*)+\s
                   ) //x;

            $x .= $_[0];
            $_[0] = $x;
            $_[0] =~ s/(\A\s+|[\t ]+\Z)//sog;
            $_[0] =~ s/\s+\n/\n/sog;
        }
        else
        {   $_[0] =~ s/(.{$min,$max})(\s)/$1\n$2/g;
            $_[0] =~ s/\s*$/\n/s;
        }
    }

    $_[0] =~ s/\A(\S+)\n\s*(?=\S)/$1 /so; 
}

# Tags are case-insensitive, but there is a (slightly) preferred construction
# being all characters are lowercase except the first of each word. Also
# if the word is an `acronym' then all characters are uppercase. We decide
# a word is an acronym if it does not contain a vowel.
# In general, this change of capitalization is a bad idea, but it is in
# the code for ages, and therefore probably crucial for existing
# applications.

sub _tag_case
{   my $tag = shift;
    $tag =~ s/\:$//;
    join '-'
      , map { /^[b-df-hj-np-tv-z]+$|^(?:MIME|SWE|SOAP|LDAP|ID)$/i
              ? uc($_) : ucfirst(lc($_))
            } split m/\-/, $tag, -1;
}

# format a complete line
#  ensure line starts with the given tag
#  ensure tag is correct case
#  change the 'From ' tag as required
#  fold the line

sub _fmt_line
{   my ($self, $tag, $line, $modify) = @_;
    $modify ||= $self->{mail_hdr_modify};
    my $ctag = undef;

    ($tag) = $line =~ /^($FIELD_NAME|From )/oi
        unless defined $tag;

    if(defined $tag && $tag =~ /^From /io && $self->{mail_hdr_mail_from} ne 'KEEP')
    {   if($self->{mail_hdr_mail_from} eq 'COERCE')
        {   $line =~ s/^From /Mail-From: /o;
            $tag = "Mail-From:";
        }
        elsif($self->{mail_hdr_mail_from} eq 'IGNORE')
        {   return ();
        }
        elsif($self->{mail_hdr_mail_from} eq 'ERROR')
        {    return _error "unadorned 'From ' ignored: <$line>";
        }
    }

    if(defined $tag)
    {   $tag  = _tag_case($ctag = $tag);
        $ctag = $tag if $modify;
        $ctag =~ s/([^ :])$/$1:/o if defined $ctag;
    }

    defined $ctag && $ctag =~ /^($FIELD_NAME|From )/oi
        or croak "Bad RFC822 field name '$tag'\n";

    # Ensure the line starts with tag
    if(defined $ctag && ($modify || $line !~ /^\Q$ctag\E/i))
    {   (my $xtag = $ctag) =~ s/\s*\Z//o;
        $line =~ s/^(\Q$ctag\E)?\s*/$xtag /i;
    }

    my $maxlen = $self->{mail_hdr_lengths}{$tag}
              || $HDR_LENGTHS{$tag}
              || $self->fold_length;

    if ($modify && defined $maxlen)
    {   # folding will fix bad header continuations for us
        _fold_line $line, $maxlen;
    }
    elsif($line =~ /\r?\n\S/)
    {   return _error "Bad header continuation, skipping '$tag': ",
                      "no space after newline in '$line'\n";
    }


    $line =~ s/\n*$/\n/so;
    ($tag, $line);
}

sub _insert
{   my ($self, $tag, $line, $where) = @_;

    if($where < 0)
    {   $where = @{$self->{mail_hdr_list}} + $where + 1;
        $where = 0 if $where < 0;
    }
    elsif($where >= @{$self->{mail_hdr_list}})
    {   $where = @{$self->{mail_hdr_list}};
    }

    my $atend = $where == @{$self->{mail_hdr_list}};
    splice @{$self->{mail_hdr_list}}, $where, 0, $line;

    $self->{mail_hdr_hash}{$tag} ||= [];
    my $ref = \${$self->{mail_hdr_list}}[$where];

    my $def = $self->{mail_hdr_hash}{$tag};
    if($def && $where)
    {   if($atend) { push @$def, $ref }
        else
        {   my $i = 0;
            foreach my $ln (@{$self->{mail_hdr_list}})
            {   my $r = \$ln;
                last if $r == $ref;
                $i++ if $r == $def->[$i];
            }
            splice @$def, $i, 0, $ref;
        }
    }
    else
    {    unshift @$def, $ref;
    }
}

#------------

sub new
{   my $call  = shift;
    my $class = ref($call) || $call;
    my $arg   = @_ % 2 ? shift : undef;
    my %opt   = @_;

    $opt{Modify} = delete $opt{Reformat}
        unless exists $opt{Modify};

    my $self = bless
      { mail_hdr_list     => []
      , mail_hdr_hash     => {}
      , mail_hdr_modify   => (delete $opt{Modify} || 0)
      , mail_hdr_foldlen  => 79
      , mail_hdr_lengths  => {}
      }, $class;

    $self->mail_from( uc($opt{MailFrom} || $MAIL_FROM) );

    $self->fold_length($opt{FoldLength})
        if exists $opt{FoldLength};

    if(!ref $arg)               {}
    elsif(ref($arg) eq 'ARRAY') { $self->extract( [ @$arg ] ) }
    elsif(defined fileno($arg)) { $self->read($arg) }

    $self;
}


sub dup
{   my $self = shift;
    my $dup  = ref($self)->new;

    %$dup    = %$self;
    $dup->empty;      # rebuild tables

    $dup->{mail_hdr_list} = [ @{$self->{mail_hdr_list}} ];

    foreach my $ln ( @{$dup->{mail_hdr_list}} )
    {    my $tag = _tag_case +($ln =~ /^($FIELD_NAME|From )/oi)[0];
         push @{$dup->{mail_hdr_hash}{$tag}}, \$ln;
    }

    $dup;
}

#------------

sub extract
{   my ($self, $lines) = @_;
    $self->empty;

    while(@$lines)
    {   my $line = shift @$lines;
        last if $line =~ /^\r?$/;

        $line    =~ /^($FIELD_NAME|From )/o or next;
        my $tag  = $1;

        $line   .= shift @$lines
            while @$lines && $lines->[0] =~ /^[ \t]+/;

        ($tag, $line) = _fmt_line $self, $tag, $line;

        _insert $self, $tag, $line, -1
            if defined $line;
    }

    $self;
}


sub read
{   my ($self, $fd) = @_;
    $self->empty;

    my ($ln, $tag, $line);
    while(1)
    {   $ln = <$fd>;

        if(defined $ln && defined $line && $ln =~ /^[ \t]+/)
        {   $line .= $ln;  # folded line
            next;
        }

        if(defined $line)
        {   ($tag, $line) = _fmt_line $self, $tag, $line;
            _insert $self, $tag, $line, -1
	        if defined $line;
            ($tag, $line) = ();
        }

        last if !defined $ln || $ln =~ m/^\r?$/;

        $ln =~ /^($FIELD_NAME|From )/o or next;
        ($tag, $line) = ($1, $ln);
    }

    $self;
}


sub empty
{   my $self = shift;
    $self->{mail_hdr_list} = [];
    $self->{mail_hdr_hash} = {};
    $self;
}


sub header
{   my $self = shift;

    $self->extract(@_)
	if @_;

    $self->fold
        if $self->{mail_hdr_modify};

    [ @{$self->{mail_hdr_list}} ];
}


sub header_hashref
{   my ($self, $hashref) = @_;

    while(my ($key, $value) = each %$hashref)
    {   $self->add($key, $_) for ref $value ? @$value : $value;
    }

    $self->fold
        if $self->{mail_hdr_modify};

    defined wantarray  # MO, added minimal optimization
        or return;

    +{ map { ($_ => [$self->get($_)] ) }   # MO: Eh?
           keys %{$self->{mail_hdr_hash}}
     }; 
}

#------------

sub modify
{   my $self = shift;
    my $old  = $self->{mail_hdr_modify};

    $self->{mail_hdr_modify} = 0 + shift
	if @_;

    $old;
}


sub mail_from
{   my $thing  = shift;
    my $choice = uc shift;

    $choice =~ /^(IGNORE|ERROR|COERCE|KEEP)$/ 
	or die "bad Mail-From choice: '$choice'";

    if(ref $thing) { $thing->{mail_hdr_mail_from} = $choice }
    else           { $MAIL_FROM = $choice }

    $thing;
}


sub fold_length
{   my $thing = shift;
    my $old;

    if(@_ == 2)
    {   my $tag = _tag_case shift;
        my $len = shift;

        my $hash = ref $thing ? $thing->{mail_hdr_lengths} : \%HDR_LENGTHS;
        $old     = $hash->{$tag};
        $hash->{$tag} = $len > 20 ? $len : 20;
    }
    else
    {   my $self = $thing;
        my $len  = shift;
        $old = $self->{mail_hdr_foldlen};

        if(defined $len)
        {    $self->{mail_hdr_foldlen} = $len > 20 ? $len : 20;
             $self->fold if $self->{mail_hdr_modify};
        }
    }

    $old;
}

#------------

sub fold
{   my ($self, $maxlen) = @_;

    while(my ($tag, $list) = each %{$self->{mail_hdr_hash}})
    {   my $len = $maxlen
             || $self->{mail_hdr_lengths}{$tag}
             || $HDR_LENGTHS{$tag}
             || $self->fold_length;

        foreach my $ln (@$list)
        {    _fold_line $$ln, $len
                 if defined $ln;
        }
    }

    $self;
}


sub unfold
{   my $self = shift;

    if(@_)
    {   my $tag  = _tag_case shift;
        my $list = $self->{mail_hdr_hash}{$tag}
            or return $self;

        foreach my $ln (@$list)
        {   $$ln =~ s/\r?\n\s+/ /sog
                if defined $ln && defined $$ln;
        }

        return $self;
    }

    while( my ($tag, $list) = each %{$self->{mail_hdr_hash}})
    {   foreach my $ln (@$list)
        {   $$ln =~ s/\r?\n\s+/ /sog
	        if defined $ln && defined $$ln;
        }
    }

    $self;
}


sub add
{   my ($self, $tag, $text, $where) = @_;
    ($tag, my $line) = _fmt_line $self, $tag, $text;

    defined $tag && defined $line
        or return undef;

    defined $where
        or $where = -1;

    _insert $self, $tag, $line, $where;

    $line =~ /^\S+\s(.*)/os;
    $1;
}


sub replace
{   my $self = shift;
    my $idx  = @_ % 2 ? pop @_ : 0;

    my ($tag, $line);
  TAG:
    while(@_)
    {   ($tag,$line) = _fmt_line $self, splice(@_,0,2);

        defined $tag && defined $line
            or return undef;

        my $field = $self->{mail_hdr_hash}{$tag};
        if($field && defined $field->[$idx])
             { ${$field->[$idx]} = $line }
        else { _insert $self, $tag, $line, -1 }
    }

    $line =~ /^\S+\s*(.*)/os;
    $1;
}


sub combine
{   my $self = shift;
    my $tag  = _tag_case shift;
    my $with = shift || ' ';

    $tag =~ /^From /io && $self->{mail_hdr_mail_from} ne 'KEEP'
        and return _error "unadorned 'From ' ignored";

    my $def = $self->{mail_hdr_hash}{$tag}
        or return undef;

    return $def->[0]
        if @$def <= 1;

    my @lines = $self->get($tag);
    chomp @lines;

    my $line = (_fmt_line $self, $tag, join($with,@lines), 1)[1];

    $self->{mail_hdr_hash}{$tag} = [ \$line ];
    $line;
}


sub get
{   my $self = shift;
    my $tag = _tag_case shift;
    my $idx = shift;

    my $def = $self->{mail_hdr_hash}{$tag}
        or return ();

    my $l = length $tag;
    $l   += 1 if $tag !~ / $/o;

    if(defined $idx || !wantarray)
    {    $idx ||= 0;
         defined $def->[$idx] or return undef;
         my $val = ${$def->[$idx]};
         defined $val or return undef;

	 $val = substr $val, $l;
	 $val =~ s/^\s+//;
         return $val;
    }

    map { my $tmp = substr $$_,$l; $tmp =~ s/^\s+//; $tmp } @$def;
}



sub count
{   my $self = shift;
    my $tag  = _tag_case shift;
    my $def  = $self->{mail_hdr_hash}{$tag};
    defined $def ? scalar(@$def) : 0;
}



sub delete
{   my $self = shift;
    my $tag  = _tag_case shift;
    my $idx  = shift;
    my @val;

    if(my $def = $self->{mail_hdr_hash}{$tag})
    {   my $l = length $tag;
        $l   += 2 if $tag !~ / $/;

        if(defined $idx)
        {   if(defined $def->[$idx])
            {   push @val, substr ${$def->[$idx]}, $l;
                undef ${$def->[$idx]};
            }
        }
        else
        {   @val = map {my $x = substr $$_,$l; undef $$_; $x } @$def;
        }

        _tidy_header($self);
    }

    @val;
}



sub print
{   my $self = shift;
    my $fd   = shift || \*STDOUT;

    foreach my $ln (@{$self->{mail_hdr_list}})
    {   defined $ln or next;
        print $fd $ln or return 0;
    }

    1;
}


sub as_string { join '', grep {defined} @{shift->{mail_hdr_list}} }


sub tags { keys %{shift->{mail_hdr_hash}} }


sub cleanup
{   my $self = shift;
    my $deleted = 0;

    foreach my $key (@_ ? @_ : keys %{$self->{mail_hdr_hash}})
    {   my $fields = $self->{mail_hdr_hash}{$key};
        foreach my $field (@$fields)
        {   next if $$field =~ /^\S+\s+\S/s;
            undef $$field;
            $deleted++;
        }
    }

    _tidy_header $self
        if $deleted;

    $self;  
}

1;
