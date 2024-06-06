package URI::_server;

use strict;
use warnings;

use parent 'URI::_generic';

use URI::Escape qw(uri_unescape);

our $VERSION = '5.10';

sub _uric_escape {
    my($class, $str) = @_;
    if ($str =~ m,^((?:$URI::scheme_re:)?)//([^/?\#]*)(.*)$,os) {
	my($scheme, $host, $rest) = ($1, $2, $3);
	my $ui = $host =~ s/(.*@)// ? $1 : "";
	my $port = $host =~ s/(:\d+)\z// ? $1 : "";
	if (_host_escape($host)) {
	    $str = "$scheme//$ui$host$port$rest";
	}
    }
    return $class->SUPER::_uric_escape($str);
}

sub _host_escape {
    return unless $_[0] =~ /[^$URI::uric]/;
    eval {
	require URI::_idna;
	$_[0] = URI::_idna::encode($_[0]);
    };
    return 0 if $@;
    return 1;
}

sub as_iri {
    my $self = shift;
    my $str = $self->SUPER::as_iri;
    if ($str =~ /\bxn--/) {
	if ($str =~ m,^((?:$URI::scheme_re:)?)//([^/?\#]*)(.*)$,os) {
	    my($scheme, $host, $rest) = ($1, $2, $3);
	    my $ui = $host =~ s/(.*@)// ? $1 : "";
	    my $port = $host =~ s/(:\d+)\z// ? $1 : "";
	    require URI::_idna;
	    $host = URI::_idna::decode($host);
	    $str = "$scheme//$ui$host$port$rest";
	}
    }
    return $str;
}

sub userinfo
{
    my $self = shift;
    my $old = $self->authority;

    if (@_) {
	my $new = $old;
	$new = "" unless defined $new;
	$new =~ s/.*@//;  # remove old stuff
	my $ui = shift;
	if (defined $ui) {
	    $ui =~ s/@/%40/g;   # protect @
	    $new = "$ui\@$new";
	}
	$self->authority($new);
    }
    return undef if !defined($old) || $old !~ /(.*)@/;
    return $1;
}

sub host
{
    my $self = shift;
    my $old = $self->authority;
    if (@_) {
	my $tmp = $old;
	$tmp = "" unless defined $tmp;
	my $ui = ($tmp =~ /(.*@)/) ? $1 : "";
	my $port = ($tmp =~ /(:\d+)$/) ? $1 : "";
	my $new = shift;
	$new = "" unless defined $new;
	if (length $new) {
	    $new =~ s/[@]/%40/g;   # protect @
	    if ($new =~ /^[^:]*:\d*\z/ || $new =~ /]:\d*\z/) {
		$new =~ s/(:\d*)\z// || die "Assert";
		$port = $1;
	    }
	    $new = "[$new]" if $new =~ /:/ && $new !~ /^\[/; # IPv6 address
	    _host_escape($new);
	}
	$self->authority("$ui$new$port");
    }
    return undef unless defined $old;
    $old =~ s/.*@//;
    $old =~ s/:\d+$//;          # remove the port
    $old =~ s{^\[(.*)\]$}{$1};  # remove brackets around IPv6 (RFC 3986 3.2.2)
    return uri_unescape($old);
}

sub ihost
{
    my $self = shift;
    my $old = $self->host(@_);
    if ($old =~ /(^|\.)xn--/) {
	require URI::_idna;
	$old = URI::_idna::decode($old);
    }
    return $old;
}

sub _port
{
    my $self = shift;
    my $old = $self->authority;
    if (@_) {
	my $new = $old;
	$new =~ s/:\d*$//;
	my $port = shift;
	$new .= ":$port" if defined $port;
	$self->authority($new);
    }
    return $1 if defined($old) && $old =~ /:(\d*)$/;
    return;
}

sub port
{
    my $self = shift;
    my $port = $self->_port(@_);
    $port = $self->default_port if !defined($port) || $port eq "";
    $port;
}

sub host_port
{
    my $self = shift;
    my $old = $self->authority;
    $self->host(shift) if @_;
    return undef unless defined $old;
    $old =~ s/.*@//;        # zap userinfo
    $old =~ s/:$//;         # empty port should be treated the same a no port
    $old .= ":" . $self->port unless $old =~ /:\d+$/;
    $old;
}


sub default_port { undef }

sub canonical
{
    my $self = shift;
    my $other = $self->SUPER::canonical;
    my $host = $other->host || "";
    my $port = $other->_port;
    my $uc_host = $host =~ /[A-Z]/;
    my $def_port = defined($port) && ($port eq "" ||
                                      $port == $self->default_port);
    if ($uc_host || $def_port) {
	$other = $other->clone if $other == $self;
	$other->host(lc $host) if $uc_host;
	$other->port(undef)    if $def_port;
    }
    $other;
}

1;
