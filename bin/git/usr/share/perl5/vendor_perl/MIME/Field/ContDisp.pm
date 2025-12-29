package MIME::Field::ContDisp;


=head1 NAME

MIME::Field::ContDisp - a "Content-disposition" field


=head1 DESCRIPTION

A subclass of Mail::Field.

I<Don't use this class directly... its name may change in the future!>
Instead, ask Mail::Field for new instances based on the field name!


=head1 SYNOPSIS

    use Mail::Field;
    use MIME::Head;

    # Create an instance from some text:
    $field = Mail::Field->new('Content-disposition', $text);

    # Inline or attachment?
    $type = $field->type;

    # Recommended filename?
    $filename = $field->filename;

=head1 SEE ALSO

L<MIME::Field::ParamVal>, L<Mail::Field>

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>), ZeeGee Software Inc (F<http://www.zeegee.com>).
Dianne Skoll (dianne@skoll.ca)


=cut

require 5.001;
use strict;
use MIME::Field::ParamVal;
use vars qw($VERSION @ISA);

@ISA = qw(MIME::Field::ParamVal);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "5.515";

# Install it:
bless([])->register('Content-disposition');

#------------------------------

sub filename {
    shift->paramstr('filename', @_);
}

sub type {
    shift->paramstr('_', @_);
}

#------------------------------
1;

