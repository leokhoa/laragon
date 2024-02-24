package URI::_userpass;

use strict;
use warnings;

use URI::Escape qw(uri_unescape);

our $VERSION = '5.21';

sub user
{
    my $self = shift;
    my $info = $self->userinfo;
    if (@_) {
	my $new = shift;
	my $pass = defined($info) ? $info : "";
	$pass =~ s/^[^:]*//;

	if (!defined($new) && !length($pass)) {
	    $self->userinfo(undef);
	} else {
	    $new = "" unless defined($new);
	    $new =~ s/%/%25/g;
	    $new =~ s/:/%3A/g;
	    $self->userinfo("$new$pass");
	}
    }
    return undef unless defined $info;
    $info =~ s/:.*//;
    uri_unescape($info);
}

sub password
{
    my $self = shift;
    my $info = $self->userinfo;
    if (@_) {
	my $new = shift;
	my $user = defined($info) ? $info : "";
	$user =~ s/:.*//;

	if (!defined($new)) {
	    $self->userinfo(length $user ? $user : undef);
	} else {
	    $new = "" unless defined($new);
	    $new =~ s/%/%25/g;
	    $self->userinfo("$user:$new");
	}
    }
    return undef unless defined $info;
    return undef unless $info =~ s/^[^:]*://;
    uri_unescape($info);
}

1;
