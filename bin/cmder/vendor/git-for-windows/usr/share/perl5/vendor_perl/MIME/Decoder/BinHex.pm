package MIME::Decoder::BinHex;
use strict;
use warnings;


=head1 NAME

MIME::Decoder::BinHex - decode a "binhex" stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.

Also supports a preamble() method to recover text before
the binhexed portion of the stream.


=head1 DESCRIPTION

A MIME::Decoder subclass for a nonstandard encoding whereby
data are binhex-encoded.  Common non-standard MIME encodings for this:

    x-uu
    x-uuencode

=head1 SEE ALSO

L<MIME::Decoder>

=head1 AUTHOR

Julian Field (F<mailscanner@ecs.soton.ac.uk>).

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut


require 5.002;
use vars qw(@ISA $VERSION);
use MIME::Decoder;
use MIME::Tools qw(whine);
use Convert::BinHex;

@ISA = qw(MIME::Decoder);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";


#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;
    my ($mode, $file);
    my (@preamble, @data);
    my $H2B = Convert::BinHex->hex2bin;
    my $line;

    $self->{MDU_Preamble} = \@preamble;
    $self->{MDU_Mode} = '600';
    $self->{MDU_File} = undef;

    ### Find beginning...
    local $_;
    while (defined($_ = $in->getline)) {
        if (/^\(This file must be converted/) {
	    $_ = $in->getline;
	    last if /^:/;
        }
        push @preamble, $_;
    }
    die("binhex decoding: fell off end of file\n") if !defined($_);

    ### Decode:
    my $data;
    $data = $H2B->next($_); # or whine("Next error is $@ $!\n");
    my $len = unpack("C", $data);
    while ($len > length($data)+21 && defined($line = $in->getline)) {
	$data .= $H2B->next($line);
    }
    if (length($data) >= 22+$len) {
	$data = substr($data, 22+$len);
    } else {
	$data = '';
    }

    $out->print($data);
    while (defined($_ = $in->getline)) {
        $line = $_;
        $data = $H2B->next($line);
        $out->print($data);
        last if $line =~ /:$/;
    }
    1;
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;
    my $line;
    my $buf = '';
    my $fname = (($self->head &&
		  $self->head->mime_attr('content-disposition.filename')) ||
		 '');
    my $B2H = Convert::BinHex->bin2hex;
    $out->print("(This file must be converted with BinHex 4.0)\n");

    # Sigh... get length of file
    $in->seek(0, 2);
    my $datalen = $in->tell();
    $in->seek(0, 0);

    # Build header in core:
    my @hdrs;
    my $flen = length($fname);
    push @hdrs, pack("C", $flen);
    push @hdrs, pack("a$flen", $fname);
    push @hdrs, pack('C', 4);
    push @hdrs, pack('a4', '????');
    push @hdrs, pack('a4', '????');
    push @hdrs, pack('n',  0);
    push @hdrs, pack('N',  $datalen);
    push @hdrs, pack('N',  0); # Resource length
    my $hdr = join '', @hdrs;

    # Compute the header CRC:
    my $crc = Convert::BinHex::binhex_crc("\000\000",
					  Convert::BinHex::binhex_crc($hdr, 0));

    # Output the header (plus its CRC):
    $out->print($B2H->next($hdr . pack('n', $crc)));

    while ($in->read($buf, 1000)) {
	$out->print($B2H->next($buf));
    }
    $out->print($B2H->done);
    1;
}

#------------------------------
#
# last_preamble
#
# Return the last preamble as ref to array of lines.
# Gets reset by decode_it().
#
sub last_preamble {
    my $self = shift;
    return $self->{MDU_Preamble} || [];
}

#------------------------------
#
# last_mode
#
# Return the last mode.
# Gets reset to undef by decode_it().
#
sub last_mode {
    shift->{MDU_Mode};
}

#------------------------------
#
# last_filename
#
# Return the last filename.
# Gets reset by decode_it().
#
sub last_filename {
    shift->{MDU_File} || undef; #[];
}

#------------------------------
1;
