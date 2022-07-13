package LWP::Authen::Digest;

use strict;
use base 'LWP::Authen::Basic';

our $VERSION = '6.57';

require Digest::MD5;

sub _reauth_requested {
    my ($class, $auth_param, $ua, $request, $auth_header) = @_;
    my $ret = defined($$auth_param{stale}) && lc($$auth_param{stale}) eq 'true';
    if ($ret) {
        my $hdr = $request->header($auth_header);
        $hdr =~ tr/,/;/;    # "," is used to separate auth-params!!
        ($hdr) = HTTP::Headers::Util::split_header_words($hdr);
        my $nonce = {@$hdr}->{nonce};
        delete $$ua{authen_md5_nonce_count}{$nonce};
    }
    return $ret;
}

sub auth_header {
    my($class, $user, $pass, $request, $ua, $h) = @_;

    my $auth_param = $h->{auth_param};

    my $nc = sprintf "%08X", ++$ua->{authen_md5_nonce_count}{$auth_param->{nonce}};
    my $cnonce = sprintf "%8x", time;

    my $uri = $request->uri->path_query;
    $uri = "/" unless length $uri;

    my $md5 = Digest::MD5->new;

    my(@digest);
    $md5->add(join(":", $user, $auth_param->{realm}, $pass));
    push(@digest, $md5->hexdigest);
    $md5->reset;

    push(@digest, $auth_param->{nonce});

    if ($auth_param->{qop}) {
	push(@digest, $nc, $cnonce, ($auth_param->{qop} =~ m|^auth[,;]auth-int$|) ? 'auth' : $auth_param->{qop});
    }

    $md5->add(join(":", $request->method, $uri));
    push(@digest, $md5->hexdigest);
    $md5->reset;

    $md5->add(join(":", @digest));
    my($digest) = $md5->hexdigest;
    $md5->reset;

    my %resp = map { $_ => $auth_param->{$_} } qw(realm nonce opaque);
    @resp{qw(username uri response algorithm)} = ($user, $uri, $digest, "MD5");

    if (($auth_param->{qop} || "") =~ m|^auth([,;]auth-int)?$|) {
	@resp{qw(qop cnonce nc)} = ("auth", $cnonce, $nc);
    }

    my(@order) = qw(username realm qop algorithm uri nonce nc cnonce response opaque);
    my @pairs;
    for (@order) {
	next unless defined $resp{$_};

	# RFC2617 says that qop-value and nc-value should be unquoted.
	if ( $_ eq 'qop' || $_ eq 'nc' ) {
		push(@pairs, "$_=" . $resp{$_});
	}
	else {
		push(@pairs, "$_=" . qq("$resp{$_}"));
	}
    }

    my $auth_value  = "Digest " . join(", ", @pairs);
    return $auth_value;
}

1;
