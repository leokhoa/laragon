package MIME::Decoder::Base64;
use strict;
use warnings;


=head1 NAME

MIME::Decoder::Base64 - encode/decode a "base64" stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.


=head1 DESCRIPTION

A L<MIME::Decoder> subclass for the C<"base64"> encoding.
The name was chosen to jibe with the pre-existing MIME::Base64
utility package, which this class actually uses to translate each chunk.

=over 4

=item *

When B<decoding>, the input is read one line at a time.
The input accumulates in an internal buffer, which is decoded in
multiple-of-4-sized chunks (plus a possible "leftover" input chunk,
of course).

=item *

When B<encoding>, the input is read 6840 (120 * 57) bytes at a time.
Each section of 57 bytes is encoded as a line containing 76 Base64
characters.

=back

=head1 SEE ALSO

L<MIME::Decoder>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut

use vars qw(@ISA $VERSION);
use MIME::Decoder;
use MIME::Base64 2.04;    
use MIME::Tools qw(debug);

@ISA = qw(MIME::Decoder);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.515";

### How many bytes to encode at a time (must be a multiple of 3)
my $EncodeChunkLength = 120 * 57;

### How many bytes to decode at a time?
my $DecodeChunkLength = 32 * 1024;

#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;
    my $len_4xN;
    
    ### Create a suitable buffer:
    my $buffer = ' ' x (120 + $DecodeChunkLength); $buffer = '';
    debug "in = $in; out = $out";

    ### Get chunks until done:
    local($_) = ' ' x $DecodeChunkLength;    
    while ($in->read($_, $DecodeChunkLength)) {
	tr{A-Za-z0-9+/}{}cd;         ### get rid of non-base64 chars

	### Concat any new input onto any leftover from the last round:
	$buffer .= $_;
	length($buffer) >= $DecodeChunkLength or next;
	
    	### Extract substring with highest multiple of 4 bytes:
	###   0 means not enough to work with... get more data!
	$len_4xN = length($buffer) & ~3; 

	### Partition into largest-multiple-of-4 (which we decode),
	### and the remainder (which gets handled next time around):
	$out->print(decode_base64(substr($buffer, 0, $len_4xN)));
	$buffer = substr($buffer, $len_4xN);
    }
    
    ### No more input remains.  Dispose of anything left in buffer:
    if (length($buffer)) {

	### Pad to 4-byte multiple, and decode:
	$buffer .= "===";            ### need no more than 3 pad chars
	$len_4xN = length($buffer) & ~3; 	

	### Decode it!
	$out->print(decode_base64(substr($buffer, 0, $len_4xN)));
    }
    1;
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;
    my $encoded;

    my $nread;
    my $buf = '';
    my $nl = $MIME::Entity::BOUNDARY_DELIMITER || "\n";
    while ($nread = $in->read($buf, $EncodeChunkLength)) {
	$encoded = encode_base64($buf, $nl);
	$encoded .= $nl unless ($encoded =~ /$nl\Z/);   ### ensure newline!
	$out->print($encoded);
    }
    1;
}

#------------------------------
1;

