package IO::Lines;

use strict;
use Carp;
use IO::ScalarArray;

# The package version, both in 1.23 style *and* usable by MakeMaker:
our $VERSION = '2.113';

# Inheritance:
our @ISA = qw(IO::ScalarArray);     ### also gets us new_tie  :-)


=head1 NAME

IO::Lines - IO:: interface for reading/writing an array of lines


=head1 SYNOPSIS

    use IO::Lines;

    ### See IO::ScalarArray for details


=head1 DESCRIPTION

This class implements objects which behave just like FileHandle
(or IO::Handle) objects, except that you may use them to write to
(or read from) an array of lines.  C<tiehandle> capable as well.

This is a subclass of L<IO::ScalarArray|IO::ScalarArray>
in which the underlying
array has its data stored in a line-oriented-format: that is,
every element ends in a C<"\n">, with the possible exception of the
final element.  This makes C<getline()> I<much> more efficient;
if you plan to do line-oriented reading/printing, you want this class.

The C<print()> method will enforce this rule, so you can print
arbitrary data to the line-array: it will break the data at
newlines appropriately.

See L<IO::ScalarArray> for full usage and warnings.

=cut


#------------------------------
#
# getline
#
# Instance method, override.
# Return the next line, or undef on end of data.
# Can safely be called in an array context.
# Currently, lines are delimited by "\n".
#
sub getline {
    my $self = shift;

    if (!defined $/) {
	return join( '', $self->_getlines_for_newlines );
    }
    elsif ($/ eq "\n") {
	if (!*$self->{Pos}) {      ### full line...
	    return *$self->{AR}[*$self->{Str}++];
	}
	else {                     ### partial line...
	    my $partial = substr(*$self->{AR}[*$self->{Str}++], *$self->{Pos});
	    *$self->{Pos} = 0;
	    return $partial;
	}
    }
    else {
	croak 'unsupported $/: must be "\n" or undef';
    }
}

#------------------------------
#
# getlines
#
# Instance method, override.
# Return an array comprised of the remaining lines, or () on end of data.
# Must be called in an array context.
# Currently, lines are delimited by "\n".
#
sub getlines {
    my $self = shift;
    wantarray or croak("can't call getlines in scalar context!");

    if ((defined $/) and ($/ eq "\n")) {
	return $self->_getlines_for_newlines(@_);
    }
    else {         ### slow but steady
	return $self->SUPER::getlines(@_);
    }
}

#------------------------------
#
# _getlines_for_newlines
#
# Instance method, private.
# If $/ is newline, do fast getlines.
# This CAN NOT invoke getline!
#
sub _getlines_for_newlines {
    my $self = shift;
    my ($rArray, $Str, $Pos) = @{*$self}{ qw( AR Str Pos ) };
    my @partial = ();

    if ($Pos) {				### partial line...
	@partial = (substr( $rArray->[ $Str++ ], $Pos ));
	*$self->{Pos} = 0;
    }
    *$self->{Str} = scalar @$rArray;	### about to exhaust @$rArray
    return (@partial,
	    @$rArray[ $Str .. $#$rArray ]);	### remaining full lines...
}

#------------------------------
#
# print ARGS...
#
# Instance method, override.
# Print ARGS to the underlying line array.
#
sub print {
    if (defined $\ && $\ ne "\n") {
	croak 'unsupported $\: must be "\n" or undef';
    }

    my $self = shift;
    ### print STDERR "\n[[ARRAY WAS...\n", @{*$self->{AR}}, "<<EOF>>\n";
    my @lines = split /^/, join('', @_); @lines or return 1;

    ### Did the previous print not end with a newline?
    ### If so, append first line:
    if (@{*$self->{AR}} and (*$self->{AR}[-1] !~ /\n\Z/)) {
	*$self->{AR}[-1] .= shift @lines;
    }
    push @{*$self->{AR}}, @lines;       ### add the remainder
    ### print STDERR "\n[[ARRAY IS NOW...\n", @{*$self->{AR}}, "<<EOF>>\n";
    1;
}

#------------------------------
1;

__END__


=head1 VERSION

$Id: Lines.pm,v 1.3 2005/02/10 21:21:53 dfs Exp $


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
