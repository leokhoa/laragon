package MIME::Entity;


=head1 NAME

MIME::Entity - class for parsed-and-decoded MIME message


=head1 SYNOPSIS

Before reading further, you should see L<MIME::Tools> to make sure that
you understand where this module fits into the grand scheme of things.
Go on, do it now.  I'll wait.

Ready?  Ok...

    ### Create an entity:
    $top = MIME::Entity->build(From    => 'me@myhost.com',
                               To      => 'you@yourhost.com',
                               Subject => "Hello, nurse!",
			       Data    => \@my_message);

    ### Attach stuff to it:
    $top->attach(Path     => $gif_path,
		 Type     => "image/gif",
		 Encoding => "base64");

    ### Sign it:
    $top->sign;

    ### Output it:
    $top->print(\*STDOUT);


=head1 DESCRIPTION

A subclass of B<Mail::Internet>.

This package provides a class for representing MIME message entities,
as specified in RFCs 2045, 2046, 2047, 2048 and 2049.


=head1 EXAMPLES

=head2 Construction examples

Create a document for an ordinary 7-bit ASCII text file (lots of
stuff is defaulted for us):

    $ent = MIME::Entity->build(Path=>"english-msg.txt");

Create a document for a text file with 8-bit (Latin-1) characters:

    $ent = MIME::Entity->build(Path     =>"french-msg.txt",
                               Encoding =>"quoted-printable",
                               From     =>'jean.luc@inria.fr',
                               Subject  =>"C'est bon!");

Create a document for a GIF file (the description is completely optional;
note that we have to specify content-type and encoding since they're
not the default values):

    $ent = MIME::Entity->build(Description => "A pretty picture",
                               Path        => "./docs/mime-sm.gif",
                               Type        => "image/gif",
                               Encoding    => "base64");

Create a document that you already have the text for, using "Data":

    $ent = MIME::Entity->build(Type        => "text/plain",
                               Encoding    => "quoted-printable",
                               Data        => ["First line.\n",
                                              "Second line.\n",
                                              "Last line.\n"]);

Create a multipart message, with the entire structure given
explicitly:

    ### Create the top-level, and set up the mail headers:
    $top = MIME::Entity->build(Type     => "multipart/mixed",
                               From     => 'me@myhost.com',
                               To       => 'you@yourhost.com',
                               Subject  => "Hello, nurse!");

    ### Attachment #1: a simple text document:
    $top->attach(Path=>"./testin/short.txt");

    ### Attachment #2: a GIF file:
    $top->attach(Path        => "./docs/mime-sm.gif",
                 Type        => "image/gif",
                 Encoding    => "base64");

    ### Attachment #3: text we'll create with text we have on-hand:
    $top->attach(Data => $contents);

Suppose you don't know ahead of time that you'll have attachments?
No problem: you can "attach" to singleparts as well:

    $top = MIME::Entity->build(From    => 'me@myhost.com',
			       To      => 'you@yourhost.com',
			       Subject => "Hello, nurse!",
			       Data    => \@my_message);
    if ($GIF_path) {
	$top->attach(Path     => $GIF_path,
	             Type     => 'image/gif');
    }

Copy an entity (headers, parts... everything but external body data):

    my $deepcopy = $top->dup;



=head2 Access examples

    ### Get the head, a MIME::Head:
    $head = $ent->head;

    ### Get the body, as a MIME::Body;
    $bodyh = $ent->bodyhandle;

    ### Get the intended MIME type (as declared in the header):
    $type = $ent->mime_type;

    ### Get the effective MIME type (in case decoding failed):
    $eff_type = $ent->effective_type;

    ### Get preamble, parts, and epilogue:
    $preamble   = $ent->preamble;          ### ref to array of lines
    $num_parts  = $ent->parts;
    $first_part = $ent->parts(0);          ### an entity
    $epilogue   = $ent->epilogue;          ### ref to array of lines


=head2 Manipulation examples

Muck about with the body data:

    ### Read the (unencoded) body data:
    if ($io = $ent->open("r")) {
	while (defined($_ = $io->getline)) { print $_ }
	$io->close;
    }

    ### Write the (unencoded) body data:
    if ($io = $ent->open("w")) {
	foreach (@lines) { $io->print($_) }
	$io->close;
    }

    ### Delete the files for any external (on-disk) data:
    $ent->purge;

Muck about with the signature:

    ### Sign it (automatically removes any existing signature):
    $top->sign(File=>"$ENV{HOME}/.signature");

    ### Remove any signature within 15 lines of the end:
    $top->remove_sig(15);

Muck about with the headers:

    ### Compute content-lengths for singleparts based on bodies:
    ###   (Do this right before you print!)
    $entity->sync_headers(Length=>'COMPUTE');

Muck about with the structure:

    ### If a 0- or 1-part multipart, collapse to a singlepart:
    $top->make_singlepart;

    ### If a singlepart, inflate to a multipart with 1 part:
    $top->make_multipart;

Delete parts:

    ### Delete some parts of a multipart message:
    my @keep = grep { keep_part($_) } $msg->parts;
    $msg->parts(\@keep);


=head2 Output examples

Print to filehandles:

    ### Print the entire message:
    $top->print(\*STDOUT);

    ### Print just the header:
    $top->print_header(\*STDOUT);

    ### Print just the (encoded) body... includes parts as well!
    $top->print_body(\*STDOUT);

Stringify... note that C<stringify_xx> can also be written C<xx_as_string>;
the methods are synonymous, and neither form will be deprecated.

If you set the variable $MIME::Entity::BOUNDARY_DELIMITER to a string,
that string will be used as the line-end delimiter on output.  If it is not set,
the line ending will be a newline character (\n)

NOTE that $MIME::Entity::BOUNDARY_DELIMITER only applies to structural
parts of the MIME data generated by this package and to the Base64
encoded output; if a part internally uses a different line-end
delimiter and is output as-is, the line-ending is not changed to match
$MIME::Entity::BOUNDARY_DELIMITER.

    ### Stringify the entire message:
    print $top->stringify;              ### or $top->as_string

    ### Stringify just the header:
    print $top->stringify_header;       ### or $top->header_as_string

    ### Stringify just the (encoded) body... includes parts as well!
    print $top->stringify_body;         ### or $top->body_as_string

Debug:

    ### Output debugging info:
    $entity->dump_skeleton(\*STDERR);



=head1 PUBLIC INTERFACE

=cut

#------------------------------

### Pragmas:
use vars qw(@ISA $VERSION);
use strict;

### System modules:
use Carp;

### Other modules:
use Mail::Internet 1.28 ();
use Mail::Field    1.05 ();

### Kit modules:
use MIME::Tools qw(:config :msgs :utils);
use MIME::Head;
use MIME::Body;
use MIME::Decoder;

@ISA = qw(Mail::Internet);


#------------------------------
#
# Globals...
#
#------------------------------

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";

### Boundary counter:
my $BCount = 0;

### Standard "Content-" MIME fields, for scrub():
my $StandardFields = 'Description|Disposition|Id|Type|Transfer-Encoding';

### Known Mail/MIME fields... these, plus some general forms like
### "x-*", are recognized by build():
my %KnownField = map {$_=>1}
qw(
   bcc         cc          comments      date          encrypted
   from        keywords    message-id    mime-version  organization
   received    references  reply-to      return-path   sender
   subject     to
   );

### Fallback preamble and epilogue:
my $DefPreamble = [ "This is a multi-part message in MIME format..." ];
my $DefEpilogue = [ ];


#==============================
#
# Utilities, private
#

#------------------------------
#
# known_field FIELDNAME
#
# Is this a recognized Mail/MIME field?
#
sub known_field {
    my $field = lc(shift);
    $KnownField{$field} or ($field =~ m{^(content|resent|x)-.});
}

#------------------------------
#
# make_boundary
#
# Return a unique boundary string.
# This is used both internally and by MIME::ParserBase, but it is NOT in
# the public interface!  Do not use it!
#
# We generate one containing a "=_", as RFC2045 suggests:
#    A good strategy is to choose a boundary that includes a character
#    sequence such as "=_" which can never appear in a quoted-printable
#    body.  See the definition of multipart messages in RFC 2046.
#
sub make_boundary {
    return "----------=_".scalar(time)."-$$-".$BCount++;
}






#==============================

=head2 Construction

=over 4

=cut


#------------------------------

=item new [SOURCE]

I<Class method.>
Create a new, empty MIME entity.
Basically, this uses the Mail::Internet constructor...

If SOURCE is an ARRAYREF, it is assumed to be an array of lines
that will be used to create both the header and an in-core body.

Else, if SOURCE is defined, it is assumed to be a filehandle
from which the header and in-core body is to be read.

B<Note:> in either case, the body will not be I<parsed:> merely read!

=cut

sub new {
    my $class = shift;
    my $self = $class->Mail::Internet::new(@_);   ### inherited
    $self->{ME_Parts} = [];                       ### no parts extracted
    $self;
}


###------------------------------

=item add_part ENTITY, [OFFSET]

I<Instance method.>
Assuming we are a multipart message, add a body part (a MIME::Entity)
to the array of body parts.  Returns the part that was just added.

If OFFSET is positive, the new part is added at that offset from the
beginning of the array of parts.  If it is negative, it counts from
the end of the array.  (An INDEX of -1 will place the new part at the
very end of the array, -2 will place it as the penultimate item in the
array, etc.)  If OFFSET is not given, the new part is added to the end
of the array.
I<Thanks to Jason L Tibbitts III for providing support for OFFSET.>

B<Warning:> in general, you only want to attach parts to entities
with a content-type of C<multipart/*>).

=cut

sub add_part {
    my ($self, $part, $index) = @_;
    defined($index) or $index = -1;

    ### Make $index count from the end if negative:
    $index = $#{$self->{ME_Parts}} + 2 + $index if ($index < 0);
    splice(@{$self->{ME_Parts}}, $index, 0, $part);
    $part;
}

#------------------------------

=item attach PARAMHASH

I<Instance method.>
The real quick-and-easy way to create multipart messages.
The PARAMHASH is used to C<build> a new entity; this method is
basically equivalent to:

    $entity->add_part(ref($entity)->build(PARAMHASH, Top=>0));

B<Note:> normally, you attach to multipart entities; however, if you
attach something to a singlepart (like attaching a GIF to a text
message), the singlepart will be coerced into a multipart automatically.

=cut

sub attach {
    my $self = shift;
    $self->make_multipart;
    $self->add_part(ref($self)->build(@_, Top=>0));
}

#------------------------------

=item build PARAMHASH

I<Class/instance method.>
A quick-and-easy catch-all way to create an entity.  Use it like this
to build a "normal" single-part entity:

   $ent = MIME::Entity->build(Type     => "image/gif",
		              Encoding => "base64",
                              Path     => "/path/to/xyz12345.gif",
                              Filename => "saveme.gif",
                              Disposition => "attachment");

And like this to build a "multipart" entity:

   $ent = MIME::Entity->build(Type     => "multipart/mixed",
                              Boundary => "---1234567");

A minimal MIME header will be created.  If you want to add or modify
any header fields afterwards, you can of course do so via the underlying
head object... but hey, there's now a prettier syntax!

   $ent = MIME::Entity->build(Type          =>"multipart/mixed",
                              From          => $myaddr,
                              Subject       => "Hi!",
                              'X-Certified' => ['SINED',
                                                'SEELED',
                                                'DELIVERED']);

Normally, an C<X-Mailer> header field is output which contains this
toolkit's name and version (plus this module's RCS version).
This will allow any bad MIME we generate to be traced back to us.
You can of course overwrite that header with your own:

   $ent = MIME::Entity->build(Type        => "multipart/mixed",
                              'X-Mailer'  => "myprog 1.1");

Or remove it entirely:

   $ent = MIME::Entity->build(Type       => "multipart/mixed",
                              'X-Mailer' => undef);

OK, enough hype.  The parameters are:

=over 4

=item (FIELDNAME)

Any field you want placed in the message header, taken from the
standard list of header fields (you don't need to worry about case):

    Bcc           Encrypted     Received      Sender
    Cc            From          References    Subject
    Comments	  Keywords      Reply-To      To
    Content-*	  Message-ID    Resent-*      X-*
    Date          MIME-Version  Return-Path
                  Organization

To give experienced users some veto power, these fields will be set
I<after> the ones I set... so be careful: I<don't set any MIME fields>
(like C<Content-type>) unless you know what you're doing!

To specify a fieldname that's I<not> in the above list, even one that's
identical to an option below, just give it with a trailing C<":">,
like C<"My-field:">.  When in doubt, that I<always> signals a mail
field (and it sort of looks like one too).

=item Boundary

I<Multipart entities only. Optional.>
The boundary string.  As per RFC-2046, it must consist only
of the characters C<[0-9a-zA-Z'()+_,-./:=?]> and space (you'll be
warned, and your boundary will be ignored, if this is not the case).
If you omit this, a random string will be chosen... which is probably
safer.

=item Charset

I<Optional.>
The character set.

=item Data

I<Single-part entities only. Optional.>
An alternative to Path (q.v.): the actual data, either as a scalar
or an array reference (whose elements are joined together to make
the actual scalar).  The body is opened on the data using
MIME::Body::InCore.

=item Description

I<Optional.>
The text of the content-description.
If you don't specify it, the field is not put in the header.

=item Disposition

I<Optional.>
The basic content-disposition (C<"attachment"> or C<"inline">).
If you don't specify it, it defaults to "inline" for backwards
compatibility.  I<Thanks to Kurt Freytag for suggesting this feature.>

=item Encoding

I<Optional.>
The content-transfer-encoding.
If you don't specify it, a reasonable default is put in.
You can also give the special value '-SUGGEST', to have it chosen for
you in a heavy-duty fashion which scans the data itself.

=item Filename

I<Single-part entities only. Optional.>
The recommended filename.  Overrides any name extracted from C<Path>.
The information is stored both the deprecated (content-type) and
preferred (content-disposition) locations.  If you explicitly want to
I<avoid> a recommended filename (even when Path is used), supply this
as empty or undef.

=item Id

I<Optional.>
Set the content-id.

=item Path

I<Single-part entities only. Optional.>
The path to the file to attach.  The body is opened on that file
using MIME::Body::File.

=item Top

I<Optional.>
Is this a top-level entity?  If so, it must sport a MIME-Version.
The default is true.  (NB: look at how C<attach()> uses it.)

=item Type

I<Optional.>
The basic content-type (C<"text/plain">, etc.).
If you don't specify it, it defaults to C<"text/plain">
as per RFC 2045.  I<Do yourself a favor: put it in.>

=back

=cut

sub build {
    my ($self, @paramlist) = @_;
    my %params = @paramlist;
    my ($field, $filename, $boundary);

    ### Create a new entity, if needed:
    ref($self) or $self = $self->new;


    ### GET INFO...

    ### Get sundry field:
    my $type         = $params{Type} || 'text/plain';
    my $charset      = $params{Charset};
    my $is_multipart = ($type =~ m{^multipart/}i);
    my $encoding     = $params{Encoding} || '';
    my $desc         = $params{Description};
    my $top          = exists($params{Top}) ? $params{Top} : 1;
    my $disposition  = $params{Disposition} || 'inline';
    my $id           = $params{Id};

    ### Get recommended filename, allowing explicit no-value value:
    my ($path_fname) = (($params{Path}||'') =~ m{([^/]+)\Z});
    $filename = (exists($params{Filename}) ? $params{Filename} : $path_fname);
    $filename = undef if (defined($filename) and $filename eq '');

    ### Type-check sanity:
    if ($type =~ m{^(multipart/|message/(rfc822|partial|external-body|delivery-status|disposition-notification|feedback-report)$)}i) {
	($encoding =~ /^(|7bit|8bit|binary|-suggest)$/i)
	    or croak "can't have encoding $encoding for message type $type!";
    }

    ### Multipart or not? Do sanity check and fixup:
    if ($is_multipart) {      ### multipart...

	### Get any supplied boundary, and check it:
	if (defined($boundary = $params{Boundary})) {  ### they gave us one...
	    if ($boundary eq '') {
		whine "empty string not a legal boundary: I'm ignoring it";
		$boundary = undef;
	    }
	    elsif ($boundary =~ m{[^0-9a-zA-Z_\'\(\)\+\,\.\/\:\=\?\- ]}) {
		whine "boundary ignored: illegal characters ($boundary)";
		$boundary = undef;
	    }
	}

	### If we have to roll our own boundary, do so:
	defined($boundary) or $boundary = make_boundary();
    }
    else {                    ### single part...
	### Create body:
	if ($params{Path}) {
	    $self->bodyhandle(new MIME::Body::File $params{Path});
	}
	elsif (defined($params{Data})) {
	    $self->bodyhandle(new MIME::Body::InCore $params{Data});
	}
	else {
	    die "can't build entity: no body, and not multipart\n";
	}

	### Check whether we need to binmode():   [Steve Kilbane]
	$self->bodyhandle->binmode(1) unless textual_type($type);
    }


    ### MAKE HEAD...

    ### Create head:
    my $head = new MIME::Head;
    $self->head($head);
    $head->modify(1);

    ### Add content-type field:
    $field = new Mail::Field 'Content_type';         ### not a typo :-(
    $field->type($type);
    $field->charset($charset)    if $charset;
    $field->name($filename)      if defined($filename);
    $field->boundary($boundary)  if defined($boundary);
    $head->replace('Content-type', $field->stringify);

    ### Now that both body and content-type are available, we can suggest
    ### content-transfer-encoding (if desired);
    if (!$encoding) {
	$encoding = $self->suggest_encoding_lite;
    }
    elsif (lc($encoding) eq '-suggest') {
	$encoding = $self->suggest_encoding;
    }

    ### Add content-disposition field (if not multipart):
    unless ($is_multipart) {
	$field = new Mail::Field 'Content_disposition';  ### not a typo :-(
	$field->type($disposition);
	$field->filename($filename) if defined($filename);
	$head->replace('Content-disposition', $field->stringify);
    }

    ### Add other MIME fields:
    $head->replace('Content-transfer-encoding', $encoding) if $encoding;
    $head->replace('Content-description', $desc)           if $desc;

    # Content-Id value should be surrounded by < >, but versions before 5.428
    # did not do this.  So, we check, and add if the caller has not done so
    # already.
    if( defined $id ) {
	if( $id !~ /^<.*>$/ ) {
		$id = "<$id>";
	}
	$head->replace('Content-id', $id);
    }
    $head->replace('MIME-Version', '1.0')                  if $top;

    ### Add the X-Mailer field, if top level (use default value if not given):
    $top and $head->replace('X-Mailer',
			    "MIME-tools ".(MIME::Tools->version).
			    " (Entity "  .($VERSION).")");

    ### Add remaining user-specified fields, if any:
    while (@paramlist) {
	my ($tag, $value) = (shift @paramlist, shift @paramlist);

	### Get fieldname, if that's what it is:
	if    ($tag =~ /^-(.*)/s)  { $tag = lc($1) }    ### old style, b.c.
	elsif ($tag =~ /(.*):$/s ) { $tag = lc($1) }    ### new style
	elsif (known_field(lc($tag)))     { 1 }    ### known field
	else { next; }                             ### not a field

	### Clear head, get list of values, and add them:
	$head->delete($tag);
	foreach $value (ref($value) ? @$value : ($value)) {
	    (defined($value) && ($value ne '')) or next;
	    $head->add($tag, $value);
	}
    }

    ### Done!
    $self;
}

#------------------------------

=item dup

I<Instance method.>
Duplicate the entity.  Does a deep, recursive copy, I<but beware:>
external data in bodyhandles is I<not> copied to new files!
Changing the data in one entity's data file, or purging that entity,
I<will> affect its duplicate.  Entities with in-core data probably need
not worry.

=cut

sub dup {
    my $self = shift;
    local($_);

    ### Self (this will also dup the header):
    my $dup = bless $self->SUPER::dup(), ref($self);

    ### Any simple inst vars:
    foreach (keys %$self) {$dup->{$_} = $self->{$_} unless ref($self->{$_})};

    ### Bodyhandle:
    $dup->bodyhandle($self->bodyhandle ? $self->bodyhandle->dup : undef);

    ### Preamble and epilogue:
    foreach (qw(ME_Preamble ME_Epilogue)) {
	$dup->{$_} = [@{$self->{$_}}]  if $self->{$_};
    }

    ### Parts:
    $dup->{ME_Parts} = [];
    foreach (@{$self->{ME_Parts}}) { push @{$dup->{ME_Parts}}, $_->dup }

    ### Done!
    $dup;
}

=back

=cut





#==============================

=head2 Access

=over 4

=cut


#------------------------------

=item body [VALUE]

I<Instance method.>
Get the I<encoded> (transport-ready) body, as an array of lines.
Returns an array reference.  Each array entry is a newline-terminated
line.

This is a read-only data structure: changing its contents will have
no effect.  Its contents are identical to what is printed by
L<print_body()|/print_body>.

Provided for compatibility with Mail::Internet, so that methods
like C<smtpsend()> will work.  Note however that if VALUE is given,
a fatal exception is thrown, since you cannot use this method to
I<set> the lines of the encoded message.

If you want the raw (unencoded) body data, use the L<bodyhandle()|/bodyhandle>
method to get and use a MIME::Body.  The content-type of the entity
will tell you whether that body is best read as text (via getline())
or raw data (via read()).

=cut

sub body {
	my ($self, $value) = @_;
	my $boundary_delimiter = $MIME::Entity::BOUNDARY_DELIMITER || "\n";
	if (@_ > 1) {      ### setting body line(s)...
		croak "you cannot use body() to set the encoded contents\n";
	} else {
		my $output = '';
		my $fh = IO::File->new(\$output, '>:') or croak("Cannot open in-memory file: $!");
		$self->print_body($fh);
		close($fh);
		my @ary = split(/\n/, $output);
		# Each line needs the terminating newline
		@ary = map { "$_$boundary_delimiter" } @ary;

		return \@ary;
	}
}

#------------------------------

=item bodyhandle [VALUE]

I<Instance method.>
Get or set an abstract object representing the body of the message.
The body holds the decoded message data.

B<Note that not all entities have bodies!>
An entity will have either a body or parts: not both.
This method will I<only> return an object if this entity can
have a body; otherwise, it will return undefined.
Whether-or-not a given entity can have a body is determined by
(1) its content type, and (2) whether-or-not the parser was told to
extract nested messages:

    Type:        | Extract nested? | bodyhandle() | parts()
    -----------------------------------------------------------------------
    multipart/*  | -               | undef        | 0 or more MIME::Entity
    message/*    | true            | undef        | 0 or 1 MIME::Entity
    message/*    | false           | MIME::Body   | empty list
    (other)      | -               | MIME::Body   | empty list

If C<VALUE> I<is not> given, the current bodyhandle is returned,
or undef if the entity cannot have a body.

If C<VALUE> I<is> given, the bodyhandle is set to the new value,
and the previous value is returned.

See L</parts> for more info.

=cut

sub bodyhandle {
    my ($self, $newvalue) = @_;
    my $value = $self->{ME_Bodyhandle};
    $self->{ME_Bodyhandle} = $newvalue if (@_ > 1);
    $value;
}

#------------------------------

=item effective_type [MIMETYPE]

I<Instance method.>
Set/get the I<effective> MIME type of this entity.  This is I<usually>
identical to the actual (or defaulted) MIME type, but in some cases
it differs.  For example, from RFC-2045:

   Any entity with an unrecognized Content-Transfer-Encoding must be
   treated as if it has a Content-Type of "application/octet-stream",
   regardless of what the Content-Type header field actually says.

Why? because if we can't decode the message, then we have to take
the bytes as-is, in their (unrecognized) encoded form.  So the
message ceases to be a "text/foobar" and becomes a bunch of undecipherable
bytes -- in other words, an "application/octet-stream".

Such an entity, if parsed, would have its effective_type() set to
C<"application/octet_stream">, although the mime_type() and the contents
of the header would remain the same.

If there is no effective type, the method just returns what
mime_type() would.

B<Warning:> the effective type is "sticky"; once set, that effective_type()
will always be returned even if the conditions that necessitated setting
the effective type become no longer true.

=cut

sub effective_type {
    my $self = shift;
    $self->{ME_EffType} = shift if @_;
    return ($self->{ME_EffType} ? lc($self->{ME_EffType}) : $self->mime_type);
}


#------------------------------

=item epilogue [LINES]

I<Instance method.>
Get/set the text of the epilogue, as an array of newline-terminated LINES.
Returns a reference to the array of lines, or undef if no epilogue exists.

If there is a epilogue, it is output when printing this entity; otherwise,
a default epilogue is used.  Setting the epilogue to undef (not []!) causes
it to fallback to the default.

=cut

sub epilogue {
    my ($self, $lines) = @_;
    $self->{ME_Epilogue} = $lines if @_ > 1;
    $self->{ME_Epilogue};
}

#------------------------------

=item head [VALUE]

I<Instance method.>
Get/set the head.

If there is no VALUE given, returns the current head.  If none
exists, an empty instance of MIME::Head is created, set, and returned.

B<Note:> This is a patch over a problem in Mail::Internet, which doesn't
provide a method for setting the head to some given object.

=cut

sub head {
    my ($self, $value) = @_;
    (@_ > 1) and $self->{'mail_inet_head'} = $value;
    $self->{'mail_inet_head'} ||= new MIME::Head;       ### KLUDGE!
}

#------------------------------

=item is_multipart

I<Instance method.>
Does this entity's effective MIME type indicate that it's a multipart entity?
Returns undef (false) if the answer couldn't be determined, 0 (false)
if it was determined to be false, and true otherwise.
Note that this says nothing about whether or not parts were extracted.

NOTE: we switched to effective_type so that multiparts with
bad or missing boundaries could be coerced to an effective type
of C<application/x-unparseable-multipart>.


=cut

sub is_multipart {
    my $self = shift;
    $self->head or return undef;        ### no head, so no MIME type!
    my ($type, $subtype) = split('/', $self->effective_type);
    (($type eq 'multipart') ? 1 : 0);
}

#------------------------------

=item mime_type

I<Instance method.>
A purely-for-convenience method.  This simply relays the request to the
associated MIME::Head object.
If there is no head, returns undef in a scalar context and
the empty array in a list context.

B<Before you use this,> consider using effective_type() instead,
especially if you obtained the entity from a MIME::Parser.

=cut

sub mime_type {
    my $self = shift;
    $self->head or return (wantarray ? () : undef);
    $self->head->mime_type;
}

#------------------------------

=item open READWRITE

I<Instance method.>
A purely-for-convenience method.  This simply relays the request to the
associated MIME::Body object (see MIME::Body::open()).
READWRITE is either 'r' (open for read) or 'w' (open for write).

If there is no body, returns false.

=cut

sub open {
    my $self = shift;
    $self->bodyhandle and $self->bodyhandle->open(@_);
}

#------------------------------

=item parts

=item parts INDEX

=item parts ARRAYREF

I<Instance method.>
Return the MIME::Entity objects which are the sub parts of this
entity (if any).

I<If no argument is given,> returns the array of all sub parts,
returning the empty array if there are none (e.g., if this is a single
part message, or a degenerate multipart).  In a scalar context, this
returns you the number of parts.

I<If an integer INDEX is given,> return the INDEXed part,
or undef if it doesn't exist.

I<If an ARRAYREF to an array of parts is given,> then this method I<sets>
the parts to a copy of that array, and returns the parts.  This can
be used to delete parts, as follows:

    ### Delete some parts of a multipart message:
    $msg->parts([ grep { keep_part($_) } $msg->parts ]);


B<Note:> for multipart messages, the preamble and epilogue are I<not>
considered parts.  If you need them, use the C<preamble()> and C<epilogue()>
methods.

B<Note:> there are ways of parsing with a MIME::Parser which cause
certain message parts (such as those of type C<message/rfc822>)
to be "reparsed" into pseudo-multipart entities.  You should read the
documentation for those options carefully: it I<is> possible for
a diddled entity to not be multipart, but still have parts attached to it!

See L</bodyhandle> for a discussion of parts vs. bodies.

=cut

sub parts {
    my $self = shift;
    ref($_[0]) and return @{$self->{ME_Parts} = [@{$_[0]}]};  ### set the parts
    (@_ ? $self->{ME_Parts}[$_[0]] : @{$self->{ME_Parts}});
}

#------------------------------

=item parts_DFS

I<Instance method.>
Return the list of all MIME::Entity objects included in the entity,
starting with the entity itself, in depth-first-search order.
If the entity has no parts, it alone will be returned.

I<Thanks to Xavier Armengou for suggesting this method.>

=cut

sub parts_DFS {
    my $self = shift;
    return ($self, map { $_->parts_DFS } $self->parts);
}

#------------------------------

=item preamble [LINES]

I<Instance method.>
Get/set the text of the preamble, as an array of newline-terminated LINES.
Returns a reference to the array of lines, or undef if no preamble exists
(e.g., if this is a single-part entity).

If there is a preamble, it is output when printing this entity; otherwise,
a default preamble is used.  Setting the preamble to undef (not []!) causes
it to fallback to the default.

=cut

sub preamble {
    my ($self, $lines) = @_;
    $self->{ME_Preamble} = $lines if @_ > 1;
    $self->{ME_Preamble};
}





=back

=cut




#==============================

=head2 Manipulation

=over 4

=cut

#------------------------------

=item make_multipart [SUBTYPE], OPTSHASH...

I<Instance method.>
Force the entity to be a multipart, if it isn't already.
We do this by replacing the original [singlepart] entity with a new
multipart that has the same non-MIME headers ("From", "Subject", etc.),
but all-new MIME headers ("Content-type", etc.).  We then create
a copy of the original singlepart, I<strip out> the non-MIME headers
from that, and make it a part of the new multipart.  So this:

    From: me
    To: you
    Content-type: text/plain
    Content-length: 12

    Hello there!

Becomes something like this:

    From: me
    To: you
    Content-type: multipart/mixed; boundary="----abc----"

    ------abc----
    Content-type: text/plain
    Content-length: 12

    Hello there!
    ------abc------

The actual type of the new top-level multipart will be "multipart/SUBTYPE"
(default SUBTYPE is "mixed").

Returns 'DONE'    if we really did inflate a singlepart to a multipart.
Returns 'ALREADY' (and does nothing) if entity is I<already> multipart
and Force was not chosen.

If OPTSHASH contains Force=>1, then we I<always> bump the top-level's
content and content-headers down to a subpart of this entity, even if
this entity is already a multipart.  This is apparently of use to
people who are tweaking messages after parsing them.

=cut

sub make_multipart {
    my ($self, $subtype, %opts) = @_;
    my $tag;
    $subtype ||= 'mixed';
    my $force = $opts{Force};

    ### Trap for simple case: already a multipart?
    return 'ALREADY' if ($self->is_multipart and !$force);

    ### Rip out our guts, and spew them into our future part:
    my $part = bless {%$self}, ref($self);         ### part is a shallow copy
    %$self = ();                                   ### lobotomize ourselves!
    $self->head($part->head->dup);                 ### dup the header

    ### Remove content headers from top-level, and set it up as a multipart:
    foreach $tag (grep {/^content-/i} $self->head->tags) {
	$self->head->delete($tag);
    }
    $self->head->mime_attr('Content-type'          => "multipart/$subtype");
    $self->head->mime_attr('Content-type.boundary' => make_boundary());

    ### Remove NON-content headers from the part:
    foreach $tag (grep {!/^content-/i} $part->head->tags) {
	$part->head->delete($tag);
    }

    ### Add the [sole] part:
    $self->{ME_Parts} = [];
    $self->add_part($part);
    'DONE';
}

#------------------------------

=item make_singlepart

I<Instance method.>
If the entity is a multipart message with one part, this tries hard to
rewrite it as a singlepart, by replacing the content (and content headers)
of the top level with those of the part.  Also crunches 0-part multiparts
into singleparts.

Returns 'DONE'    if we really did collapse a multipart to a singlepart.
Returns 'ALREADY' (and does nothing) if entity is already a singlepart.
Returns '0'       (and does nothing) if it can't be made into a singlepart.

=cut

sub make_singlepart {
    my $self = shift;

    ### Trap for simple cases:
    return 'ALREADY' if !$self->is_multipart;      ### already a singlepart?
    return '0' if ($self->parts > 1);              ### can this even be done?

    # Get rid of all our existing content info
    my $tag;
    foreach $tag (grep {/^content-/i} $self->head->tags) {
        $self->head->delete($tag);
    }

    if ($self->parts == 1) {    ### one part
	my $part = $self->parts(0);

	### Populate ourselves with any content info from the part:
	foreach $tag (grep {/^content-/i} $part->head->tags) {
	    foreach ($part->head->get($tag)) { $self->head->add($tag, $_) }
	}

	### Save reconstructed header, replace our guts, and restore header:
	my $new_head = $self->head;
	%$self = %$part;               ### shallow copy is ok!
	$self->head($new_head);

	### One more thing: the part *may* have been a multi with 0 or 1 parts!
	return $self->make_singlepart(@_) if $self->is_multipart;
    }
    else {                      ### no parts!
	$self->head->mime_attr('Content-type'=>'text/plain');   ### simple
    }
    'DONE';
}

#------------------------------

=item purge

I<Instance method.>
Recursively purge (e.g., unlink) all external (e.g., on-disk) body parts
in this message.  See MIME::Body::purge() for details.

B<Note:> this does I<not> delete the directories that those body parts
are contained in; only the actual message data files are deleted.
This is because some parsers may be customized to create intermediate
directories while others are not, and it's impossible for this class
to know what directories are safe to remove.  Only your application
program truly knows that.

B<If you really want to "clean everything up",> one good way is to
use C<MIME::Parser::file_under()>, and then do this before parsing
your next message:

    $parser->filer->purge();

I wouldn't attempt to read those body files after you do this, for
obvious reasons.  As of MIME-tools 4.x, each body's path I<is> undefined
after this operation.  I warned you I might do this; truly I did.

I<Thanks to Jason L. Tibbitts III for suggesting this method.>

=cut

sub purge {
    my $self = shift;
    $self->bodyhandle and $self->bodyhandle->purge;      ### purge me
    foreach ($self->parts) { $_->purge }                 ### recurse
    1;
}

#------------------------------
#
# _do_remove_sig
#
# Private.  Remove a signature within NLINES lines from the end of BODY.
# The signature must be flagged by a line containing only "-- ".

sub _do_remove_sig {
    my ($body, $nlines) = @_;
    $nlines ||= 10;
    my $i = 0;

    my $line = int(@$body) || return;
    while ($i++ < $nlines and $line--) {
	if ($body->[$line] =~ /\A--[ \040][\r\n]+\Z/) {
	    $#{$body} = $line-1;
	    return;
	}
    }
}

#------------------------------

=item remove_sig [NLINES]

I<Instance method, override.>
Attempts to remove a user's signature from the body of a message.

It does this by looking for a line matching C</^-- $/> within the last
C<NLINES> of the message.  If found then that line and all lines after
it will be removed. If C<NLINES> is not given, a default value of 10
will be used.  This would be of most use in auto-reply scripts.

For MIME entity, this method is reasonably cautious: it will only
attempt to un-sign a message with a content-type of C<text/*>.

If you send remove_sig() to a multipart entity, it will relay it to
the first part (the others usually being the "attachments").

B<Warning:> currently slurps the whole message-part into core as an
array of lines, so you probably don't want to use this on extremely
long messages.

Returns truth on success, false on error.

=cut

sub remove_sig {
    my $self = shift;
    my $nlines = shift;

    # If multipart, we only attempt to remove the sig from the first
    # part.  This is usually a good assumption for multipart/mixed, but
    # may not always be correct.  It is also possibly incorrect on
    # multipart/alternative (both may have sigs).
    if( $self->is_multipart ) {
	my $first_part = $self->parts(0);
	if( $first_part ) {
            return $first_part->remove_sig(@_);
	}
	return undef;
    }

    ### Refuse non-textual unless forced:
    textual_type($self->head->mime_type)
	or return error "I won't un-sign a non-text message unless I'm forced";

    ### Get body data, as an array of newline-terminated lines:
    $self->bodyhandle or return undef;
    my @body = $self->bodyhandle->as_lines;

    ### Nuke sig:
    _do_remove_sig(\@body, $nlines);

    ### Output data back into body:
    my $io = $self->bodyhandle->open("w");
    foreach (@body) { $io->print($_) };  ### body data
    $io->close;

    ### Done!
    1;
}

#------------------------------

=item sign PARAMHASH

I<Instance method, override.>
Append a signature to the message.  The params are:

=over 4

=item Attach

Instead of appending the text, add it to the message as an attachment.
The disposition will be C<inline>, and the description will indicate
that it is a signature.  The default behavior is to append the signature
to the text of the message (or the text of its first part if multipart).
I<MIME-specific; new in this subclass.>

=item File

Use the contents of this file as the signature.
Fatal error if it can't be read.
I<As per superclass method.>

=item Force

Sign it even if the content-type isn't C<text/*>.  Useful for
non-standard types like C<x-foobar>, but be careful!
I<MIME-specific; new in this subclass.>

=item Remove

Normally, we attempt to strip out any existing signature.
If true, this gives us the NLINES parameter of the remove_sig call.
If zero but defined, tells us I<not> to remove any existing signature.
If undefined, removal is done with the default of 10 lines.
I<New in this subclass.>

=item Signature

Use this text as the signature.  You can supply it as either
a scalar, or as a ref to an array of newline-terminated scalars.
I<As per superclass method.>

=back

For MIME messages, this method is reasonably cautious: it will only
attempt to sign a message with a content-type of C<text/*>, unless
C<Force> is specified.

If you send this message to a multipart entity, it will relay it to
the first part (the others usually being the "attachments").

B<Warning:> currently slurps the whole message-part into core as an
array of lines, so you probably don't want to use this on extremely
long messages.

Returns true on success, false otherwise.

=cut

sub sign {
    my $self = shift;
    my %params = @_;
    my $io;

    my $boundary_delimiter = $MIME::Entity::BOUNDARY_DELIMITER || "\n";
    ### If multipart and not attaching, try to sign our first part:
    if ($self->is_multipart and !$params{Attach}) {
	return $self->parts(0)->sign(@_);
    }

    ### Get signature:
    my $sig;
    if (defined($sig = $params{Signature})) {    ### scalar or array
	$sig = (ref($sig) ? join('', @$sig) : $sig);
    }
    elsif ($params{File}) {                      ### file contents
	my $fh = IO::File->new( $params{File} ) or croak "can't open $params{File}: $!";
	$sig = join('', $fh->getlines);
	$fh->close or croak "can't close $params{File}: $!";
    }
    else {
	croak "no signature given!";
    }

    ### Add signature to message as appropriate:
    if ($params{Attach}) {      ### Attach .sig as new part...
	return $self->attach(Type        => 'text/plain',
			     Description => 'Signature',
			     Disposition => 'inline',
			     Encoding    => '-SUGGEST',
			     Data        => $sig);
    }
    else {                      ### Add text of .sig to body data...

	### Refuse non-textual unless forced:
	($self->head->mime_type =~ m{text/}i or $params{Force}) or
	    return error "I won't sign a non-text message unless I'm forced";

	### Get body data, as an array of newline-terminated lines:
	$self->bodyhandle or return undef;
	my @body = $self->bodyhandle->as_lines;

	### Nuke any existing sig?
	if (!defined($params{Remove}) || ($params{Remove} > 0)) {
	    _do_remove_sig(\@body, $params{Remove});
	}

	### Output data back into body, followed by signature:
	my $line;
	$io = $self->open("w") or croak("open: $!");
	foreach $line (@body) { $io->print($line) };      ### body data
	(($body[-1]||'') =~ /\n\Z/) or $io->print($boundary_delimiter);  ### ensure final \n
	$io->print("-- $boundary_delimiter$sig");                          ### separator + sig
	$io->close or croak("close: $!");
	return 1;         ### done!
    }
}

#------------------------------

=item suggest_encoding

I<Instance method.>
Based on the effective content type, return a good suggested encoding.

C<text> and C<message> types have their bodies scanned line-by-line
for 8-bit characters and long lines; lack of either means that the
message is 7bit-ok.  Other types are chosen independent of their body:

    Major type:      7bit ok?    Suggested encoding:
    -----------------------------------------------------------
    text             yes         7bit
    text             no          quoted-printable
    message          yes         7bit
    message          no          binary
    multipart        *           binary (in case some parts are bad)
    image, etc...    *           base64

=cut

### TO DO: resolve encodings of nested entities (possibly in sync_headers).

sub suggest_encoding {
    my $self = shift;

    my ($type) = split '/', $self->effective_type;
    if (($type eq 'text') || ($type eq 'message')) {    ### scan message body
	$self->bodyhandle || return ($self->parts ? 'binary' : '7bit');
	my ($IO, $unclean);
	if ($IO = $self->bodyhandle->open("r")) {
	    ### Scan message for 7bit-cleanliness
	    local $_;
	    while (defined($_ = $IO->getline)) {
		last if ($unclean = ((length($_) > 999) or /[\200-\377]/));
	    }

	    ### Return '7bit' if clean; try and encode if not...
	    ### Note that encodings are not permitted for messages!
	    return ($unclean
		    ? (($type eq 'message') ? 'binary' : 'quoted-printable')
		    : '7bit');
	}
    }
    else {
	return ($type eq 'multipart') ? 'binary' : 'base64';
    }
}

sub suggest_encoding_lite {
    my $self = shift;
    my ($type) = split '/', $self->effective_type;
    return (($type =~ /^(text|message|multipart)$/) ? 'binary' : 'base64');
}

#------------------------------

=item sync_headers OPTIONS

I<Instance method.>
This method does a variety of activities which ensure that
the MIME headers of an entity "tree" are in-synch with the body parts
they describe.  It can be as expensive an operation as printing
if it involves pre-encoding the body parts; however, the aim is to
produce fairly clean MIME.  B<You will usually only need to invoke
this if processing and re-sending MIME from an outside source.>

The OPTIONS is a hash, which describes what is to be done.

=over 4


=item Length

One of the "official unofficial" MIME fields is "Content-Length".
Normally, one doesn't care a whit about this field; however, if
you are preparing output destined for HTTP, you may.  The value of
this option dictates what will be done:

B<COMPUTE> means to set a C<Content-Length> field for every non-multipart
part in the entity, and to blank that field out for every multipart
part in the entity.

B<ERASE> means that C<Content-Length> fields will all
be blanked out.  This is fast, painless, and safe.

B<Any false value> (the default) means to take no action.


=item Nonstandard

Any header field beginning with "Content-" is, according to the RFC,
a MIME field.  However, some are non-standard, and may cause problems
with certain MIME readers which interpret them in different ways.

B<ERASE> means that all such fields will be blanked out.  This is
done I<before> the B<Length> option (q.v.) is examined and acted upon.

B<Any false value> (the default) means to take no action.


=back

Returns a true value if everything went okay, a false value otherwise.

=cut

sub sync_headers {
    my $self = shift;
    my $opts = ((int(@_) % 2 == 0) ? {@_} : shift);
    my $ENCBODY;     ### keep it around until done!

    ### Get options:
    my $o_nonstandard = ($opts->{Nonstandard} || 0);
    my $o_length      = ($opts->{Length}      || 0);

    ### Get head:
    my $head = $self->head;

    ### What to do with "nonstandard" MIME fields?
    if ($o_nonstandard eq 'ERASE') {       ### Erase them...
	my $tag;
	foreach $tag ($head->tags()) {
	    if (($tag =~ /\AContent-/i) &&
		($tag !~ /\AContent-$StandardFields\Z/io)) {
		$head->delete($tag);
	    }
	}
    }

    ### What to do with the "Content-Length" MIME field?
    if ($o_length eq 'COMPUTE') {        ### Compute the content length...
	my $content_length = '';

	### We don't have content-lengths in multiparts...
	if ($self->is_multipart) {           ### multipart...
	    $head->delete('Content-length');
	}
	else {                               ### singlepart...

	    ### Get the encoded body, if we don't have it already:
	    unless ($ENCBODY) {
		$ENCBODY = tmpopen() || die "can't open tmpfile";
		$self->print_body($ENCBODY);    ### write encoded to tmpfile
	    }

	    ### Analyse it:
	    $ENCBODY->seek(0,2);                ### fast-forward
	    $content_length = $ENCBODY->tell;   ### get encoded length
	    $ENCBODY->seek(0,0);                ### rewind

	    ### Remember:
	    $self->head->replace('Content-length', $content_length);
	}
    }
    elsif ($o_length eq 'ERASE') {         ### Erase the content-length...
	$head->delete('Content-length');
    }

    ### Done with everything for us!
    undef($ENCBODY);

    ### Recurse:
    my $part;
    foreach $part ($self->parts) { $part->sync_headers($opts) or return undef }
    1;
}

#------------------------------

=item tidy_body

I<Instance method, override.>
Currently unimplemented for MIME messages.  Does nothing, returns false.

=cut

sub tidy_body {
    usage "MIME::Entity::tidy_body currently does nothing";
    0;
}

=back

=cut





#==============================

=head2 Output

=over 4

=cut

#------------------------------

=item dump_skeleton [FILEHANDLE]

I<Instance method.>
Dump the skeleton of the entity to the given FILEHANDLE, or
to the currently-selected one if none given.

Each entity is output with an appropriate indentation level,
the following selection of attributes:

    Content-type: multipart/mixed
    Effective-type: multipart/mixed
    Body-file: NONE
    Subject: Hey there!
    Num-parts: 2

This is really just useful for debugging purposes; I make no guarantees
about the consistency of the output format over time.

=cut

sub dump_skeleton {
    my ($self, $fh, $indent) = @_;
    $fh or $fh = select;
    defined($indent) or $indent = 0;
    my $ind = '    ' x $indent;
    my $part;
    no strict 'refs';


    ### The content type:
    print $fh $ind,"Content-type: ",   ($self->mime_type||'UNKNOWN'),"\n";
    print $fh $ind,"Effective-type: ", ($self->effective_type||'UNKNOWN'),"\n";

    ### The name of the file containing the body (if any!):
    my $path = ($self->bodyhandle ? $self->bodyhandle->path : undef);
    print $fh $ind, "Body-file: ", ($path || 'NONE'), "\n";

    ### The recommended file name (thanks to Allen Campbell):
    my $filename = $self->head->recommended_filename;
    print $fh $ind, "Recommended-filename: ", $filename, "\n" if ($filename);

    ### The subject (note: already a newline if 2.x!)
    my $subj = $self->head->get('subject',0);
    defined($subj) or $subj = '';
    chomp($subj);
    print $fh $ind, "Subject: $subj\n" if $subj;

    ### The parts:
    my @parts = $self->parts;
    print $fh $ind, "Num-parts: ", int(@parts), "\n" if @parts;
    print $fh $ind, "--\n";
    foreach $part (@parts) {
	$part->dump_skeleton($fh, $indent+1);
    }
}

#------------------------------

=item print [OUTSTREAM]

I<Instance method, override.>
Print the entity to the given OUTSTREAM, or to the currently-selected
filehandle if none given.  OUTSTREAM can be a filehandle, or any object
that responds to a print() message.

The entity is output as a valid MIME stream!  This means that the
header is always output first, and the body data (if any) will be
encoded if the header says that it should be.
For example, your output may look like this:

    Subject: Greetings
    Content-transfer-encoding: base64

    SGkgdGhlcmUhCkJ5ZSB0aGVyZSEK

I<If this entity has MIME type "multipart/*",>
the preamble, parts, and epilogue are all output with appropriate
boundaries separating each.
Any bodyhandle is ignored:

    Content-type: multipart/mixed; boundary="*----*"
    Content-transfer-encoding: 7bit

    [Preamble]
    --*----*
    [Entity: Part 0]
    --*----*
    [Entity: Part 1]
    --*----*--
    [Epilogue]

I<If this entity has a single-part MIME type with no attached parts,>
then we're looking at a normal singlepart entity: the body is output
according to the encoding specified by the header.
If no body exists, a warning is output and the body is treated as empty:

    Content-type: image/gif
    Content-transfer-encoding: base64

    [Encoded body]

I<If this entity has a single-part MIME type but it also has parts,>
then we're probably looking at a "re-parsed" singlepart, usually one
of type C<message/*> (you can get entities like this if you set the
C<parse_nested_messages(NEST)> option on the parser to true).
In this case, the parts are output with single blank lines separating each,
and any bodyhandle is ignored:

    Content-type: message/rfc822
    Content-transfer-encoding: 7bit

    [Entity: Part 0]

    [Entity: Part 1]

In all cases, when outputting a "part" of the entity, this method
is invoked recursively.

B<Note:> the output is very likely I<not> going to be identical
to any input you parsed to get this entity.  If you're building
some sort of email handler, it's up to you to save this information.

=cut

use Symbol;
sub print {
    my ($self, $out) = @_;
    my $boundary_delimiter = $MIME::Entity::BOUNDARY_DELIMITER || "\n";
    $out = select if @_ < 2;
    $out = Symbol::qualify($out,scalar(caller)) unless ref($out);

    $self->print_header($out);   ### the header
    $out->print($boundary_delimiter);
    $self->print_body($out);     ### the "stuff after the header"
}

#------------------------------

=item print_body [OUTSTREAM]

I<Instance method, override.>
Print the body of the entity to the given OUTSTREAM, or to the
currently-selected filehandle if none given.  OUTSTREAM can be a
filehandle, or any object that responds to a print() message.

The body is output for inclusion in a valid MIME stream; this means
that the body data will be encoded if the header says that it should be.

B<Note:> by "body", we mean "the stuff following the header".
A printed multipart body includes the printed representations of its subparts.

B<Note:> The body is I<stored> in an un-encoded form; however, the idea is that
the transfer encoding is used to determine how it should be I<output.>
This means that the C<print()> method is always guaranteed to get you
a sendmail-ready stream whose body is consistent with its head.
If you want the I<raw body data> to be output, you can either read it from
the bodyhandle yourself, or use:

    $ent->bodyhandle->print($outstream);

which uses read() calls to extract the information, and thus will
work with both text and binary bodies.

B<Warning:> Please supply an OUTSTREAM.  This override method differs
from Mail::Internet's behavior, which outputs to the STDOUT if no
filehandle is given: this may lead to confusion.

=cut

sub print_body {
    my ($self, $out) = @_;
    $out ||= select;
    my ($type) = split '/', lc($self->mime_type);  ### handle by MIME type
    my $boundary_delimiter = $MIME::Entity::BOUNDARY_DELIMITER || "\n";

    ### Multipart...
    if ($type eq 'multipart') {
	my $boundary = $self->head->multipart_boundary;

	### Preamble:
	my $plines = $self->preamble;
	if (defined $plines) {
	    # Defined, so output the preamble if it exists (avoiding additional
	    # newline as per ticket 60931)
	    $out->print( join('', @$plines) . $boundary_delimiter) if (@$plines > 0);
	} else {
	    # Undefined, so use default preamble
	    $out->print( join('', @$DefPreamble) . $boundary_delimiter . $boundary_delimiter );
	}

	### Parts:
	my $part;
	foreach $part ($self->parts) {
	    $out->print("--$boundary$boundary_delimiter");
	    $part->print($out);
	    $out->print($boundary_delimiter);           ### needed for next delim/close
	}
	$out->print("--$boundary--$boundary_delimiter");

	### Epilogue:
	my $epilogue = join('', @{ $self->epilogue || $DefEpilogue });
	if ($epilogue ne '') {
	    $out->print($epilogue);
	    $out->print($boundary_delimiter) if ($epilogue !~ /\n\Z/);  ### be nice
	}
    }

    ### Singlepart type with parts...
    ###    This makes $ent->print handle message/rfc822 bodies
    ###    when parse_nested_messages('NEST') is on [idea by Marc Rouleau].
    elsif ($self->parts) {
	my $need_sep = 0;
	my $part;
	foreach $part ($self->parts) {
	    $out->print("$boundary_delimiter$boundary_delimiter") if $need_sep++;
	    $part->print($out);
	}
    }

    ### Singlepart type, or no parts: output body...
    else {
	$self->bodyhandle ? $self->print_bodyhandle($out)
	                  : whine "missing body; treated as empty";
    }
    1;
}

#------------------------------
#
# print_bodyhandle
#
# Instance method, unpublicized.  Print just the bodyhandle, *encoded*.
#
# WARNING: $self->print_bodyhandle() != $self->bodyhandle->print()!
# The former encodes, and the latter does not!
#
sub print_bodyhandle {
    my ($self, $out) = @_;
    $out ||= select;

    my $IO = $self->open("r")     || die "open body: $!";
    if ( $self->bodyhandle->is_encoded ) {
      ### Transparent mode: data is already encoded, so no
      ### need to encode it again
      my $buf;
      $out->print($buf) while ($IO->read($buf, 8192));
    } else {
      ### Get the encoding, defaulting to "binary" if unsupported:
      my $encoding = ($self->head->mime_encoding || 'binary');
      my $decoder = best MIME::Decoder $encoding;
      $decoder->head($self->head);      ### associate with head, if any
      $decoder->encode($IO, $out, textual_type($self->head->mime_type) ? 1 : 0)   || return error "encoding failed";
    }

    $IO->close;
    1;
}

#------------------------------

=item print_header [OUTSTREAM]

I<Instance method, inherited.>
Output the header to the given OUTSTREAM.  You really should supply
the OUTSTREAM.

=cut

### Inherited.

#------------------------------

=item stringify

I<Instance method.>
Return the entity as a string, exactly as C<print> would print it.
The body will be encoded as necessary, and will contain any subparts.
You can also use C<as_string()>.

=cut

sub stringify {
	my ($self) = @_;
	my $output = '';
	my $fh = IO::File->new( \$output, '>:' ) or croak("Cannot open in-memory file: $!");
	$self->print($fh);
	$fh->close;
	return $output;
}

sub as_string { shift->stringify };      ### silent BC

#------------------------------

=item stringify_body

I<Instance method.>
Return the I<encoded> message body as a string, exactly as C<print_body>
would print it.  You can also use C<body_as_string()>.

If you want the I<unencoded> body, and you are dealing with a
singlepart message (like a "text/plain"), use C<bodyhandle()> instead:

    if ($ent->bodyhandle) {
	$unencoded_data = $ent->bodyhandle->as_string;
    }
    else {
	### this message has no body data (but it might have parts!)
    }

=cut

sub stringify_body {
	my ($self) = @_;
	my $output = '';
	my $fh = IO::File->new( \$output, '>:' ) or croak("Cannot open in-memory file: $!");
	$self->print_body($fh);
	$fh->close;
	return $output;
}

sub body_as_string { shift->stringify_body }

#------------------------------

=item stringify_header

I<Instance method.>
Return the header as a string, exactly as C<print_header> would print it.
You can also use C<header_as_string()>.

=cut

sub stringify_header {
    shift->head->stringify;
}
sub header_as_string { shift->stringify_header }


1;
__END__

#------------------------------

=back

=head1 NOTES

=head2 Under the hood

A B<MIME::Entity> is composed of the following elements:

=over 4

=item *

A I<head>, which is a reference to a MIME::Head object
containing the header information.

=item *

A I<bodyhandle>, which is a reference to a MIME::Body object
containing the decoded body data.  This is only defined if
the message is a "singlepart" type:

    application/*
    audio/*
    image/*
    text/*
    video/*

=item *

An array of I<parts>, where each part is a MIME::Entity object.
The number of parts will only be nonzero if the content-type
is I<not> one of the "singlepart" types:

    message/*        (should have exactly one part)
    multipart/*      (should have one or more parts)


=back



=head2 The "two-body problem"

MIME::Entity and Mail::Internet see message bodies differently,
and this can cause confusion and some inconvenience.  Sadly, I can't
change the behavior of MIME::Entity without breaking lots of code already
out there.  But let's open up the floor for a few questions...

=over 4

=item What is the difference between a "message" and an "entity"?

A B<message> is the actual data being sent or received; usually
this means a stream of newline-terminated lines.
An B<entity> is the representation of a message as an object.

This means that you get a "message" when you print an "entity"
I<to> a filehandle, and you get an "entity" when you parse a message
I<from> a filehandle.


=item What is a message body?

B<Mail::Internet:>
The portion of the printed message after the header.

B<MIME::Entity:>
The portion of the printed message after the header.


=item How is a message body stored in an entity?

B<Mail::Internet:>
As an array of lines.

B<MIME::Entity:>
It depends on the content-type of the message.
For "container" types (C<multipart/*>, C<message/*>), we store the
contained entities as an array of "parts", accessed via the C<parts()>
method, where each part is a complete MIME::Entity.
For "singlepart" types (C<text/*>, C<image/*>, etc.), the unencoded
body data is referenced via a MIME::Body object, accessed via
the C<bodyhandle()> method:

                      bodyhandle()   parts()
    Content-type:     returns:       returns:
    ------------------------------------------------------------
    application/*     MIME::Body     empty
    audio/*           MIME::Body     empty
    image/*           MIME::Body     empty
    message/*         undef          MIME::Entity list (usually 1)
    multipart/*       undef          MIME::Entity list (usually >0)
    text/*            MIME::Body     empty
    video/*           MIME::Body     empty
    x-*/*             MIME::Body     empty

As a special case, C<message/*> is currently ambiguous: depending
on the parser, a C<message/*> might be treated as a singlepart,
with a MIME::Body and no parts.  Use bodyhandle() as the final
arbiter.


=item What does the body() method return?

B<Mail::Internet:>
As an array of lines, ready for sending.

B<MIME::Entity:>
As an array of lines, ready for sending.

=item What's the best way to get at the body data?

B<Mail::Internet:>
Use the body() method.

B<MIME::Entity:>
Depends on what you want... the I<encoded> data (as it is
transported), or the I<unencoded> data?  Keep reading...


=item How do I get the "encoded" body data?

B<Mail::Internet:>
Use the body() method.

B<MIME::Entity:>
Use the body() method.  You can also use:

    $entity->print_body()
    $entity->stringify_body()   ### a.k.a. $entity->body_as_string()


=item How do I get the "unencoded" body data?

B<Mail::Internet:>
Use the body() method.

B<MIME::Entity:>
Use the I<bodyhandle()> method!
If bodyhandle() method returns true, then that value is a
L<MIME::Body|MIME::Body> which can be used to access the data via
its open() method.  If bodyhandle() method returns an undefined value,
then the entity is probably a "container" that has no real body data of
its own (e.g., a "multipart" message): in this case, you should access
the components via the parts() method.  Like this:

    if ($bh = $entity->bodyhandle) {
	$io = $bh->open;
	...access unencoded data via $io->getline or $io->read...
	$io->close;
    }
    else {
	foreach my $part (@parts) {
	    ...do something with the part...
	}
    }

You can also use:

    if ($bh = $entity->bodyhandle) {
	$unencoded_data = $bh->as_string;
    }
    else {
	...do stuff with the parts...
    }


=item What does the body() method return?

B<Mail::Internet:>
The transport-encoded message body, as an array of lines.

B<MIME::Entity:>
The transport-encoded message body, as an array of lines.


=item What does print_body() print?

B<Mail::Internet:>
Exactly what body() would return to you.

B<MIME::Entity:>
Exactly what body() would return to you.


=item Say I have an entity which might be either singlepart or multipart.
      How do I print out just "the stuff after the header"?

B<Mail::Internet:>
Use print_body().

B<MIME::Entity:>
Use print_body().


=item Why is MIME::Entity so different from Mail::Internet?

Because MIME streams are expected to have non-textual data...
possibly, quite a lot of it, such as a tar file.

Because MIME messages can consist of multiple parts, which are most-easily
manipulated as MIME::Entity objects themselves.

Because in the simpler world of Mail::Internet, the data of a message
and its printed representation are I<identical>... and in the MIME
world, they're not.

Because parsing multipart bodies on-the-fly, or formatting multipart
bodies for output, is a non-trivial task.


=item This is confusing.  Can the two classes be made more compatible?

Not easily; their implementations are necessarily quite different.
Mail::Internet is a simple, efficient way of dealing with a "black box"
mail message... one whose internal data you don't care much about.
MIME::Entity, in contrast, cares I<very much> about the message contents:
that's its job!

=back



=head2 Design issues

=over 4

=item Some things just can't be ignored

In multipart messages, the I<"preamble"> is the portion that precedes
the first encapsulation boundary, and the I<"epilogue"> is the portion
that follows the last encapsulation boundary.

According to RFC 2046:

    There appears to be room for additional information prior
    to the first encapsulation boundary and following the final
    boundary.  These areas should generally be left blank, and
    implementations must ignore anything that appears before the
    first boundary or after the last one.

    NOTE: These "preamble" and "epilogue" areas are generally
    not used because of the lack of proper typing of these parts
    and the lack of clear semantics for handling these areas at
    gateways, particularly X.400 gateways.  However, rather than
    leaving the preamble area blank, many MIME implementations
    have found this to be a convenient place to insert an
    explanatory note for recipients who read the message with
    pre-MIME software, since such notes will be ignored by
    MIME-compliant software.

In the world of standards-and-practices, that's the standard.
Now for the practice:

I<Some "MIME" mailers may incorrectly put a "part" in the preamble>.
Since we have to parse over the stuff I<anyway>, in the future I
I<may> allow the parser option of creating special MIME::Entity objects
for the preamble and epilogue, with bogus MIME::Head objects.

For now, though, we're MIME-compliant, so I probably won't change
how we work.

=back

=head1 SEE ALSO

L<MIME::Tools>, L<MIME::Head>, L<MIME::Body>, L<MIME::Decoder>, L<Mail::Internet>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (dfs@roaringpenguin.com) http://www.roaringpenguin.com

All rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
