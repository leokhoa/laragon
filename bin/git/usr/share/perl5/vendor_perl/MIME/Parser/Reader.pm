package MIME::Parser::Reader;

=head1 NAME

MIME::Parser::Reader - a line-oriented reader for a MIME::Parser


=head1 SYNOPSIS

This module is used internally by MIME::Parser; you probably
don't need to be looking at it at all.  But just in case...

    ### Create a top-level reader, where chunks end at EOF:
    $rdr = MIME::Parser::Reader->new();

    ### Spawn a child reader, where chunks also end at a boundary:
    $subrdr = $rdr->spawn->add_boundary($bound);

    ### Spawn a child reader, where chunks also end at a given string:
    $subrdr = $rdr->spawn->add_terminator($string);

    ### Read until boundary or terminator:
    $subrdr->read_chunk($in, $out);


=head1 DESCRIPTION

A line-oriented reader which can deal with virtual end-of-stream
defined by a collection of boundaries.

B<Warning:> this is a private class solely for use by MIME::Parser.
This class has no official public interface

=cut

use strict;

### All possible end-of-line sequences.
### Note that "" is included because last line of stream may have no newline!
my @EOLs = ("", "\r", "\n", "\r\n", "\n\r");

### Long line:
my $LONGLINE = ' ' x 1000;


#------------------------------
#
# new
#
# I<Class method.>
# Construct an empty (top-level) reader.
#
sub new {
    my ($class) = @_;
    my $eos;
    return bless {
	Bounds => [],
	BH     => {},
	TH     => {},
	EOS    => \$eos,
    }, $class;
}

#------------------------------
#
# spawn
#
# I<Instance method.>
# Return a reader which is mostly a duplicate, except that the EOS
# accumulator is shared.
#
sub spawn {
    my $self = shift;
    my $dup = bless {}, ref($self);
    $dup->{Bounds} = [ @{$self->{Bounds}} ];  ### deep copy
    $dup->{BH}     = { %{$self->{BH}} };      ### deep copy
    $dup->{TH}     = { %{$self->{TH}} };      ### deep copy
    $dup->{EOS}    = $self->{EOS};            ### shallow copy; same ref!
    $dup;
}

#------------------------------
#
# add_boundary BOUND
#
# I<Instance method.>
# Let BOUND be the new innermost boundary.  Returns self.
#
sub add_boundary {
    my ($self, $bound) = @_;
    unshift @{$self->{Bounds}}, $bound;   ### now at index 0
    $self->{BH}{"--$bound"}   = "DELIM $bound";
    $self->{BH}{"--$bound--"} = "CLOSE $bound";
    $self;
}

#------------------------------
#
# add_terminator LINE
#
# I<Instance method.>
# Let LINE be another terminator.  Returns self.
#
sub add_terminator {
    my ($self, $line) = @_;
    foreach (@EOLs) {
	$self->{TH}{"$line$_"} = "DONE $line";
    }
    $self;
}

#------------------------------
#
# has_bounds
#
# I<Instance method.>
# Are there boundaries to contend with?
#
sub has_bounds {
    scalar(@{shift->{Bounds}});
}

#------------------------------
#
# depth
#
# I<Instance method.>
# How many levels are there?
#
sub depth {
    scalar(@{shift->{Bounds}});
}

#------------------------------
#
# eos [EOS]
#
# I<Instance method.>
# Return the last end-of-stream token seen.
# See read_chunk() for what these might be.
#
sub eos {
    my $self = shift;
    ${$self->{EOS}} = $_[0] if @_;
    ${$self->{EOS}};
}

#------------------------------
#
# eos_type [EOSTOKEN]
#
# I<Instance method.>
# Return the high-level type of the given token (defaults to our token).
#
#    DELIM       saw an innermost boundary like --xyz
#    CLOSE       saw an innermost boundary like --xyz--
#    DONE        callback returned false
#    EOF         end of file
#    EXT         saw boundary of some higher-level
#
sub eos_type {
    my ($self, $eos) = @_;
    $eos = $self->eos if (@_ == 1);

    if    ($eos =~ /^(DONE|EOF)/) {
	return $1;
    }
    elsif ($eos =~ /^(DELIM|CLOSE) (.*)$/) {
	return (($2 eq $self->{Bounds}[0]) ? $1 : 'EXT');
    }
    else {
	die("internal error: unable to classify boundary token ($eos)");
    }
}

#------------------------------
#
# native_handle HANDLE
#
# I<Function.>
# Can we do native i/o on HANDLE?  If true, returns the handle
# that will respond to native I/O calls; else, returns undef.
#
sub native_handle {
    my $fh = shift;
    return $fh if ($fh->isa('IO::File') || $fh->isa('IO::Handle'));
    return $fh if (ref $fh eq 'GLOB');
    undef;
}

#------------------------------
#
# read_chunk INHANDLE, OUTHANDLE
#
# I<Instance method.>
# Get lines until end-of-stream.
# Returns the terminating-condition token:
#
#    DELIM xyz   saw boundary line "--xyz"
#    CLOSE xyz   saw boundary line "--xyz--"
#    DONE xyz    saw terminator line "xyz"
#    EOF         end of file

# Parse up to (and including) the boundary, and dump output.
# Follows the RFC 2046 specification, that the CRLF immediately preceding
# the boundary is part of the boundary, NOT part of the input!
#
# NOTE: while parsing bodies, we take care to remember the EXACT end-of-line
# sequence.  This is because we *may* be handling 'binary' encoded data, and
# in that case we can't just massage \r\n into \n!  Don't worry... if the
# data is styled as '7bit' or '8bit', the "decoder" will massage the CRLF
# for us.  For now, we're just trying to chop up the data stream.

# NBK - Oct 12, 1999
# The CRLF at the end of the current line is considered part
# of the boundary.  I buffer the current line and output the
# last.  I strip the last CRLF when I hit the boundary.

sub read_chunk {
    my ($self, $in, $out, $keep_newline, $normalize_newlines) = @_;

    # If we're parsing a preamble or epilogue, we need to keep the blank line
    # that precedes the boundary line.
    $keep_newline ||= 0;

    $normalize_newlines ||= 0;
    ### Init:
    my %bh = %{$self->{BH}};
    my %th = %{$self->{TH}}; my $thx = keys %th;
    local $_ = $LONGLINE;
    my $maybe;
    my $last = '';
    my $eos  = '';

    ### Determine types:
    my $n_in  = native_handle($in);
    my $n_out = native_handle($out);

    ### Handle efficiently by type:
    if ($n_in) {
	if ($n_out) {            ### native input, native output [fastest]
	    while (<$n_in>) {
		# Normalize line ending
		$_ =~ s/(?:\n\r|\r\n|\r)$/\n/ if $normalize_newlines;
		if (substr($_, 0, 2) eq '--') {
		    ($maybe = $_) =~ s/[ \t\r\n]+\Z//;
		    $bh{$maybe} and do { $eos = $bh{$maybe}; last };
		}
		$thx and $th{$_} and do { $eos = $th{$_}; last };
		print $n_out $last; $last = $_;
	    }
	}
	else {                   ### native input, OO output [slower]
	    while (<$n_in>) {
		# Normalize line ending
		$_ =~ s/(?:\n\r|\r\n|\r)$/\n/ if $normalize_newlines;
		if (substr($_, 0, 2) eq '--') {
		    ($maybe = $_) =~ s/[ \t\r\n]+\Z//;
		    $bh{$maybe} and do { $eos = $bh{$maybe}; last };
		}
		$thx and $th{$_} and do { $eos = $th{$_}; last };
		$out->print($last); $last = $_;
	    }
	}
    }
    else {
	if ($n_out) {            ### OO input, native output [even slower]
	    while (defined($_ = $in->getline)) {
		# Normalize line ending
		$_ =~ s/(?:\n\r|\r\n|\r)$/\n/ if $normalize_newlines;
		if (substr($_, 0, 2) eq '--') {
		    ($maybe = $_) =~ s/[ \t\r\n]+\Z//;
		    $bh{$maybe} and do { $eos = $bh{$maybe}; last };
		}
		$thx and $th{$_} and do { $eos = $th{$_}; last };
		print $n_out $last; $last = $_;
	    }
	}
	else {                   ### OO input, OO output [slowest]
	    while (defined($_ = $in->getline)) {
		# Normalize line ending
		$_ =~ s/(?:\n\r|\r\n|\r)$/\n/ if $normalize_newlines;
		if (substr($_, 0, 2) eq '--') {
		    ($maybe = $_) =~ s/[ \t\r\n]+\Z//;
		    $bh{$maybe} and do { $eos = $bh{$maybe}; last };
		}
		$thx and $th{$_} and do { $eos = $th{$_}; last };
		$out->print($last); $last = $_;
	    }
	}
    }

    # Write out last held line, removing terminating CRLF if ended on bound,
    # unless the line consists only of CRLF and we're wanting to keep the
    # preceding blank line (as when parsing a preamble)
    $last =~ s/[\r\n]+\Z// if ($eos =~ /^(DELIM|CLOSE)/ && !($keep_newline && $last =~ m/^[\r\n]\z/));
    $out->print($last);

    ### Save and return what we finished on:
    ${$self->{EOS}} = ($eos || 'EOF');
    1;
}

#------------------------------
#
# read_lines INHANDLE, \@OUTLINES
#
# I<Instance method.>
# Read lines into the given array.
#
sub read_lines {
    my ($self, $in, $outlines) = @_;

    my $data = '';
    open(my $fh, '>', \$data) or die $!;
    $self->read_chunk($in, $fh);
    @$outlines =  split(/^/, $data);
    close $fh;

    1;
}

1;
__END__

=head1 SEE ALSO

L<MIME::Tools>, L<MIME::Parser>
