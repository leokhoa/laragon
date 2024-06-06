package MIME::WordDecoder;

=head1 NAME

MIME::WordDecoder - decode RFC 2047 encoded words to a local representation

WARNING: Most of this module is deprecated and may disappear.  The only
function you should use for MIME decoding is "mime_to_perl_string".

=head1 SYNOPSIS

See L<MIME::Words> for the basics of encoded words.
See L<"DESCRIPTION"> for how this class works.

    use MIME::WordDecoder;


    ### Get the default word-decoder (used by unmime()):
    $wd = default MIME::WordDecoder;

    ### Get a word-decoder which maps to ISO-8859-1 (Latin1):
    $wd = supported MIME::WordDecoder "ISO-8859-1";


    ### Decode a MIME string (e.g., into Latin1) via the default decoder:
    $str = $wd->decode('To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld>');

    ### Decode a string using the default decoder, non-OO style:
    $str = unmime('To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld>');

    ### Decode a string to an internal Perl string, non-OO style
    ### The result is likely to have the UTF8 flag ON.
    $str = mime_to_perl_string('To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld>');

=head1 DESCRIPTION

WARNING: Most of this module is deprecated and may disappear.  It
duplicates (badly) the function of the standard 'Encode' module.  The
only function you should rely on is mime_to_perl_string.

A MIME::WordDecoder consists, fundamentally, of a hash which maps
a character set name (US-ASCII, ISO-8859-1, etc.) to a subroutine which
knows how to take bytes in that character set and turn them into
the target string representation.  Ideally, this target representation
would be Unicode, but we don't want to overspecify the translation
that takes place: if you want to convert MIME strings directly to Big5,
that's your own decision.

The subroutine will be invoked with two arguments: DATA (the data in
the given character set), and CHARSET (the upcased character set name).

For example:

    ### Keep 7-bit characters as-is, convert 8-bit characters to '#':
    sub keep7bit {
	local $_ = shift;
	tr/\x00-\x7F/#/c;
	$_;
    }

Here's a decoder which uses that:

   ### Construct a decoder:
   $wd = MIME::WordDecoder->new({'US-ASCII'   => "KEEP",   ### sub { $_[0] }
                                 'ISO-8859-1' => \&keep7bit,
                                 'ISO-8859-2' => \&keep7bit,
                                 'Big5'       => "WARN",
                                 '*'          => "DIE"});

   ### Convert some MIME text to a pure ASCII string...
   $ascii = $wd->decode('To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld>');

   ### ...which will now hold: "To: Keld J#rn Simonsen <keld>"

The UTF-8 built-in decoder decodes everything into Perl's internal
string format, possibly turning on the internal UTF8 flag.  Use it like
this:

    $wd = supported MIME::WordDecoder 'UTF-8';
    $perl_string = $wd->decode('To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld>');
    # perl_string will be a valid UTF-8 string with the "UTF8" flag set.

Generally, you should use the UTF-8 decoder in preference to "unmime".

=head1 PUBLIC INTERFACE

=over

=cut

use strict;
use Carp qw( carp croak );
use MIME::Words qw(decode_mimewords);
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw( unmime mime_to_perl_string );



#------------------------------
#
# Globals
#
#------------------------------

### Decoders.
my %DecoderFor = ();

### Standard handlers.
my %Handler =
(
 KEEP   => sub {$_[0]},
 IGNORE => sub {''},
 WARN   => sub { carp "ignoring text in character set `$_[1]'\n" },
 DIE    => sub { croak "can't handle text in character set `$_[1]'\n" },
 );

### Global default decoder.  We init it below.
my $Default;

### Global UTF8 decoder.
my $DefaultUTF8;

#------------------------------

=item default [DECODER]

I<Class method.>
Get/set the default DECODER object.

=cut

sub default {
    my $class = shift;
    if (@_) {
	$Default = shift;
    }
    $Default;
}

#------------------------------

=item supported CHARSET, [DECODER]

I<Class method.>
If just CHARSET is given, returns a decoder object which maps
data into that character set (the character set is forced to
all-uppercase).

    $wd = supported MIME::WordDecoder "ISO-8859-1";

If DECODER is given, installs such an object:

    MIME::WordDecoder->supported("ISO-8859-1" =>
				 (new MIME::WordDecoder::ISO_8859 "1"));

You should not override this method.

=cut

sub supported {
    my ($class, $charset, $decoder) = @_;
    $DecoderFor{uc($charset)} = $decoder if (@_ > 2);
    $DecoderFor{uc($charset)};
}

#------------------------------

=item new [\@HANDLERS]

I<Class method, constructor.>
If \@HANDLERS is given, then @HANDLERS is passed to handler()
to initialize the internal map.

=cut

sub new {
    my ($class, $h) = @_;
    my $self = bless { MWD_Map=>{} }, $class;

    ### Init the map:
    $self->handler(@$h);

    ### Add fallbacks:
    $self->{MWD_Map}{'*'}   ||= $Handler{WARN};
    $self->{MWD_Map}{'raw'} ||= $self->{MWD_Map}{'US-ASCII'};
    $self;
}

#------------------------------

=item handler CHARSET=>\&SUBREF, ...

I<Instance method.>
Set the handler SUBREF for a given CHARSET, for as many pairs
as you care to supply.

When performing the translation of a MIME-encoded string, a
given SUBREF will be invoked when translating a block of text
in character set CHARSET.  The subroutine will be invoked with
the following arguments:

    DATA    - the data in the given character set.
    CHARSET - the upcased character set name, which may prove useful
              if you are using the same SUBREF for multiple CHARSETs.
    DECODER - the decoder itself, if it contains configuration information
              that your handler function needs.

For example:

    $wd = new MIME::WordDecoder;
    $wd->handler('US-ASCII'   => "KEEP");
    $wd->handler('ISO-8859-1' => \&handle_latin1,
		 'ISO-8859-2' => \&handle_latin1,
		 '*'          => "DIE");

Notice that, much as with %SIG, the SUBREF can also be taken from
a set of special keywords:

   KEEP     Pass data through unchanged.
   IGNORE   Ignore data in this character set, without warning.
   WARN     Ignore data in this character set, with warning.
   DIE      Fatal exception with "can't handle character set" message.

The subroutine for the special CHARSET of 'raw' is used for raw
(non-MIME-encoded) text, which is supposed to be US-ASCII.
The handler for 'raw' defaults to whatever was specified for 'US-ASCII'
at the time of construction.

The subroutine for the special CHARSET of '*' is used for any
unrecognized character set.  The default action for '*' is WARN.

=cut

sub handler {
    my $self = shift;

    ### Copy the hash, and edit it:
    while (@_) {
	my $c   = shift;
	my $sub = shift;
	$self->{MWD_Map}{$c} = $self->real_handler($sub);
    }
    $self;
}

#------------------------------

=item decode STRING

I<Instance method.>
Decode a STRING which might contain MIME-encoded components into a
local representation (e.g., UTF-8, etc.).

=cut

sub decode {
    my ($self, $str) = @_;
    defined($str) or return undef;
    join('', map {
	### Get the data and (upcased) charset:
	my $data    = $_->[0];
	my $charset = (defined($_->[1]) ? uc($_->[1]) : 'raw');
	$charset =~ s/\*\w+\Z//;   ### RFC2184 language suffix

	### Get the handler; guess if never seen before:
	defined($self->{MWD_Map}{$charset}) or
	    $self->{MWD_Map}{$charset} =
		($self->real_handler($self->guess_handler($charset)) || 0);
	my $subr = $self->{MWD_Map}{$charset} || $self->{MWD_Map}{'*'};

	### Map this chunk:
	&$subr($data, $charset, $self);
    } decode_mimewords($str));
}

#------------------------------
#
# guess_handler CHARSET
#
# Instance method.
# An unrecognized charset has been seen.  Guess a handler subref
# for the given charset, returning false if there is none.
# Successful mappings will be cached in the main map.
#
sub guess_handler {
    undef;
}

#------------------------------
#
# real_handler HANDLER
#
# Instance method.
# Translate the given handler, which might be a subref or a string.
#
sub real_handler {
    my ($self, $sub) = @_;
    (!$sub) or
	(ref($sub) eq 'CODE') or
	    $sub = ($Handler{$sub} || croak "bad named handler: $sub\n");
    $sub;
}

#------------------------------

=item unmime STRING

I<Function, exported.>
Decode the given STRING using the default() decoder.
See L<default()|/default>.

You should consider using the UTF-8 decoder instead.  It decodes
MIME strings into Perl's internal string format.

=cut

sub unmime($) {
    my $str = shift;
    $Default->decode($str);
}

=item mime_to_perl_string

I<Function, exported.>
Decode the given STRING into an internal Perl Unicode string.
You should use this function in preference to all others.

The result of mime_to_perl_string is likely to have Perl's
UTF8 flag set.

=cut

sub mime_to_perl_string($) {
    my $str = shift;
    $DecoderFor{'UTF-8'}->decode($str);
}

=back

=cut





=head1 SUBCLASSES

=over

=cut

#------------------------------------------------------------
#------------------------------------------------------------

=item MIME::WordDecoder::ISO_8859

A simple decoder which keeps US-ASCII and the 7-bit characters
of ISO-8859 character sets and UTF8, and also keeps 8-bit
characters from the indicated character set.

    ### Construct:
    $wd = new MIME::WordDecoder::ISO_8859 2;    ### ISO-8859-2

    ### What to translate unknown characters to (can also use empty):
    ### Default is "?".
    $wd->unknown("?");

    ### Collapse runs of unknown characters to a single unknown()?
    ### Default is false.
    $wd->collapse(1);


According to B<http://czyborra.com/charsets/iso8859.html>
(ca. November 2000):

ISO 8859 is a full series of 10 (and soon even more) standardized
multilingual single-byte coded (8bit) graphic character sets for
writing in alphabetic languages:

    1. Latin1 (West European)
    2. Latin2 (East European)
    3. Latin3 (South European)
    4. Latin4 (North European)
    5. Cyrillic
    6. Arabic
    7. Greek
    8. Hebrew
    9. Latin5 (Turkish)
   10. Latin6 (Nordic)

The ISO 8859 charsets are not even remotely as complete as the truly
great Unicode but they have been around and usable for quite a while
(first registered Internet charsets for use with MIME) and have
already offered a major improvement over the plain 7bit US-ASCII.

Characters 0 to 127 are always identical with US-ASCII and the
positions 128 to 159 hold some less used control characters: the
so-called C1 set from ISO 6429.

=cut

package MIME::WordDecoder::ISO_8859;

use strict;
use vars qw(@ISA);
@ISA = qw( MIME::WordDecoder );


#------------------------------
#
# HANDLERS
#
#------------------------------

### Keep 7bit characters.
### Turn all else to the special \x00.
sub h_keep7bit {
    local $_    = $_[0];
#   my $unknown = $_[2]->{MWDI_Unknown};

    s{[\x80-\xFF]}{\x00}g;
    $_;
}

### Note: should use Unicode::String, converting/manipulating
### everything into full Unicode form.

### Keep 7bit UTF8 characters (ASCII).
### Keep ISO-8859-1 if this decoder is for Latin-1.
### Turn all else to the special \x00.
sub h_utf8 {
    local $_    = $_[0];
#   my $unknown = $_[2]->{MWDI_Unknown};
    my $latin1 = ($_[2]->{MWDI_Num} == 1);
    #print STDERR "UTF8 in:  <$_>\n";

    local($1,$2,$3);
    my $tgt = '';
    while (m{\G(
          ([\x00-\x7F])                | # 0xxxxxxx
	  ([\xC0-\xDF] [\x80-\xBF])    | # 110yyyyy 10xxxxxx
	  ([\xE0-\xEF] [\x80-\xBF]{2}) | # 1110zzzz 10yyyyyy 10xxxxxx
	  ([\xF0-\xF7] [\x80-\xBF]{3}) | # 11110uuu 10uuzzzz 10yyyyyy 10xxxxxx
	  .                              # error; synch
	  )}gcsx and ($1 ne '')) {

	if    (defined($2))            { $tgt .= $2 }
	elsif (defined($3) && $latin1) { $tgt .= "\x00" }
        else                           { $tgt .= "\x00" }
    }

    #print STDERR "UTF8 out: <$tgt>\n";
    $tgt;
}

### Keep characters which are 7bit in UTF8 (ASCII).
### Keep ISO-8859-1 if this decoder is for Latin-1.
### Turn all else to the special \x00.
sub h_utf16 {
    local $_    = $_[0];
#   my $unknown = $_[2]->{MWDI_Unknown};
    my $latin1 = ($_[2]->{MWDI_Num} == 1);
    #print STDERR "UTF16 in:  <$_>\n";

    local($1,$2,$3,$4,$5);
    my $tgt = '';
    while (m{\G(
		(  \x00  ([\x00-\x7F])) |  # 00000000 0xxxxxxx
		(  \x00  ([\x80-\xFF])) |  # 00000000 1xxxxxxx
		( [^\x00] [\x00-\xFF])  |  # etc
		)
	     }gcsx and ($1 ne '')) {

	if    (defined($2))            { $tgt .= $3 }
	elsif (defined($4) && $latin1) { $tgt .= $5 }
        else                           { $tgt .= "\x00" }
    }

    #print STDERR "UTF16 out: <$tgt>\n";
    $tgt;
}


#------------------------------
#
# PUBLIC INTERFACE
#
#------------------------------

#------------------------------
#
# new NUMBER
#
sub new {
    my ($class, $num) = @_;

    my $self = $class->SUPER::new();
    $self->handler('raw'      => 'KEEP',
		   'US-ASCII' => 'KEEP');

    $self->{MWDI_Num} = $num;
    $self->{MWDI_Unknown} = "?";
    $self->{MWDI_Collapse} = 0;
    $self;
}

#------------------------------
#
# guess_handler CHARSET
#
sub guess_handler {
    my ($self, $charset) = @_;
    return 'KEEP'              if (($charset =~ /^ISO[-_]?8859[-_](\d+)$/) &&
				   ($1 eq $self->{MWDI_Num}));
    return \&h_keep7bit        if ($charset =~ /^ISO[-_]?8859/);
    return \&h_utf8            if ($charset =~ /^UTF[-_]?8$/);
    return \&h_utf16           if ($charset =~ /^UTF[-_]?16$/);
    undef;
}

#------------------------------
#
# unknown [REPLACEMENT]
#
sub unknown {
    my $self = shift;
    $self->{MWDI_Unknown} = shift if @_;
    $self->{MWDI_Unknown};
}

#------------------------------
#
# collapse [YESNO]
#
sub collapse {
    my $self = shift;
    $self->{MWDI_Collapse} = shift if @_;
    $self->{MWDI_Collapse};
}

#------------------------------
#
# decode STRING
#
sub decode {
    my $self = shift;

    ### Do inherited action:
    my $basic = $self->SUPER::decode(@_);
    defined($basic) or return undef;

    ### Translate/consolidate illegal characters:
    $basic =~ tr{\x00}{\x00}c     if $self->{MWDI_Collapse};
    $basic =~ s{\x00}{$self->{MWDI_Unknown}}g;
    $basic;
}

#------------------------------------------------------------
#------------------------------------------------------------

=item MIME::WordDecoder::US_ASCII

A subclass of the ISO-8859-1 decoder which discards 8-bit characters.
You're probably better off using ISO-8859-1.

=cut

package MIME::WordDecoder::US_ASCII;

use strict;
use vars qw(@ISA);
@ISA = qw( MIME::WordDecoder::ISO_8859 );

sub new {
    my ($class) = @_;
    return $class->SUPER::new("1");
}

sub decode {
    my $self = shift;

    ### Do inherited action:
    my $basic = $self->SUPER::decode(@_);
    defined($basic) or return undef;

    ### Translate/consolidate 8-bit characters:
    $basic =~ tr{\x80-\xFF}{}c     if $self->{MWDI_Collapse};
    $basic =~ s{[\x80-\xFF]}{$self->{MWDI_Unknown}}g;
    $basic;
}

=back

=cut

package MIME::WordDecoder::UTF_8;
use strict;
use Encode qw();
use Carp qw( carp );
use vars qw(@ISA);

@ISA = qw( MIME::WordDecoder );

sub h_convert_to_utf8
{
	my ($data, $charset, $decoder) = @_;
	$charset = 'US-ASCII' if ($charset eq 'raw');
	my $enc = Encode::find_encoding($charset);
	if (!$enc) {
		carp "Unable to convert text in character set `$charset' to UTF-8... ignoring\n";
		return '';
	}
	my $ans = $enc->decode($data, Encode::FB_PERLQQ);
	return $ans;
}

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new();
	$self->handler('*'     => \&h_convert_to_utf8);
}


#------------------------------------------------------------
#------------------------------------------------------------

package MIME::WordDecoder;

### Now we can init the default handler.
$Default = (MIME::WordDecoder::ISO_8859->new('1'));


### Add US-ASCII handler:
$DecoderFor{"US-ASCII"} = MIME::WordDecoder::US_ASCII->new;

### Add ISO-8859-{1..15} handlers:
for (1..15) {
    $DecoderFor{"ISO-8859-$_"} = MIME::WordDecoder::ISO_8859->new($_);
}

### UTF-8
$DecoderFor{'UTF-8'} = MIME::WordDecoder::UTF_8->new();

1;           # end the module
__END__

=head1 SEE ALSO

L<MIME::Tools>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (dianne@skoll.ca)

=cut


BEGIN { unshift @INC, ".", "./etc", "./lib" };
import MIME::WordDecoder;

### Decode a MIME string (e.g., into Latin1) via the default decoder:
my $charset = $ARGV[0] || 'ISO-8859-1';
my $wd = MIME::WordDecoder->supported($charset) || die "unsupported charset: $charset\n";

$wd->unknown('#');
my @encs = (
	    'ASCII:  =?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>',
	    'Latin1: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>',
	    'Latin1: =?ISO-8859-1?Q?Andr=E9_?= Pirard <PIRARD@vm1.ulg.ac.be>',
	    'Latin1: =?ISO-8859-1?Q?Andr=E9_?=Pirard <PIRARD@vm1.ulg.ac.be>',
	    ' UTF-8: =?UTF-8?Q?Andr=E9_?=Pirard <PIRARD@vm1.ulg.ac.be>',
	    'UTF-16: =?UTF-16?Q?=00A=00n=00d=00r=00=E9?= Pirard <PIRARD@vm1.ulg.ac.be>',
	    ('=?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?='.
	     '=?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?='.
	     '=?US-ASCII?Q?.._cool!?='));
$str = $wd->decode(join "\n", @encs);
print "$str\n";
1;
