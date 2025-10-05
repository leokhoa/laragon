package URI::geo;

use warnings;
use strict;

use Carp;
use URI::Split qw( uri_split uri_join );

use base qw( URI );

our $VERSION = '5.29';

sub _MINIMUM_LATITUDE      { return -90 }
sub _MAXIMUM_LATITUDE      { return 90 }
sub _MINIMUM_LONGITUDE     { return -180 }
sub _MAXIMUM_LONGITUDE     { return 180 }
sub _MAX_POINTY_PARAMETERS { return 3 }

sub _can {
    my ($can_pt, @keys) = @_;
    for my $key (@keys) {
        return $key if $can_pt->can($key);
    }
    return;
}

sub _has {
    my ($has_pt, @keys) = @_;
    for my $key (@keys) {
        return $key if exists $has_pt->{$key};
    }
    return;
}

# Try hard to extract location information from something. We handle lat,
# lon, alt as scalars, arrays containing lat, lon, alt, hashes with
# suitably named keys and objects with suitably named methods.

sub _location_of_pointy_thing {
    my ($class, @parameters) = @_;

    my @lat = qw( lat latitude );
    my @lon = qw( lon long longitude lng );
    my @ele = qw( ele alt elevation altitude );

    if (ref $parameters[0]) {
        my $pt = shift @parameters;

        if (@parameters) {
            croak q[Too many arguments];
        }

        if (eval { $pt->can('can') }) {
            for my $m (qw( location latlong )) {
                return $pt->$m() if _can($pt, $m);
            }

            my $latk = _can($pt, @lat);
            my $lonk = _can($pt, @lon);
            my $elek = _can($pt, @ele);

            if (defined $latk && defined $lonk) {
                return $pt->$latk(), $pt->$lonk(),
                    defined $elek ? $pt->$elek() : undef;
            }
        }
        elsif ('ARRAY' eq ref $pt) {
            return $class->_location_of_pointy_thing(@{$pt});
        }
        elsif ('HASH' eq ref $pt) {

            my $latk = _has($pt, @lat);
            my $lonk = _has($pt, @lon);
            my $elek = _has($pt, @ele);

            if (defined $latk && defined $lonk) {
                return $pt->{$latk}, $pt->{$lonk},
                    defined $elek ? $pt->{$elek} : undef;
            }
        }

        croak q[Don't know how to convert point];
    }
    else {
        croak q[Need lat, lon or lat, lon, alt]
            if @parameters < 2 || @parameters > _MAX_POINTY_PARAMETERS();
        return my ($lat, $lon, $alt) = @parameters;
    }
}

sub _num {
    my ($class, $n) = @_;
    if (!defined $n) {
        return q[];
    }
    (my $rep = sprintf '%f', $n) =~ s/[.]0*$//smx;
    return $rep;
}

sub new {
    my ($self, @parameters) = @_;
    my $class = ref $self || $self;
    my $uri   = uri_join 'geo', undef, $class->_path(@parameters);
    return bless \$uri, $class;
}

sub _init {
    my ($class, $uri, $scheme) = @_;

    my $self = $class->SUPER::_init($uri, $scheme);

    # Normalise at poles.
    my $lat = $self->latitude;
    if ($lat == _MAXIMUM_LATITUDE() || $lat == _MINIMUM_LATITUDE()) {
        $self->longitude(0);
    }
    return $self;
}

sub location {
    my ($self, @parameters) = @_;

    if (@parameters) {
        my ($lat, $lon, $alt) = @parameters;
        return $self->latitude($lat)->longitude($lon)->altitude($alt);
    }

    return $self->latitude, $self->longitude, $self->altitude;
}

sub latitude {
    my ($self, @parameters) = @_;
    return $self->field('latitude', @parameters);
}

sub longitude {
    my ($self, @parameters) = @_;
    return $self->field('longitude', @parameters);
}

sub altitude {
    my ($self, @parameters) = @_;
    return $self->field('altitude', @parameters);
}

sub crs {
    my ($self, @parameters) = @_;
    return $self->field('crs', @parameters);
}

sub uncertainty {
    my ($self, @parameters) = @_;
    return $self->field('uncertainty', @parameters);
}

sub field {
    my ($self, $name, @remainder) = @_;
    my ($scheme, $auth, $v, $query, $frag) = $self->_parse;

    if (!exists $v->{$name}) {
        croak "No such field: $name";
    }
    if (!@remainder) {
        return $v->{$name};
    }
    $v->{$name} = shift @remainder;
    ${$self} = uri_join $scheme, $auth, $self->_format($v), $query, $frag;
    return $self;
}

{
    my $pnum = qr{\d+(?:[.]\d+)?}smx;
    my $num  = qr{-?$pnum}smx;
    my $crsp = qr{(?:;crs=(\w+))}smx;
    my $uncp = qr{(?:;u=($pnum))}smx;
    my $parm = qr{(?:;\w+=[^;]*)+}smx;

    sub _parse {
        my $self = shift;
        my ($scheme, $auth, $path, $query, $frag) = uri_split ${$self};

        $path =~ m{^ ($num), ($num) (?: , ($num) ) ?
                   (?: $crsp ) ?
                   (?: $uncp ) ?
                   ( $parm ) ? 
                $}smx or croak 'Badly formed geo uri';

        # No named captures before 5.10.0
        return $scheme, $auth,
            {
            latitude    => $1,
            longitude   => $2,
            altitude    => $3,
            crs         => $4,
            uncertainty => $5,
            parameters  => (defined $6 ? substr $6, 1 : undef),
            },
            $query, $frag;
    }
}

sub _format {
    my ($class, $v) = @_;
    return join q[;],
        (
        join q[,],
        map { $class->_num($_) } @{$v}{'latitude', 'longitude'},
        (defined $v->{altitude} ? ($v->{altitude}) : ())
        ),
        (defined $v->{crs} ? ('crs=' . $class->_num($v->{crs})) : ()),
        (
        defined $v->{uncertainty}
        ? ('u=' . $class->_num($v->{uncertainty}))
        : ()), (defined $v->{parameters} ? ($v->{parameters}) : ());
}

sub _path {
    my ($class, @parameters) = @_;
    my ($lat, $lon, $alt) = $class->_location_of_pointy_thing(@parameters);
    croak 'Latitude out of range'
        if $lat < _MINIMUM_LATITUDE() || $lat > _MAXIMUM_LATITUDE();
    croak 'Longitude out of range'
        if $lon < _MINIMUM_LONGITUDE() || $lon > _MAXIMUM_LONGITUDE();
    if ($lat == _MINIMUM_LATITUDE() || $lat == _MAXIMUM_LATITUDE()) {
        $lat = 0;
    }
    return $class->_format(
        {latitude => $lat, longitude => $lon, altitude => $alt});
}

1;

__END__

=head1 NAME

URI::geo - URI scheme for geo Identifiers

=head1 SYNOPSIS

  use URI;

  # Geo URI from textual uri
  my $guri = URI->new( 'geo:54.786989,-2.344214' );

  # From coordinates
  my $guri = URI::geo->new( 54.786989, -2.344214 );

  # Decode
  my ( $lat, $lon, $alt ) = $guri->location;
  my $latitude = $guri->latitude;

  # Update
  $guri->location( 55, -1 );
  $guri->longitude( -43.23 );
  
=head1 DESCRIPTION

From L<http://geouri.org/>:

  More and more protocols and data formats are being extended by methods
  to add geographic information. However, all of those options are tied
  to that specific protocol or data format.

  A dedicated Uniform Resource Identifier (URI) scheme for geographic
  locations would be independent from any protocol, usable by any
  software/data format that can handle generich URIs. Like a "mailto:"
  URI launches your favourite mail application today, a "geo:" URI could
  soon launch your favourite mapping service, or queue that location for
  a navigation device.

=head1 SUBROUTINES/METHODS

=head2 C<< new >>

Create a new URI::geo. The arguments should be either

=over

=item * latitude, longitude and optionally altitude

=item * a reference to an array containing lat, lon, alt

=item * a reference to a hash with suitably named keys or

=item * a reference to an object with suitably named accessors

=back

To maximize the likelihood that you can pass in some object that
represents a geographical location and have URI::geo do the right thing
we try a number of different accessor names.

If the object has a C<latlong> method (e.g. L<Geo::Point>) we'll use that.
If there's a C<location> method we call that. Otherwise we look for
accessors called C<lat>, C<latitude>, C<lon>, C<long>, C<longitude>,
C<ele>, C<alt>, C<elevation> or C<altitude> and use them.

Often if you have an object or hash reference that represents a point
you can pass it directly to C<new>; so for example this will work:

  use URI::geo;
  use Geo::Point;

  my $pt = Geo::Point->latlong( 48.208333, 16.372778 );
  my $guri = URI::geo->new( $pt );

As will this:

  my $guri = URI::geo->new( { lat => 55, lon => -1 } );

and this:

  my $guri = URI::geo->new( 55, -1 );

Note that you can also create a new C<URI::geo> by passing a Geo URI to
C<URI::new>:

  use URI;

  my $guri = URI->new( 'geo:55,-1' );

=head2 C<location>

Get or set the location of this geo URI.

  my ( $lat, $lon, $alt ) = $guri->location;
  $guri->location( 55.3, -3.7, 120 );

When setting the location it is possible to pass any of the argument
types that can be passed to C<new>.

=head2 C<latitude>

Get or set the latitude of this geo URI.

=head2 C<longitude>

Get or set the longitude of this geo URI.

=head2 C<altitude>

Get or set the L<altitude|https://en.wikipedia.org/wiki/Geo_URI_scheme#Altitude> of this geo URI. To delete the altitude set it to C<undef>.

=head2 C<crs>

Get or set the L<Coordinate Reference System|https://en.wikipedia.org/wiki/Geo_URI_scheme#Coordinate_reference_systems> of this geo URI. To delete the CRS set it to C<undef>.

=head2 C<uncertainty>

Get or set the L<uncertainty|https://en.wikipedia.org/wiki/Geo_URI_scheme#Uncertainty> of this geo URI. To delete the uncertainty set it to C<undef>.

=head2 C<field>

=head1 CONFIGURATION AND ENVIRONMENT

URI::geo requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<URI>

=head1 DIAGNOSTICS

=over
 
=item C<< Too many arguments >>
 
The L<new|/new> method can only accept three parameters; latitude, longitude and altitude.
 
=item C<< Don't know how to convert point >>

The L<new|/new> method doesn't know how to convert the supplied parameters into a URI::geo object.

=item C<< Need lat, lon or lat, lon, alt >>

The L<new|/new> method needs two (latitude and longitude) or three (latitude, longitude and altitude) parameters in a list.  Any less or more than this is an error.

=item C<< No such field: %s >>

This field is not a known field for the L<URI::geo|URI::geo> object.

=item C<< Badly formed geo uri >>

The L<URI|URI> cannot be parsed as a URI

=item C<< Badly formed geo uri >>

The L<URI|URI> cannot be parsed as a URI

=item C<< Latitude out of range >>

Latitude may only be from -90 to +90

=item C<< Longitude out of range >>

Longitude may only be from -180 to +180

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

To report a bug, or view the current list of bugs, please visit L<https://github.com/libwww-perl/URI/issues>

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
