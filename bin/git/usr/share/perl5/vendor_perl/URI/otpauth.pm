package URI::otpauth;

use warnings;
use strict;
use MIME::Base32();
use URI::Split();
use URI::Escape();

use parent qw( URI URI::_query );

our $VERSION = '5.29';

sub new {
    my ($class, @parameters) = @_;
    my %fields = $class->_set(@parameters);
    my $uri    = URI::Split::uri_join(
        'otpauth', $fields{type},
        $class->_path(%fields),
        $class->_query(%fields),
    );
    return bless \$uri, $class;
}

sub _parse {
    my $self = shift;
    my ($scheme, $type, $path, $query, $frag) = URI::Split::uri_split(${$self});
    $path =~ s/^\///smxg;
    my @path_parts = split /:/smx, $path;
    my ($issuer_prefix, $account_name);
    if (scalar @path_parts == 1) {
        $account_name = $path_parts[0];
    }
    else {
        $issuer_prefix = $path_parts[0];
        $account_name  = $path_parts[1];
    }
    my %fields = (label => $path, type => $type, account_name => $account_name);
    my $issuer_parameter = $self->query_param('issuer');
    if (defined $issuer_parameter) {
        if ((defined $issuer_prefix) && ($issuer_prefix ne $issuer_parameter)) {
            Carp::carp(
                "Issuer prefix from label '$issuer_prefix' does not match issuer parameter '$issuer_parameter'"
            );
        }
        $fields{issuer} = $issuer_parameter;
    }
    elsif (defined $issuer_prefix) {
        $fields{issuer} = URI::Escape::uri_unescape($issuer_prefix);
    }
    if (my $encoded_secret = $self->query_param('secret')) {
        $fields{secret} = MIME::Base32::decode_base32($encoded_secret);
    }
    foreach my $name (qw(algorithm digits counter period)) {
        if (my $value = $self->query_param($name)) {
            $fields{$name} = $value;
        }
    }
    %fields = $self->_set(%fields);
    return ($scheme, $fields{type}, \%fields, $query, $frag);
}

my $label_escape_regex = qr/[^[:alnum:]@.]/smx;

sub _set {
    my ($self, %fields) = @_;
    delete $fields{label};
    if (defined $fields{account_name}) {
        if (defined $fields{issuer}) {
            $fields{label} = $fields{issuer} . q[:] . $fields{account_name};
        }
        else {
            $fields{label} = $fields{account_name};
        }
    }
    if (!length $fields{type}) {
        $fields{type} = 'totp';
    }
    return %fields;
}

my %field_names = map { $_ => 1 }
    qw(secret label counter algorithm period digits issuer type account_name);
my @query_names = qw(secret issuer algorithm digits counter period);
my %defaults = (algorithm => 'SHA1', digits => 6, type => 'totp', period => 30);

sub _field {
    my ($self, $name, @remainder) = @_;
    my ($scheme, $type, $fields, $query, $frag) = $self->_parse();

    if (!@remainder) {
        if (defined $fields->{$name}) {
            return $fields->{$name};
        }
        else {
            return $defaults{$name};
        }
    }
    $fields->{$name} = shift @remainder;
    ${$self} = URI::Split::uri_join(
        $scheme, $fields->{type},
        $self->_path(%{$fields}),
        $self->_query(%{$fields}), $frag
    );
    return $self;
}

sub _query {
    my ($class, %fields) = @_;
    if (defined $fields{secret}) {
        $fields{secret} = MIME::Base32::encode_base32($fields{secret});
    }
    else {
        Carp::croak('secret is a mandatory parameter for ' . __PACKAGE__);
    }
    return join q[&],
        map { join q[=], $_ => $fields{$_} }
        grep { exists $fields{$_} } @query_names;
}

sub _path {
    my ($class, %fields) = @_;
    my $path = $fields{label};
    return $path;
}

sub type {
    my ($self, @parameters) = @_;
    return $self->_field('type', @parameters);
}

sub label {
    my ($self, @parameters) = @_;
    return $self->_field('label', @parameters);
}

sub account_name {
    my ($self, @parameters) = @_;
    return $self->_field('account_name', @parameters);
}

sub issuer {
    my ($self, @parameters) = @_;
    return $self->_field('issuer', @parameters);
}

sub secret {
    my ($self, @parameters) = @_;
    return $self->_field('secret', @parameters);
}

sub algorithm {
    my ($self, @parameters) = @_;
    return $self->_field('algorithm', @parameters);
}

sub counter {
    my ($self, @parameters) = @_;
    return $self->_field('counter', @parameters);
}

sub digits {
    my ($self, @parameters) = @_;
    return $self->_field('digits', @parameters);
}

sub period {
    my ($self, @parameters) = @_;
    return $self->_field('period', @parameters);
}

1;

__END__

=head1 NAME

URI::otpauth - URI scheme for secret keys for OTP secrets.  Usually found in QR codes

=head1 VERSION

Version 5.29

=head1 SYNOPSIS

  use URI;

  # optauth URI from textual uri
  my $uri = URI->new( 'otpauth://totp/Example:alice@google.com?secret=NFZS25DINFZV643VOAZXELLTGNRXEM3UH4&issuer=Example' );

  # same URI but created from arguments
  my $uri = URI::otpauth->new( type => 'totp', issuer => 'Example', account_name => 'alice@google.com', secret => 'is-this_sup3r-s3cr3t?' );
  
=head1 DESCRIPTION

This URI scheme is defined in L<https://github.com/google/google-authenticator/wiki/Key-Uri-Format/>:

=head1 SUBROUTINES/METHODS

=head2 C<< new >>

Create a new URI::otpauth. The available arguments are listed below;

=over

=item * account_name - this can be the account name (probably an email address) used when authenticating with this secret.  It is an optional field.

=item * algorithm - this is the L<cryptographic hash function|https://en.wikipedia.org/wiki/Cryptographic_hash_function> that should be used.  Current values are L<SHA1|https://en.wikipedia.org/wiki/SHA-1>, L<SHA256|https://en.wikipedia.org/wiki/SHA-2> or L<SHA512|https://en.wikipedia.org/wiki/SHA-2>.  It is an optional field and will default to SHA1.

=item * counter - this is only required when the type is HOTP.

=item * digits - this determines the L<length|https://github.com/google/google-authenticator/wiki/Key-Uri-Format/#digits> of the code presented to the user.  It is an optional field and will default to 6 digits.

=item * issuer - this can be the L<application / system|https://github.com/google/google-authenticator/wiki/Key-Uri-Format/#issuer> that this secret can be used to authenticate to.  It is an optional field.

=item * label - this is the L<issuer and the account name|https://github.com/google/google-authenticator/wiki/Key-Uri-Format/#label> joined with a ":" character.  It is an optional field.

=item * period - this is the L<period that the TOTP code is valid for|https://github.com/google/google-authenticator/wiki/Key-Uri-Format/#counter>.  It is an optional field and will default to 30 seconds.

=item * secret - this is the L<key|https://en.wikipedia.org/wiki/Key_(cryptography)> that the L<TOTP|https://en.wikipedia.org/wiki/Time-based_one-time_password>/L<HOTP|https://en.wikipedia.org/wiki/HMAC-based_one-time_password> algorithm uses to derive the value.  It is an arbitrary byte string and must remain private.  This field is mandatory.

=item * type - this can be 'L<hotp|https://en.wikipedia.org/wiki/HMAC-based_one-time_password>' or 'L<totp|https://en.wikipedia.org/wiki/Time-based_one-time_password>'.  This field will default to 'totp'.

=back

=head2 C<algorithm>

Get or set the algorithm of this otpauth URI.

=head2 C<account_name>

Get or set the account_name of this otpauth URI.

=head2 C<counter>

Get or set the counter of this otpauth URI.

=head2 C<digits>

Get or set the digits of this otpauth URI.

=head2 C<issuer>

Get or set the issuer of this otpauth URI.

=head2 C<label>

Get or set the label of this otpauth URI.

=head2 C<period>

Get or set the period of this otpauth URI.

=head2 C<secret>

Get or set the secret of this otpauth URI.

=head2 C<type>

Get or set the type of this otpauth URI.

  my $type = $uri->type('hotp');

=head1 CONFIGURATION AND ENVIRONMENT

URI::otpauth requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<URI>

=head1 DIAGNOSTICS

=over
 
=item C<< secret is a mandatory parameter for URI::otpauth >>
 
The secret parameter was not detected for the URI::otpauth->new() method.
 
=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

To report a bug, or view the current list of bugs, please visit L<https://github.com/libwww-perl/URI/issues>

=head1 AUTHOR

David Dick C<< <ddick@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, David Dick C<< <ddick@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
