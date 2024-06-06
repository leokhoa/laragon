package MIME::Decoder::Gzip64;


=head1 NAME

MIME::Decoder::Gzip64 - decode a "base64" gzip stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.


=head1 DESCRIPTION

A MIME::Decoder::Base64 subclass for a nonstandard encoding whereby
data are gzipped, then the gzipped file is base64-encoded.
Common non-standard MIME encodings for this:

    x-gzip64

Since this class relies on external programs which may not
exist on your machine, MIME-tools does not "install" it by default.
To use it, you need to say in your main program:

    install MIME::Decoder::Gzip64 'x-gzip64';

Note: if this class isn't working for you, you may need to change the
commands it runs.  In your main program, you can do so by setting up
the two commands which handle the compression/decompression.

    use MIME::Decoder::Gzip64;

    $MIME::Decoder::Gzip64::GZIP   = 'gzip -c';
    $MIME::Decoder::Gzip64::GUNZIP = 'gzip -d -c';

=head1 SEE ALSO

L<MIME::Decoder>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.


=cut


require 5.002;
use strict;
use vars qw(@ISA $VERSION $GZIP $GUNZIP);
use MIME::Decoder;
use MIME::Base64;
use MIME::Decoder::Base64;
use MIME::Tools qw(tmpopen whine);

# Inheritance:
@ISA = qw(MIME::Decoder::Base64);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";

# How to compress stdin to stdout:
$GZIP   = "gzip -c";

# How to UNcompress stdin to stdout:
$GUNZIP = "gzip -d -c";


#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;

    # Open a temp file (assume the worst, that this is a big stream):
    my $tmp = tmpopen() || die "can't get temp file";

    # Stage 1: decode the base64'd stream into zipped data:
    $self->SUPER::decode_it($in, $tmp)    or die "base64 decoding failed!";
    
    # Stage 2: un-zip the zipped data:
    $tmp->seek(0, 0); 
    $self->filter($tmp, $out, $GUNZIP)    or die "gzip decoding failed!";
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;
    whine "Encoding ", $self->encoding, " is not standard MIME!"; 
    
    # Open a temp file (assume the worst, that this is a big stream):
    my $tmp = tmpopen() || die "can't get temp file";
  
    # Stage 1: zip the raw data:
    $self->filter($in, $tmp, $GZIP)       or die "gzip encoding failed!";
    
    # Stage 2: encode the zipped data via base64:
    $tmp->seek(0, 0);    
    $self->SUPER::encode_it($tmp, $out)   or die "base64 encoding failed!";
}

#------------------------------
1;
