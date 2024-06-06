package MIME::Field::ContType;


=head1 NAME

MIME::Field::ContType - a "Content-type" field


=head1 DESCRIPTION

A subclass of Mail::Field.

I<Don't use this class directly... its name may change in the future!>
Instead, ask Mail::Field for new instances based on the field name!


=head1 SYNOPSIS

    use Mail::Field;
    use MIME::Head;

    # Create an instance from some text:
    $field = Mail::Field->new('Content-type',
                              'text/HTML; charset="US-ASCII"');

    # Get the MIME type, like 'text/plain' or 'x-foobar'.
    # Returns 'text/plain' as default, as per RFC 2045:
    my ($type, $subtype) = split('/', $field->type);

    # Get generic information:
    print $field->name;

    # Get information related to "message" type:
    if ($type eq 'message') {
	print $field->id;
	print $field->number;
	print $field->total;
    }

    # Get information related to "multipart" type:
    if ($type eq 'multipart') {
	print $field->boundary;            # the basic value, fixed up
	print $field->multipart_boundary;  # empty if not a multipart message!
    }

    # Get information related to "text" type:
    if ($type eq 'text') {
	print $field->charset;      # returns 'us-ascii' as default
    }


=head1 PUBLIC INTERFACE

=over 4

=cut

require 5.001;
use strict;
use MIME::Field::ParamVal;
use vars qw($VERSION @ISA);

@ISA = qw(MIME::Field::ParamVal);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.515";

# Install it:
bless([])->register('Content-type');

#------------------------------
#
# Basic access/storage methods...
#
sub charset {
    lc(shift->paramstr('charset', @_)) || 'us-ascii';   # RFC 2045
}
sub id {
    shift->paramstr('id', @_);
}
sub name {
    shift->paramstr('name', @_);
}
sub number {
    shift->paramstr('number', @_);
}
sub total {
    shift->paramstr('total', @_);
}


#------------------------------

=item boundary

Return the boundary field.  The boundary is returned exactly
as given in the C<Content-type:> field; that is, the leading
double-hyphen (C<-->) is I<not> prepended.

(Well, I<almost> exactly... from RFC 2046:

   (If a boundary appears to end with white space, the white space
   must be presumed to have been added by a gateway, and must be deleted.)

so we oblige and remove any trailing spaces.)

Returns the empty string if there is no boundary, or if the boundary is
illegal (e.g., if it is empty after all trailing whitespace has been
removed).

=cut

sub boundary {
    my $value = shift->param('boundary', @_);
    defined($value) || return '';
    $value =~ s/\s+$//;                  # kill trailing white, per RFC 2046
    $value;
}

#------------------------------

=item multipart_boundary

Like C<boundary()>, except that this will also return the empty
string if the message is not a multipart message.  In other words,
there's an automatic sanity check.

=cut

sub multipart_boundary {
    my $self = shift;
    my ($type) = split('/', $self->type);
    return '' if ($type ne 'multipart');    # not multipart!
    $self->boundary;                        # okay, return the boundary
}

#------------------------------

=item type

Try real hard to determine the content type (e.g., C<"text/plain">,
C<"image/gif">, C<"x-weird-type">, which is returned
in all-lowercase.

A happy thing: the following code will work just as you would want,
even if there's no subtype (as in C<"x-weird-type">)... in such a case,
the $subtype would simply be the empty string:

    ($type, $subtype) = split('/', $head->mime_type);

If the content-type information is missing, it defaults to C<"text/plain">,
as per RFC 2045:

    Default RFC 2822 messages are typed by this protocol as plain text in
    the US-ASCII character set, which can be explicitly specified as
    "Content-type: text/plain; charset=us-ascii".  If no Content-Type is
    specified, this default is assumed.

B<Note:> under the "be liberal in what we accept" principle, this routine
no longer syntax-checks the content type.  If it ain't empty,
just downcase and return it.

=cut

sub type {
    lc(shift->paramstr('_', @_)) || 'text/plain';  # RFC 2045
}

#------------------------------

=back


=head1 NOTES

Since nearly all (if not all) parameters must have non-empty values
to be considered valid, we just return the empty string to signify
missing fields.  If you need to get the I<real> underlying value,
use the inherited C<param()> method (which returns undef if the
parameter is missing).

=head1 SEE ALSO

L<MIME::Field::ParamVal>, L<Mail::Field>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (dianne@skoll.ca)

=cut

1;



