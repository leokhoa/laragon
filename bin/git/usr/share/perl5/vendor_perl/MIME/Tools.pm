package MIME::Tools;

#------------------------------
# Because the POD documentation is pretty extensive, it follows
# the __END__ statement below...
#------------------------------

use strict;
use vars (qw(@ISA %CONFIG @EXPORT_OK %EXPORT_TAGS $VERSION $ME
	     $M_DEBUG $M_WARNING $M_ERROR ));

require Exporter;
use IO::File;
use File::Temp 0.18 ();
use Carp;

$ME = "MIME-tools";

@ISA = qw(Exporter);

# Exporting (importing should only be done by modules in this toolkit!):
%EXPORT_TAGS = (
    'config'  => [qw(%CONFIG)],
    'msgs'    => [qw(usage debug whine error)],
    'msgtypes'=> [qw($M_DEBUG $M_WARNING $M_ERROR)],
    'utils'   => [qw(textual_type tmpopen )],
    );
Exporter::export_ok_tags('config', 'msgs', 'msgtypes', 'utils');

# The TOOLKIT version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.509";

# Configuration (do NOT alter this directly)...
# All legal CONFIG vars *must* be in here, even if only to be set to undef:
%CONFIG =
    (
     DEBUGGING       => 0,
     QUIET           => 1,
     );

# Message-logging constants:
$M_DEBUG   = 'debug';
$M_WARNING = 'warning';
$M_ERROR   = 'error';



#------------------------------
#
# CONFIGURATION... (see below)
#
#------------------------------

sub config {
    my $class = shift;
    usage("config() is obsolete");

    # No args? Just return list:
    @_ or return keys %CONFIG;
    my $method = lc(shift);
    return $class->$method(@_);
}

sub debugging {
    my ($class, $value) = @_;
    $CONFIG{'DEBUGGING'} = $value   if (@_ > 1);
    return $CONFIG{'DEBUGGING'};
}

sub quiet {
    my ($class, $value) = @_;
    $CONFIG{'QUIET'} = $value   if (@_ > 1);
    return $CONFIG{'QUIET'};
}

sub version {
    my ($class, $value) = @_;
    return $VERSION;
}



#------------------------------
#
# MESSAGES...
#
#------------------------------

#------------------------------
#
# debug MESSAGE...
#
# Function, private.
# Output a debug message.
#
sub debug {
    print STDERR "$ME: $M_DEBUG: ", @_, "\n"      if $CONFIG{DEBUGGING};
}

#------------------------------
#
# whine MESSAGE...
#
# Function, private.
# Something doesn't look right: issue a warning.
# Only output if $^W (-w) is true, and we're not being QUIET.
#
sub whine {
    my $msg = "$ME: $M_WARNING: ".join('', @_)."\n";
    warn $msg if ($^W && !$CONFIG{QUIET});
    return (wantarray ? () : undef);
}

#------------------------------
#
# error MESSAGE...
#
# Function, private.
# Something failed, but not so badly that we want to throw an
# exception.  Just report our general unhappiness.
# Only output if $^W (-w) is true, and we're not being QUIET.
#
sub error {
    my $msg = "$ME: $M_ERROR: ".join('', @_)."\n";
    warn $msg if ($^W && !$CONFIG{QUIET});
    return (wantarray ? () : undef);
}

#------------------------------
#
# usage MESSAGE...
#
# Register unhappiness about usage.
#
sub usage {
    my ( $p,  $f,  $l,  $s) = caller(1);
    my ($cp, $cf, $cl, $cs) = caller(2);
    my $msg = join('', (($s =~ /::/) ? "$s() " : "${p}::$s() "), @_, "\n");
    my $loc = ($cf ? "\tin code called from $cf l.$cl" : '');

    warn "$msg$loc\n" if ($^W && !$CONFIG{QUIET});
    return (wantarray ? () : undef);
}



#------------------------------
#
# UTILS...
#
#------------------------------

#------------------------------
#
# textual_type MIMETYPE
#
# Function.  Does the given MIME type indicate a textlike document?
#
sub textual_type {
    ($_[0] =~ m{^(text|message)(/|\Z)}i);
}

#------------------------------
#
# tmpopen
#
#
sub tmpopen
{
	my ($args) = @_;
	$args ||= {};
	return File::Temp->new( %{$args} );
}

#------------------------------
1;
__END__


=head1 NAME

MIME-tools - modules for parsing (and creating!) MIME entities


=head1 SYNOPSIS

Here's some pretty basic code for B<parsing a MIME message,> and outputting
its decoded components to a given directory:

    use MIME::Parser;

    ### Create parser, and set some parsing options:
    my $parser = new MIME::Parser;
    $parser->output_under("$ENV{HOME}/mimemail");

    ### Parse input:
    $entity = $parser->parse(\*STDIN) or die "parse failed\n";

    ### Take a look at the top-level entity (and any parts it has):
    $entity->dump_skeleton;


Here's some code which B<composes and sends a MIME message> containing
three parts: a text file, an attached GIF, and some more text:

    use MIME::Entity;

    ### Create the top-level, and set up the mail headers:
    $top = MIME::Entity->build(Type    =>"multipart/mixed",
                               From    => "me\@myhost.com",
	                       To      => "you\@yourhost.com",
                               Subject => "Hello, nurse!");

    ### Part #1: a simple text document:
    $top->attach(Path=>"./testin/short.txt");

    ### Part #2: a GIF file:
    $top->attach(Path        => "./docs/mime-sm.gif",
                 Type        => "image/gif",
                 Encoding    => "base64");

    ### Part #3: some literal text:
    $top->attach(Data=>$message);

    ### Send it:
    open MAIL, "| /usr/lib/sendmail -t -oi -oem" or die "open: $!";
    $top->print(\*MAIL);
    close MAIL;


For more examples, look at the scripts in the B<examples> directory
of the MIME-tools distribution.



=head1 DESCRIPTION

MIME-tools is a collection of Perl5 MIME:: modules for parsing, decoding,
I<and generating> single- or multipart (even nested multipart) MIME
messages.  (Yes, kids, that means you can send messages with attached
GIF files).


=head1 REQUIREMENTS

You will need the following installed on your system:

	File::Path
	File::Spec
	IPC::Open2              (optional)
	MIME::Base64
	MIME::QuotedPrint
	Net::SMTP
	Mail::Internet, ...     from the MailTools distribution.

See the Makefile.PL in your distribution for the most-comprehensive
list of prerequisite modules and their version numbers.


=head1 A QUICK TOUR

=head2 Overview of the classes

Here are the classes you'll generally be dealing with directly:


    (START HERE)            results() .-----------------.
          \                 .-------->| MIME::          |
           .-----------.   /          | Parser::Results |
           | MIME::    |--'           `-----------------'
           | Parser    |--.           .-----------------.
           `-----------'   \ filer()  | MIME::          |
              | parse()     `-------->| Parser::Filer   |
              | gives you             `-----------------'
              | a...                        	      | output_path()
              |                         	      | determines
              |					      | path() of...
              |    head()       .--------.	      |
              |    returns...   | MIME:: | get()      |
              V       .-------->| Head   | etc...     |
           .--------./          `--------'            |
     .---> | MIME:: | 				      |
     `-----| Entity |           .--------.            |
   parts() `--------'\          | MIME:: |           /
   returns            `-------->| Body   |<---------'
   sub-entities    bodyhandle() `--------'
   (if any)        returns...       | open()
                                    | returns...
                                    |
                                    V
                                .--------. read()
                                | IO::   | getline()
                                | Handle | print()
                                `--------' etc...


To illustrate, parsing works this way:

=over 4

=item *

B<The "parser" parses the MIME stream.>
A parser is an instance of C<MIME::Parser>.
You hand it an input stream (like a filehandle) to parse a message from:
if the parse is successful, the result is an "entity".

=item *

B<A parsed message is represented by an "entity".>
An entity is an instance of C<MIME::Entity> (a subclass of C<Mail::Internet>).
If the message had "parts" (e.g., attachments), then those parts
are "entities" as well, contained inside the top-level entity.
Each entity has a "head" and a "body".

=item *

B<The entity's "head" contains information about the message.>
A "head" is an instance of C<MIME::Head> (a subclass of C<Mail::Header>).
It contains information from the message header: content type,
sender, subject line, etc.

=item *

B<The entity's "body" knows where the message data is.>
You can ask to "open" this data source for I<reading> or I<writing>,
and you will get back an "I/O handle".

=item *

B<You can open() a "body" and get an "I/O handle" to read/write message data.>
This handle is an object that is basically like an IO::Handle...  it
can be any class, so long as it supports a small, standard set of
methods for reading from or writing to the underlying data source.

=back

A typical multipart message containing two parts -- a textual greeting
and an "attached" GIF file -- would be a tree of MIME::Entity objects,
each of which would have its own MIME::Head.  Like this:

    .--------.
    | MIME:: | Content-type: multipart/mixed
    | Entity | Subject: Happy Samhaine!
    `--------'
         |
         `----.
        parts |
              |   .--------.
              |---| MIME:: | Content-type: text/plain; charset=us-ascii
              |   | Entity | Content-transfer-encoding: 7bit
              |   `--------'
              |   .--------.
              |---| MIME:: | Content-type: image/gif
                  | Entity | Content-transfer-encoding: base64
                  `--------' Content-disposition: inline;
                               filename="hs.gif"



=head2 Parsing messages

You usually start by creating an instance of B<MIME::Parser>
and setting up certain parsing parameters: what directory to save
extracted files to, how to name the files, etc.

You then give that instance a readable filehandle on which waits a
MIME message.  If all goes well, you will get back a B<MIME::Entity>
object (a subclass of B<Mail::Internet>), which consists of...

=over 4

=item *

A B<MIME::Head> (a subclass of B<Mail::Header>) which holds the MIME
header data.

=item *

A B<MIME::Body>, which is a object that knows where the body data is.
You ask this object to "open" itself for reading, and it
will hand you back an "I/O handle" for reading the data: this could be
of any class, so long as it conforms to a subset of the B<IO::Handle>
interface.

=back

If the original message was a multipart document, the MIME::Entity
object will have a non-empty list of "parts", each of which is in
turn a MIME::Entity (which might also be a multipart entity, etc,
etc...).

Internally, the parser (in MIME::Parser) asks for instances
of B<MIME::Decoder> whenever it needs to decode an encoded file.
MIME::Decoder has a mapping from supported encodings (e.g., 'base64')
to classes whose instances can decode them.  You can add to this mapping
to try out new/experiment encodings.  You can also use
MIME::Decoder by itself.


=head2 Composing messages

All message composition is done via the B<MIME::Entity> class.
For single-part messages, you can use the B<MIME::Entity/build>
constructor to create MIME entities very easily.

For multipart messages, you can start by creating a top-level
C<multipart> entity with B<MIME::Entity::build()>, and then use
the similar B<MIME::Entity::attach()> method to attach parts to
that message.  I<Please note:> what most people think of as
"a text message with an attached GIF file" is I<really> a multipart
message with 2 parts: the first being the text message, and the
second being the GIF file.

When building MIME a entity, you'll have to provide two very important
pieces of information: the I<content type> and the
I<content transfer encoding>.  The type is usually easy, as it is directly
determined by the file format; e.g., an HTML file is C<text/html>.
The encoding, however, is trickier... for example, some HTML files are
C<7bit>-compliant, but others might have very long lines and would need to be
sent C<quoted-printable> for reliability.

See the section on encoding/decoding for more details, as well as
L<"A MIME PRIMER"> below.


=head2 Sending email

Since MIME::Entity inherits directly from Mail::Internet,
you can use the normal Mail::Internet mechanisms to send
email.  For example,

    $entity->smtpsend;



=head2 Encoding/decoding support

The B<MIME::Decoder> class can be used to I<encode> as well; this is done
when printing MIME entities.  All the standard encodings are supported
(see L<"A MIME PRIMER"> below for details):

    Encoding:        | Normally used when message contents are:
    -------------------------------------------------------------------
    7bit             | 7-bit data with under 1000 chars/line, or multipart.
    8bit             | 8-bit data with under 1000 chars/line.
    binary           | 8-bit data with some long lines (or no line breaks).
    quoted-printable | Text files with some 8-bit chars (e.g., Latin-1 text).
    base64           | Binary files.

Which encoding you choose for a given document depends largely on
(1) what you know about the document's contents (text vs binary), and
(2) whether you need the resulting message to have a reliable encoding
for 7-bit Internet email transport.

In general, only C<quoted-printable> and C<base64> guarantee reliable
transport of all data; the other three "no-encoding" encodings simply
pass the data through, and are only reliable if that data is 7bit ASCII
with under 1000 characters per line, and has no conflicts with the
multipart boundaries.

I've considered making it so that the content-type and encoding
can be automatically inferred from the file's path, but that seems
to be asking for trouble... or at least, for Mail::Cap...



=head2 Message-logging

MIME-tools is a large and complex toolkit which tries to deal with
a wide variety of external input.  It's sometimes helpful to see
what's really going on behind the scenes.
There are several kinds of messages logged by the toolkit itself:

=over 4

=item Debug messages

These are printed directly to the STDERR, with a prefix of
C<"MIME-tools: debug">.

Debug message are only logged if you have turned
L</debugging> on in the MIME::Tools configuration.


=item Warning messages

These are logged by the standard Perl warn() mechanism
to indicate an unusual situation.
They all have a prefix of C<"MIME-tools: warning">.

Warning messages are only logged if C<$^W> is set true
and MIME::Tools is not configured to be L</quiet>.


=item Error messages

These are logged by the standard Perl warn() mechanism
to indicate that something actually failed.
They all have a prefix of C<"MIME-tools: error">.

Error messages are only logged if C<$^W> is set true
and MIME::Tools is not configured to be L</quiet>.


=item Usage messages

Unlike "typical" warnings above, which warn about problems processing
data, usage-warnings are for alerting developers of deprecated methods
and suspicious invocations.

Usage messages are currently only logged if C<$^W> is set true
and MIME::Tools is not configured to be L</quiet>.

=back

When a MIME::Parser (or one of its internal helper classes)
wants to report a message, it generally does so by recording
the message to the B<MIME::Parser::Results> object
immediately before invoking the appropriate function above.
That means each parsing run has its own trace-log which
can be examined for problems.


=head2 Configuring the toolkit

If you want to tweak the way this toolkit works (for example, to
turn on debugging), use the routines in the B<MIME::Tools> module.

=over

=item debugging

Turn debugging on or off.
Default is false (off).

     MIME::Tools->debugging(1);


=item quiet

Turn the reporting of warning/error messages on or off.
Default is true, meaning that these message are silenced.

     MIME::Tools->quiet(1);


=item version

Return the toolkit version.

     print MIME::Tools->version, "\n";

=back








=head1 THINGS YOU SHOULD DO


=head2 Take a look at the examples

The MIME-Tools distribution comes with an "examples" directory.
The scripts in there are basically just tossed-together, but
they'll give you some ideas of how to use the parser.


=head2 Run with warnings enabled

I<Always> run your Perl script with C<-w>.
If you see a warning about a deprecated method, change your
code ASAP.  This will ease upgrades tremendously.


=head2 Avoid non-standard encodings

Don't try to MIME-encode using the non-standard MIME encodings.
It's just not a good practice if you want people to be able to
read your messages.


=head2 Plan for thrown exceptions

For example, if your mail-handling code absolutely must not die,
then perform mail parsing like this:

    $entity = eval { $parser->parse(\*INPUT) };

Parsing is a complex process, and some components may throw exceptions
if seriously-bad things happen.  Since "seriously-bad" is in the
eye of the beholder, you're better off I<catching> possible exceptions
instead of asking me to propagate C<undef> up the stack.  Use of exceptions in
reusable modules is one of those religious issues we're never all
going to agree upon; thankfully, that's what C<eval{}> is good for.


=head2 Check the parser results for warnings/errors

As of 5.3xx, the parser tries extremely hard to give you a
MIME::Entity.  If there were any problems, it logs warnings/errors
to the underlying "results" object (see L<MIME::Parser::Results>).
Look at that object after each parse.
Print out the warnings and errors, I<especially> if messages don't
parse the way you thought they would.


=head2 Don't plan on printing exactly what you parsed!

I<Parsing is a (slightly) lossy operation.>
Because of things like ambiguities in base64-encoding, the following
is I<not> going to spit out its input unchanged in all cases:

    $entity = $parser->parse(\*STDIN);
    $entity->print(\*STDOUT);

If you're using MIME::Tools to process email, remember to save
the data you parse if you want to send it on unchanged.
This is vital for things like PGP-signed email.


=head2 Understand how international characters are represented

The MIME standard allows for text strings in headers to contain
characters from any character set, by using special sequences
which look like this:

    =?ISO-8859-1?Q?Keld_J=F8rn_Simonsen?=

To be consistent with the existing Mail::Field classes, MIME::Tools
does I<not> automatically unencode these strings, since doing so would
lose the character-set information and interfere with the parsing
of fields (see L<MIME::Parser/decode_headers> for a full explanation).
That means you should be prepared to deal with these encoded strings.

The most common question then is, B<how do I decode these encoded strings?>
The answer depends on what you want to decode them I<to>:
ASCII, Latin1, UTF-8, etc.  Be aware that your "target" representation
may not support all possible character sets you might encounter;
for example, Latin1 (ISO-8859-1) has no way of representing Big5
(Chinese) characters.  A common practice is to represent "untranslateable"
characters as "?"s, or to ignore them completely.

To unencode the strings into some of the more-popular Western byte
representations (e.g., Latin1, Latin2, etc.), you can use the decoders
in MIME::WordDecoder (see L<MIME::WordDecoder>).
The simplest way is by using C<unmime()>, a function wrapped
around your "default" decoder, as follows:

    use MIME::WordDecoder;
    ...
    $subject = unmime $entity->head->get('subject');

One place this I<is> done automatically is in extracting the recommended
filename for a part while parsing.  That's why you should start by
setting up the best "default" decoder if the default target of Latin1
isn't to your liking.



=head1 THINGS I DO THAT YOU SHOULD KNOW ABOUT


=head2 Fuzzing of CRLF and newline on input

RFC 2045 dictates that MIME streams have lines terminated by CRLF
(C<"\r\n">).  However, it is extremely likely that folks will want to
parse MIME streams where each line ends in the local newline
character C<"\n"> instead.

An attempt has been made to allow the parser to handle both CRLF
and newline-terminated input.


=head2 Fuzzing of CRLF and newline when decoding

The C<"7bit"> and C<"8bit"> decoders will decode both
a C<"\n"> and a C<"\r\n"> end-of-line sequence into a C<"\n">.

The C<"binary"> decoder (default if no encoding specified)
still outputs stuff verbatim... so a MIME message with CRLFs
and no explicit encoding will be output as a text file
that, on many systems, will have an annoying ^M at the end of
each line... I<but this is as it should be>.


=head2 Fuzzing of CRLF and newline when encoding/composing

TODO FIXME
All encoders currently output the end-of-line sequence as a C<"\n">,
with the assumption that the local mail agent will perform
the conversion from newline to CRLF when sending the mail.
However, there probably should be an option to output CRLF as per RFC 2045


=head2 Inability to handle multipart boundaries with embedded newlines

Let's get something straight: this is an evil, EVIL practice.
If your mailer creates multipart boundary strings that contain
newlines, give it two weeks notice and find another one.  If your
mail robot receives MIME mail like this, regard it as syntactically
incorrect, which it is.


=head2 Ignoring non-header headers

People like to hand the parser raw messages straight from
POP3 or from a mailbox.  There is often predictable non-header
information in front of the real headers; e.g., the initial
"From" line in the following message:

    From - Wed Mar 22 02:13:18 2000
    Return-Path: <eryq@zeegee.com>
    Subject: Hello

The parser simply ignores such stuff quietly.  Perhaps it
shouldn't, but most people seem to want that behavior.


=head2 Fuzzing of empty multipart preambles

Please note that there is currently an ambiguity in the way
preambles are parsed in.  The following message fragments I<both>
are regarded as having an empty preamble (where C<\n> indicates a
newline character):

     Content-type: multipart/mixed; boundary="xyz"\n
     Subject: This message (#1) has an empty preamble\n
     \n
     --xyz\n
     ...

     Content-type: multipart/mixed; boundary="xyz"\n
     Subject: This message (#2) also has an empty preamble\n
     \n
     \n
     --xyz\n
     ...

In both cases, the I<first> completely-empty line (after the "Subject")
marks the end of the header.

But we should clearly ignore the I<second> empty line in message #2,
since it fills the role of I<"the newline which is only there to make
sure that the boundary is at the beginning of a line">.
Such newlines are I<never> part of the content preceding the boundary;
thus, there is no preamble "content" in message #2.

However, it seems clear that message #1 I<also> has no preamble
"content", and is in fact merely a compact representation of an
empty preamble.


=head2 Use of a temp file during parsing

I<Why not do everything in core?>
Although the amount of core available on even a modest home
system continues to grow, the size of attachments continues
to grow with it.  I wanted to make sure that even users with small
systems could deal with decoding multi-megabyte sounds and movie files.
That means not being core-bound.

As of the released 5.3xx, MIME::Parser gets by with only
one temp file open per parser.  This temp file provides
a sort of infinite scratch space for dealing with the current
message part.  It's fast and lightweight, but you should know
about it anyway.


=head2 Why do I assume that MIME objects are email objects?

Achim Bohnet once pointed out that MIME headers do nothing more than
store a collection of attributes, and thus could be represented as
objects which don't inherit from Mail::Header.

I agree in principle, but RFC 2045 says otherwise.
RFC 2045 [MIME] headers are a syntactic subset of RFC-822 [email] headers.
Perhaps a better name for these modules would have been RFC1521::
instead of MIME::, but we're a little beyond that stage now.

When I originally wrote these modules for the CPAN, I agonized for a long
time about whether or not they really should subclass from B<Mail::Internet>
(then at version 1.17).  Thanks to Graham Barr, who graciously evolved
MailTools 1.06 to be more MIME-friendly, unification was achieved
at MIME-tools release 2.0.
The benefits in reuse alone have been substantial.




=head1 A MIME PRIMER

So you need to parse (or create) MIME, but you're not quite up on
the specifics?  No problem...



=head2 Glossary

Here are some definitions adapted from RFC 1521 (predecessor of the
current RFC 204[56789] defining MIME) explaining the terminology we
use; each is accompanied by the equivalent in MIME:: module terms...

=over 4

=item attachment

An "attachment" is common slang for any part of a multipart message --
except, perhaps, for the first part, which normally carries a user
message describing the attachments that follow (e.g.: "Hey dude, here's
that GIF file I promised you.").

In our system, an attachment is just a B<MIME::Entity> under the
top-level entity, probably one of its L<parts|MIME::Entity/parts>.

=item body

The "body" of an L<entity|/entity> is that portion of the entity
which follows the L<header|/header> and which contains the real message
content.  For example, if your MIME message has a GIF file attachment,
then the body of that attachment is the base64-encoded GIF file itself.

A body is represented by an instance of B<MIME::Body>.  You get the
body of an entity by sending it a L<bodyhandle()|MIME::Entity/bodyhandle>
message.

=item body part

One of the parts of the body of a multipart B</entity>.
A body part has a B</header> and a B</body>, so it makes sense to
speak about the body of a body part.

Since a body part is just a kind of entity, it's represented by
an instance of B<MIME::Entity>.

=item entity

An "entity" means either a B</message> or a B</body part>.
All entities have a B</header> and a B</body>.

An entity is represented by an instance of B<MIME::Entity>.
There are instance methods for recovering the
L<header|MIME::Entity/head> (a B<MIME::Head>) and the
L<body|MIME::Entity/bodyhandle> (a B<MIME::Body>).

=item header

This is the top portion of the MIME message, which contains the
"Content-type", "Content-transfer-encoding", etc.  Every MIME entity has
a header, represented by an instance of B<MIME::Head>.  You get the
header of an entity by sending it a head() message.

=item message

A "message" generally means the complete (or "top-level") message being
transferred on a network.

There currently is no explicit package for "messages"; under MIME::,
messages are streams of data which may be read in from files or
filehandles.  You can think of the B<MIME::Entity> returned by the
B<MIME::Parser> as representing the full message.


=back


=head2 Content types

This indicates what kind of data is in the MIME message, usually
as I<majortype/minortype>.  The standard major types are shown below.
A more-comprehensive listing may be found in RFC-2046.

=over 4

=item application

Data which does not fit in any of the other categories, particularly
data to be processed by some type of application program.
C<application/octet-stream>, C<application/gzip>, C<application/postscript>...

=item audio

Audio data.
C<audio/basic>...

=item image

Graphics data.
C<image/gif>, C<image/jpeg>...

=item message

A message, usually another mail or MIME message.
C<message/rfc822>...

=item multipart

A message containing other messages.
C<multipart/mixed>, C<multipart/alternative>...

=item text

Textual data, meant for humans to read.
C<text/plain>, C<text/html>...

=item video

Video or video+audio data.
C<video/mpeg>...

=back


=head2 Content transfer encodings

This is how the message body is packaged up for safe transit.
There are the 5 major MIME encodings.
A more-comprehensive listing may be found in RFC-2045.

=over 4

=item 7bit

No encoding is done at all.  This label simply asserts that no
8-bit characters are present, and that lines do not exceed 1000 characters
in length (including the CRLF).

=item 8bit

No encoding is done at all.  This label simply asserts that the message
might contain 8-bit characters, and that lines do not exceed 1000 characters
in length (including the CRLF).

=item binary

No encoding is done at all.  This label simply asserts that the message
might contain 8-bit characters, and that lines may exceed 1000 characters
in length.  Such messages are the I<least> likely to get through mail
gateways.

=item base64

A standard encoding, which maps arbitrary binary data to the 7bit domain.
Like "uuencode", but very well-defined.  This is how you should send
essentially binary information (tar files, GIFs, JPEGs, etc.).

=item quoted-printable

A standard encoding, which maps arbitrary line-oriented data to the
7bit domain.  Useful for encoding messages which are textual in
nature, yet which contain non-ASCII characters (e.g., Latin-1,
Latin-2, or any other 8-bit alphabet).

=back

=head1 SEE ALSO

L<MIME::Parser>, L<MIME::Head>, L<MIME::Body>, L<MIME::Entity>, L<MIME::Decoder>, L<Mail::Header>,
L<Mail::Internet>

At the time of this writing, the MIME-tools homepage was
F<http://www.mimedefang.org/static/mime-tools.php>.  Check there for
updates and support.

The MIME format is documented in RFCs 1521-1522, and more recently
in RFCs 2045-2049.

The MIME header format is an outgrowth of the mail header format
documented in RFC 822.

=head1 SUPPORT

Please file support requests via rt.cpan.org.

=head1 CHANGE LOG

Released as MIME-parser (1.0): 28 April 1996.
Released as MIME-tools (2.0): Halloween 1996.
Released as MIME-tools (4.0): Christmas 1997.
Released as MIME-tools (5.0): Mother's Day 2000.

See ChangeLog file for full details.

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (F<dfs@roaringpenguin.com>) F<http://www.roaringpenguin.com>.

Copyright (c) 1998, 1999 by ZeeGee Software Inc (www.zeegee.com).
Copyright (c) 2004 by Roaring Penguin Software Inc (www.roaringpenguin.com)

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See the COPYING file in the distribution for details.

=head1 ACKNOWLEDGMENTS

B<This kit would not have been possible> but for the direct
contributions of the following:

    Gisle Aas             The MIME encoding/decoding modules.
    Laurent Amon          Bug reports and suggestions.
    Graham Barr           The new MailTools.
    Achim Bohnet          Numerous good suggestions, including the I/O model.
    Kent Boortz           Initial code for RFC-1522-decoding of MIME headers.
    Andreas Koenig        Numerous good ideas, tons of beta testing,
                            and help with CPAN-friendly packaging.
    Igor Starovoitov      Bug reports and suggestions.
    Jason L Tibbitts III  Bug reports, suggestions, patches.

Not to mention the Accidental Beta Test Team, whose bug reports (and
comments) have been invaluable in improving the whole:

    Phil Abercrombie
    Mike Blazer
    Brandon Browning
    Kurt Freytag
    Steve Kilbane
    Jake Morrison
    Rolf Nelson
    Joel Noble
    Michael W. Normandin
    Tim Pierce
    Andrew Pimlott
    Dragomir R. Radev
    Nickolay Saukh
    Russell Sutherland
    Larry Virden
    Zyx

Please forgive me if I've accidentally left you out.
Better yet, email me, and I'll put you in.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See the COPYING file for more details.

=cut
