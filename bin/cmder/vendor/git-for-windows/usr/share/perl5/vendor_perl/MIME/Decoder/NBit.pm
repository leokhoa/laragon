package MIME::Decoder::NBit;
use strict;
use warnings;


=head1 NAME

MIME::Decoder::NBit - encode/decode a "7bit" or "8bit" stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.


=head1 DESCRIPTION

This is a MIME::Decoder subclass for the C<7bit> and C<8bit> content
transfer encodings.  These are not "encodings" per se: rather, they
are simply assertions of the content of the message.
From RFC-2045 Section 6.2.:

   Three transformations are currently defined: identity, the "quoted-
   printable" encoding, and the "base64" encoding.  The domains are
   "binary", "8bit" and "7bit".

   The Content-Transfer-Encoding values "7bit", "8bit", and "binary" all
   mean that the identity (i.e. NO) encoding transformation has been
   performed.  As such, they serve simply as indicators of the domain of
   the body data, and provide useful information about the sort of
   encoding that might be needed for transmission in a given transport
   system.  

In keeping with this: as of MIME-tools 4.x, 
I<this class does no modification of its input when encoding;> 
all it does is attempt to I<detect violations> of the 7bit/8bit assertion, 
and issue a warning (one per message) if any are found.


=head2 Legal 7bit data

RFC-2045 Section 2.7 defines legal C<7bit> data:

   "7bit data" refers to data that is all represented as relatively
   short lines with 998 octets or less between CRLF line separation
   sequences [RFC-821].  No octets with decimal values greater than 127
   are allowed and neither are NULs (octets with decimal value 0).  CR
   (decimal value 13) and LF (decimal value 10) octets only occur as
   part of CRLF line separation sequences.


=head2 Legal 8bit data

RFC-2045 Section 2.8 defines legal C<8bit> data:

   "8bit data" refers to data that is all represented as relatively
   short lines with 998 octets or less between CRLF line separation
   sequences [RFC-821]), but octets with decimal values greater than 127
   may be used.  As with "7bit data" CR and LF octets only occur as part
   of CRLF line separation sequences and no NULs are allowed.


=head2 How decoding is done

The B<decoder> does a line-by-line pass-through from input to output,
leaving the data unchanged I<except> that an end-of-line sequence of
CRLF is converted to a newline "\n".  Given the line-oriented nature
of 7bit and 8bit, this seems relatively sensible.


=head2 How encoding is done

The B<encoder> does a line-by-line pass-through from input to output,
and simply attempts to I<detect> violations of the C<7bit>/C<8bit>
domain.  The default action is to warn once per encoding if violations
are detected; the warnings may be silenced with the QUIET configuration
of L<MIME::Tools>.

=head1 SEE ALSO

L<MIME::Decoder>


=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut

use vars qw(@ISA $VERSION);

use MIME::Decoder;
use MIME::Tools qw(:msgs);

@ISA = qw(MIME::Decoder);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";

### How many bytes to decode at a time?
my $DecodeChunkLength = 8 * 1024;

#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;
    my $and_also;

    ### Allocate a buffer suitable for a chunk and a line:
    local $_ = (' ' x ($DecodeChunkLength + 1024)); $_ = '';

    ### Get chunks until done:
    while ($in->read($_, $DecodeChunkLength)) {
	$and_also = $in->getline;
	$_ .= $and_also if defined($and_also);

	### Just got a chunk ending in a line.
	s/\015\012$/\n/g;
	$out->print($_);
    }
    1;
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;
    my $saw_8bit = 0;    ### warn them ONCE PER ENCODING if 8-bit data exists
    my $saw_long = 0;    ### warn them ONCE PER ENCODING if long lines exist
    my $seven_bit = ($self->encoding eq '7bit');      ### 7bit?

    my $line;
    while (defined($line = $in->getline)) {

	### Whine if encoding is 7bit and it has 8-bit data:
	if ($seven_bit && ($line =~ /[\200-\377]/)) { ### oops! saw 8-bit data!
	    whine "saw 8-bit data while encoding 7bit" unless $saw_8bit++;
	}

	### Whine if long lines detected:
	if (length($line) > 998) {
	    whine "saw long line while encoding 7bit/8bit" unless $saw_long++;
	}

	### Output!
	$out->print($line);
    }
    1;
}

1;


