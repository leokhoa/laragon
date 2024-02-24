# Error/Simple.pm
#
# Copyright (c) 2006 Shlomi Fish <shlomif@shlomifish.org>.
# This file is free software; you can redistribute it and/or
# modify it under the terms of the MIT/X11 license (whereas the licence
# of the Error distribution as a whole is the GPLv1+ and the Artistic
# licence).

package Error::Simple;
$Error::Simple::VERSION = '0.17029';
use strict;
use warnings;

use Error;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Error::Simple - the simple error sub-class of Error

=head1 VERSION

version 0.17029

=head1 SYNOPSIS

    use base 'Error::Simple';

=head1 DESCRIPTION

The only purpose of this module is to allow one to say:

    use base 'Error::Simple';

and the only thing it does is "use" Error.pm. Refer to the documentation
of L<Error> for more information about Error::Simple.

=head1 METHODS

=head2 Error::Simple->new($text [, $value])

Constructs an Error::Simple with the text C<$text> and the optional value
C<$value>.

=head2 $err->stringify()

Error::Simple overloads this method.

=head1 KNOWN BUGS

None.

=head1 AUTHORS

Shlomi Fish ( L<http://www.shlomifish.org/> )

=head1 SEE ALSO

L<Error>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Error>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Error>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Error>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Error>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Error>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/E/Error>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Error>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Error>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-error at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Error>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-error.pm>

  git clone git://github.com/shlomif/perl-error.pm.git

=head1 AUTHOR

Shlomi Fish ( http://www.shlomifish.org/ )

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-error.pm/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Shlomi Fish ( http://www.shlomifish.org/ ).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
