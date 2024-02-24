package LWP::Authen::Basic;

use strict;

our $VERSION = '6.72';

require Encode;
require MIME::Base64;

sub auth_header {
    my($class, $user, $pass, $request, $ua, $h) = @_;

    my $userpass = "$user:$pass";
    # https://tools.ietf.org/html/rfc7617#section-2.1
    my $charset = uc($h->{auth_param}->{charset} || "");
    $userpass = Encode::encode($charset, $userpass)
        if ($charset eq "UTF-8");

    return "Basic " . MIME::Base64::encode($userpass, "");
}

sub _reauth_requested {
    return 0;
}

sub authenticate
{
    my($class, $ua, $proxy, $auth_param, $response,
       $request, $arg, $size) = @_;

    my $realm = $auth_param->{realm} || "";
    my $url = $proxy ? $request->{proxy} : $request->uri_canonical;
    return $response unless $url;
    my $host_port = $url->host_port;
    my $auth_header = $proxy ? "Proxy-Authorization" : "Authorization";

    my @m = $proxy ? (m_proxy => $url) : (m_host_port => $host_port);
    push(@m, realm => $realm);

    my $h = $ua->get_my_handler("request_prepare", @m, sub {
        $_[0]{callback} = sub {
            my($req, $ua, $h) = @_;
            my($user, $pass) = $ua->credentials($host_port, $h->{realm});
	    if (defined $user) {
		my $auth_value = $class->auth_header($user, $pass, $req, $ua, $h);
		$req->header($auth_header => $auth_value);
	    }
        };
    });
    $h->{auth_param} = $auth_param;

    my $reauth_requested
        = $class->_reauth_requested($auth_param, $ua, $request, $auth_header);
    if (   !$proxy
        && (!$request->header($auth_header) || $reauth_requested)
        && $ua->credentials($host_port, $realm))
    {
        # we can make sure this handler applies and retry
        add_path($h, $url->path)
            unless $reauth_requested;  # Do not clobber up path list for retries
        return $ua->request($request->clone, $arg, $size, $response);
    }

    my($user, $pass) = $ua->get_basic_credentials($realm, $url, $proxy);
    unless (defined $user and defined $pass) {
	$ua->set_my_handler("request_prepare", undef, @m);  # delete handler
	return $response;
    }

    # check that the password has changed
    my ($olduser, $oldpass) = $ua->credentials($host_port, $realm);
    return $response if (defined $olduser and defined $oldpass and
                         $user eq $olduser and $pass eq $oldpass);

    $ua->credentials($host_port, $realm, $user, $pass);
    add_path($h, $url->path) unless $proxy;
    return $ua->request($request->clone, $arg, $size, $response);
}

sub add_path {
    my($h, $path) = @_;
    $path =~ s,[^/]+\z,,;
    push(@{$h->{m_path_prefix}}, $path);
}

1;
