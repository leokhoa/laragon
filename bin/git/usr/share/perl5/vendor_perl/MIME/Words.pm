package MIME::Words;

=head1 NAME

MIME::Words - deal with RFC 2047 encoded words


=head1 SYNOPSIS

Before reading further, you should see L<MIME::Tools> to make sure that
you understand where this module fits into the grand scheme of things.
Go on, do it now.  I'll wait.

Ready?  Ok...


    use MIME::Words qw(:all);

    ### Decode the string into another string, forgetting the charsets:
    $decoded = decode_mimewords(
          'To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>',
          );

    ### Split string into array of decoded [DATA,CHARSET] pairs:
    @decoded = decode_mimewords(
          'To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>',
          );

    ### Encode a single unsafe word:
    $encoded = encode_mimeword("\xABFran\xE7ois\xBB");

    ### Encode a string, trying to find the unsafe words inside it:
    $encoded = encode_mimewords("Me and \xABFran\xE7ois\xBB in town");



=head1 DESCRIPTION

Fellow Americans, you probably won't know what the hell this module
is for.  Europeans, Russians, et al, you probably do.  C<:-)>.

For example, here's a valid MIME header you might get:

      From: =?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>
      To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>
      CC: =?ISO-8859-1?Q?Andr=E9_?= Pirard <PIRARD@vm1.ulg.ac.be>
      Subject: =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
       =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=
       =?US-ASCII?Q?.._cool!?=

The fields basically decode to (sorry, I can only approximate the
Latin characters with 7 bit sequences /o and 'e):

      From: Keith Moore <moore@cs.utk.edu>
      To: Keld J/orn Simonsen <keld@dkuug.dk>
      CC: Andr'e  Pirard <PIRARD@vm1.ulg.ac.be>
      Subject: If you can read this you understand the example... cool!


=head1 PUBLIC INTERFACE

=over 4

=cut

require 5.001;

### Pragmas:
use strict;
use re 'taint';
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

### Exporting:
use Exporter;
%EXPORT_TAGS = (all => [qw(decode_mimewords
			   encode_mimeword
			   encode_mimewords
			   )]);
Exporter::export_ok_tags('all');

### Inheritance:
@ISA = qw(Exporter);

### Other modules:
use MIME::Base64;
use MIME::QuotedPrint;



#------------------------------
#
# Globals...
#
#------------------------------

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.510";

### Nonprintables (controls + x7F + 8bit):
my $NONPRINT = "\\x00-\\x1F\\x7F-\\xFF";


#------------------------------

# _decode_Q STRING
#     Private: used by _decode_header() to decode "Q" encoding, which is
#     almost, but not exactly, quoted-printable.  :-P
sub _decode_Q {
    my $str = shift;
    local $1;
    $str =~ s/_/\x20/g;                                # RFC-1522, Q rule 2
    $str =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;  # RFC-1522, Q rule 1
    $str;
}

# _encode_Q STRING
#     Private: used by _encode_header() to decode "Q" encoding, which is
#     almost, but not exactly, quoted-printable.  :-P
sub _encode_Q {
    my $str = shift;
    local $1;
    $str =~ s{([ _\?\=$NONPRINT])}{sprintf("=%02X", ord($1))}eog;
    $str;
}

# _decode_B STRING
#     Private: used by _decode_header() to decode "B" encoding.
sub _decode_B {
    my $str = shift;
    decode_base64($str);
}

# _encode_B STRING
#     Private: used by _decode_header() to decode "B" encoding.
sub _encode_B {
    my $str = shift;
    encode_base64($str, '');
}



#------------------------------

=item decode_mimewords ENCODED

I<Function.>
Go through the string looking for RFC 2047-style "Q"
(quoted-printable, sort of) or "B" (base64) encoding, and decode them.

B<In an array context,> splits the ENCODED string into a list of decoded
C<[DATA, CHARSET]> pairs, and returns that list.  Unencoded
data are returned in a 1-element array C<[DATA]>, giving an effective
CHARSET of C<undef>.

    $enc = '=?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>';
    foreach (decode_mimewords($enc)) {
        print "", ($_->[1] || 'US-ASCII'), ": ", $_->[0], "\n";
    }

B<In a scalar context,> joins the "data" elements of the above
list together, and returns that.  I<Warning: this is information-lossy,>
and probably I<not> what you want, but if you know that all charsets
in the ENCODED string are identical, it might be useful to you.
(Before you use this, please see L<MIME::WordDecoder/unmime>,
which is probably what you want.)

In the event of a syntax error, $@ will be set to a description
of the error, but parsing will continue as best as possible (so as to
get I<something> back when decoding headers).
$@ will be false if no error was detected.

Any arguments past the ENCODED string are taken to define a hash of options:

=cut

sub decode_mimewords {
    my $encstr = shift;
    my @tokens;
    local($1,$2,$3);
    $@ = '';           ### error-return

    ### Collapse boundaries between adjacent encoded words:
    $encstr =~ s{(\?\=)\s*(\=\?)}{$1$2}gs;
    pos($encstr) = 0;
    ### print STDOUT "ENC = [", $encstr, "]\n";

    ### Decode:
    my ($charset, $encoding, $enc, $dec);
    while (1) {
	last if (pos($encstr) >= length($encstr));
	my $pos = pos($encstr);               ### save it

	### Case 1: are we looking at "=?..?..?="?
	if ($encstr =~    m{\G             # from where we left off..
			    =\?([^?]*)     # "=?" + charset +
			     \?([bq])      #  "?" + encoding +
			     \?([^?]+)     #  "?" + data maybe with spcs +
			     \?=           #  "?="
			    }xgi) {
	    ($charset, $encoding, $enc) = ($1, lc($2), $3);
	    $dec = (($encoding eq 'q') ? _decode_Q($enc) : _decode_B($enc));
	    push @tokens, [$dec, $charset];
	    next;
	}

	### Case 2: are we looking at a bad "=?..." prefix?
	### We need this to detect problems for case 3, which stops at "=?":
	pos($encstr) = $pos;               # reset the pointer.
	if ($encstr =~ m{\G=\?}xg) {
	    $@ .= qq|unterminated "=?..?..?=" in "$encstr" (pos $pos)\n|;
	    push @tokens, ['=?'];
	    next;
	}

	### Case 3: are we looking at ordinary text?
	pos($encstr) = $pos;               # reset the pointer.
	if ($encstr =~ m{\G                # from where we left off...
			 (.*?    #   shortest possible string,
			  \n*)             #   followed by 0 or more NLs,
		         (?=(\Z|=\?))      # terminated by "=?" or EOS
			}sxg) {
	    length($1) or die "MIME::Words: internal logic err: empty token\n";
	    push @tokens, [$1];
	    next;
	}

	### Case 4: bug!
	die "MIME::Words: unexpected case:\n($encstr) pos $pos\n\t".
	    "Please alert developer.\n";
    }
    return (wantarray ? @tokens : join('',map {$_->[0]} @tokens));
}

#------------------------------

=item encode_mimeword RAW, [ENCODING], [CHARSET]

I<Function.>
Encode a single RAW "word" that has unsafe characters.
The "word" will be encoded in its entirety.

    ### Encode "<<Franc,ois>>":
    $encoded = encode_mimeword("\xABFran\xE7ois\xBB");

You may specify the ENCODING (C<"Q"> or C<"B">), which defaults to C<"Q">.
You may specify the CHARSET, which defaults to C<iso-8859-1>.

=cut

sub encode_mimeword {
    my $word = shift;
    my $encoding = uc(shift || 'Q');
    my $charset  = uc(shift || 'ISO-8859-1');
    my $encfunc  = (($encoding eq 'Q') ? \&_encode_Q : \&_encode_B);
    "=?$charset?$encoding?" . &$encfunc($word) . "?=";
}

#------------------------------

=item encode_mimewords RAW, [OPTS]

I<Function.>
Given a RAW string, try to find and encode all "unsafe" sequences
of characters:

    ### Encode a string with some unsafe "words":
    $encoded = encode_mimewords("Me and \xABFran\xE7ois\xBB");

Returns the encoded string.
Any arguments past the RAW string are taken to define a hash of options:

=over 4

=item Charset

Encode all unsafe stuff with this charset.  Default is 'ISO-8859-1',
a.k.a. "Latin-1".

=item Encoding

The encoding to use, C<"q"> or C<"b">.  The default is C<"q">.

=back

B<Warning:> this is a quick-and-dirty solution, intended for character
sets which overlap ASCII.  B<It does not comply with the RFC 2047
rules regarding the use of encoded words in message headers>.
You may want to roll your own variant,
using C<encode_mimeword()>, for your application.
I<Thanks to Jan Kasprzak for reminding me about this problem.>

=cut

sub encode_mimewords {
    my ($rawstr, %params) = @_;
    my $charset  = $params{Charset} || 'ISO-8859-1';
    my $encoding = lc($params{Encoding} || 'q');

    ### Encode any "words" with unsafe characters.
    ###    We limit such words to 18 characters, to guarantee that the
    ###    worst-case encoding give us no more than 54 + ~10 < 75 characters
    my $word;
    local $1;
    $rawstr =~ s{([a-zA-Z0-9\x7F-\xFF]+\s*)}{     ### get next "word"
	$word = $1;
	(($word !~ /(?:[$NONPRINT])|(?:^\s+$)/o)
	 ? $word                                          ### no unsafe chars
	 : encode_mimeword($word, $encoding, $charset));  ### has unsafe chars
    }xeg;
    $rawstr =~ s/\?==\?/?= =?/g;
    $rawstr;
}

1;
__END__


=back

=head1 SEE ALSO

L<MIME::Base64>, L<MIME::QuotedPrint>, L<MIME::Tools>

For other implementations of this or similar functionality (particularly, ones
with proper UTF8 support), see:

L<Encode::MIME::Header>, L<MIME::EncWords>, L<MIME::AltWords>

At some future point, one of these implementations will likely replace
MIME::Words and MIME::Words will become deprecated.

=head1 NOTES

Exports its principle functions by default, in keeping with
MIME::Base64 and MIME::QuotedPrint.


=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (dianne@skoll.ca)

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

Thanks also to...

      Kent Boortz        For providing the idea, and the baseline
                         RFC-1522-decoding code!
      KJJ at PrimeNet    For requesting that this be split into
                         its own module.
      Stephane Barizien  For reporting a nasty bug.

