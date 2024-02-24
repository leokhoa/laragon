package MIME::Decoder::UU;
use strict;
use warnings;

=head1 NAME

MIME::Decoder::UU - decode a "uuencoded" stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.

Also supports a preamble() method to recover text before
the uuencoded portion of the stream.


=head1 DESCRIPTION

A MIME::Decoder subclass for a nonstandard encoding whereby
data are uuencoded.  Common non-standard MIME encodings for this:

    x-uu
    x-uuencode

=head1 SEE ALSO

L<MIME::Decoder>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

UU-decoding code lifted from "uuexplode", a Perl script by an
unknown author...

All rights reserved.  This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut


require 5.002;
use vars qw(@ISA $VERSION);
use MIME::Decoder;
use MIME::Tools qw(whine);

@ISA = qw(MIME::Decoder);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.510";


#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;
    my ($mode, $file);
    my @preamble;

    ### Init:
    $self->{MDU_Preamble} = \@preamble;
    $self->{MDU_Mode} = undef;
    $self->{MDU_File} = undef;

    ### Find beginning...
    local $_;
    while (defined($_ = $in->getline)) {
	if (/^begin(.*)/) {        ### found it: now decode it...
	    my $modefile = $1;
	    if ($modefile =~ /^(\s+(\d+))?(\s+(.*?\S))?\s*\Z/) {
		($mode, $file) = ($2, $4);
	    }
	    last;                  ### decoded or not, we're done
	}
	push @preamble, $_;
    }
    die("uu decoding: no begin found\n") if !defined($_);      # hit eof!

    ### Store info:
    $self->{MDU_Mode} = $mode;
    $self->{MDU_File} = $file;

    ### Decode:
    while (defined($_ = $in->getline)) {
	last if /^end/;
	next if /[a-z]/;
	next unless int((((ord() - 32) & 077) + 2) / 3) == int(length() / 4);
	$out->print(unpack('u', $_));
    }
    ### chmod oct($mode), $file;    # sheeyeah... right...
    whine "file incomplete, no end found\n" if !defined($_); # eof
    1;
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out) = @_;
    my $buf = '';

    my $fname = (($self->head && 
		  $self->head->mime_attr('content-disposition.filename')) ||
		 '');
    my $nl = $MIME::Entity::BOUNDARY_DELIMITER || "\n";
    $out->print("begin 644 $fname$nl");
    while ($in->read($buf, 45)) { $out->print(pack('u', $buf)) }
    $out->print("end$nl");
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
    shift->{MDU_File} || [];
}

#------------------------------
1;
