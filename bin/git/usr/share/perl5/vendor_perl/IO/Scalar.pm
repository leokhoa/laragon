package IO::Scalar;

use strict;

use Carp;
use IO::Handle;

### Stringification, courtesy of B. K. Oxley (binkley):  :-)
use overload '""'   => sub { ${*{$_[0]}->{SR}} };
use overload 'bool' => sub { 1 };      ### have to do this, so object is true!

### The package version, both in 1.23 style *and* usable by MakeMaker:
our $VERSION = '2.113';

### Inheritance:
our @ISA = qw(IO::Handle);

### This stuff should be got rid of ASAP.
require IO::WrapTie and push @ISA, 'IO::WrapTie::Slave' if ($] >= 5.004);

#==============================



=head1 NAME

IO::Scalar - IO:: interface for reading/writing a scalar


=head1 SYNOPSIS

Perform I/O on strings, using the basic OO interface...

    use 5.005;
    use IO::Scalar;
    $data = "My message:\n";

    ### Open a handle on a string, and append to it:
    $SH = new IO::Scalar \$data;
    $SH->print("Hello");
    $SH->print(", world!\nBye now!\n");
    print "The string is now: ", $data, "\n";

    ### Open a handle on a string, read it line-by-line, then close it:
    $SH = new IO::Scalar \$data;
    while (defined($_ = $SH->getline)) {
	print "Got line: $_";
    }
    $SH->close;

    ### Open a handle on a string, and slurp in all the lines:
    $SH = new IO::Scalar \$data;
    print "All lines:\n", $SH->getlines;

    ### Get the current position (either of two ways):
    $pos = $SH->getpos;
    $offset = $SH->tell;

    ### Set the current position (either of two ways):
    $SH->setpos($pos);
    $SH->seek($offset, 0);

    ### Open an anonymous temporary scalar:
    $SH = new IO::Scalar;
    $SH->print("Hi there!");
    print "I printed: ", ${$SH->sref}, "\n";      ### get at value


Don't like OO for your I/O?  No problem.
Thanks to the magic of an invisible tie(), the following now
works out of the box, just as it does with IO::Handle:

    use 5.005;
    use IO::Scalar;
    $data = "My message:\n";

    ### Open a handle on a string, and append to it:
    $SH = new IO::Scalar \$data;
    print $SH "Hello";
    print $SH ", world!\nBye now!\n";
    print "The string is now: ", $data, "\n";

    ### Open a handle on a string, read it line-by-line, then close it:
    $SH = new IO::Scalar \$data;
    while (<$SH>) {
	print "Got line: $_";
    }
    close $SH;

    ### Open a handle on a string, and slurp in all the lines:
    $SH = new IO::Scalar \$data;
    print "All lines:\n", <$SH>;

    ### Get the current position (WARNING: requires 5.6):
    $offset = tell $SH;

    ### Set the current position (WARNING: requires 5.6):
    seek $SH, $offset, 0;

    ### Open an anonymous temporary scalar:
    $SH = new IO::Scalar;
    print $SH "Hi there!";
    print "I printed: ", ${$SH->sref}, "\n";      ### get at value


And for you folks with 1.x code out there: the old tie() style still works,
though this is I<unnecessary and deprecated>:

    use IO::Scalar;

    ### Writing to a scalar...
    my $s;
    tie *OUT, 'IO::Scalar', \$s;
    print OUT "line 1\nline 2\n", "line 3\n";
    print "String is now: $s\n"

    ### Reading and writing an anonymous scalar...
    tie *OUT, 'IO::Scalar';
    print OUT "line 1\nline 2\n", "line 3\n";
    tied(OUT)->seek(0,0);
    while (<OUT>) {
        print "Got line: ", $_;
    }


Stringification works, too!

    my $SH = new IO::Scalar \$data;
    print $SH "Hello, ";
    print $SH "world!";
    print "I printed: $SH\n";



=head1 DESCRIPTION

This class is part of the IO::Stringy distribution;
see L<IO::Stringy> for change log and general information.

The IO::Scalar class implements objects which behave just like
IO::Handle (or FileHandle) objects, except that you may use them
to write to (or read from) scalars.  These handles are
automatically C<tiehandle>d (though please see L<"WARNINGS">
for information relevant to your Perl version).


Basically, this:

    my $s;
    $SH = new IO::Scalar \$s;
    $SH->print("Hel", "lo, ");         ### OO style
    $SH->print("world!\n");            ### ditto

Or this:

    my $s;
    $SH = tie *OUT, 'IO::Scalar', \$s;
    print OUT "Hel", "lo, ";           ### non-OO style
    print OUT "world!\n";              ### ditto

Causes $s to be set to:

    "Hello, world!\n"


=head1 PUBLIC INTERFACE

=head2 Construction

=over 4

=cut

#------------------------------

=item new [ARGS...]

I<Class method.>
Return a new, unattached scalar handle.
If any arguments are given, they're sent to open().

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless \do { local *FH }, $class;
    tie *$self, $class, $self;
    $self->open(@_);   ### open on anonymous by default
    $self;
}
sub DESTROY {
    shift->close;
}

#------------------------------

=item open [SCALARREF]

I<Instance method.>
Open the scalar handle on a new scalar, pointed to by SCALARREF.
If no SCALARREF is given, a "private" scalar is created to hold
the file data.

Returns the self object on success, undefined on error.

=cut

sub open {
    my ($self, $sref) = @_;

    ### Sanity:
    defined($sref) or do {my $s = ''; $sref = \$s};
    (ref($sref) eq "SCALAR") or croak "open() needs a ref to a scalar";

    ### Setup:
    *$self->{Pos} = 0;          ### seek position
    *$self->{SR}  = $sref;      ### scalar reference
    $self;
}

#------------------------------

=item opened

I<Instance method.>
Is the scalar handle opened on something?

=cut

sub opened {
    *{shift()}->{SR};
}

#------------------------------

=item close

I<Instance method.>
Disassociate the scalar handle from its underlying scalar.
Done automatically on destroy.

=cut

sub close {
    my $self = shift;
    %{*$self} = ();
    1;
}

=back

=cut



#==============================

=head2 Input and output

=over 4

=cut


#------------------------------

=item flush

I<Instance method.>
No-op, provided for OO compatibility.

=cut

sub flush { "0 but true" }

#------------------------------

=item fileno

I<Instance method.>
No-op, returns undef

=cut

sub fileno { }

#------------------------------

=item getc

I<Instance method.>
Return the next character, or undef if none remain.

=cut

sub getc {
    my $self = shift;

    ### Return undef right away if at EOF; else, move pos forward:
    return undef if $self->eof;
    substr(${*$self->{SR}}, *$self->{Pos}++, 1);
}

#------------------------------

=item getline

I<Instance method.>
Return the next line, or undef on end of string.
Can safely be called in an array context.
Currently, lines are delimited by "\n".

=cut

sub getline {
    my $self = shift;

    ### Return undef right away if at EOF:
    return undef if $self->eof;

    ### Get next line:
    my $sr = *$self->{SR};
    my $i  = *$self->{Pos};	        ### Start matching at this point.

    ### Minimal impact implementation!
    ### We do the fast thing (no regexps) if using the
    ### classic input record separator.

    ### Case 1: $/ is undef: slurp all...
    if    (!defined($/)) {
	*$self->{Pos} = length $$sr;
        return substr($$sr, $i);
    }

    ### Case 2: $/ is "\n": zoom zoom zoom...
    elsif ($/ eq "\012") {

        ### Seek ahead for "\n"... yes, this really is faster than regexps.
        my $len = length($$sr);
        for (; $i < $len; ++$i) {
           last if ord (substr ($$sr, $i, 1)) == 10;
        }

        ### Extract the line:
        my $line;
        if ($i < $len) {                ### We found a "\n":
            $line = substr ($$sr, *$self->{Pos}, $i - *$self->{Pos} + 1);
            *$self->{Pos} = $i+1;            ### Remember where we finished up.
        }
        else {                          ### No "\n"; slurp the remainder:
            $line = substr ($$sr, *$self->{Pos}, $i - *$self->{Pos});
            *$self->{Pos} = $len;
        }
        return $line;
    }

    ### Case 3: $/ is ref to int. Do fixed-size records.
    ###        (Thanks to Dominique Quatravaux.)
    elsif (ref($/)) {
        my $len = length($$sr);
		my $i = ${$/} + 0;
		my $line = substr ($$sr, *$self->{Pos}, $i);
		*$self->{Pos} += $i;
        *$self->{Pos} = $len if (*$self->{Pos} > $len);
		return $line;
    }

    ### Case 4: $/ is either "" (paragraphs) or something weird...
    ###         This is Graham's general-purpose stuff, which might be
    ###         a tad slower than Case 2 for typical data, because
    ###         of the regexps.
    else {
        pos($$sr) = $i;

	### If in paragraph mode, skip leading lines (and update i!):
        length($/) or
	    (($$sr =~ m/\G\n*/g) and ($i = pos($$sr)));

        ### If we see the separator in the buffer ahead...
        if (length($/)
	    ?  $$sr =~ m,\Q$/\E,g          ###   (ordinary sep) TBD: precomp!
            :  $$sr =~ m,\n\n,g            ###   (a paragraph)
            ) {
            *$self->{Pos} = pos $$sr;
            return substr($$sr, $i, *$self->{Pos}-$i);
        }
        ### Else if no separator remains, just slurp the rest:
        else {
            *$self->{Pos} = length $$sr;
            return substr($$sr, $i);
        }
    }
}

#------------------------------

=item getlines

I<Instance method.>
Get all remaining lines.
It will croak() if accidentally called in a scalar context.

=cut

sub getlines {
    my $self = shift;
    wantarray or croak("can't call getlines in scalar context!");
    my ($line, @lines);
    push @lines, $line while (defined($line = $self->getline));
    @lines;
}

#------------------------------

=item print ARGS...

I<Instance method.>
Print ARGS to the underlying scalar.

B<Warning:> this continues to always cause a seek to the end
of the string, but if you perform seek()s and tell()s, it is
still safer to explicitly seek-to-end before subsequent print()s.

=cut

sub print {
    my $self = shift;
    *$self->{Pos} = length(${*$self->{SR}} .= join('', @_) . (defined($\) ? $\ : ""));
    1;
}
sub _unsafe_print {
    my $self = shift;
    my $append = join('', @_) . $\;
    ${*$self->{SR}} .= $append;
    *$self->{Pos}   += length($append);
    1;
}
sub _old_print {
    my $self = shift;
    ${*$self->{SR}} .= join('', @_) . $\;
    *$self->{Pos} = length(${*$self->{SR}});
    1;
}


#------------------------------

=item read BUF, NBYTES, [OFFSET]

I<Instance method.>
Read some bytes from the scalar.
Returns the number of bytes actually read, 0 on end-of-file, undef on error.

=cut

sub read {
    my $self = $_[0];
    my $n    = $_[2];
    my $off  = $_[3] || 0;

    my $read = substr(${*$self->{SR}}, *$self->{Pos}, $n);
    $n = length($read);
    *$self->{Pos} += $n;
    ($off ? substr($_[1], $off) : $_[1]) = $read;
    return $n;
}

#------------------------------

=item write BUF, NBYTES, [OFFSET]

I<Instance method.>
Write some bytes to the scalar.

=cut

sub write {
    my $self = $_[0];
    my $n    = $_[2];
    my $off  = $_[3] || 0;

    my $data = substr($_[1], $off, $n);
    $n = length($data);
    $self->print($data);
    return $n;
}

#------------------------------

=item sysread BUF, LEN, [OFFSET]

I<Instance method.>
Read some bytes from the scalar.
Returns the number of bytes actually read, 0 on end-of-file, undef on error.

=cut

sub sysread {
  my $self = shift;
  $self->read(@_);
}

#------------------------------

=item syswrite BUF, NBYTES, [OFFSET]

I<Instance method.>
Write some bytes to the scalar.

=cut

sub syswrite {
  my $self = shift;
  $self->write(@_);
}

=back

=cut


#==============================

=head2 Seeking/telling and other attributes

=over 4

=cut


#------------------------------

=item autoflush

I<Instance method.>
No-op, provided for OO compatibility.

=cut

sub autoflush {}

#------------------------------

=item binmode

I<Instance method.>
No-op, provided for OO compatibility.

=cut

sub binmode {}

#------------------------------

=item clearerr

I<Instance method.>  Clear the error and EOF flags.  A no-op.

=cut

sub clearerr { 1 }

#------------------------------

=item eof

I<Instance method.>  Are we at end of file?

=cut

sub eof {
    my $self = shift;
    (*$self->{Pos} >= length(${*$self->{SR}}));
}

#------------------------------

=item seek OFFSET, WHENCE

I<Instance method.>  Seek to a given position in the stream.

=cut

sub seek {
    my ($self, $pos, $whence) = @_;
    my $eofpos = length(${*$self->{SR}});

    ### Seek:
    if    ($whence == 0) { *$self->{Pos} = $pos }             ### SEEK_SET
    elsif ($whence == 1) { *$self->{Pos} += $pos }            ### SEEK_CUR
    elsif ($whence == 2) { *$self->{Pos} = $eofpos + $pos}    ### SEEK_END
    else                 { croak "bad seek whence ($whence)" }

    ### Fixup:
    if (*$self->{Pos} < 0)       { *$self->{Pos} = 0 }
    if (*$self->{Pos} > $eofpos) { *$self->{Pos} = $eofpos }
    return 1;
}

#------------------------------

=item sysseek OFFSET, WHENCE

I<Instance method.> Identical to C<seek OFFSET, WHENCE>, I<q.v.>

=cut

sub sysseek {
    my $self = shift;
    $self->seek (@_);
}

#------------------------------

=item tell

I<Instance method.>
Return the current position in the stream, as a numeric offset.

=cut

sub tell { *{shift()}->{Pos} }

#------------------------------
#
# use_RS [YESNO]
#
# I<Instance method.>
# Obey the current setting of $/, like IO::Handle does?
# Default is false in 1.x, but cold-welded true in 2.x and later.
#
sub use_RS {
    my ($self, $yesno) = @_;
    carp "use_RS is deprecated and ignored; \$/ is always consulted\n";
 }

#------------------------------

=item setpos POS

I<Instance method.>
Set the current position, using the opaque value returned by C<getpos()>.

=cut

sub setpos { shift->seek($_[0],0) }

#------------------------------

=item getpos

I<Instance method.>
Return the current position in the string, as an opaque object.

=cut

*getpos = \&tell;


#------------------------------

=item sref

I<Instance method.>
Return a reference to the underlying scalar.

=cut

sub sref { *{shift()}->{SR} }


#------------------------------
# Tied handle methods...
#------------------------------

# Conventional tiehandle interface:
sub TIEHANDLE {
    ((defined($_[1]) && UNIVERSAL::isa($_[1], "IO::Scalar"))
     ? $_[1]
     : shift->new(@_));
}
sub GETC      { shift->getc(@_) }
sub PRINT     { shift->print(@_) }
sub PRINTF    { shift->print(sprintf(shift, @_)) }
sub READ      { shift->read(@_) }
sub READLINE  { wantarray ? shift->getlines(@_) : shift->getline(@_) }
sub WRITE     { shift->write(@_); }
sub CLOSE     { shift->close(@_); }
sub SEEK      { shift->seek(@_); }
sub TELL      { shift->tell(@_); }
sub EOF       { shift->eof(@_); }
sub BINMODE   { 1; }

#------------------------------------------------------------

1;

__END__



=back

=cut


=head1 AUTHOR

Eryq (F<eryq@zeegee.com>).
President, ZeeGee Software Inc (F<http://www.zeegee.com>).

=head1 CONTRIBUTORS

Dianne Skoll (F<dfs@roaringpenguin.com>).

=head1 COPYRIGHT & LICENSE

Copyright (c) 1997 Erik (Eryq) Dorfman, ZeeGee Software, Inc. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
