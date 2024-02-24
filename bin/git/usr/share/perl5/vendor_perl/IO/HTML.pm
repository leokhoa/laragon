#---------------------------------------------------------------------
package IO::HTML;
#
# Copyright 2020 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 14 Jan 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Open an HTML file with automatic charset detection
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Carp 'croak';
use Encode 2.10 qw(decode find_encoding); # need utf-8-strict encoding
use Exporter 5.57 'import';

our $VERSION = '1.004';
# This file is part of IO-HTML 1.004 (September 26, 2020)


our $bytes_to_check   ||= 1024;
our $default_encoding ||= 'cp1252';

our @EXPORT    = qw(html_file);
our @EXPORT_OK = qw(find_charset_in html_file_and_encoding html_outfile
                    sniff_encoding);

our %EXPORT_TAGS = (
  rw  => [qw( html_file html_file_and_encoding html_outfile )],
  all => [ @EXPORT, @EXPORT_OK ],
);

#=====================================================================


sub html_file
{
  (&html_file_and_encoding)[0]; # return just the filehandle
} # end html_file


# Note: I made html_file and html_file_and_encoding separate functions
# (instead of making html_file context-sensitive) because I wanted to
# use html_file in function calls (i.e. list context) without having
# to write "scalar html_file" all the time.

sub html_file_and_encoding
{
  my ($filename, $options) = @_;

  $options ||= {};

  open(my $in, '<:raw', $filename) or croak "Failed to open $filename: $!";


  my ($encoding, $bom) = sniff_encoding($in, $filename, $options);

  if (not defined $encoding) {
    croak "No default encoding specified"
        unless defined($encoding = $default_encoding);
    $encoding = find_encoding($encoding) if $options->{encoding};
  } # end if we didn't find an encoding

  binmode $in, sprintf(":encoding(%s):crlf",
                       $options->{encoding} ? $encoding->name : $encoding);

  return ($in, $encoding, $bom);
} # end html_file_and_encoding
#---------------------------------------------------------------------


sub html_outfile
{
  my ($filename, $encoding, $bom) = @_;

  if (not defined $encoding) {
    croak "No default encoding specified"
        unless defined($encoding = $default_encoding);
  } # end if we didn't find an encoding
  elsif (ref $encoding) {
    $encoding = $encoding->name;
  }

  open(my $out, ">:encoding($encoding)", $filename)
      or croak "Failed to open $filename: $!";

  print $out "\x{FeFF}" if $bom;

  return $out;
} # end html_outfile
#---------------------------------------------------------------------


sub sniff_encoding
{
  my ($in, $filename, $options) = @_;

  $filename = 'file' unless defined $filename;
  $options ||= {};

  my $pos = tell $in;
  croak "Could not seek $filename: $!" if $pos < 0;

  croak "Could not read $filename: $!"
      unless defined read $in, my($buf), $bytes_to_check;

  seek $in, $pos, 0 or croak "Could not seek $filename: $!";


  # Check for BOM:
  my $bom;
  my $encoding = do {
    if ($buf =~ /^\xFe\xFF/) {
      $bom = 2;
      'UTF-16BE';
    } elsif ($buf =~ /^\xFF\xFe/) {
      $bom = 2;
      'UTF-16LE';
    } elsif ($buf =~ /^\xEF\xBB\xBF/) {
      $bom = 3;
      'utf-8-strict';
    } else {
      find_charset_in($buf, $options); # check for <meta charset>
    }
  }; # end $encoding

  if ($bom) {
    seek $in, $bom, 1 or croak "Could not seek $filename: $!";
    $bom = 1;
  }
  elsif (not defined $encoding) { # try decoding as UTF-8
    my $test = decode('utf-8-strict', $buf, Encode::FB_QUIET);
    if ($buf =~ /^(?:                   # nothing left over
         | [\xC2-\xDF]                  # incomplete 2-byte char
         | [\xE0-\xEF] [\x80-\xBF]?     # incomplete 3-byte char
         | [\xF0-\xF4] [\x80-\xBF]{0,2} # incomplete 4-byte char
        )\z/x and $test =~ /[^\x00-\x7F]/) {
      $encoding = 'utf-8-strict';
    } # end if valid UTF-8 with at least one multi-byte character:
  } # end if testing for UTF-8

  if (defined $encoding and $options->{encoding} and not ref $encoding) {
    $encoding = find_encoding($encoding);
  } # end if $encoding is a string and we want an object

  return wantarray ? ($encoding, $bom) : $encoding;
} # end sniff_encoding

#=====================================================================
# Based on HTML5 8.2.2.2 Determining the character encoding:

# Get attribute from current position of $_
sub _get_attribute
{
  m!\G[\x09\x0A\x0C\x0D /]+!gc; # skip whitespace or /

  return if /\G>/gc or not /\G(=?[^\x09\x0A\x0C\x0D =]*)/gc;

  my ($name, $value) = (lc $1, '');

  if (/\G[\x09\x0A\x0C\x0D ]*=[\x09\x0A\x0C\x0D ]*/gc) {
    if (/\G"/gc) {
      # Double-quoted attribute value
      /\G([^"]*)("?)/gc;
      return unless $2; # Incomplete attribute (missing closing quote)
      $value = lc $1;
    } elsif (/\G'/gc) {
      # Single-quoted attribute value
      /\G([^']*)('?)/gc;
      return unless $2; # Incomplete attribute (missing closing quote)
      $value = lc $1;
    } else {
      # Unquoted attribute value
      /\G([^\x09\x0A\x0C\x0D >]*)/gc;
      $value = lc $1;
    }
  } # end if attribute has value

  return wantarray ? ($name, $value) : 1;
} # end _get_attribute

# Examine a meta value for a charset:
sub _get_charset_from_meta
{
  for (shift) {
    while (/charset[\x09\x0A\x0C\x0D ]*=[\x09\x0A\x0C\x0D ]*/ig) {
      return $1 if (/\G"([^"]*)"/gc or
                    /\G'([^']*)'/gc or
                    /\G(?!['"])([^\x09\x0A\x0C\x0D ;]+)/gc);
    }
  } # end for value

  return undef;
} # end _get_charset_from_meta
#---------------------------------------------------------------------


sub find_charset_in
{
  for (shift) {
    my $options = shift || {};
    # search only the first $bytes_to_check bytes (default 1024)
    my $stop = length > $bytes_to_check ? $bytes_to_check : length;

    my $expect_pragma = (defined $options->{need_pragma}
                         ? $options->{need_pragma} : 1);

    pos() = 0;
    while (pos() < $stop) {
      if (/\G<!--.*?(?<=--)>/sgc) {
      } # Skip comment
      elsif (m!\G<meta(?=[\x09\x0A\x0C\x0D /])!gic) {
        my ($got_pragma, $need_pragma, $charset);

        while (my ($name, $value) = &_get_attribute) {
          if ($name eq 'http-equiv' and $value eq 'content-type') {
            $got_pragma = 1;
          } elsif ($name eq 'content' and not defined $charset) {
            $need_pragma = $expect_pragma
                if defined($charset = _get_charset_from_meta($value));
          } elsif ($name eq 'charset') {
            $charset = $value;
            $need_pragma = 0;
          }
        } # end while more attributes in this <meta> tag

        if (defined $need_pragma and (not $need_pragma or $got_pragma)) {
          $charset = 'UTF-8'  if $charset =~ /^utf-?16/;
          $charset = 'cp1252' if $charset eq 'iso-8859-1'; # people lie
          if (my $encoding = find_encoding($charset)) {
            return $options->{encoding} ? $encoding : $encoding->name;
          } # end if charset is a recognized encoding
        } # end if found charset
      } # end elsif <meta
      elsif (m!\G</?[a-zA-Z][^\x09\x0A\x0C\x0D >]*!gc) {
        1 while &_get_attribute;
      } # end elsif some other tag
      elsif (m{\G<[!/?][^>]*}gc) {
      } # skip unwanted things
      elsif (m/\G</gc) {
      } # skip < that doesn't open anything we recognize

      # Advance to the next <:
      m/\G[^<]+/gc;
    } # end while not at search boundary
  } # end for string

  return undef;                 # Couldn't find a charset
} # end find_charset_in
#---------------------------------------------------------------------


# Shortcuts for people who don't like exported functions:
*file               = \&html_file;
*file_and_encoding  = \&html_file_and_encoding;
*outfile            = \&html_outfile;

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

IO::HTML - Open an HTML file with automatic charset detection

=head1 VERSION

This document describes version 1.004 of
IO::HTML, released September 26, 2020.

=head1 SYNOPSIS

  use IO::HTML;                 # exports html_file by default
  use HTML::TreeBuilder;

  my $tree = HTML::TreeBuilder->new_from_file(
               html_file('foo.html')
             );

  # Alternative interface:
  open(my $in, '<:raw', 'bar.html');
  my $encoding = IO::HTML::sniff_encoding($in, 'bar.html');

=head1 DESCRIPTION

IO::HTML provides an easy way to open a file containing HTML while
automatically determining its encoding.  It uses the HTML5 encoding
sniffing algorithm specified in section 8.2.2.2 of the draft standard.

The algorithm as implemented here is:

=over

=item 1.

If the file begins with a byte order mark indicating UTF-16LE,
UTF-16BE, or UTF-8, then that is the encoding.

=item 2.

If the first C<$bytes_to_check> bytes of the file contain a C<< <meta> >> tag that
indicates the charset, and Encode recognizes the specified charset
name, then that is the encoding.  (This portion of the algorithm is
implemented by C<find_charset_in>.)

The C<< <meta> >> tag can be in one of two formats:

  <meta charset="...">
  <meta http-equiv="Content-Type" content="...charset=...">

The search is case-insensitive, and the order of attributes within the
tag is irrelevant.  Any additional attributes of the tag are ignored.
The first matching tag with a recognized encoding ends the search.

=item 3.

If the first C<$bytes_to_check> bytes of the file are valid UTF-8 (with at least 1
non-ASCII character), then the encoding is UTF-8.

=item 4.

If all else fails, use the default character encoding.  The HTML5
standard suggests the default encoding should be locale dependent, but
currently it is always C<cp1252> unless you set
C<$IO::HTML::default_encoding> to a different value.  Note:
C<sniff_encoding> does not apply this step; only C<html_file> does
that.

=back

=head1 SUBROUTINES

=head2 html_file

  $filehandle = html_file($filename, \%options);

This function (exported by default) is the primary entry point.  It
opens the file specified by C<$filename> for reading, uses
C<sniff_encoding> to find a suitable encoding layer, and applies it.
It also applies the C<:crlf> layer.  If the file begins with a BOM,
the filehandle is positioned just after the BOM.

The optional second argument is a hashref containing options.  The
possible keys are described under C<find_charset_in>.

If C<sniff_encoding> is unable to determine the encoding, it defaults
to C<$IO::HTML::default_encoding>, which is set to C<cp1252>
(a.k.a. Windows-1252) by default.  According to the standard, the
default should be locale dependent, but that is not currently
implemented.

It dies if the file cannot be opened, or if C<sniff_encoding> cannot
determine the encoding and C<$IO::HTML::default_encoding> has been set
to C<undef>.


=head2 html_file_and_encoding

  ($filehandle, $encoding, $bom)
    = html_file_and_encoding($filename, \%options);

This function (exported only by request) is just like C<html_file>,
but returns more information.  In addition to the filehandle, it
returns the name of the encoding used, and a flag indicating whether a
byte order mark was found (if C<$bom> is true, the file began with a
BOM).  This may be useful if you want to write the file out again
(especially in conjunction with the C<html_outfile> function).

The optional second argument is a hashref containing options.  The
possible keys are described under C<find_charset_in>.

It dies if the file cannot be opened, or if C<sniff_encoding> cannot
determine the encoding and C<$IO::HTML::default_encoding> has been set
to C<undef>.

The result of calling C<html_file_and_encoding> in scalar context is undefined
(in the C sense of there is no guarantee what you'll get).


=head2 html_outfile

  $filehandle = html_outfile($filename, $encoding, $bom);

This function (exported only by request) opens C<$filename> for output
using C<$encoding>, and writes a BOM to it if C<$bom> is true.
If C<$encoding> is C<undef>, it defaults to C<$IO::HTML::default_encoding>.
C<$encoding> may be either an encoding name or an Encode::Encoding object.

It dies if the file cannot be opened, or if both C<$encoding> and
C<$IO::HTML::default_encoding> are C<undef>.


=head2 sniff_encoding

  ($encoding, $bom) = sniff_encoding($filehandle, $filename, \%options);

This function (exported only by request) runs the HTML5 encoding
sniffing algorithm on C<$filehandle> (which must be seekable, and
should have been opened in C<:raw> mode).  C<$filename> is used only
for error messages (if there's a problem using the filehandle), and
defaults to "file" if omitted.  The optional third argument is a
hashref containing options.  The possible keys are described under
C<find_charset_in>.

It returns Perl's canonical name for the encoding, which is not
necessarily the same as the MIME or IANA charset name.  It returns
C<undef> if the encoding cannot be determined.  C<$bom> is true if the
file began with a byte order mark.  In scalar context, it returns only
C<$encoding>.

The filehandle's position is restored to its original position
(normally the beginning of the file) unless C<$bom> is true.  In that
case, the position is immediately after the BOM.

Tip: If you want to run C<sniff_encoding> on a file you've already
loaded into a string, open an in-memory file on the string, and pass
that handle:

  ($encoding, $bom) = do {
    open(my $fh, '<', \$string);  sniff_encoding($fh)
  };

(This only makes sense if C<$string> contains bytes, not characters.)


=head2 find_charset_in

  $encoding = find_charset_in($string_containing_HTML, \%options);

This function (exported only by request) looks for charset information
in a C<< <meta> >> tag in a possibly-incomplete HTML document using
the "two step" algorithm specified by HTML5.  It does not look for a BOM.
The C<< <meta> >> tag must begin within the first C<$IO::HTML::bytes_to_check>
bytes of the string.

It returns Perl's canonical name for the encoding, which is not
necessarily the same as the MIME or IANA charset name.  It returns
C<undef> if no charset is specified or if the specified charset is not
recognized by the Encode module.

The optional second argument is a hashref containing options.  The
following keys are recognized:

=over

=item C<encoding>

If true, return the L<Encode::Encoding> object instead of its name.
Defaults to false.

=item C<need_pragma>

If true (the default), follow the HTML5 spec and examine the
C<content> attribute only of C<< <meta http-equiv="Content-Type" >>.
If set to 0, relax the HTML5 spec, and look for "charset=" in the
C<content> attribute of I<every> meta tag.

=back

=head1 EXPORTS

By default, only C<html_file> is exported.  Other functions may be
exported on request.

For people who prefer not to export functions, all functions beginning
with C<html_> have an alias without that prefix (e.g. you can call
C<IO::HTML::file(...)> instead of C<IO::HTML::html_file(...)>.  These
aliases are not exportable.

=for Pod::Coverage
file
file_and_encoding
outfile

The following export tags are available:

=over

=item C<:all>

All exportable functions.

=item C<:rw>

C<html_file>, C<html_file_and_encoding>, C<html_outfile>.

=back

=head1 SEE ALSO

The HTML5 specification, section 8.2.2.2 Determining the character encoding:
L<http://www.w3.org/TR/html5/syntax.html#determining-the-character-encoding>

=head1 DIAGNOSTICS

=over

=item C<< Could not read %s: %s >>

The specified file could not be read from for the reason specified by C<$!>.


=item C<< Could not seek %s: %s >>

The specified file could not be rewound for the reason specified by C<$!>.


=item C<< Failed to open %s: %s >>

The specified file could not be opened for reading for the reason
specified by C<$!>.


=item C<< No default encoding specified >>

The C<sniff_encoding> algorithm didn't find an encoding to use, and
you set C<$IO::HTML::default_encoding> to C<undef>.


=back

=head1 CONFIGURATION AND ENVIRONMENT

There are two global variables that affect IO::HTML.  If you need to
change them, you should do so using C<local> if possible:

  my $file = do {
    # This file may define the charset later in the header
    local $IO::HTML::bytes_to_check = 4096;
    html_file(...);
  };

=over

=item C<$bytes_to_check>

This is the number of bytes that C<sniff_encoding> will read from the
stream.  It is also the number of bytes that C<find_charset_in> will
search for a C<< <meta> >> tag containing charset information.
It must be a positive integer.

The HTML 5 specification recommends using the default value of 1024,
but some pages do not follow the specification.

=item C<$default_encoding>

This is the encoding that C<html_file> and C<html_file_and_encoding>
will use if no encoding can be detected by C<sniff_encoding>.
The default value is C<cp1252> (a.k.a. Windows-1252).

Setting it to C<undef> will cause the file subroutines to croak if
C<sniff_encoding> fails to determine the encoding.  (C<sniff_encoding>
itself does not use C<$default_encoding>).

=back

=head1 DEPENDENCIES

IO::HTML has no non-core dependencies for Perl 5.8.7+.  With earlier
versions of Perl 5.8, you need to upgrade L<Encode> to at least
version 2.10, and
you may need to upgrade L<Exporter> to at least version
5.57.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-IO-HTML AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=IO-HTML >>.

You can follow or contribute to IO-HTML's development at
L<< https://github.com/madsen/io-html >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
