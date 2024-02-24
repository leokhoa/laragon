package IO::Wrap;

use strict;
use Exporter;
use FileHandle;
use Carp;

our $VERSION = '2.113';
our @ISA = qw(Exporter);
our @EXPORT = qw(wraphandle);


#------------------------------
# wraphandle RAW
#------------------------------
sub wraphandle {
    my $raw = shift;
    new IO::Wrap $raw;
}

#------------------------------
# new STREAM
#------------------------------
sub new {
    my ($class, $stream) = @_;
    no strict 'refs';

    ### Convert raw scalar to globref:
    ref($stream) or $stream = \*$stream;

    ### Wrap globref and incomplete objects:
    if ((ref($stream) eq 'GLOB') or      ### globref
	(ref($stream) eq 'FileHandle') && !defined(&FileHandle::read)) {
	return bless \$stream, $class;
    }
    $stream;           ### already okay!
}

#------------------------------
# I/O methods...
#------------------------------
sub close {
    my $self = shift;
    return close($$self);
}
sub fileno {
    my $self = shift;
    my $fh = $$self;
    return fileno($fh);
}

sub getline {
    my $self = shift;
    my $fh = $$self;
    return scalar(<$fh>);
}
sub getlines {
    my $self = shift;
    wantarray or croak("Can't call getlines in scalar context!");
    my $fh = $$self;
    <$fh>;
}
sub print {
    my $self = shift;
    print { $$self } @_;
}
sub read {
    my $self = shift;
    return read($$self, $_[0], $_[1]);
}
sub seek {
    my $self = shift;
    return seek($$self, $_[0], $_[1]);
}
sub tell {
    my $self = shift;
    return tell($$self);
}

1;
__END__


=head1 NAME

IO::Wrap - Wrap raw filehandles in the IO::Handle interface

=head1 SYNOPSIS

    use strict;
    use warnings;
    use IO::Wrap;

    # this is a fairly senseless use case as IO::Handle already does this.
    my $wrap_fh = IO::Wrap->new(\*STDIN);
    my $line = $wrap_fh->getline();

    # Do stuff with any kind of filehandle (including a bare globref), or
    # any kind of blessed object that responds to a print() message.

    # already have a globref? a FileHandle? a scalar filehandle name?
    $wrap_fh = IO::Wrap->new($some_unknown_thing);

    # At this point, we know we have an IO::Handle-like object! YAY
    $wrap_fh->print("Hey there!");

You can also do this using a convenience wrapper function

    use strict;
    use warnings;
    use IO::Wrap qw(wraphandle);

    # this is a fairly senseless use case as IO::Handle already does this.
    my $wrap_fh = wraphandle(\*STDIN);
    my $line = $wrap_fh->getline();

    # Do stuff with any kind of filehandle (including a bare globref), or
    # any kind of blessed object that responds to a print() message.

    # already have a globref? a FileHandle? a scalar filehandle name?
    $wrap_fh = wraphandle($some_unknown_thing);

    # At this point, we know we have an IO::Handle-like object! YAY
    $wrap_fh->print("Hey there!");

=head1 DESCRIPTION

Let's say you want to write some code which does I/O, but you don't
want to force the caller to provide you with a L<FileHandle> or L<IO::Handle>
object.  You want them to be able to say:

    do_stuff(\*STDOUT);
    do_stuff('STDERR');
    do_stuff($some_FileHandle_object);
    do_stuff($some_IO_Handle_object);

And even:

    do_stuff($any_object_with_a_print_method);

Sure, one way to do it is to force the caller to use C<tiehandle()>.
But that puts the burden on them.  Another way to do it is to
use B<IO::Wrap>.

Clearly, when wrapping a raw external filehandle (like C<\*STDOUT>),
I didn't want to close the file descriptor when the wrapper object is
destroyed; the user might not appreciate that! Hence, there's no
C<DESTROY> method in this class.

When wrapping a L<FileHandle> object, however, I believe that Perl will
invoke the C<FileHandle::DESTROY> when the last reference goes away,
so in that case, the filehandle is closed if the wrapped L<FileHandle>
really was the last reference to it.

=head1 FUNCTIONS

L<IO::Wrap> makes the following functions available.

=head2 wraphandle

    # wrap a filehandle glob
    my $fh = wraphandle(\*STDIN);
    # wrap a raw filehandle glob by name
    $fh = wraphandle('STDIN');
    # wrap a handle in an object
    $fh = wraphandle('Class::HANDLE');

    # wrap a blessed FileHandle object
    use FileHandle;
    my $fho = FileHandle->new("/tmp/foo.txt", "r");
    $fh = wraphandle($fho);

    # wrap any other blessed object that shares IO::Handle's interface
    $fh = wraphandle($some_object);

This function is simply a wrapper to the L<IO::Wrap/"new"> constructor method.

=head1 METHODS

L<IO::Wrap> implements the following methods.

=head2 close

    $fh->close();

The C<close> method will attempt to close the system file descriptor. For a
more complete description, read L<perlfunc/close>.

=head2 fileno

    my $int = $fh->fileno();

The C<fileno> method returns the file descriptor for the wrapped filehandle.
See L<perlfunc/fileno> for more information.

=head2 getline

    my $data = $fh->getline();

The C<getline> method mimics the function by the same name in L<IO::Handle>.
It's like calling C<< my $data = <$fh>; >> but only in scalar context.

=head2 getlines

    my @data = $fh->getlines();

The C<getlines> method mimics the function by the same name in L<IO::Handle>.
It's like calling C<< my @data = <$fh>; >> but only in list context. Calling
this method in scalar context will result in a croak.

=head2 new

    # wrap a filehandle glob
    my $fh = IO::Wrap->new(\*STDIN);
    # wrap a raw filehandle glob by name
    $fh = IO::Wrap->new('STDIN');
    # wrap a handle in an object
    $fh = IO::Wrap->new('Class::HANDLE');

    # wrap a blessed FileHandle object
    use FileHandle;
    my $fho = FileHandle->new("/tmp/foo.txt", "r");
    $fh = IO::Wrap->new($fho);

    # wrap any other blessed object that shares IO::Handle's interface
    $fh = IO::Wrap->new($some_object);

The C<new> constructor method takes in a single argument and decides to wrap
it or not it based on what it seems to be.

A raw scalar file handle name, like C<"STDOUT"> or C<"Class::HANDLE"> can be
wrapped, returning an L<IO::Wrap> object instance.

A raw filehandle glob, like C<\*STDOUT> can also be wrapped, returning an
L<IO::Wrawp> object instance.

A blessed L<FileHandle> object can also be wrapped. This is a special case
where an L<IO::Wrap> object instance will only be returned in the case that
your L<FileHandle> object doesn't support the C<read> method.

Also, any other kind of blessed object that conforms to the
L<IO::Handle> interface can be passed in. In this case, you just get back
that object.

In other words, we only wrap it into an L<IO::Wrap> object when what you've
supplied doesn't already conform to the L<IO::Handle> interface.

If you get back an L<IO::Wrap> object, it will obey a basic subset of
the C<IO::> interface. It will do so with object B<methods>, not B<operators>.

=head3 CAVEATS

This module does not allow you to wrap filehandle names which are given
as strings that lack the package they were opened in. That is, if a user
opens FOO in package Foo, they must pass it to you either as C<\*FOO>
or as C<"Foo::FOO">.  However, C<"STDIN"> and friends will work just fine.

=head2 print

    $fh->print("Some string");
    $fh->print("more", " than one", " string");

The C<print> method will attempt to print a string or list of strings to the
filehandle. For a more complete description, read
L<perlfunc/print>.

=head2 read

    my $buffer;
    # try to read 30 chars into the buffer starting at the
    # current cursor position.
    my $num_chars_read = $fh->read($buffer, 30);

The L<read> method attempts to read a number of characters, starting at the
filehandle's current cursor position. It returns the number of characters
actually read. See L<perlfunc/read> for more information.

=head2 seek

    use Fcntl qw(:seek); # import the SEEK_CUR, SEEK_SET, SEEK_END constants
    # seek to the position in bytes
    $fh->seek(0, SEEK_SET);
    # seek to the position in bytes from the current position
    $fh->seek(22, SEEK_CUR);
    # seek to the EOF plus bytes
    $fh->seek(0, SEEK_END);

The C<seek> method will attempt to set the cursor to a given position in bytes
for the wrapped file handle. See L<perlfunc/seek> for more information.

=head2 tell

    my $bytes = $fh->tell();

The C<tell> method will attempt to return the current position of the cursor
in bytes for the wrapped file handle. See L<perlfunc/tell> for more
information.

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
