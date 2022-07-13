package MIME::Decoder::Binary;
use strict;
use warnings;


=head1 NAME

MIME::Decoder::Binary - perform no encoding/decoding


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.


=head1 DESCRIPTION

A MIME::Decoder subclass for the C<"binary"> encoding (in other words,
no encoding).  

The C<"binary"> decoder is a special case, since it's ill-advised
to read the input line-by-line: after all, an uncompressed image file might
conceivably have loooooooooong stretches of bytes without a C<"\n"> among
them, and we don't want to risk blowing out our core.  So, we 
read-and-write fixed-size chunks.

Both the B<encoder> and B<decoder> do a simple pass-through of the data
from input to output.

=head1 SEE ALSO

L<MIME::Decoder>


=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut

use MIME::Decoder;
use vars qw(@ISA $VERSION);

@ISA = qw(MIME::Decoder);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";

### Buffer length:
my $BUFLEN = 8192;

#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;

    my ($buf, $nread) = ('', 0);
    while ($nread = $in->read($buf, $BUFLEN)) {
	$out->print($buf);
    }
    defined($nread) or return undef;      ### check for error
    1;
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;

    my ($buf, $nread) = ('', 0);
    while ($nread = $in->read($buf, $BUFLEN)) {
	$out->print($buf);
    }
    defined($nread) or return undef;      ### check for error
    1;
}

#------------------------------
1;
