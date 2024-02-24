package IO::AtomicFile;

use strict;
use warnings;
use parent 'IO::File';

our $VERSION = '2.113';

#------------------------------
# new ARGS...
#------------------------------
# Class method, constructor.
# Any arguments are sent to open().
#
sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    ${*$self}{'io_atomicfile_suffix'} = '';
    $self->open(@_) if @_;
    $self;
}

#------------------------------
# DESTROY
#------------------------------
# Destructor.
#
sub DESTROY {
    shift->close(1);   ### like close, but raises fatal exception on failure
}

#------------------------------
# open PATH, MODE
#------------------------------
# Class/instance method.
#
sub open {
    my ($self, $path, $mode) = @_;
    ref($self) or $self = $self->new;    ### now we have an instance!

    ### Create tmp path, and remember this info:
    my $temp = "${path}..TMP" . ${*$self}{'io_atomicfile_suffix'};
    ${*$self}{'io_atomicfile_temp'} = $temp;
    ${*$self}{'io_atomicfile_path'} = $path;

    ### Open the file!  Returns filehandle on success, for use as a constructor:
    $self->SUPER::open($temp, $mode) ? $self : undef;
}

#------------------------------
# _closed [YESNO]
#------------------------------
# Instance method, private.
# Are we already closed?  Argument sets new value, returns previous one.
#
sub _closed {
    my $self = shift;
    my $oldval = ${*$self}{'io_atomicfile_closed'};
    ${*$self}{'io_atomicfile_closed'} = shift if @_;
    $oldval;
}

#------------------------------
# close
#------------------------------
# Instance method.
# Close the handle, and rename the temp file to its final name.
#
sub close {
    my ($self, $die) = @_;
    unless ($self->_closed(1)) {             ### sentinel...
	    if ($self->SUPER::close()) {
		    rename(${*$self}{'io_atomicfile_temp'},
			   ${*$self}{'io_atomicfile_path'})
			or ($die ? die "close (rename) atomic file: $!\n" : return undef);
	    } else {
		    ($die ? die "close atomic file: $!\n" : return undef);
	    }
    }
    1;
}

#------------------------------
# delete
#------------------------------
# Instance method.
# Close the handle, and delete the temp file.
#
sub delete {
    my $self = shift;
    unless ($self->_closed(1)) {             ### sentinel...
        $self->SUPER::close();
        return unlink(${*$self}{'io_atomicfile_temp'});
    }
    1;
}

#------------------------------
# detach
#------------------------------
# Instance method.
# Close the handle, but DO NOT delete the temp file.
#
sub detach {
    my $self = shift;
    $self->SUPER::close() unless ($self->_closed(1));
    1;
}

#------------------------------
1;
__END__


=head1 NAME

IO::AtomicFile - write a file which is updated atomically

=head1 SYNOPSIS

    use strict;
    use warnings;
    use feature 'say';
    use IO::AtomicFile;

    # Write a temp file, and have it install itself when closed:
    my $fh = IO::AtomicFile->open("bar.dat", "w");
    $fh->say("Hello!");
    $fh->close || die "couldn't install atomic file: $!";

    # Write a temp file, but delete it before it gets installed:
    my $fh = IO::AtomicFile->open("bar.dat", "w");
    $fh->say("Hello!");
    $fh->delete;

    # Write a temp file, but neither install it nor delete it:
    my $fh = IO::AtomicFile->open("bar.dat", "w");
    $fh->say("Hello!");
    $fh->detach;

=head1 DESCRIPTION

This module is intended for people who need to update files
reliably in the face of unexpected program termination.

For example, you generally don't want to be halfway in the middle of
writing I</etc/passwd> and have your program terminate!  Even
the act of writing a single scalar to a filehandle is I<not> atomic.

But this module gives you true atomic updates, via C<rename>.
When you open a file I</foo/bar.dat> via this module, you are I<actually>
opening a temporary file I</foo/bar.dat..TMP>, and writing your
output there. The act of closing this file (either explicitly
via C<close>, or implicitly via the destruction of the object)
will cause C<rename> to be called... therefore, from the point
of view of the outside world, the file's contents are updated
in a single time quantum.

To ensure that problems do not go undetected, the C<close> method
done by the destructor will raise a fatal exception if the C<rename>
fails.  The explicit C<close> just returns C<undef>.

You can also decide at any point to trash the file you've been
building.

=head1 METHODS

L<IO::AtomicFile> inherits all methods from L<IO::File> and
implements the following new ones.

=head2 close

    $fh->close();

This method calls its parent L<IO::File/"close"> and then renames its temporary file
as the original file name.

=head2 delete

    $fh->delete();

This method calls its parent L<IO::File/"close"> and then deletes the temporary file.

=head2 detach

    $fh->detach();

This method calls its parent L<IO::File/"close">. Unlike L<IO::AtomicFile/"delete"> it
does not then delete the temporary file.

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
