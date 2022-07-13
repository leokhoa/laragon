package Math::BigInt::FastCalc;

use 5.006;
use strict;
use warnings;

use Math::BigInt::Calc 1.999801;

our @ISA = qw< Math::BigInt::Calc >;

our $VERSION = '0.5009';

##############################################################################
# global constants, flags and accessory

# announce that we are compatible with MBI v1.83 and up
sub api_version () { 2; }

# use Calc to override the methods that we do not provide in XS

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION, Math::BigInt::Calc->_base_len());

##############################################################################
##############################################################################

1;

__END__

=pod

=head1 NAME

Math::BigInt::FastCalc - Math::BigInt::Calc with some XS for more speed

=head1 SYNOPSIS

    # to use it with Math::BigInt
    use Math::BigInt lib => 'FastCalc';

    # to use it with Math::BigFloat
    use Math::BigFloat lib => 'FastCalc';

    # to use it with Math::BigRat
    use Math::BigRat lib => 'FastCalc';

=head1 DESCRIPTION

Math::BigInt::FastCalc inherits from Math::BigInt::Calc.

Provides support for big integer calculations. Not intended to be used by
other modules. Other modules which sport the same functions can also be used
to support Math::BigInt, like L<Math::BigInt::GMP> or L<Math::BigInt::Pari>.

In order to allow for multiple big integer libraries, Math::BigInt was
rewritten to use library modules for core math routines. Any module which
follows the same API as this can be used instead by using the following:

	use Math::BigInt lib => 'libname';

'libname' is either the long name ('Math::BigInt::Pari'), or only the short
version like 'Pari'. To use this library:

	use Math::BigInt lib => 'FastCalc';

=head1 STORAGE

Math::BigInt::FastCalc works exactly like Math::BigInt::Calc. Numbers are
stored in decimal form chopped into parts.

=head1 METHODS

The following functions are now implemented in FastCalc.xs:

	_is_odd		_is_even	_is_one		_is_zero
	_is_two		_is_ten
	_zero		_one		_two		_ten
	_acmp		_len
	_inc		_dec
	__strip_zeros	_copy

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-fastcalc at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-FastCalc>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigInt::FastCalc

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-FastCalc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-BigInt-FastCalc>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt-FastCalc>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt-FastCalc/>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-FastCalc>

=item * The Bignum mailing list

=over 4

=item * Post to mailing list

C<bignum at lists.scsys.co.uk>

=item * View mailing list

L<http://lists.scsys.co.uk/pipermail/bignum/>

=item * Subscribe/Unsubscribe

L<http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/bignum>

=back

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHORS

Original math code by Mark Biggar, rewritten by Tels L<http://bloodgate.com/>
in late 2000.
Separated from BigInt and shaped API with the help of John Peacock.

Fixed, sped-up and enhanced by Tels http://bloodgate.com 2001-2003.
Further streamlining (api_version 1 etc.) by Tels 2004-2007.

Bug-fixing by Peter John Acklam E<lt>pjacklam@online.noE<gt> 2010-2016.

=head1 SEE ALSO

L<Math::BigInt::Lib> for a description of the API.

Alternative libraries L<Math::BigInt::Calc>, L<Math::BigInt::GMP>, and
L<Math::BigInt::Pari>.

Some of the modules that use these libraries L<Math::BigInt>,
L<Math::BigFloat>, and L<Math::BigRat>.

=cut
