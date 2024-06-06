package MIME::Body;

=head1 NAME

MIME::Body - the body of a MIME message


=head1 SYNOPSIS

Before reading further, you should see L<MIME::Tools> to make sure that
you understand where this module fits into the grand scheme of things.
Go on, do it now.  I'll wait.

Ready?  Ok...


=head2 Obtaining bodies

   ### Get the bodyhandle of a MIME::Entity object:
   $body = $entity->bodyhandle;

   ### Create a body which stores data in a disk file:
   $body = new MIME::Body::File "/path/to/file";

   ### Create a body which stores data in an in-core array:
   $body = new MIME::Body::InCore \@strings;


=head2 Opening, closing, and using IO handles

   ### Write data to the body:
   $IO = $body->open("w")      || die "open body: $!";
   $IO->print($message);
   $IO->close                  || die "close I/O handle: $!";

   ### Read data from the body (in this case, line by line):
   $IO = $body->open("r")      || die "open body: $!";
   while (defined($_ = $IO->getline)) {
       ### do stuff
   }
   $IO->close                  || die "close I/O handle: $!";


=head2 Other I/O

   ### Dump the ENCODED body data to a filehandle:
   $body->print(\*STDOUT);

   ### Slurp all the UNENCODED data in, and put it in a scalar:
   $string = $body->as_string;

   ### Slurp all the UNENCODED data in, and put it in an array of lines:
   @lines = $body->as_lines;


=head2 Working directly with paths to underlying files

   ### Where's the data?
   if (defined($body->path)) {   ### data is on disk:
       print "data is stored externally, in ", $body->path;
   }
   else {                        ### data is in core:
       print "data is already in core, and is...\n", $body->as_string;
   }

   ### Get rid of anything on disk:
   $body->purge;


=head1 DESCRIPTION

MIME messages can be very long (e.g., tar files, MPEGs, etc.) or very
short (short textual notes, as in ordinary mail).  Long messages
are best stored in files, while short ones are perhaps best stored
in core.

This class is an attempt to define a common interface for objects
which contain message data, regardless of how the data is
physically stored.  The lifespan of a "body" object
usually looks like this:

=over 4

=item 1.

B<Body object is created by a MIME::Parser during parsing.>
It's at this point that the actual MIME::Body subclass is chosen,
and new() is invoked.  (For example: if the body data is going to
a file, then it is at this point that the class MIME::Body::File,
and the filename, is chosen).

=item 2.

B<Data is written to the body> (usually by the MIME parser) like this:
The body is opened for writing, via C<open("w")>.  This will trash any
previous contents, and return an "I/O handle" opened for writing.
Data is written to this I/O handle, via print().
Then the I/O handle is closed, via close().

=item 3.

B<Data is read from the body> (usually by the user application) like this:
The body is opened for reading by a user application, via C<open("r")>.
This will return an "I/O handle" opened for reading.
Data is read from the I/O handle, via read(), getline(), or getlines().
Then the I/O handle is closed, via close().

=item 4.

B<Body object is destructed.>

=back

You can write your own subclasses, as long as they follow the
interface described below.  Implementers of subclasses should assume
that steps 2 and 3 may be repeated any number of times, and in
different orders (e.g., 1-2-2-3-2-3-3-3-3-3-2-4).

In any case, once a MIME::Body has been created, you ask to open it
for reading or writing, which gets you an "i/o handle": you then use
the same mechanisms for reading from or writing to that handle, no matter
what class it is.

Beware: unless you know for certain what kind of body you have, you
should I<not> assume that the body has an underlying filehandle.


=head1 PUBLIC INTERFACE

=over 4

=cut


### Pragmas:
use strict;
use vars qw($VERSION);

### System modules:
use Carp;
use IO::File;

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";


#------------------------------

=item new ARGS...

I<Class method, constructor.>
Create a new body.  Any ARGS are sent to init().

=cut

sub new {
    my $self = bless {}, shift;
    $self->init(@_);
    $self;
}

#------------------------------

=item init ARGS...

I<Instance method, abstract, initiallizer.>
This is called automatically by C<new()>, with the arguments given
to C<new()>.  The arguments are optional, and entirely up to the
subclass.  The default method does nothing,

=cut

sub init { 1 }

#------------------------------

=item as_lines

I<Instance method.>
Return the contents of the body as an array of lines (each terminated
by a newline, with the possible exception of the final one).
Returns empty on failure (NB: indistinguishable from an empty body!).

Note: the default method gets the data via
repeated getline() calls; your subclass might wish to override this.

=cut

sub as_lines {
    my $self = shift;
    my @lines;
    my $io = $self->open("r") || return ();
    local $_;
    push @lines, $_ while (defined($_ = $io->getline()));
    $io->close;
    @lines;
}

#------------------------------

=item as_string

I<Instance method.>
Return the body data as a string (slurping it into core if necessary).
Best not to do this unless you're I<sure> that the body is reasonably small!
Returns empty string for an empty body, and undef on failure.

Note: the default method uses print(), which gets the data via
repeated read() calls; your subclass might wish to override this.

=cut

sub as_string {
    my $self = shift;
    my $str = '';
    my $fh = IO::File->new(\$str, '>:') or croak("Cannot open in-memory file: $!");
    $self->print($fh);
    close($fh);
    return $str;
}
*data = \&as_string;         ### silently invoke preferred usage


#------------------------------

=item binmode [ONOFF]

I<Instance method.>
With argument, flags whether or not open() should return an I/O handle
which has binmode() activated.  With no argument, just returns the
current value.

=cut

sub binmode {
    my ($self, $onoff) = @_;
    $self->{MB_Binmode} = $onoff if (@_ > 1);
    $self->{MB_Binmode};
}

#------------------------------

=item is_encoded [ONOFF]

I<Instance method.>
If set to yes, no decoding is applied on output. This flag is set
by MIME::Parser, if the parser runs in decode_bodies(0) mode, so the
content is handled unmodified.

=cut

sub is_encoded {
    my ($self, $yesno) = @_;
    $self->{MB_IsEncoded} = $yesno if (@_ > 1);
    $self->{MB_IsEncoded};
}

#------------------------------

=item dup

I<Instance method.>
Duplicate the bodyhandle.

I<Beware:> external data in bodyhandles is I<not> copied to new files!
Changing the data in one body's data file, or purging that body,
I<will> affect its duplicate.  Bodies with in-core data probably need
not worry.

=cut

sub dup {
    my $self = shift;
    bless { %$self }, ref($self);   ### shallow copy ok for ::File and ::Scalar
}

#------------------------------

=item open READWRITE

I<Instance method, abstract.>
This should do whatever is necessary to open the body for either
writing (if READWRITE is "w") or reading (if mode is "r").

This method is expected to return an "I/O handle" object on success,
and undef on error.  An I/O handle can be any object that supports a
small set of standard methods for reading/writing data.
See the IO::Handle class for an example.

=cut

sub open {
    undef;
}

#------------------------------

=item path [PATH]

I<Instance method.>
If you're storing the body data externally (e.g., in a disk file), you'll
want to give applications the ability to get at that data, for cleanup.
This method should return the path to the data, or undef if there is none.

Where appropriate, the path I<should> be a simple string, like a filename.
With argument, sets the PATH, which should be undef if there is none.

=cut

sub path {
    my $self = shift;
    $self->{MB_Path} = shift if @_;
    $self->{MB_Path};
}

#------------------------------

=item print FILEHANDLE

I<Instance method.>
Output the body data to the given filehandle, or to the currently-selected
one if none is given.

=cut

sub print {
    my ($self, $fh) = @_;
    my $nread;

    ### Get output filehandle, and ensure that it's a printable object:
    $fh ||= select;

    ### Write it:
    my $buf = '';
    my $io = $self->open("r") || return undef;
    $fh->print($buf) while ($nread = $io->read($buf, 8192));
    $io->close;
    return defined($nread);    ### how'd we do?
}

#------------------------------

=item purge

I<Instance method, abstract.>
Remove any data which resides external to the program (e.g., in disk files).
Immediately after a purge(), the path() should return undef to indicate
that the external data is no longer available.

=cut

sub purge {
    1;
}



=back

=head1 SUBCLASSES

The following built-in classes are provided:

   Body                 Stores body     When open()ed,
   class:               data in:        returns:
   --------------------------------------------------------
   MIME::Body::File     disk file       IO::Handle
   MIME::Body::Scalar   scalar          IO::Handle
   MIME::Body::InCore   scalar array    IO::Handle

=cut


#------------------------------------------------------------
package MIME::Body::File;
#------------------------------------------------------------

=head2 MIME::Body::File

A body class that stores the data in a disk file.  Invoke the
constructor as:

    $body = new MIME::Body::File "/path/to/file";

In this case, the C<path()> method would return the given path,
so you I<could> say:

    if (defined($body->path)) {
	open BODY, $body->path or die "open: $!";
	while (<BODY>) {
	    ### do stuff
        }
	close BODY;
    }

But you're best off not doing this.

=cut


### Pragmas:
use vars qw(@ISA);
use strict;

### System modules:
use IO::File;

### Kit modules:
use MIME::Tools qw(whine);

@ISA = qw(MIME::Body);


#------------------------------
# init PATH
#------------------------------
sub init {
    my ($self, $path) = @_;
    $self->path($path);               ### use it as-is
    $self;
}

#------------------------------
# open READWRITE
#------------------------------
sub open {
    my ($self, $mode) = @_;

    my $path = $self->path;

    if( $mode ne 'r' && $mode ne 'w' ) {
	die "bad mode: '$mode'";
    }

    my $IO = IO::File->new($path, $mode) || die "MIME::Body::File->open $path: $!";

    $IO->binmode() if $self->binmode;

    return $IO;
}

#------------------------------
# purge
#------------------------------
# Unlink the path (and undefine it).
#
sub purge {
    my $self = shift;
    if (defined($self->path)) {
	unlink $self->path or whine "couldn't unlink ".$self->path.": $!";
	$self->path(undef);
    }
    1;
}




#------------------------------------------------------------
package MIME::Body::Scalar;
#------------------------------------------------------------

=head2 MIME::Body::Scalar

A body class that stores the data in-core, in a simple scalar.
Invoke the constructor as:

    $body = new MIME::Body::Scalar \$string;

A single scalar argument sets the body to that value, exactly as though
you'd opened for the body for writing, written the value,
and closed the body again:

    $body = new MIME::Body::Scalar "Line 1\nLine 2\nLine 3";

A single array reference sets the body to the result of joining all the
elements of that array together:

    $body = new MIME::Body::Scalar ["Line 1\n",
                                    "Line 2\n",
                                    "Line 3"];

=cut

use vars qw(@ISA);
use strict;

use Carp;

@ISA = qw(MIME::Body);


#------------------------------
# init DATA
#------------------------------
sub init {
    my ($self, $data) = @_;
    $data = join('', @$data)    if (ref($data) && (ref($data) eq 'ARRAY'));
    $self->{MBS_Data} = (defined($data) ? $data : '');
    $self;
}

#------------------------------
# as_string
#------------------------------
sub as_string {
    shift->{MBS_Data};
}

#------------------------------
# open READWRITE
#------------------------------
sub open {
    my ($self, $mode) = @_;
    $self->{MBS_Data} = '' if ($mode eq 'w');        ### writing

    if ($mode eq 'w') {
	    $mode = '>:';
    } elsif ($mode eq 'r') {
	    $mode = '<:';
    } else {
	    die "bad mode: $mode";
    }

    return IO::File->new(\ $self->{MBS_Data}, $mode);
}





#------------------------------------------------------------
package MIME::Body::InCore;
#------------------------------------------------------------

=head2 MIME::Body::InCore

A body class that stores the data in-core.
Invoke the constructor as:

    $body = new MIME::Body::InCore \$string;
    $body = new MIME::Body::InCore  $string;
    $body = new MIME::Body::InCore \@stringarray

A simple scalar argument sets the body to that value, exactly as though
you'd opened for the body for writing, written the value,
and closed the body again:

    $body = new MIME::Body::InCore "Line 1\nLine 2\nLine 3";

A single array reference sets the body to the concatenation of all
scalars that it holds:

    $body = new MIME::Body::InCore ["Line 1\n",
                                    "Line 2\n",
                                    "Line 3"];

=cut

use vars qw(@ISA);
use strict;

use Carp;

@ISA = qw(MIME::Body::Scalar);


#------------------------------
# init DATA
#------------------------------
sub init {
    my ($self, $data) = @_;
    if (!defined($data)) {  ### nothing
	$self->{MBS_Data} = '';
    }
    elsif (!ref($data)) {   ### simple scalar
	$self->{MBS_Data} = $data;
    }
    elsif (ref($data) eq 'SCALAR') {
	$self->{MBS_Data} = $$data;
    }
    elsif (ref($data) eq 'ARRAY') {
	$self->{MBS_Data} = join('', @$data);
    }
    else {
	croak "I can't handle DATA which is a ".ref($data)."\n";
    }
    $self;
}

1;
__END__


#------------------------------

=head2 Defining your own subclasses

So you're not happy with files and scalar-arrays?
No problem: just define your own MIME::Body subclass, and make a subclass
of MIME::Parser or MIME::ParserBase which returns an instance of your
body class whenever appropriate in the C<new_body_for(head)> method.

Your "body" class must inherit from MIME::Body (or some subclass of it),
and it must either provide (or inherit the default for) the following
methods...

The default inherited method I<should suffice> for all these:

    new
    binmode [ONOFF]
    path

The default inherited method I<may suffice> for these, but perhaps
there's a better implementation for your subclass.

    init ARGS...
    as_lines
    as_string
    dup
    print
    purge

The default inherited method I<will probably not suffice> for these:

    open



=head1 NOTES

One reason I didn't just use IO::Handle objects for message bodies was
that I wanted a "body" object to be a form of completely encapsulated
program-persistent storage; that is, I wanted users to be able to write
code like this...

   ### Get body handle from this MIME message, and read its data:
   $body = $entity->bodyhandle;
   $IO = $body->open("r");
   while (defined($_ = $IO->getline)) {
       print STDOUT $_;
   }
   $IO->close;

...without requiring that they know anything more about how the
$body object is actually storing its data (disk file, scalar variable,
array variable, or whatever).

Storing the body of each MIME message in a persistently-open
IO::Handle was a possibility, but it seemed like a bad idea,
considering that a single multipart MIME message could easily suck up
all the available file descriptors on some systems.  This risk increases
if the user application is processing more than one MIME entity at a time.

=head1 SEE ALSO

L<MIME::Tools>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
David F. Skoll (dfs@roaringpenguin.com) http://www.roaringpenguin.com

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

Thanks to Achim Bohnet for suggesting that MIME::Parser not be restricted
to the use of FileHandles.

#------------------------------
1;

