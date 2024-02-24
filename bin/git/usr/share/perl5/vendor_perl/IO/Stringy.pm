package IO::Stringy;
use strict;
use Exporter;

our $VERSION = '2.113';

1;
__END__

=head1 NAME

IO-stringy - I/O on in-core objects like strings and arrays

=head1 SYNOPSIS

    use strict;
    use warnings;

    use IO::AtomicFile; # Write a file which is updated atomically
    use IO::InnerFile; # define a file inside another file
    use IO::Lines; # I/O handle to read/write to array of lines
    use IO::Scalar; # I/O handle to read/write to a string
    use IO::ScalarArray; # I/O handle to read/write to array of scalars
    use IO::Wrap; # Wrap old-style FHs in standard OO interface
    use IO::WrapTie; # Tie your handles & retain full OO interface

    # ...

=head1 DESCRIPTION

This toolkit primarily provides modules for performing both traditional
and object-oriented i/o) on things I<other> than normal filehandles;
in particular, L<IO::Scalar|IO::Scalar>, L<IO::ScalarArray|IO::ScalarArray>,
and L<IO::Lines|IO::Lines>.

In the more-traditional IO::Handle front, we
have L<IO::AtomicFile|IO::AtomicFile>
which may be used to painlessly create files which are updated
atomically.

And in the "this-may-prove-useful" corner, we have L<IO::Wrap|IO::Wrap>,
whose exported wraphandle() function will clothe anything that's not
a blessed object in an IO::Handle-like wrapper... so you can just
use OO syntax and stop worrying about whether your function's caller
handed you a string, a globref, or a FileHandle.

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
