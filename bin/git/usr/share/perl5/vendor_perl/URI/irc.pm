package URI::irc;  # draft-butcher-irc-url-04

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::_login';

use overload (
   '""'     => sub { $_[0]->as_string  },
   '=='     => sub {  URI::_obj_eq(@_) },
   '!='     => sub { !URI::_obj_eq(@_) },
   fallback => 1,
);

sub default_port { 6667 }

#   ircURL   = ircURI "://" location "/" [ entity ] [ flags ] [ options ]
#   ircURI   = "irc" / "ircs"
#   location = [ authinfo "@" ] hostport
#   authinfo = [ username ] [ ":" password ]
#   username = *( escaped / unreserved )
#   password = *( escaped / unreserved ) [ ";" passtype ]
#   passtype = *( escaped / unreserved )
#   entity   = [ "#" ] *( escaped / unreserved )
#   flags    = ( [ "," enttype ] [ "," hosttype ] )
#           /= ( [ "," hosttype ] [ "," enttype ] )
#   enttype  = "," ( "isuser" / "ischannel" )
#   hosttype = "," ( "isserver" / "isnetwork" )
#   options  = "?" option *( "&" option )
#   option   = optname [ "=" optvalue ]
#   optname  = *( ALPHA / "-" )
#   optvalue = optparam *( "," optparam )
#   optparam = *( escaped / unreserved )

# XXX: Technically, passtype is part of the protocol, but is rarely used and
# not defined in the RFC beyond the URL ABNF.

# Starting the entity with /# is okay per spec, but it needs to be encoded to
# %23 for the URL::_generic::path operations to parse correctly.
sub _init {
    my $class = shift;
    my $self = $class->SUPER::_init(@_);
    $$self =~ s|^((?:[^:/?\#]+:)?(?://[^/?\#]*)?)/\#|$1/%23|s;
    $self;
}

# Return the /# form, since this is most common for channel names.
sub path {
    my $self = shift;
    my ($new) = @_;
    $new =~ s|^/\#|/%23| if (@_ && defined $new);
    my $val = $self->SUPER::path(@_ ? $new : ());
    $val =~ s|^/%23|/\#|;
    $val;
}
sub path_query {
    my $self = shift;
    my ($new) = @_;
    $new =~ s|^/\#|/%23| if (@_ && defined $new);
    my $val = $self->SUPER::path_query(@_ ? $new : ());
    $val =~ s|^/%23|/\#|;
    $val;
}
sub as_string {
    my $self = shift;
    my $val = $self->SUPER::as_string;
    $val =~ s|^((?:[^:/?\#]+:)?(?://[^/?\#]*)?)/%23|$1/\#|s;
    $val;
}

sub entity {
    my $self = shift;

    my $path = $self->path;
    $path =~ s|^/||;
    my ($entity, @flags) = split /,/, $path;

    if (@_) {
        my $new = shift;
        $new = '' unless defined $new;
        $self->path( '/'.join(',', $new, @flags) );
    }

    return unless length $entity;
    $entity;
}

sub flags {
    my $self = shift;

    my $path = $self->path;
    $path =~ s|^/||;
    my ($entity, @flags) = split /,/, $path;

    if (@_) {
        $self->path( '/'.join(',', $entity, @_) );
    }

    @flags;
}

sub options { shift->query_form(@_) }

sub canonical {
    my $self = shift;
    my $other = $self->SUPER::canonical;

    # Clean up the flags
    my $path = $other->path;
    $path =~ s|^/||;
    my ($entity, @flags) = split /,/, $path;

    my @clean =
        map { $_ eq 'isnick' ? 'isuser' : $_ }  # convert isnick->isuser
        map { lc }
        # NOTE: Allow flags from draft-mirashi-url-irc-01 as well
        grep { /^(?:is(?:user|channel|server|network|nick)|need(?:pass|key))$/i }
        @flags
    ;

    # Only allow the first type of each category, per the Butcher draft
    my ($enttype)  = grep { /^is(?:user|channel)$/   } @clean;
    my ($hosttype) = grep { /^is(?:server|network)$/ } @clean;
    my @others     = grep { /^need(?:pass|key)$/ }     @clean;

    my @new = (
        $enttype  ? $enttype  : (),
        $hosttype ? $hosttype : (),
        @others,
    );

    unless (join(',', @new) eq join(',', @flags)) {
        $other = $other->clone if $other == $self;
        $other->path( '/'.join(',', $entity, @new) );
    }

    $other;
}

1;
