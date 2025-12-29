package MIME::Decoder;


=head1 NAME

MIME::Decoder - an object for decoding the body part of a MIME stream


=head1 SYNOPSIS

Before reading further, you should see L<MIME::Tools> to make sure that
you understand where this module fits into the grand scheme of things.
Go on, do it now.  I'll wait.

Ready?  Ok...


=head2 Decoding a data stream

Here's a simple filter program to read quoted-printable data from STDIN
(until EOF) and write the decoded data to STDOUT:

    use MIME::Decoder;

    $decoder = new MIME::Decoder 'quoted-printable' or die "unsupported";
    $decoder->decode(\*STDIN, \*STDOUT);


=head2 Encoding a data stream

Here's a simple filter program to read binary data from STDIN
(until EOF) and write base64-encoded data to STDOUT:

    use MIME::Decoder;

    $decoder = new MIME::Decoder 'base64' or die "unsupported";
    $decoder->encode(\*STDIN, \*STDOUT);


=head2 Non-standard encodings

You can B<write and install> your own decoders so that
MIME::Decoder will know about them:

    use MyBase64Decoder;

    install MyBase64Decoder 'base64';

You can also B<test> if a given encoding is supported:

    if (supported MIME::Decoder 'x-uuencode') {
	### we can uuencode!
    }


=head1 DESCRIPTION

This abstract class, and its private concrete subclasses (see below)
provide an OO front end to the actions of...

=over 4

=item *

Decoding a MIME-encoded stream

=item *

Encoding a raw data stream into a MIME-encoded stream.

=back

The constructor for MIME::Decoder takes the name of an encoding
(C<base64>, C<7bit>, etc.), and returns an instance of a I<subclass>
of MIME::Decoder whose C<decode()> method will perform the appropriate
decoding action, and whose C<encode()> method will perform the appropriate
encoding action.


=cut


### Pragmas:
use strict;
use vars qw($VERSION %DecoderFor);

### System modules:
use IPC::Open2;
use IO::Select;
use FileHandle;

### Kit modules:
use MIME::Tools qw(:config :msgs);
use Carp;

#------------------------------
#
# Globals
#
#------------------------------

### The stream decoders:
%DecoderFor = (

  ### Standard...
    '7bit'       => 'MIME::Decoder::NBit',
    '8bit'       => 'MIME::Decoder::NBit',
    'base64'     => 'MIME::Decoder::Base64',
    'binary'     => 'MIME::Decoder::Binary',
    'none'       => 'MIME::Decoder::Binary',
    'quoted-printable' => 'MIME::Decoder::QuotedPrint',

  ### Non-standard...
    'binhex'     => 'MIME::Decoder::BinHex',
    'binhex40'   => 'MIME::Decoder::BinHex',
    'mac-binhex40' => 'MIME::Decoder::BinHex',
    'mac-binhex' => 'MIME::Decoder::BinHex',
    'x-uu'       => 'MIME::Decoder::UU',
    'x-uuencode' => 'MIME::Decoder::UU',

  ### This was removed, since I fear that x-gzip != x-gzip64...
### 'x-gzip'     => 'MIME::Decoder::Gzip64',

  ### This is no longer installed by default, since not all folks have gzip:
### 'x-gzip64'   => 'MIME::Decoder::Gzip64',
);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.515";

### Me:
my $ME = 'MIME::Decoder';


#------------------------------

=head1 PUBLIC INTERFACE

=head2 Standard interface

If all you are doing is I<using> this class, here's all you'll need...

=over 4

=cut

#------------------------------

=item new ENCODING

I<Class method, constructor.>
Create and return a new decoder object which can handle the
given ENCODING.

    my $decoder = new MIME::Decoder "7bit";

Returns the undefined value if no known decoders are appropriate.

=cut

sub new {
    my ($class, @args) = @_;
    my ($encoding) = @args;

    ### Coerce the type to be legit:
    $encoding = lc($encoding || '');

    ### Get the class:
    my $concrete_name = $DecoderFor{$encoding};

    if( ! $concrete_name ) {
	carp "no decoder for $encoding";
	return undef;
    }

    ### Create the new object (if we can):
    my $self = { MD_Encoding => lc($encoding) };
    unless (eval "require $concrete_name;") {
	carp $@;
	return undef;
    }
    bless $self, $concrete_name;
    $self->init(@args);
}

#------------------------------

=item best ENCODING

I<Class method, constructor.>
Exactly like new(), except that this defaults any unsupported encoding to
"binary", after raising a suitable warning (it's a fatal error if there's
no binary decoder).

    my $decoder = best MIME::Decoder "x-gzip64";

Will either return a decoder, or a raise a fatal exception.

=cut

sub best {
    my ($class, $enc, @args) = @_;
    my $self = $class->new($enc, @args);
    if (!$self) {
	usage "unsupported encoding '$enc': using 'binary'";
	$self = $class->new('binary') || croak "ack! no binary decoder!";
    }
    $self;
}

#------------------------------

=item decode INSTREAM,OUTSTREAM

I<Instance method.>
Decode the document waiting in the input handle INSTREAM,
writing the decoded information to the output handle OUTSTREAM.

Read the section in this document on I/O handles for more information
about the arguments.  Note that you can still supply old-style
unblessed filehandles for INSTREAM and OUTSTREAM.

Returns true on success, throws exception on failure.

=cut

sub decode {
    my ($self, $in, $out) = @_;

    ### Set up the default input record separator to be CRLF:
    ### $in->input_record_separator("\012\015");

    ### Invoke back-end method to do the work:
    $self->decode_it($in, $out) ||
	die "$ME: ".$self->encoding." decoding failed\n";
    1;
}

#------------------------------

=item encode INSTREAM,OUTSTREAM

I<Instance method.>
Encode the document waiting in the input filehandle INSTREAM,
writing the encoded information to the output stream OUTSTREAM.

Read the section in this document on I/O handles for more information
about the arguments.  Note that you can still supply old-style
unblessed filehandles for INSTREAM and OUTSTREAM.

Returns true on success, throws exception on failure.

=cut

sub encode {
    my ($self, $in, $out, $textual_type) = @_;

    ### Invoke back-end method to do the work:
    $self->encode_it($in, $out, $self->encoding eq 'quoted-printable' ? ($textual_type) : ()) ||
	die "$ME: ".$self->encoding." encoding failed\n";
}

#------------------------------

=item encoding

I<Instance method.>
Return the encoding that this object was created to handle,
coerced to all lowercase (e.g., C<"base64">).

=cut

sub encoding {
    shift->{MD_Encoding};
}

#------------------------------

=item head [HEAD]

I<Instance method.>
Completely optional: some decoders need to know a little about the file
they are encoding/decoding; e.g., x-uu likes to have the filename.
The HEAD is any object which responds to messages like:

    $head->mime_attr('content-disposition.filename');

=cut

sub head {
    my ($self, $head) = @_;
    $self->{MD_Head} = $head if @_ > 1;
    $self->{MD_Head};
}

#------------------------------

=item supported [ENCODING]

I<Class method.>
With one arg (an ENCODING name), returns truth if that encoding
is currently handled, and falsity otherwise.  The ENCODING will
be automatically coerced to lowercase:

    if (supported MIME::Decoder '7BIT') {
	### yes, we can handle it...
    }
    else {
	### drop back six and punt...
    }

With no args, returns a reference to a hash of all available decoders,
where the key is the encoding name (all lowercase, like '7bit'),
and the value is true (it happens to be the name of the class
that handles the decoding, but you probably shouldn't rely on that).
You may safely modify this hash; it will I<not> change the way the
module performs its lookups.  Only C<install> can do that.

I<Thanks to Achim Bohnet for suggesting this method.>

=cut

sub supported {
    my ($class, $decoder) = @_;
    defined($decoder) ? $DecoderFor{lc($decoder)}: { %DecoderFor };
}

#------------------------------

=back

=head2 Subclass interface

If you are writing (or installing) a new decoder subclass, there
are some other methods you'll need to know about:

=over 4

=item decode_it INSTREAM,OUTSTREAM

I<Abstract instance method.>
The back-end of the B<decode> method.  It takes an input handle
opened for reading (INSTREAM), and an output handle opened for
writing (OUTSTREAM).

If you are writing your own decoder subclass, you must override this
method in your class.  Your method should read from the input
handle via C<getline()> or C<read()>, decode this input, and print the
decoded data to the output handle via C<print()>.  You may do this
however you see fit, so long as the end result is the same.

Note that unblessed references and globrefs are automatically turned
into I/O handles for you by C<decode()>, so you don't need to worry
about it.

Your method must return either C<undef> (to indicate failure),
or C<1> (to indicate success).
It may also throw an exception to indicate failure.

=cut

sub decode_it {
    die "attempted to use abstract 'decode_it' method!";
}

=item encode_it INSTREAM,OUTSTREAM

I<Abstract instance method.>
The back-end of the B<encode> method.  It takes an input handle
opened for reading (INSTREAM), and an output handle opened for
writing (OUTSTREAM).

If you are writing your own decoder subclass, you must override this
method in your class.  Your method should read from the input
handle via C<getline()> or C<read()>, encode this input, and print the
encoded data to the output handle via C<print()>.  You may do this
however you see fit, so long as the end result is the same.

Note that unblessed references and globrefs are automatically turned
into I/O handles for you by C<encode()>, so you don't need to worry
about it.

Your method must return either C<undef> (to indicate failure),
or C<1> (to indicate success).
It may also throw an exception to indicate failure.

=cut

sub encode_it {
    die "attempted to use abstract 'encode_it' method!";
}

=item filter IN, OUT, COMMAND...

I<Class method, utility.>
If your decoder involves an external program, you can invoke
them easily through this method.  The command must be a "filter": a
command that reads input from its STDIN (which will come from the IN argument)
and writes output to its STDOUT (which will go to the OUT argument).

For example, here's a decoder that un-gzips its data:

    sub decode_it {
	my ($self, $in, $out) = @_;
	$self->filter($in, $out, "gzip -d -");
    }

The usage is similar to IPC::Open2::open2 (which it uses internally),
so you can specify COMMAND as a single argument or as an array.

=cut

sub filter
{
	my ($self, $in, $out, @cmd) = @_;
	my $buf = '';

	### Open pipe:
	STDOUT->flush;  ### very important, or else we get duplicate output!

	my $kidpid = open2(my $child_out, my $child_in, @cmd) || die "@cmd: open2 failed: $!";

	### We have to use select() for doing both reading and writing.
	my $rsel = IO::Select->new( $child_out );
	my $wsel = IO::Select->new( $child_in  );

	while (1) {

		### Wait for one hour; if that fails, it's too bad.
		my ($read, $write) = IO::Select->select( $rsel, $wsel, undef, 3600);

		if( !defined $read && !defined $write ) {
			kill 1, $kidpid;
			waitpid $kidpid, 0;
			die "@cmd: select failed: $!";
		}

		### If can read from child:
		if( my $fh = shift @$read ) {
			if( $fh->sysread(my $buf, 1024) ) {
				$out->print($buf);
			} else {
				$rsel->remove($fh);
				$fh->close();
			}
		}

		### If can write to child:
		if( my $fh = shift @$write ) {
			if($in->read(my $buf, 1024)) {
				local $SIG{PIPE} = sub {
					warn "got SIGPIPE from @cmd";
					$wsel->remove($fh);
					$fh->close();
				};
				$fh->syswrite( $buf );
			} else {
				$wsel->remove($fh);
				$fh->close();
			}
		}

		### If both $child_out and $child_in are done:
		last unless ($rsel->count() || $wsel->count());
	}

	### Wait for it:
	waitpid($kidpid, 0) == $kidpid or die "@cmd: couldn't reap child $kidpid";
	### Check if it failed:
	$? == 0 or die "@cmd: bad exit status: \$? = $?";
	1;
}


#------------------------------

=item init ARGS...

I<Instance method.>
Do any necessary initialization of the new instance,
taking whatever arguments were given to C<new()>.
Should return the self object on success, undef on failure.

=cut

sub init {
    $_[0];
}

#------------------------------

=item install ENCODINGS...

I<Class method>.
Install this class so that each encoding in ENCODINGS is handled by it:

    install MyBase64Decoder 'base64', 'x-base64super';

You should not override this method.

=cut

sub install {
    my $class = shift;
    $DecoderFor{lc(shift @_)} = $class while (@_);
}

#------------------------------

=item uninstall ENCODINGS...

I<Class method>.
Uninstall support for encodings.  This is a way to turn off the decoding
of "experimental" encodings.  For safety, always use MIME::Decoder directly:

    uninstall MIME::Decoder 'x-uu', 'x-uuencode';

You should not override this method.

=cut

sub uninstall {
    shift;
    $DecoderFor{lc(shift @_)} = undef while (@_);
}

1;

__END__

#------------------------------

=back

=head1 DECODER SUBCLASSES

You don't need to C<"use"> any other Perl modules; the
following "standard" subclasses are included as part of MIME::Decoder:

     Class:                         Handles encodings:
     ------------------------------------------------------------
     MIME::Decoder::Binary          binary
     MIME::Decoder::NBit            7bit, 8bit
     MIME::Decoder::Base64          base64
     MIME::Decoder::QuotedPrint     quoted-printable

The following "non-standard" subclasses are also included:

     Class:                         Handles encodings:
     ------------------------------------------------------------
     MIME::Decoder::UU              x-uu, x-uuencode
     MIME::Decoder::Gzip64          x-gzip64            ** requires gzip!



=head1 NOTES

=head2 Input/Output handles

As of MIME-tools 2.0, this class has to play nice with the new MIME::Body
class... which means that input and output routines cannot just assume that
they are dealing with filehandles.

Therefore, all that MIME::Decoder and its subclasses require (and, thus,
all that they can assume) is that INSTREAMs and OUTSTREAMs are objects
which respond to a subset of the messages defined in the IO::Handle
interface; minimally:

      print
      getline
      read(BUF,NBYTES)

I<Thanks to Achim Bohnet for suggesting this more-generic I/O model.>


=head2 Writing a decoder

If you're experimenting with your own encodings, you'll probably want
to write a decoder.  Here are the basics:

=over 4

=item 1.

Create a module, like "MyDecoder::", for your decoder.
Declare it to be a subclass of MIME::Decoder.

=item 2.

Create the following instance methods in your class, as described above:

    decode_it
    encode_it
    init

=item 3.

In your application program, activate your decoder for one or
more encodings like this:

    require MyDecoder;

    install MyDecoder "7bit";   ### use MyDecoder to decode "7bit"
    install MyDecoder "x-foo";  ### also use MyDecoder to decode "x-foo"

=back

To illustrate, here's a custom decoder class for the C<quoted-printable>
encoding:

    package MyQPDecoder;

    @ISA = qw(MIME::Decoder);
    use MIME::Decoder;
    use MIME::QuotedPrint;

    ### decode_it - the private decoding method
    sub decode_it {
	my ($self, $in, $out) = @_;
	local $_;
	while (defined($_ = $in->getline)) {
	    my $decoded = decode_qp($_);
	    $out->print($decoded);
	}
	1;
    }

    ### encode_it - the private encoding method
    sub encode_it {
	my ($self, $in, $out) = @_;

	my ($buf, $nread) = ('', 0);
	while ($in->read($buf, 60)) {
	    my $encoded = encode_qp($buf);
	    $out->print($encoded);
	}
	1;
    }

That's it.  The task was pretty simple because the C<"quoted-printable">
encoding can easily be converted line-by-line... as can
even C<"7bit"> and C<"8bit"> (since all these encodings guarantee
short lines, with a max of 1000 characters).
The good news is: it is very likely that it will be similarly-easy to
write a MIME::Decoder for any future standard encodings.

The C<"binary"> decoder, however, really required block reads and writes:
see L<"MIME::Decoder::Binary"> for details.

=head1 SEE ALSO

L<MIME::Tools>, other MIME::Decoder subclasses.

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

1;
