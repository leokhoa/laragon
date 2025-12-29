package MIME::Head;

use MIME::WordDecoder;
=head1 NAME

MIME::Head - MIME message header (a subclass of Mail::Header)


=head1 SYNOPSIS

Before reading further, you should see L<MIME::Tools> to make sure that
you understand where this module fits into the grand scheme of things.
Go on, do it now.  I'll wait.

Ready?  Ok...

=head2 Construction

    ### Create a new, empty header, and populate it manually:
    $head = MIME::Head->new;
    $head->replace('content-type', 'text/plain; charset=US-ASCII');
    $head->replace('content-length', $len);

    ### Parse a new header from a filehandle:
    $head = MIME::Head->read(\*STDIN);

    ### Parse a new header from a file, or a readable pipe:
    $testhead = MIME::Head->from_file("/tmp/test.hdr");
    $a_b_head = MIME::Head->from_file("cat a.hdr b.hdr |");


=head2 Output

    ### Output to filehandle:
    $head->print(\*STDOUT);

    ### Output as string:
    print STDOUT $head->as_string;
    print STDOUT $head->stringify;


=head2 Getting field contents

    ### Is this a reply?
    $is_reply = 1 if ($head->get('Subject') =~ /^Re: /);

    ### Get receipt information:
    print "Last received from: ", $head->get('Received', 0);
    @all_received = $head->get('Received');

    ### Print the subject, or the empty string if none:
    print "Subject: ", $head->get('Subject',0);

    ### Too many hops?  Count 'em and see!
    if ($head->count('Received') > 5) { ...

    ### Test whether a given field exists
    warn "missing subject!" if (! $head->count('subject'));


=head2 Setting field contents

    ### Declare this to be an HTML header:
    $head->replace('Content-type', 'text/html');


=head2 Manipulating field contents

    ### Get rid of internal newlines in fields:
    $head->unfold;

    ### Decode any Q- or B-encoded-text in fields (DEPRECATED):
    $head->decode;


=head2 Getting high-level MIME information

    ### Get/set a given MIME attribute:
    unless ($charset = $head->mime_attr('content-type.charset')) {
        $head->mime_attr("content-type.charset" => "US-ASCII");
    }

    ### The content type (e.g., "text/html"):
    $mime_type     = $head->mime_type;

    ### The content transfer encoding (e.g., "quoted-printable"):
    $mime_encoding = $head->mime_encoding;

    ### The recommended name when extracted:
    $file_name     = $head->recommended_filename;

    ### The boundary text, for multipart messages:
    $boundary      = $head->multipart_boundary;


=head1 DESCRIPTION

A class for parsing in and manipulating RFC-822 message headers, with
some methods geared towards standard (and not so standard) MIME fields
as specified in the various I<Multipurpose Internet Mail Extensions>
RFCs (starting with RFC 2045)


=head1 PUBLIC INTERFACE

=cut

#------------------------------

require 5.002;

### Pragmas:
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

### System modules:
use IO::File;

### Other modules:
use Mail::Header 1.09 ();
use Mail::Field  1.05 ();

### Kit modules:
use MIME::Words qw(:all);
use MIME::Tools qw(:config :msgs);
use MIME::Field::ParamVal;
use MIME::Field::ConTraEnc;
use MIME::Field::ContDisp;
use MIME::Field::ContType;

@ISA = qw(Mail::Header);

# The presence of more than one of the following headers
# in a given MIME entity could indicate an ambiguous parse
# and hence a security risk

my $singleton_headers =
    [
     'content-type',
     'content-disposition',
     'content-transfer-encoding',
     'content-id',
    ];

# The presence of a duplicated parameters in one of the following
# headers in a given MIME entity could indicate an ambiguous parse and
# hence a security risk
my $singleton_parameter_headers =
    [
     'content-type',
     'content-disposition',
    ];


#------------------------------
#
# Public globals...
#
#------------------------------

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.515";

### Sanity (we put this test after our own version, for CPAN::):
use Mail::Header 1.06 ();


#------------------------------

=head2 Creation, input, and output

=over 4

=cut

#------------------------------


#------------------------------

=item new [ARG],[OPTIONS]

I<Class method, inherited.>
Creates a new header object.  Arguments are the same as those in the
superclass.

=cut

sub new {
    my $class = shift;
    bless Mail::Header->new(@_), $class;
}

=item ambiguous_content

I<Instance method.>

Returns true if this header has any the following properties:

=over 4

More than one Content-Type, Content-ID, Content-Transfer-Encoding or
Content-Disposition header.

A Content-Type or Content-Disposition header contains a repeated
parameter.

=back

Messages with ambiguous content should be treated as a security risk.
In particular, if MIME-tools is used in an email security tool,
ambiguous messages should not be delivered to end-users.

=cut
sub ambiguous_content {
    my ($self) = @_;

    foreach my $hdr (@$singleton_headers) {
        if ($self->count($hdr) > 1) {
            return 1;
        }
    }

    foreach my $hdr (@$singleton_parameter_headers) {
        if ($self->mime_attr($hdr . '.@duplicate_parameters')) {
            return 1;
        }
    }
    return 0;
}
#------------------------------

=item from_file EXPR,OPTIONS

I<Class or instance method>.
For convenience, you can use this to parse a header object in from EXPR,
which may actually be any expression that can be sent to open() so as to
return a readable filehandle.  The "file" will be opened, read, and then
closed:

    ### Create a new header by parsing in a file:
    my $head = MIME::Head->from_file("/tmp/test.hdr");

Since this method can function as either a class constructor I<or>
an instance initializer, the above is exactly equivalent to:

    ### Create a new header by parsing in a file:
    my $head = MIME::Head->new->from_file("/tmp/test.hdr");

On success, the object will be returned; on failure, the undefined value.

The OPTIONS are the same as in new(), and are passed into new()
if this is invoked as a class method.

B<Note:> This is really just a convenience front-end onto C<read()>,
provided mostly for backwards-compatibility with MIME-parser 1.0.

=cut

sub from_file {
    my ($self, $file, @opts) = @_; ### at this point, $self is inst. or class!
    my $class = ref($self) ? ref($self) : $self;

    ### Parse:
    my $fh = IO::File->new($file, '<') or return error("open $file: $!");
    $fh->binmode() or return error("binmode $file: $!");  # we expect to have \r\n at line ends, and want to keep 'em.
    $self = $class->new($fh, @opts);      ### now, $self is instance or undef
    $fh->close or return error("close $file: $!");
    $self;
}

#------------------------------

=item read FILEHANDLE

I<Instance (or class) method.>
This initializes a header object by reading it in from a FILEHANDLE,
until the terminating blank line is encountered.
A syntax error or end-of-stream will also halt processing.

Supply this routine with a reference to a filehandle glob; e.g., C<\*STDIN>:

    ### Create a new header by parsing in STDIN:
    $head->read(\*STDIN);

On success, the self object will be returned; on failure, a false value.

B<Note:> in the MIME world, it is perfectly legal for a header to be
empty, consisting of nothing but the terminating blank line.  Thus,
we can't just use the formula that "no tags equals error".

B<Warning:> as of the time of this writing, Mail::Header::read did not flag
either syntax errors or unexpected end-of-file conditions (an EOF
before the terminating blank line).  MIME::ParserBase takes this
into account.

=cut

sub read {
    my $self = shift;      ### either instance or class!
    ref($self) or $self = $self->new;    ### if used as class method, make new
    $self->SUPER::read(@_);
}



#------------------------------

=back

=head2 Getting/setting fields

The following are methods related to retrieving and modifying the header
fields.  Some are inherited from Mail::Header, but I've kept the
documentation around for convenience.

=over 4

=cut

#------------------------------


#------------------------------

=item add TAG,TEXT,[INDEX]

I<Instance method, inherited.>
Add a new occurrence of the field named TAG, given by TEXT:

    ### Add the trace information:
    $head->add('Received',
               'from eryq.pr.mcs.net by gonzo.net with smtp');

Normally, the new occurrence will be I<appended> to the existing
occurrences.  However, if the optional INDEX argument is 0, then the
new occurrence will be I<prepended>.  If you want to be I<explicit>
about appending, specify an INDEX of -1.

B<Warning>: this method always adds new occurrences; it doesn't overwrite
any existing occurrences... so if you just want to I<change> the value
of a field (creating it if necessary), then you probably B<don't> want to use
this method: consider using C<replace()> instead.

=cut

### Inherited.

#------------------------------
#
# copy
#
# Instance method, DEPRECATED.
# Duplicate the object.
#
sub copy {
    usage "deprecated: use dup() instead.";
    shift->dup(@_);
}

#------------------------------

=item count TAG

I<Instance method, inherited.>
Returns the number of occurrences of a field; in a boolean context, this
tells you whether a given field exists:

    ### Was a "Subject:" field given?
    $subject_was_given = $head->count('subject');

The TAG is treated in a case-insensitive manner.
This method returns some false value if the field doesn't exist,
and some true value if it does.

=cut

### Inherited.


#------------------------------

=item decode [FORCE]

I<Instance method, DEPRECATED.>
Go through all the header fields, looking for RFC 1522 / RFC 2047 style
"Q" (quoted-printable, sort of) or "B" (base64) encoding, and decode
them in-place.  Fellow Americans, you probably don't know what the hell
I'm talking about.  Europeans, Russians, et al, you probably do.
C<:-)>.

B<This method has been deprecated.>
See L<MIME::Parser/decode_headers> for the full reasons.
If you absolutely must use it and don't like the warning, then
provide a FORCE:

   "I_NEED_TO_FIX_THIS"
          Just shut up and do it.  Not recommended.
          Provided only for those who need to keep old scripts functioning.

   "I_KNOW_WHAT_I_AM_DOING"
          Just shut up and do it.  Not recommended.
          Provided for those who REALLY know what they are doing.

B<What this method does.>
For an example, let's consider a valid email header you might get:

    From: =?US-ASCII?Q?Keith_Moore?= <moore@cs.utk.edu>
    To: =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?= <keld@dkuug.dk>
    CC: =?ISO-8859-1?Q?Andr=E9_?= Pirard <PIRARD@vm1.ulg.ac.be>
    Subject: =?ISO-8859-1?B?SWYgeW91IGNhbiByZWFkIHRoaXMgeW8=?=
     =?ISO-8859-2?B?dSB1bmRlcnN0YW5kIHRoZSBleGFtcGxlLg==?=
     =?US-ASCII?Q?.._cool!?=

That basically decodes to (sorry, I can only approximate the
Latin characters with 7 bit sequences /o and 'e):

    From: Keith Moore <moore@cs.utk.edu>
    To: Keld J/orn Simonsen <keld@dkuug.dk>
    CC: Andr'e  Pirard <PIRARD@vm1.ulg.ac.be>
    Subject: If you can read this you understand the example... cool!

B<Note:> currently, the decodings are done without regard to the
character set: thus, the Q-encoding C<=F8> is simply translated to the
octet (hexadecimal C<F8>), period.  For piece-by-piece decoding
of a given field, you want the array context of
C<MIME::Words::decode_mimewords()>.

B<Warning:> the CRLF+SPACE separator that splits up long encoded words
into shorter sequences (see the Subject: example above) gets lost
when the field is unfolded, and so decoding after unfolding causes
a spurious space to be left in the field.
I<THEREFORE: if you're going to decode, do so BEFORE unfolding!>

This method returns the self object.

I<Thanks to Kent Boortz for providing the idea, and the baseline
RFC-1522-decoding code.>

=cut

sub decode {
    my $self = shift;

    ### Warn if necessary:
    my $force = shift || 0;
    unless (($force eq "I_NEED_TO_FIX_THIS") ||
	    ($force eq "I_KNOW_WHAT_I_AM_DOING")) {
	usage "decode is deprecated for safety";
    }

    my ($tag, $i, @decoded);
    foreach $tag ($self->tags) {
	@decoded = map { scalar(decode_mimewords($_, Field=>$tag))
			 } $self->get_all($tag);
	for ($i = 0; $i < @decoded; $i++) {
	    $self->replace($tag, $decoded[$i], $i);
	}
    }
    $self->{MH_Decoded} = 1;
    $self;
}

#------------------------------

=item delete TAG,[INDEX]

I<Instance method, inherited.>
Delete all occurrences of the field named TAG.

    ### Remove some MIME information:
    $head->delete('MIME-Version');
    $head->delete('Content-type');

=cut

### Inherited


#------------------------------
#
# exists
#
sub exists {
    usage "deprecated; use count() instead";
    shift->count(@_);
}

#------------------------------
#
# fields
#
sub fields {
    usage "deprecated: use tags() instead",
    shift->tags(@_);
}

#------------------------------

=item get TAG,[INDEX]

I<Instance method, inherited.>
Get the contents of field TAG.

If a B<numeric INDEX> is given, returns the occurrence at that index,
or undef if not present:

    ### Print the first and last 'Received:' entries (explicitly):
    print "First, or most recent: ", $head->get('received', 0);
    print "Last, or least recent: ", $head->get('received',-1);

If B<no INDEX> is given, but invoked in a B<scalar> context, then
INDEX simply defaults to 0:

    ### Get the first 'Received:' entry (implicitly):
    my $most_recent = $head->get('received');

If B<no INDEX> is given, and invoked in an B<array> context, then
I<all> occurrences of the field are returned:

    ### Get all 'Received:' entries:
    my @all_received = $head->get('received');

B<NOTE>: The header(s) returned may end with a newline.  If you don't
want this, then B<chomp> the return value.

=cut

### Inherited.


#------------------------------

=item get_all FIELD

I<Instance method.>
Returns the list of I<all> occurrences of the field, or the
empty list if the field is not present:

    ### How did it get here?
    @history = $head->get_all('Received');

B<Note:> I had originally experimented with having C<get()> return all
occurrences when invoked in an array context... but that causes a lot of
accidents when you get careless and do stuff like this:

    print "\u$field: ", $head->get($field);

It also made the intuitive behaviour unclear if the INDEX argument
was given in an array context.  So I opted for an explicit approach
to asking for all occurrences.

=cut

sub get_all {
    my ($self, $tag) = @_;
    $self->count($tag) or return ();          ### empty if doesn't exist
    ($self->get($tag));
}

#------------------------------
#
# original_text
#
# Instance method, DEPRECATED.
# Return an approximation of the original text.
#
sub original_text {
    usage "deprecated: use stringify() instead";
    shift->stringify(@_);
}

#------------------------------

=item print [OUTSTREAM]

I<Instance method, override.>
Print the header out to the given OUTSTREAM, or the currently-selected
filehandle if none.  The OUTSTREAM may be a filehandle, or any object
that responds to a print() message.

The override actually lets you print to any object that responds to
a print() method.  This is vital for outputting MIME entities to scalars.

Also, it defaults to the I<currently-selected> filehandle if none is given
(not STDOUT!), so I<please> supply a filehandle to prevent confusion.

=cut

sub print {
    my ($self, $fh) = @_;
    $fh ||= select;
    $fh->print($self->as_string);
}

#------------------------------
#
# set TAG,TEXT
#
# Instance method, DEPRECATED.
# Set the field named TAG to [the single occurrence given by the TEXT.
#
sub set {
    my $self = shift;
    usage "deprecated: use the replace() method instead.";
    $self->replace(@_);
}

#------------------------------

=item stringify

I<Instance method.>
Return the header as a string.  You can also invoke it as C<as_string>.

If you set the variable $MIME::Entity::BOUNDARY_DELIMITER to a string,
that string will be used as line-end delimiter.  If it is not set,
the line ending will be a newline character (\n)

=cut

sub stringify {
    my $self = shift;          ### build clean header, and output...
    my @header = grep {defined($_) ? $_ : ()} @{$self->header};
    my $header_delimiter = $MIME::Entity::BOUNDARY_DELIMITER || "\n";
    join "", map { /\n$/ ? substr($_, 0, -1) . $header_delimiter : $_ . $header_delimiter } @header;
}
sub as_string { shift->stringify(@_) }

#------------------------------

=item unfold [FIELD]

I<Instance method, inherited.>
Unfold (remove newlines in) the text of all occurrences of the given FIELD.
If the FIELD is omitted, I<all> fields are unfolded.
Returns the "self" object.

=cut

### Inherited


#------------------------------

=back

=head2 MIME-specific methods

All of the following methods extract information from the following fields:

    Content-type
    Content-transfer-encoding
    Content-disposition

Be aware that they do not just return the raw contents of those fields,
and in some cases they will fill in sensible (I hope) default values.
Use C<get()> or C<mime_attr()> if you need to grab and process the
raw field text.

B<Note:> some of these methods are provided both as a convenience and
for backwards-compatibility only, while others (like
recommended_filename()) I<really do have to be in MIME::Head to work
properly,> since they look for their value in more than one field.
However, if you know that a value is restricted to a single
field, you should really use the Mail::Field interface to get it.

=over 4

=cut

#------------------------------


#------------------------------
#
# params TAG
#
# Instance method, DEPRECATED.
# Extract parameter info from a structured field, and return
# it as a hash reference.  Provided for 1.0 compatibility only!
# Use the new MIME::Field interface classes (subclasses of Mail::Field).

sub params {
    my ($self, $tag) = @_;
    usage "deprecated: use the MIME::Field interface classes from now on!";
    return MIME::Field::ParamVal->parse_params($self->get($tag,0));
}

#------------------------------

=item mime_attr ATTR,[VALUE]

A quick-and-easy interface to set/get the attributes in structured
MIME fields:

    $head->mime_attr("content-type"         => "text/html");
    $head->mime_attr("content-type.charset" => "US-ASCII");
    $head->mime_attr("content-type.name"    => "homepage.html");

This would cause the final output to look something like this:

    Content-type: text/html; charset=US-ASCII; name="homepage.html"

Note that the special empty sub-field tag indicates the anonymous
first sub-field.

B<Giving VALUE as undefined> will cause the contents of the named subfield
to be deleted:

    $head->mime_attr("content-type.charset" => undef);

B<Supplying no VALUE argument> just returns the attribute's value,
or undefined if it isn't there:

    $type = $head->mime_attr("content-type");      ### text/html
    $name = $head->mime_attr("content-type.name"); ### homepage.html

In all cases, the new/current value is returned.

The special sub-field tag C<@duplicate_parameters> (which can never be
a real tag) returns an arrayref of tags that were duplicated in the header,
or C<undef> if no such tags were found.  For example, given the header:

    Content-Type: multipart/mixed; boundary="foo"; boundary="bar"

Then:

    $head->mime_attr('content-type.@duplicate_parameters')

would return:

    [ 'boundary' ]

A duplicate "boundary" tag should be treated as a security risk, as should
duplicate Content-Type headers in a message.  Since such messages cannot
be parsed unambiguously, we strongly recommend that they never be
delivered to end-users.

=cut

sub mime_attr {
    my ($self, $attr, $value) = @_;

    ### Break attribute name up:
    my ($tag, $subtag) = split /\./, $attr;
    $subtag ||= '_';

    ### Set or get?
    my $field = MIME::Field::ParamVal->parse($self->get($tag, 0));
    if (@_ > 2) {   ### set it:
	$field->param($subtag, $value);             ### set subfield
	$self->replace($tag, $field->stringify);    ### replace!
	return $value;
    }
    else {          ### get it:
	return $field->param($subtag);
    }
}

#------------------------------

=item mime_encoding

I<Instance method.>
Try I<real hard> to determine the content transfer encoding
(e.g., C<"base64">, C<"binary">), which is returned in all-lowercase.

If no encoding could be found, the default of C<"7bit"> is returned
I quote from RFC 2045 section 6.1:

    This is the default value -- that is, "Content-Transfer-Encoding: 7BIT"
    is assumed if the Content-Transfer-Encoding header field is not present.

I do one other form of fixup: "7_bit", "7-bit", and "7 bit" are
corrected to "7bit"; likewise for "8bit".

=cut

sub mime_encoding {
    my $self = shift;
    my $enc = lc($self->mime_attr('content-transfer-encoding') || '7bit');
    $enc =~ s{^([78])[ _-]bit\Z}{$1bit};
    $enc;
}

#------------------------------

=item mime_type [DEFAULT]

I<Instance method.>
Try C<real hard> to determine the content type (e.g., C<"text/plain">,
C<"image/gif">, C<"x-weird-type">, which is returned in all-lowercase.
"Real hard" means that if no content type could be found, the default
(usually C<"text/plain">) is returned.  From RFC 2045 section 5.2:

   Default RFC 822 messages without a MIME Content-Type header are
   taken by this protocol to be plain text in the US-ASCII character
   set, which can be explicitly specified as:

      Content-type: text/plain; charset=us-ascii

   This default is assumed if no Content-Type header field is specified.

Unless this is a part of a "multipart/digest", in which case
"message/rfc822" is the default.  Note that you can also I<set> the
default, but you shouldn't: normally only the MIME parser uses this
feature.

=cut

sub mime_type {
    my ($self, $default) = @_;
    $self->{MIH_DefaultType} = $default if @_ > 1;
    my $s = $self->mime_attr('content-type') ||
       $self->{MIH_DefaultType} ||
       'text/plain';
    # avoid [perl #87336] bug, lc laundering tainted data
    return lc($s)  if $] <= 5.008 || $] >= 5.014;
    $s =~ tr/A-Z/a-z/;
    $s;
}

#------------------------------

=item multipart_boundary

I<Instance method.>
If this is a header for a multipart message, return the
"encapsulation boundary" used to separate the parts.  The boundary
is returned exactly as given in the C<Content-type:> field; that
is, the leading double-hyphen (C<-->) is I<not> prepended.

Well, I<almost> exactly... this passage from RFC 2046 dictates
that we remove any trailing spaces:

   If a boundary appears to end with white space, the white space
   must be presumed to have been added by a gateway, and must be deleted.

Returns undef (B<not> the empty string) if either the message is not
multipart or if there is no specified boundary.

=cut

sub multipart_boundary {
    my $self = shift;
    my $value =  $self->mime_attr('content-type.boundary');
    (!defined($value)) ? undef : $value;
}

#------------------------------

=item recommended_filename

I<Instance method.>
Return the recommended external filename.  This is used when
extracting the data from the MIME stream.  The filename is always
returned as a string in Perl's internal format (the UTF8 flag may be on!)

Returns undef if no filename could be suggested.

=cut

sub recommended_filename
{
	my $self = shift;

	# Try these headers in order, taking the first defined,
	# non-blank one we find.
	my $wd = supported MIME::WordDecoder 'UTF-8';
	foreach my $attr_name ( qw( content-disposition.filename content-type.name ) ) {
		my $value = $self->mime_attr( $attr_name );
		if ( defined $value
		    && $value ne ''
		    && $value =~ /\S/ ) {
			return $wd->decode($value);
		}
	}

	return undef;
}

#------------------------------

=back

=cut


#------------------------------
#
# tweak_FROM_parsing
#
# DEPRECATED.  Use the inherited mail_from() class method now.

sub tweak_FROM_parsing {
    my $self = shift;
    usage "deprecated.  Use mail_from() instead.";
    $self->mail_from(@_);
}


__END__

#------------------------------


=head1 NOTES

=over 4

=item Why have separate objects for the entity, head, and body?

See the documentation for the MIME-tools distribution
for the rationale behind this decision.


=item Why assume that MIME headers are email headers?

I quote from Achim Bohnet, who gave feedback on v.1.9 (I think
he's using the word "header" where I would use "field"; e.g.,
to refer to "Subject:", "Content-type:", etc.):

    There is also IMHO no requirement [for] MIME::Heads to look
    like [email] headers; so to speak, the MIME::Head [simply stores]
    the attributes of a complex object, e.g.:

        new MIME::Head type => "text/plain",
                       charset => ...,
                       disposition => ..., ... ;

I agree in principle, but (alas and dammit) RFC 2045 says otherwise.
RFC 2045 [MIME] headers are a syntactic subset of RFC-822 [email] headers.

In my mind's eye, I see an abstract class, call it MIME::Attrs, which does
what Achim suggests... so you could say:

     my $attrs = new MIME::Attrs type => "text/plain",
				 charset => ...,
                                 disposition => ..., ... ;

We could even make it a superclass of MIME::Head: that way, MIME::Head
would have to implement its interface, I<and> allow itself to be
initialized from a MIME::Attrs object.

However, when you read RFC 2045, you begin to see how much MIME information
is organized by its presence in particular fields.  I imagine that we'd
begin to mirror the structure of RFC 2045 fields and subfields to such
a degree that this might not give us a tremendous gain over just
having MIME::Head.


=item Why all this "occurrence" and "index" jazz?  Isn't every field unique?

Aaaaaaaaaahh....no.

Looking at a typical mail message header, it is sooooooo tempting to just
store the fields as a hash of strings, one string per hash entry.
Unfortunately, there's the little matter of the C<Received:> field,
which (unlike C<From:>, C<To:>, etc.) will often have multiple
occurrences; e.g.:

    Received: from gsfc.nasa.gov by eryq.pr.mcs.net  with smtp
        (Linux Smail3.1.28.1 #5) id m0tStZ7-0007X4C;
	 Thu, 21 Dec 95 16:34 CST
    Received: from rhine.gsfc.nasa.gov by gsfc.nasa.gov
	 (5.65/Ultrix3.0-C) id AA13596;
	 Thu, 21 Dec 95 17:20:38 -0500
    Received: (from eryq@localhost) by rhine.gsfc.nasa.gov
	 (8.6.12/8.6.12) id RAA28069;
	 Thu, 21 Dec 1995 17:27:54 -0500
    Date: Thu, 21 Dec 1995 17:27:54 -0500
    From: Eryq <eryq@rhine.gsfc.nasa.gov>
    Message-Id: <199512212227.RAA28069@rhine.gsfc.nasa.gov>
    To: eryq@eryq.pr.mcs.net
    Subject: Stuff and things

The C<Received:> field is used for tracing message routes, and although
it's not generally used for anything other than human debugging, I
didn't want to inconvenience anyone who actually wanted to get at that
information.

I also didn't want to make this a special case; after all, who
knows what other fields could have multiple occurrences in the
future?  So, clearly, multiple entries had to somehow be stored
multiple times... and the different occurrences had to be retrievable.

=back

=head1 SEE ALSO

L<Mail::Header>, L<Mail::Field>, L<MIME::Words>, L<MIME::Tools>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (dianne@skoll.ca)

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The more-comprehensive filename extraction is courtesy of
Lee E. Brotzman, Advanced Data Solutions.

=cut

1;
