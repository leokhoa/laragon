package LWP::MemberMixin;

our $VERSION = '6.81';

sub _elem {
    my $self = shift;
    my $elem = shift;
    my $old  = $self->{$elem};
    $self->{$elem} = shift if @_;
    return $old;
}

1;

__END__

=pod

=head1 NAME

LWP::MemberMixin - Member access mixin class

=head1 SYNOPSIS

 package Foo;
 use parent qw(LWP::MemberMixin);

=head1 DESCRIPTION

A mixin class to get methods that provide easy access to member
variables in the C<%$self>.
Ideally there should be better Perl language support for this.

=head1 METHODS

There is only one method provided:

=head2 _elem

    _elem($elem [, $val])

Internal method to get/set the value of member variable
C<$elem>. If C<$val> is present it is used as the new value
for the member variable.  If it is not present the current
value is not touched. In both cases the previous value of
the member variable is returned.

=cut
