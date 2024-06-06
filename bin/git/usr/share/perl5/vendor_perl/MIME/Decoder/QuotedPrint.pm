package MIME::Decoder::QuotedPrint;
use strict;
use warnings;
use version;

=head1 NAME

MIME::Decoder::QuotedPrint - encode/decode a "quoted-printable" stream


=head1 SYNOPSIS

A generic decoder object; see L<MIME::Decoder> for usage.


=head1 DESCRIPTION

A MIME::Decoder subclass for the C<"quoted-printable"> encoding.
The name was chosen to jibe with the pre-existing MIME::QuotedPrint
utility package, which this class actually uses to translate each line.

=over 4

=item *

The B<decoder> does a line-by-line translation from input to output.

=item *

The B<encoder> does a line-by-line translation, breaking lines
so that they fall under the standard 76-character limit for this
encoding.

=back


B<Note:> just like MIME::QuotedPrint, we currently use the
native C<"\n"> for line breaks, and not C<CRLF>.  This may
need to change in future versions.

=head1 SEE ALSO

L<MIME::Decoder>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

use vars qw(@ISA $VERSION);
use MIME::Decoder;
use MIME::QuotedPrint;

@ISA = qw(MIME::Decoder);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.515";

#------------------------------
# If we have MIME::QuotedPrint 3.03 or later, use the three-argument
# version.  If we have an earlier version of MIME::QuotedPrint, we
# may get the wrong results.  However, on some systems (RH Linux,
# for example), MIME::QuotedPrint is part of the Perl package and
# upgrading it separately breaks their magic auto-update tools.
# We are supporting older versions of MIME::QuotedPrint even though
# they may give incorrect results simply because it's too painful
# for many people to upgrade.

# The following code is horrible.  I know.  Beat me up. --dfs
BEGIN {
    if (!defined(&encode_qp_threearg)) {
        my $ver = version->parse($::MIME::QuotedPrint::VERSION);
        if ($ver >= version->parse(3.03)) {
            eval 'sub encode_qp_threearg ( $$$ ) { encode_qp(shift, shift, shift); }';
        } else {
            eval 'sub encode_qp_threearg ( $$$ ) { encode_qp(shift); }';
        }
    }
}

#------------------------------
#
# encode_qp_really STRING TEXTUAL_TYPE_FLAG
#
# Encode QP, and then follow guideline 8 from RFC 2049 (thanks to Denis
# N. Antonioli) whereby we make things a little safer for the transport
# and storage of messages.  WARNING: we can only do this if the line won't
# grow beyond 76 characters!
#
sub encode_qp_really {
    my $enc = encode_qp_threearg(shift, undef, not shift);
    if (length($enc) < 74) {
	$enc =~ s/^\.\n/=2E\n/g;      # force encoding of /^\.$/
	$enc =~ s/^From /=46rom /g;   # force encoding of /^From /
    }
    $enc;
}

#------------------------------
#
# decode_it IN, OUT
#
sub decode_it {
    my ($self, $in, $out) = @_;
    my $init = 0;
    my $badpdf = 0;

    local $_;
    while (defined($_ = $in->getline)) {
	#
	# Dirty hack to fix QP-Encoded PDFs from MS-Outlook.
	#
	# Check if we have a PDF file and if it has been encoded
	# on Windows. Unix encoded files are fine. If we have
	# one encoded CR after the PDF init string but are missing
	# an encoded CR before the newline this means the PDF is broken.
	#
	if (!$init) {
	    $init = 1;
	    if ($_ =~ /^%PDF-[0-9\.]+=0D/ && $_ !~ /=0D\n$/) {
		$badpdf = 1;
	    }
	}
	#
	# Decode everything with decode_qp() except corrupted PDFs.
	#
	if ($badpdf) {
	    my $output = $_;
	    $output =~ s/[ \t]+?(\r?\n)/$1/g;
	    $output =~ s/=\r?\n//g;
	    $output =~ s/(^|[^\r])\n\Z/$1\r\n/;
	    $output =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
	    $out->print($output);
	} else {
	    $out->print(decode_qp($_));
	}
    }
    1;
}

#------------------------------
#
# encode_it IN, OUT
#
sub encode_it {
    my ($self, $in, $out, $textual_type) = @_;

    local $_;
    while (defined($_ = $in->getline)) {
	$out->print(encode_qp_really($_, $textual_type));
    }
    1;
}

#------------------------------
1;
