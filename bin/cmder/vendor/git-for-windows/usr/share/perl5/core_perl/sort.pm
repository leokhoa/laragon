package sort;

our $VERSION = '2.04';

# The hints for pp_sort are now stored in $^H{sort}; older versions
# of perl used the global variable $sort::hints. -- rjh 2005-12-19

$sort::stable_bit      = 0x00000100;
$sort::unstable_bit    = 0x00000200;

use strict;

sub import {
    shift;
    if (@_ == 0) {
	require Carp;
	Carp::croak("sort pragma requires arguments");
    }
    local $_;
    $^H{sort} //= 0;
    while ($_ = shift(@_)) {
	if ($_ eq 'stable') {
	    $^H{sort} |=  $sort::stable_bit;
	    $^H{sort} &= ~$sort::unstable_bit;
	} elsif ($_ eq 'defaults') {
	    $^H{sort} =   0;
	} else {
	    require Carp;
	    Carp::croak("sort: unknown subpragma '$_'");
	}
    }
}

sub unimport {
    shift;
    if (@_ == 0) {
	require Carp;
	Carp::croak("sort pragma requires arguments");
    }
    local $_;
    no warnings 'uninitialized';	# bitops would warn
    while ($_ = shift(@_)) {
	if ($_ eq 'stable') {
	    $^H{sort} &= ~$sort::stable_bit;
	    $^H{sort} |=  $sort::unstable_bit;
	} else {
	    require Carp;
	    Carp::croak("sort: unknown subpragma '$_'");
	}
    }
}

sub current {
    my @sort;
    if ($^H{sort}) {
	push @sort, 'stable'    if $^H{sort} & $sort::stable_bit;
    }
    join(' ', @sort);
}

1;
__END__

=head1 NAME

sort - perl pragma to control sort() behaviour

=head1 SYNOPSIS

    use sort 'stable';		# guarantee stability
    use sort 'defaults';	# revert to default behavior
    no  sort 'stable';		# stability not important

    my $current;
    BEGIN {
	$current = sort::current();	# identify prevailing pragmata
    }

=head1 DESCRIPTION

With the C<sort> pragma you can control the behaviour of the builtin
C<sort()> function.

A stable sort means that for records that compare equal, the original
input ordering is preserved.
Stability will matter only if elements that compare equal can be
distinguished in some other way.  That means that simple numerical
and lexical sorts do not profit from stability, since equal elements
are indistinguishable.  However, with a comparison such as

   { substr($a, 0, 3) cmp substr($b, 0, 3) }

stability might matter because elements that compare equal on the
first 3 characters may be distinguished based on subsequent characters.

Whether sorting is stable by default is an accident of implementation
that can change (and has changed) between Perl versions.
If stability is important, be sure to
say so with a

  use sort 'stable';

The C<no sort> pragma doesn't
I<forbid> what follows, it just leaves the choice open.  Thus, after

  no sort 'stable';

sorting may happen to be stable anyway.

=head1 CAVEATS

As of Perl 5.10, this pragma is lexically scoped and takes effect
at compile time. In earlier versions its effect was global and took
effect at run-time; the documentation suggested using C<eval()> to
change the behaviour:

  { eval 'no sort "stable"';      # stability not wanted
    print sort::current . "\n";
    @a = sort @b;
    eval 'use sort "defaults"';   # clean up, for others
  }
  { eval 'use sort qw(defaults stable)';     # force stability
    print sort::current . "\n";
    @c = sort @d;
    eval 'use sort "defaults"';   # clean up, for others
  }

Such code no longer has the desired effect, for two reasons.
Firstly, the use of C<eval()> means that the sorting algorithm
is not changed until runtime, by which time it's too late to
have any effect. Secondly, C<sort::current> is also called at
run-time, when in fact the compile-time value of C<sort::current>
is the one that matters.

So now this code would be written:

  { no sort "stable";      # stability not wanted
    my $current;
    BEGIN { $current = sort::current; }
    print "$current\n";
    @a = sort @b;
    # Pragmas go out of scope at the end of the block
  }
  { use sort qw(defaults stable);     # force stability
    my $current;
    BEGIN { $current = sort::current; }
    print "$current\n";
    @c = sort @d;
  }

=cut

