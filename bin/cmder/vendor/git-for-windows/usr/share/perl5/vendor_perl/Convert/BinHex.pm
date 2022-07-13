package Convert::BinHex;


=head1 NAME

Convert::BinHex - extract data from Macintosh BinHex files

I<ALPHA WARNING: this code is currently in its Alpha release.
Things may change drastically until the interface is hammered out:
if you have suggestions or objections, please speak up now!>


=head1 SYNOPSIS

B<Simple functions:>

    use Convert::BinHex qw(binhex_crc macbinary_crc);

    # Compute HQX7-style CRC for data, pumping in old CRC if desired:
    $crc = binhex_crc($data, $crc);

    # Compute the MacBinary-II-style CRC for the data:
    $crc = macbinary_crc($data, $crc);

B<Hex to bin, low-level interface.>
Conversion is actually done via an object (L<"Convert::BinHex::Hex2Bin">)
which keeps internal conversion state:

    # Create and use a "translator" object:
    my $H2B = Convert::BinHex->hex2bin;    # get a converter object
    while (<STDIN>) {
	print $STDOUT $H2B->next($_);        # convert some more input
    }
    print $STDOUT $H2B->done;              # no more input: finish up

B<Hex to bin, OO interface.>
The following operations I<must> be done in the order shown!

    # Read data in piecemeal:
    $HQX = Convert::BinHex->open(FH=>\*STDIN) || die "open: $!";
    $HQX->read_header;                  # read header info
    @data = $HQX->read_data;            # read in all the data
    @rsrc = $HQX->read_resource;        # read in all the resource

B<Bin to hex, low-level interface.>
Conversion is actually done via an object (L<"Convert::BinHex::Bin2Hex">)
which keeps internal conversion state:

    # Create and use a "translator" object:
    my $B2H = Convert::BinHex->bin2hex;    # get a converter object
    while (<STDIN>) {
	print $STDOUT $B2H->next($_);        # convert some more input
    }
    print $STDOUT $B2H->done;              # no more input: finish up

B<Bin to hex, file interface.>  Yes, you can convert I<to> BinHex
as well as from it!

    # Create new, empty object:
    my $HQX = Convert::BinHex->new;

    # Set header attributes:
    $HQX->filename("logo.gif");
    $HQX->type("GIFA");
    $HQX->creator("CNVS");

    # Give it the data and resource forks (either can be absent):
    $HQX->data(Path => "/path/to/data");       # here, data is on disk
    $HQX->resource(Data => $resourcefork);     # here, resource is in core

    # Output as a BinHex stream, complete with leading comment:
    $HQX->encode(\*STDOUT);

B<PLANNED!!!! Bin to hex, "CAP" interface.>
I<Thanks to Ken Lunde for suggesting this>.

    # Create new, empty object from CAP tree:
    my $HQX = Convert::BinHex->from_cap("/path/to/root/file");
    $HQX->encode(\*STDOUT);


=head1 DESCRIPTION

B<BinHex> is a format used by Macintosh for transporting Mac files
safely through electronic mail, as short-lined, 7-bit, semi-compressed
data streams.  Ths module provides a means of converting those
data streams back into into binary data.


=head1 FORMAT

I<(Some text taken from RFC-1741.)>
Files on the Macintosh consist of two parts, called I<forks>:

=over 4

=item Data fork

The actual data included in the file.  The Data fork is typically the
only meaningful part of a Macintosh file on a non-Macintosh computer system.
For example, if a Macintosh user wants to send a file of data to a
user on an IBM-PC, she would only send the Data fork.

=item Resource fork

Contains a collection of arbitrary attribute/value pairs, including
program segments, icon bitmaps, and parametric values.

=back

Additional information regarding Macintosh files is stored by the
Finder in a hidden file, called the "Desktop Database".

Because of the complications in storing different parts of a
Macintosh file in a non-Macintosh filesystem that only handles
consecutive data in one part, it is common to convert the Macintosh
file into some other format before transferring it over the network.
The BinHex format squashes that data into transmittable ASCII as follows:

=over 4

=item 1.

The file is output as a B<byte stream> consisting of some basic header
information (filename, type, creator), then the data fork, then the
resource fork.

=item 2.

The byte stream is B<compressed> by looking for series of duplicated
bytes and representing them using a special binary escape sequence
(of course, any occurences of the escape character must also be escaped).

=item 3.

The compressed stream is B<encoded> via the "6/8 hemiola" common
to I<base64> and I<uuencode>: each group of three 8-bit bytes (24 bits)
is chopped into four 6-bit numbers, which are used as indexes into
an ASCII "alphabet".
(I assume that leftover bytes are zero-padded; documentation is thin).

=back

=cut

use strict;
use warnings;
use vars qw(@ISA @EXPORT_OK $VERSION $QUIET);
use integer;

use Carp;
use Exporter;
use FileHandle;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
		macbinary_crc
		binhex_crc
		);



our $VERSION = '1.125'; # VERSION

# My identity:
my $I = 'binhex:';

# Utility function:
sub min {
    my ($a, $b) = @_;
    ($a < $b) ? $a : $b;
}

# An array useful for CRC calculations that use 0x1021 as the "seed":
my @MAGIC = (
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
    0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
    0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
    0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
    0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
    0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
    0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
    0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
    0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
    0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
    0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
    0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
    0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
    0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
    0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
    0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
    0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
    0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
    0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
    0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
    0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
    0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
    0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0
);

# Ssssssssssshhhhhhhhhh:
$QUIET = 0;



#==============================

=head1 FUNCTIONS

=head2 CRC computation

=over 4

=cut

#------------------------------------------------------------

=item macbinary_crc DATA, SEED

Compute the MacBinary-II-style CRC for the given DATA, with the CRC
seeded to SEED.  Normally, you start with a SEED of 0, and you pump in
the previous CRC as the SEED if you're handling a lot of data one chunk
at a time.  That is:

    $crc = 0;
    while (<STDIN>) {
        $crc = macbinary_crc($_, $crc);
    }

I<Note:> Extracted from the I<mcvert> utility (Doug Moore, April '87),
using a "magic array" algorithm by Jim Van Verth for efficiency.
Converted to Perl5 by Eryq.  B<Untested.>

=cut

sub macbinary_crc {
    my $len = length($_[0]);
    my $crc = $_[1];
    my $i;
    for ($i = 0; $i < $len; $i++) {
	($crc ^= (vec($_[0], $i, 8) << 8)) &= 0xFFFF;
	$crc = ($crc << 8) ^ $MAGIC[$crc >> 8];
    }
    $crc;
}

#------------------------------------------------------------

=item binhex_crc DATA, SEED

Compute the HQX-style CRC for the given DATA, with the CRC seeded to SEED.
Normally, you start with a SEED of 0, and you pump in the previous CRC as
the SEED if you're handling a lot of data one chunk at a time.  That is:

    $crc = 0;
    while (<STDIN>) {
        $crc = binhex_crc($_, $crc);
    }

I<Note:> Extracted from the I<mcvert> utility (Doug Moore, April '87),
using a "magic array" algorithm by Jim Van Verth for efficiency.
Converted to Perl5 by Eryq.

=cut

sub binhex_crc {
    my $len = length($_[0]);
    my $crc = $_[1];
    if (! defined $crc) {
    	$crc = 0;
    }
    my $i;
    for ($i = 0; $i < $len; $i++) {
	my $ocrc = $crc;
	$crc = (((($crc & 0xFF) << 8) | vec($_[0], $i, 8))
		^ $MAGIC[$crc >> 8]) & 0xFFFF;
	## printf "CRCin = %04x, char = %02x (%c), CRCout = %04x\n",
	##        $ocrc, vec($_[0], $i, 8), ord(substr($_[0], $i, 1)), $crc;
    }
    $crc;
}


=back

=cut



#==============================

=head1 OO INTERFACE

=head2 Conversion

=over 4

=cut

#------------------------------------------------------------

=item bin2hex

I<Class method, constructor.>
Return a converter object.  Just creates a new instance of
L<"Convert::BinHex::Bin2Hex">; see that class for details.

=cut

sub bin2hex {
    return Convert::BinHex::Bin2Hex->new;
}

#------------------------------------------------------------

=item hex2bin

I<Class method, constructor.>
Return a converter object.  Just creates a new instance of
L<"Convert::BinHex::Hex2Bin">; see that class for details.

=cut

sub hex2bin {
    return Convert::BinHex::Hex2Bin->new;
}

=back

=cut



#==============================

=head2 Construction

=over 4

=cut

#------------------------------------------------------------

=item new PARAMHASH

I<Class method, constructor.>
Return a handle on a BinHex'able entity.  In general, the data and resource
forks for such an entity are stored in native format (binary) format.

Parameters in the PARAMHASH are the same as header-oriented method names,
and may be used to set attributes:

    $HQX = new Convert::BinHex filename => "icon.gif",
                               type    => "GIFB",
                               creator => "CNVS";

=cut

sub new {
    my ($class, %params) = @_;

    # Create object:
    my $self = bless {
	Data => new Convert::BinHex::Fork,      # data fork
	Rsrc => new Convert::BinHex::Fork,      # resource fork
    }, $class;   # basic object

    # Process params:
    my $method;
    foreach $method (qw(creator	filename flags requires type version
			software_version)){
	$self->$method($params{$method}) if exists($params{$method});
    }
    $self;
}

#------------------------------------------------------------

=item open PARAMHASH

I<Class method, constructor.>
Return a handle on a new BinHex'ed stream, for parsing.
Params are:

=over 4

=item Data

Input a HEX stream from the given data.  This can be a scalar, or a
reference to an array of scalars.

=item Expr

Input a HEX stream from any open()able expression.  It will be opened and
binmode'd, and the filehandle will be closed either on a C<close()>
or when the object is destructed.

=item FH

Input a HEX stream from the given filehandle.

=item NoComment

If true, the parser should not attempt to skip a leading "(This file...)"
comment.  That means that the first nonwhite characters encountered
must be the binhex'ed data.

=back

=cut

sub open {
    my $self = shift;
    my %params = @_;

    # Create object:
    ref($self) or $self = $self->new;

    # Set up input:
    my $data;
    if ($params{FH}) {
	$self->{FH} = Convert::BinHex::IO_Handle->wrap($params{FH});
    }
    elsif ($params{Expr}) {
	$self->{FH} = FileHandle->new($params{Expr}) or
	    croak "$I can't open $params{Expr}: $!\n";
	$self->{FH} = Convert::BinHex::IO_Handle->wrap($self->{FH});
    }
    elsif ($params{Data}) {
	if (!ref($data = $params{Data})) {   # scalar
	    $self->{FH} = Convert::BinHex::IO_Scalar->wrap(\$data);
	}
	elsif (ref($data) eq 'ARRAY') {
	    $data = join('', @$data);
	    $self->{FH} = Convert::BinHex::IO_Scalar->wrap(\$data);
	}
    }
    $self->{FH} or croak "$I missing a valid input source\n";

    # Comments?
    $self->{CommentRead} = $params{NoComment};

    # Reset the converter!
    $self->{H2B} = Convert::BinHex::Hex2Bin->new;
    $self;
}


=back

=cut




#==============================

=head2 Get/set header information

=over 4

=cut

#------------------------------

=item creator [VALUE]

I<Instance method.>
Get/set the creator of the file.  This is a four-character
string (though I don't know if it's guaranteed to be printable ASCII!)
that serves as part of the Macintosh's version of a MIME "content-type".

For example, a document created by "Canvas" might have
creator C<"CNVS">.

=cut

sub creator  { (@_ > 1) ? ($_[0]->{Creator}  = $_[1]) : $_[0]->{Creator} }

#------------------------------

=item data [PARAMHASH]

I<Instance method.>
Get/set the data fork.  Any arguments are passed into the
new() method of L<"Convert::BinHex::Fork">.

=cut

sub data {
    my $self = shift;
    @_ ? $self->{Data} = Convert::BinHex::Fork->new(@_) : $self->{Data};
}

#------------------------------

=item filename [VALUE]

I<Instance method.>
Get/set the name of the file.

=cut

sub filename { (@_ > 1) ? ($_[0]->{Filename} = $_[1]) : $_[0]->{Filename} }

#------------------------------

=item flags [VALUE]

I<Instance method.>
Return the flags, as an integer.  Use bitmasking to get as the values
you need.

=cut

sub flags    { (@_ > 1) ? ($_[0]->{Flags}    = $_[1]) : $_[0]->{Flags} }

#------------------------------

=item header_as_string

Return a stringified version of the header that you might
use for logging/debugging purposes.  It looks like this:

    X-HQX-Software: BinHex 4.0 (Convert::BinHex 1.102)
    X-HQX-Filename: Something_new.eps
    X-HQX-Version: 0
    X-HQX-Type: EPSF
    X-HQX-Creator: ART5
    X-HQX-Data-Length: 49731
    X-HQX-Rsrc-Length: 23096

As some of you might have guessed, this is RFC-822-style, and
may be easily plunked down into the middle of a mail header, or
split into lines, etc.

=cut

sub header_as_string {
    my $self = shift;
    my @h;
    push @h, "X-HQX-Software: " .
	     "BinHex " . ($self->requires || '4.0') .
	     " (Convert::BinHex $VERSION)";
    push @h, "X-HQX-Filename: " . $self->filename;
    push @h, "X-HQX-Version: "  . $self->version;
    push @h, "X-HQX-Type: "     . $self->type;
    push @h, "X-HQX-Creator: "  . $self->creator;
    push @h, "X-HQX-Flags: "    . sprintf("%x", $self->flags);
    push @h, "X-HQX-Data-Length: " . $self->data->length;
    push @h, "X-HQX-Rsrc-Length: " . $self->resource->length;
    push @h, "X-HQX-CRC: "      . sprintf("%x", $self->{HdrCRC});
    return join("\n", @h) . "\n";
}

#------------------------------

=item requires [VALUE]

I<Instance method.>
Get/set the software version required to convert this file, as
extracted from the comment that preceded the actual binhex'ed
data; e.g.:

    (This file must be converted with BinHex 4.0)

In this case, after parsing in the comment, the code:

    $HQX->requires;

would get back "4.0".

=cut

sub requires  {
    (@_ > 1) ? ($_[0]->{Requires}  = $_[1]) : $_[0]->{Requires}
}
*software_version = \&requires;

#------------------------------

=item resource [PARAMHASH]

I<Instance method.>
Get/set the resource fork.  Any arguments are passed into the
new() method of L<"Convert::BinHex::Fork">.

=cut

sub resource {
    my $self = shift;
    @_ ? $self->{Rsrc} = Convert::BinHex::Fork->new(@_) : $self->{Rsrc};
}

#------------------------------

=item type [VALUE]

I<Instance method.>
Get/set the type of the file.  This is a four-character
string (though I don't know if it's guaranteed to be printable ASCII!)
that serves as part of the Macintosh's version of a MIME "content-type".

For example, a GIF89a file might have type C<"GF89">.

=cut

sub type  { (@_ > 1) ? ($_[0]->{Type}  = $_[1]) : $_[0]->{Type} }

#------------------------------

=item version [VALUE]

I<Instance method.>
Get/set the version, as an integer.

=cut

sub version  { (@_ > 1) ? ($_[0]->{Version}  = $_[1]) : $_[0]->{Version} }


=back

=cut

### OBSOLETE!!!
sub data_length     { shift->data->length(@_) }
sub resource_length { shift->resource->length(@_) }




#==============================

=head2 Decode, high-level

=over 4

=cut

#------------------------------------------------------------

=item read_comment

I<Instance method.>
Skip past the opening comment in the file, which is of the form:

   (This file must be converted with BinHex 4.0)

As per RFC-1741, I<this comment must immediately precede the BinHex data,>
and any text before it will be ignored.

I<You don't need to invoke this method yourself;> C<read_header()> will
do it for you.  After the call, the version number in the comment is
accessible via the C<requires()> method.

=cut

sub read_comment {
    my $self = shift;
    return 1 if ($self->{CommentRead});   # prevent accidents
    local($_);
    while (defined($_ = $self->{FH}->getline)) {
	chomp;
	if (/^\(This file must be converted with BinHex ([\d\.]+).*\)\s*$/i) {
	    $self->requires($1);
	    return $self->{CommentRead} = 1;
	}
    }
    croak "$I comment line (This file must be converted with BinHex...) ".
	  "not found\n";
}

#------------------------------------------------------------

=item read_header

I<Instance method.>
Read in the BinHex file header.  You must do this first!

=cut

sub read_header {
    my $self = shift;
    return 1 if ($self->{HeaderRead});   # prevent accidents

    # Skip comment:
    $self->read_comment;

    # Get header info:
    $self->filename ($self->read_str($self->read_byte));
    $self->version  ($self->read_byte);
    $self->type     ($self->read_str(4));
    $self->creator  ($self->read_str(4));
    $self->flags    ($self->read_short);
    $self->data_length     ($self->read_long);
    $self->resource_length ($self->read_long);
    $self->{HdrCRC}   = $self->read_short;
    $self->{HeaderRead} = 1;
}

#------------------------------------------------------------
#
# _read_fork
#
# I<Instance method, private.>
# Read in a fork.
#

sub _read_fork {
    my $self = shift;

    # Pass in call if array context:
    if (wantarray) {
	local($_);
	my @all;
	push @all, $_ while (defined($_ = $self->_read_fork(@_)));
	return @all;
    }

    # Get args:
    my ($fork, $n) = @_;
    if($self->{$fork}->length == 0) {
    	$self->{$fork}->crc($self->read_short);
    	return undef;
    }
    defined($n) or $n = 2048;

    # Reset pointer into fork if necessary:
    if (!defined($self->{$fork}{Ptr})) {
	$self->{$fork}{Ptr} = 0;
	$self->{CompCRC} = 0;
    }

    # Check for EOF:
    return undef if ($self->{$fork}{Ptr} >= $self->{$fork}->length);

    # Read up to, but not exceeding, the number of bytes left in the fork:
    my $n2read = min($n, ($self->{$fork}->length - $self->{$fork}{Ptr}));
    my $data = $self->read_str($n2read);
    $self->{$fork}{Ptr} += length($data);

    # If we just read the last byte, read the CRC also:
    if (($self->{$fork}{Ptr} == $self->{$fork}->length) &&    # last byte
	!defined($self->{$fork}->crc)) {                   # no CRC
	my $comp_CRC;

	# Move computed CRC forward by two zero bytes, and grab the value:
	if ($self->{CheckCRC}) {
	    $self->{CompCRC} = binhex_crc("\000\000", $self->{CompCRC});
	}

	# Get CRC as stored in file:
	$self->{$fork}->crc($self->read_short);          # get stored CRC

	# Compare, and note corruption if detected:
	if ($self->{CheckCRC} and ($self->{$fork}->crc != $comp_CRC)) {
	    &Carp::carp("CRCs do not match: corrupted data?") unless $QUIET;
	    $self->{Corrupted} = 1;
	}
    }

    # Return the bytes:
    $data;
}

#------------------------------------------------------------

=item read_data [NBYTES]

I<Instance method.>
Read information from the data fork.  Use it in an array context to
slurp all the data into an array of scalars:

    @data = $HQX->read_data;

Or use it in a scalar context to get the data piecemeal:

    while (defined($data = $HQX->read_data)) {
       # do stuff with $data
    }

The NBYTES to read defaults to 2048.

=cut

sub read_data {
    shift->_read_fork('Data',@_);
}

#------------------------------------------------------------

=item read_resource [NBYTES]

I<Instance method.>
Read in all/some of the resource fork.
See C<read_data()> for usage.

=cut

sub read_resource {
    shift->_read_fork('Rsrc',@_);
}

=back

=cut



#------------------------------------------------------------
#
# read BUFFER, NBYTES
#
# Read the next NBYTES (decompressed) bytes from the input stream
# into BUFFER.  Returns the number of bytes actually read, and
# undef on end of file.
#
# I<Note:> the calling style mirrors the IO::Handle read() function.

my $READBUF = '';
sub read {
    my ($self, $n) = ($_[0], $_[2]);
    $_[1] = '';            # just in case
    my $FH = $self->{FH};
    local($^W) = 0;

    # Get more BIN bytes until enough or EOF:
    my $bin;
    while (length($self->{BIN_QUEUE}) < $n) {
	$FH->read($READBUF, 4096) or last;
	$self->{BIN_QUEUE} .= $self->{H2B}->next($READBUF);   # save BIN
    }

    # We've got as many bytes as we're gonna get:
    $_[1] = substr($self->{BIN_QUEUE}, 0, $n);
    $self->{BIN_QUEUE} = substr($self->{BIN_QUEUE}, $n);

    # Advance the CRC:
    if ($self->{CheckCRC}) {
	$self->{CompCRC} = binhex_crc($_[1], $self->{CompCRC});
    }
    return length($_[1]);
}

#------------------------------------------------------------
#
# read_str NBYTES
#
# Read and return the next NBYTES bytes, or die with "unexpected end of file"

sub read_str {
    my ($self, $n) = @_;
    my $buf = '';
    $self->read($buf, $n);
    croak "$I unexpected end of file (wanted $n, got " . length($buf) . ")\n"
	if ($n and (length($buf) < $n));
    return $buf;
}

#------------------------------------------------------------
#
# read_byte
# read_short
# read_long
#
# Read 1, 2, or 4 bytes, and return the value read as an unsigned integer.
# If not that many bytes remain, die with "unexpected end of file";

sub read_byte {
    ord($_[0]->read_str(1));
}

sub read_short {
    unpack("n", $_[0]->read_str(2));
}

sub read_long {
    unpack("N", $_[0]->read_str(4));
}









#==============================

=head2 Encode, high-level

=over 4

=cut

#------------------------------------------------------------

=item encode OUT

Encode the object as a BinHex stream to the given output handle OUT.
OUT can be a filehandle, or any blessed object that responds to a
C<print()> message.

The leading comment is output, using the C<requires()> attribute.

=cut

sub encode {
    my $self = shift;

    # Get output handle:
    my $OUT = shift; $OUT = wrap Convert::BinHex::IO_Handle $OUT;

    # Get a new converter:
    my $B2H = $self->bin2hex;

    # Comment:
    $OUT->print("(This file must be converted with BinHex ",
		($self->requires || '4.0'),
		")\n");

    # Build header in core:
    my @hdrs;
    my $flen = length($self->filename);
    push @hdrs, pack("C", $flen);
    push @hdrs, pack("a$flen", $self->filename);
    push @hdrs, pack('C', $self->version);
    push @hdrs, pack('a4', $self->type    || '????');
    push @hdrs, pack('a4', $self->creator || '????');
    push @hdrs, pack('n',  $self->flags   || 0);
    push @hdrs, pack('N',  $self->data->length        || 0);
    push @hdrs, pack('N',  $self->resource->length    || 0);
    my $hdr = join '', @hdrs;

    # Compute the header CRC:
    my $crc = binhex_crc("\000\000", binhex_crc($hdr, 0));

    # Output the header (plus its CRC):
    $OUT->print($B2H->next($hdr . pack('n', $crc)));

    # Output the data fork:
    $self->data->encode($OUT, $B2H);

    # Output the resource fork:
    $self->resource->encode($OUT, $B2H);

    # Finish:
    $OUT->print($B2H->done);
    1;
}

=back

=cut



#==============================

=head1 SUBMODULES

=cut

#============================================================
#
package Convert::BinHex::Bin2Hex;
#
#============================================================

=head2 Convert::BinHex::Bin2Hex

A BINary-to-HEX converter.  This kind of conversion requires
a certain amount of state information; it cannot be done by
just calling a simple function repeatedly.  Use it like this:

    # Create and use a "translator" object:
    my $B2H = Convert::BinHex->bin2hex;    # get a converter object
    while (<STDIN>) {
	print STDOUT $B2H->next($_);          # convert some more input
    }
    print STDOUT $B2H->done;               # no more input: finish up

    # Re-use the object:
    $B2H->rewind;                 # ready for more action!
    while (<MOREIN>) { ...

On each iteration, C<next()> (and C<done()>) may return either
a decent-sized non-empty string (indicating that more converted data
is ready for you) or an empty string (indicating that the converter
is waiting to amass more input in its private buffers before handing
you more stuff to output.

Note that C<done()> I<always> converts and hands you whatever is left.

This may have been a good approach.  It may not.  Someday, the converter
may also allow you give it an object that responds to read(), or
a FileHandle, and it will do all the nasty buffer-filling on its own,
serving you stuff line by line:

    # Someday, maybe...
    my $B2H = Convert::BinHex->bin2hex(\*STDIN);
    while (defined($_ = $B2H->getline)) {
	print STDOUT $_;
    }

Someday, maybe.  Feel free to voice your opinions.

=cut

#------------------------------
#
# new

sub new {
    my $self = bless {}, shift;
    return $self->rewind;
}

#------------------------------
#
# rewind

sub rewind {
    my $self = shift;
    $self->{CBIN} = ' ' x 2048; $self->{CBIN} = ''; # BIN waiting for xlation
    $self->{HEX}  = ' ' x 2048; $self->{HEX}  = ''; # HEX waiting for output
    $self->{LINE} = 0;       # current line of output
    $self->{EOL} = "\n";
    $self;
}

#------------------------------
#
# next MOREDATA

sub next { shift->_next(0, @_) }

#------------------------------
#
# done

sub done { shift->_next(1) }

#------------------------------
#
# _next ATEOF, [MOREDATA]
#
# Instance method, private.  Supply more data, and get any more output.
# Returns the empty string often, if not enough output has accumulated.

sub _next {
    my $self = shift;
    my $eof = shift;

    # Get the BINary data to process this time round, re-queueing the rest:
    # Handle EOF and non-EOF conditions separately:
    my $new_bin;
    if ($eof) {                      # No more BINary input...
	# Pad the queue with nuls to exactly 3n characters:
	$self->{CBIN} .= ("\x00" x ((3 - length($self->{CBIN}) % 3) % 3))
    }
    else {                           # More BINary input...
	# "Compress" new stuff, and add it to the queue:
	($new_bin = $_[0]) =~ s/\x90/\x90\x00/g;
	$self->{CBIN} .= $new_bin;

	# Return if not enough to bother with:
	return '' if (length($self->{CBIN}) < 2048);
    }

    # ...At this point, QUEUE holds compressed binary which we will attempt
    # to convert to some HEX characters...

    # Trim QUEUE to exactly 3n characters, saving the excess:
    my $requeue = '';
    $requeue .= chop($self->{CBIN}) while (length($self->{CBIN}) % 3);

    # Uuencode, adding stuff to hex:
    my $hex = ' ' x 2048; $hex = '';
    pos($self->{CBIN}) = 0;
    while ($self->{CBIN} =~ /(.{1,45})/gs) {
	$hex .= substr(pack('u', $1), 1);
	chop($hex);
    }
    $self->{CBIN} = reverse($requeue);     # put the excess back on the queue

    # Switch to BinHex alphabet:
    $hex =~ tr
        {` -_}
        {!!"#$%&'()*+,\x2D012345689@ABCDEFGHIJKLMNPQRSTUVXYZ[`abcdefhijklmpqr};

    # Prepend any HEX we have queued from the last time:
    $hex = (($self->{LINE}++ ? '' : ':') .   # start with ":" pad?
	    $self->{HEX} .              # any output in the queue?
	    $hex);

    # Break off largest chunk of 64n characters, put remainder back in queue:
    my $rem = length($hex) % 64;
    $self->{HEX} = ($rem ? substr($hex, -$rem) : '');
    $hex = substr($hex, 0, (length($hex)-$rem));

    # Put in an EOL every 64'th character:
    $hex =~ s{(.{64})}{$1$self->{EOL}}sg;

    # No more input?  Then tack on the remainder now:
    if ($eof) {
        $hex .= $self->{HEX} . ":" . ($self->{EOL} ? $self->{EOL} : '');
    }

    # Done!
    $hex;
}




#============================================================
#
package Convert::BinHex::Hex2Bin;
#
#============================================================

=head2 Convert::BinHex::Hex2Bin

A HEX-to-BINary converter. This kind of conversion requires
a certain amount of state information; it cannot be done by
just calling a simple function repeatedly.  Use it like this:

    # Create and use a "translator" object:
    my $H2B = Convert::BinHex->hex2bin;    # get a converter object
    while (<STDIN>) {
	print STDOUT $H2B->next($_);          # convert some more input
    }
    print STDOUT $H2B->done;               # no more input: finish up

    # Re-use the object:
    $H2B->rewind;                 # ready for more action!
    while (<MOREIN>) { ...

On each iteration, C<next()> (and C<done()>) may return either
a decent-sized non-empty string (indicating that more converted data
is ready for you) or an empty string (indicating that the converter
is waiting to amass more input in its private buffers before handing
you more stuff to output.

Note that C<done()> I<always> converts and hands you whatever is left.

Note that this converter does I<not> find the initial
"BinHex version" comment.  You have to skip that yourself.  It
only handles data between the opening and closing C<":">.

=cut

#------------------------------
#
# new

sub new {
    my $self = bless {}, shift;
    return $self->rewind;
}

#------------------------------
#
# rewind

sub rewind {
    my $self = shift;
    $self->hex2comp_rewind;
    $self->comp2bin_rewind;
    $self;
}

#------------------------------
#
# next MOREDATA

sub next {
    my $self = shift;
    $_[0] =~ s/\s//g if (defined($_[0]));      # more input
    return $self->comp2bin_next($self->hex2comp_next($_[0]));
}

#------------------------------
#
# done

sub done {
    return "";
}

#------------------------------
#
# hex2comp_rewind

sub hex2comp_rewind {
    my $self = shift;
    $self->{HEX} = '';
}

#------------------------------
#
# hex2comp_next HEX
#
# WARNING: argument is modified destructively for efficiency!!!!

sub hex2comp_next {
    my $self = shift;
    ### print "hex2comp: newhex = $newhex\n";

    # Concat new with queue, and kill any padding:
    my $hex = $self->{HEX} . (defined($_[0]) ? $_[0] : '');
    if (index($hex, ':') >= 0) {
	$hex =~ s/^://;                                 # start of input
	if ($hex =~ s/:\s*\Z//) {                       # end of input
	    my $leftover = (length($hex) % 4);                # need to pad!
	    $hex .= "\000" x (4 - $leftover)  if $leftover;   # zero pad
	}
    }

    # Get longest substring of length 4n possible; put rest back on queue:
    my $rem = length($hex) % 4;
    $self->{HEX} = ($rem ? substr($hex, -$rem) : '');
    for (; $rem; --$rem) { chop $hex };
    return undef if ($hex eq '');            # nothing to do!

    # Convert to uuencoded format:
    $hex =~ tr
        {!"#$%&'()*+,\x2D012345689@ABCDEFGHIJKLMNPQRSTUVXYZ[`abcdefhijklmpqr}
        { -_};

    # Now, uudecode:
    my $comp = '';
    my $len;
    my $up;
    local($^W) = 0;       ### KLUDGE
    while ($hex =~ /\G(.{1,60})/gs) {
	$len = chr(32 + ((length($1)*3)>>2));  # compute length byte
	$comp .= unpack("u", $len . $1 );      # uudecode
    }

    # We now have the compressed binary... expand it:
    ### print "hex2comp: comp = $comp\n";
    $comp;
}

#------------------------------
#
# comp2bin_rewind

sub comp2bin_rewind {
    my $self = shift;
    $self->{COMP} = '';
    $self->{LASTC} = '';
}

#------------------------------
#
# comp2bin_next COMP
#
# WARNING: argument is modified destructively for efficiency!!!!

sub comp2bin_next {
    my $self = shift;

    # Concat new with queue... anything to do?
    my $comp = $self->{COMP} . (defined($_[0]) ? $_[0] : '');
    return undef if ($comp eq '');

    # For each character in compressed string...
    $self->{COMP} = '';
    my $lastc = $self->{LASTC};      # speed hack
    my $exp = '';       # expanded string
    my $i;
    my ($c, $n);
    for ($i = 0; $i < length($comp); $i++) {
	if (($c = substr($comp, $i, 1)) eq "\x90") {    # MARK
	    ### print "c = MARK\n";
	    unless (length($n = substr($comp, ++$i, 1))) {
		$self->{COMP} = "\x90";
		last;
	    }
	    ### print "n = ", ord($n), "; lastc = ", ord($lastc), "\n";
	    $exp .= ((ord($n) ? ($lastc x (ord($n)-1))  # repeat last char
		              : ($lastc = "\x90")));    # literal MARK
	}
	else {                                          # other CHAR
	    ### print "c = ", ord($c), "\n";
	    $exp .= ($lastc = $c);
	}
	### print "exp is now $exp\n";
    }

    # Either hit EOS, or there's a MARK char at the very end:
    $self->{LASTC} = $lastc;
    ### print "leaving with lastc=$lastc and comp=$self->{COMP}\n";
    ### print "comp2bin: exp = $exp\n";
    $exp;
}






#============================================================
#
package Convert::BinHex::Fork;
#
#============================================================

=head2 Convert::BinHex::Fork

A fork in a Macintosh file.

    # How to get them...
    $data_fork = $HQX->data;      # get the data fork
    $rsrc_fork = $HQX->resource;  # get the resource fork

    # Make a new fork:
    $FORK = Convert::BinHex::Fork->new(Path => "/tmp/file.data");
    $FORK = Convert::BinHex::Fork->new(Data => $scalar);
    $FORK = Convert::BinHex::Fork->new(Data => \@array_of_scalars);

    # Get/set the length of the data fork:
    $len = $FORK->length;
    $FORK->length(170);        # this overrides the REAL value: be careful!

    # Get/set the path to the underlying data (if in a disk file):
    $path = $FORK->path;
    $FORK->path("/tmp/file.data");

    # Get/set the in-core data itself, which may be a scalar or an arrayref:
    $data = $FORK->data;
    $FORK->data($scalar);
    $FORK->data(\@array_of_scalars);

    # Get/set the CRC:
    $crc = $FORK->crc;
    $FORK->crc($crc);

=cut


# Import some stuff into our namespace:
*binhex_crc = \&Convert::BinHex::binhex_crc;

#------------------------------
#
# new PARAMHASH

sub new {
    my ($class, %params) = @_;
    bless \%params, $class;
}

#------------------------------
#
# length [VALUE]

sub length {
    my $self = shift;

    # Set length?
    $self->{Length} = shift if @_;

    # Return explicit length, if any
    return $self->{Length} if defined($self->{Length});

    # Compute it:
    if (defined($self->{Path})) {
	return (-s $self->{Path});
    }
    elsif (!ref($self->{Data})) {
	return length($self->{Data});
    }
    elsif (ref($self->{Data} eq 'ARRAY')) {
	my $n = 0;
	foreach (@{$self->{Data}}) { $n += length($_) }
	return $n;
    }
    return undef;          # unknown!
}

#------------------------------
#
# path [VALUE]

sub path {
    my $self = shift;
    if (@_) { $self->{Path} = shift; delete $self->{Data} }
    $self->{Path};
}

#------------------------------
#
# data [VALUE]

sub data {
    my $self = shift;
    if (@_) { $self->{Data} = shift; delete $self->{Path} }
    $self->{Data};
}

#------------------------------
#
# crc [VALUE]

sub crc {
    my $self = shift;
    @_ ? $self->{CRC} = shift : $self->{CRC};
}

#------------------------------
#
# encode OUT, B2H
#
# Instance method, private.  Encode this fork as part of a BinHex stream.
# It will be printed to handle OUT using the binhexer B2H.

sub encode {
    my ($self, $OUT, $B2H) = @_;
    my $buf = '';
    require POSIX if $^O||'' eq "MacOS";
    require Fcntl if $^O||'' eq "MacOS";
    my $fd;

    # Reset the CRC:
    $self->{CRC} = 0;

    # Output the data, calculating the CRC as we go:
    if (defined($self->{Path})) { # path to fork file
        if ($^O||'' eq "MacOS" and $self->{Fork} eq "RSRC") {
    	    $fd = POSIX::open($self->{Path},&POSIX::O_RDONLY | &Fcntl::O_RSRC);
	    while (POSIX::read($fd, $buf, 2048) > 0) {
		$self->{CRC} = binhex_crc($buf, $self->{CRC});
		$OUT->print($B2H->next($buf));
	    }
	    POSIX::close($fd);
        }
	else {
	    open FORK, $self->{Path} or die "$self->{Path}: $!";
	    while (read(\*FORK, $buf, 2048)) {
		$self->{CRC} = binhex_crc($buf, $self->{CRC});
		$OUT->print($B2H->next($buf));
	    }
	    close FORK;
	}
    }
    elsif (!defined($self->{Data})) {        # nothing!
	&Carp::carp("no data in fork!") unless $Convert::BinHex::QUIET;
    }
    elsif (!ref($self->{Data})) {            # scalar
	$self->{CRC} = binhex_crc($self->{Data}, $self->{CRC});
	$OUT->print($B2H->next($self->{Data}));
    }
    elsif (ref($self->{Data}) eq 'ARRAY') {  # array of scalars
	foreach $buf (@{$self->{Data}}) {
	    $self->{CRC} = binhex_crc($buf, $self->{CRC});
	    $OUT->print($B2H->next($buf));
	}
    }
    else {
	&Carp::croak("bad/unsupported data in fork");
    }

    # Finish the CRC, and output it:
    $self->{CRC} = binhex_crc("\000\000", $self->{CRC});
    $OUT->print($B2H->next(pack("n", $self->{CRC})));
    1;
}




#============================================================
#
package Convert::BinHex::IO_Handle;
#
#============================================================

# Wrap a non-object filehandle inside a blessed, printable interface:
# Does nothing if the given $fh is already a blessed object.
sub wrap {
    my ($class, $fh) = @_;
    no strict 'refs';
    $fh or $fh = select;        # no filehandle means selected one
    ref($fh) or $fh = \*$fh;    # scalar becomes a globref
    return $fh if (ref($fh) and (ref($fh) !~ /^(GLOB|FileHandle)$/));
    bless \$fh, $class;         # wrap it in a printable interface
}
sub print {
    my $FH = ${shift(@_)};
    print $FH @_;
}
sub getline {
    my $FH = ${shift(@_)};
    scalar(<$FH>);
}
sub read {
    read ${$_[0]}, $_[1], $_[2];
}



#============================================================
#
package Convert::BinHex::IO_Scalar;
#
#============================================================

# Wrap a scalar inside a blessed, printable interface:
sub wrap {
    my ($class, $scalarref) = @_;
    defined($scalarref) or $scalarref = \"";
    pos($$scalarref) = 0;
    bless $scalarref, $class;
}
sub print {
    my $self = shift;
    $$self .= join('', @_);
    1;
}
sub getline {
    my $self = shift;
    ($$self =~ /\G(.*?\n?)/g) or return undef;
    return $1;
}
sub read {
    my $self = shift;
    $_[0] = substr($$self, pos($$self), $_[1]);
    pos($$self) += $_[1];
    return length($_[0]);
}



#==============================

=head1 UNDER THE HOOD

=head2 Design issues

=over 4

=item BinHex needs a stateful parser

Unlike its cousins I<base64> and I<uuencode>, BinHex format is not
amenable to being parsed line-by-line.  There appears to be no
guarantee that lines contain 4n encoded characters... and even if there
is one, the BinHex compression algorithm interferes: even when you
can I<decode> one line at a time, you can't necessarily
I<decompress> a line at a time.

For example: a decoded line ending with the byte C<\x90> (the escape
or "mark" character) is ambiguous: depending on the next decoded byte,
it could mean a literal C<\x90> (if the next byte is a C<\x00>), or
it could mean n-1 more repetitions of the previous character (if
the next byte is some nonzero C<n>).

For this reason, a BinHex parser has to be somewhat stateful: you
cannot have code like this:

    #### NO! #### NO! #### NO! #### NO! #### NO! ####
    while (<STDIN>) {            # read HEX
        print hexbin($_);          # convert and write BIN
    }

unless something is happening "behind the scenes" to keep track of
what was last done.  I<The dangerous thing, however, is that this
approach will B<seem> to work, if you only test it on BinHex files
which do not use compression and which have 4n HEX characters
on each line.>

Since we have to be stateful anyway, we use the parser object to
keep our state.


=item We need to be handle large input files

Solutions that demand reading everything into core don't cut
it in my book.  The first MPEG file that comes along can louse
up your whole day.  So, there are no size limitations in this
module: the data is read on-demand, and filehandles are always
an option.


=item Boy, is this slow!

A lot of the byte-level manipulation that has to go on, particularly
the CRC computing (which involves intensive bit-shifting and masking)
slows this module down significantly.  What is needed perhaps is an
I<optional> extension library where the slow pieces can be done more
quickly... a Convert::BinHex::CRC, if you will.  Volunteers, anyone?

Even considering that, however, it's slower than I'd like.  I'm
sure many improvements can be made in the HEX-to-BIN end of things.
No doubt I'll attempt some as time goes on...

=back



=head2 How it works

Since BinHex is a layered format, consisting of...

      A Macintosh file [the "BIN"]...
         Encoded as a structured 8-bit bytestream, then...
            Compressed to reduce duplicate bytes, then...
               Encoded as 7-bit ASCII [the "HEX"]

...there is a layered parsing algorithm to reverse the process.
Basically, it works in a similar fashion to stdio's fread():

       0. There is an internal buffer of decompressed (BIN) data,
          initially empty.
       1. Application asks to read() n bytes of data from object
       2. If the buffer is not full enough to accommodate the request:
            2a. The read() method grabs the next available chunk of input
                data (the HEX).
            2b. HEX data is converted and decompressed into as many BIN
                bytes as possible.
            2c. BIN bytes are added to the read() buffer.
            2d. Go back to step 2a. until the buffer is full enough
                or we hit end-of-input.

The conversion-and-decompression algorithms need their own internal
buffers and state (since the next input chunk may not contain all the
data needed for a complete conversion/decompression operation).
These are maintained in the object, so parsing two different
input streams simultaneously is possible.


=head1 WARNINGS

Only handles C<Hqx7> files, as per RFC-1741.

Remember that Macintosh text files use C<"\r"> as end-of-line:
this means that if you want a textual file to look normal on
a non-Mac system, you probably want to do this to the data:

    # Get the data, and output it according to normal conventions:
    foreach ($HQX->read_data) { s/\r/\n/g; print }


=head1 AUTHOR AND CREDITS

Maintained by Stephen Nelson <stephenenelson@mac.com>

Written by Eryq, F<http://www.enteract.com/~eryq> / F<eryq@enteract.com>

Support for native-Mac conversion, I<plus> invaluable contributions in 
Alpha Testing, I<plus> a few patches, I<plus> the baseline binhex/debinhex
programs, were provided by Paul J. Schinder (NASA/GSFC).

Ken Lunde (Adobe) suggested incorporating the CAP file representation.


=head1 LICENSE

Copyright (c) 1997 by Eryq.  All rights reserved.  This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

This software comes with B<NO WARRANTY> of any kind.
See the COPYING file in the distribution for details.

=cut

1;

__END__

my $HQX = new Convert::BinHex
    version => 0,
    filename=>"s.gif",
    type    => "GIF8",
    creator => "PCBH",
    flags => 0xFFFF
    ;

$HQX->data(Path=>"/home/eryq/s.gif");
$HQX->resource(Path=>"/etc/issue");

#$HQX->data(Data=>"123456789");
#$HQX->resource(Data=>'');

$HQX->encode(\*STDOUT);

1;









