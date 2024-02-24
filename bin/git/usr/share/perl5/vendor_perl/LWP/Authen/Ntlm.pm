package LWP::Authen::Ntlm;

use strict;

our $VERSION = '6.60';

use Authen::NTLM "1.02";
use MIME::Base64 "2.12";

sub authenticate {
    my($class, $ua, $proxy, $auth_param, $response,
       $request, $arg, $size) = @_;

    my($user, $pass) = $ua->get_basic_credentials($auth_param->{realm},
                                                  $request->uri, $proxy);

    unless(defined $user and defined $pass) {
		return $response;
	}

	if (!$ua->conn_cache()) {
		warn "The keep_alive option must be enabled for NTLM authentication to work.  NTLM authentication aborted.\n";
		return $response;
	}

	my($domain, $username) = split(/\\/, $user);

	ntlm_domain($domain);
	ntlm_user($username);
	ntlm_password($pass);

    my $auth_header = $proxy ? "Proxy-Authorization" : "Authorization";

	# my ($challenge) = $response->header('WWW-Authenticate');
	my $challenge;
	foreach ($response->header('WWW-Authenticate')) {
		last if /^NTLM/ && ($challenge=$_);
	}

	if ($challenge eq 'NTLM') {
		# First phase, send handshake
	    my $auth_value = "NTLM " . ntlm();
		ntlm_reset();

	    # Need to check this isn't a repeated fail!
	    my $r = $response;
		my $retry_count = 0;
	    while ($r) {
			my $auth = $r->request->header($auth_header);
			++$retry_count if ($auth && $auth eq $auth_value);
			if ($retry_count > 2) {
				    # here we know this failed before
				    $response->header("Client-Warning" =>
						      "Credentials for '$user' failed before");
				    return $response;
			}
			$r = $r->previous;
	    }

	    my $referral = $request->clone;
	    $referral->header($auth_header => $auth_value);
	    return $ua->request($referral, $arg, $size, $response);
	}

	else {
		# Second phase, use the response challenge (unless non-401 code
		#  was returned, in which case, we just send back the response
		#  object, as is
		my $auth_value;
		if ($response->code ne '401') {
			return $response;
		}
		else {
			my $challenge;
			foreach ($response->header('WWW-Authenticate')) {
				last if /^NTLM/ && ($challenge=$_);
			}
			$challenge =~ s/^NTLM //;
			ntlm();
			$auth_value = "NTLM " . ntlm($challenge);
			ntlm_reset();
		}

	    my $referral = $request->clone;
	    $referral->header($auth_header => $auth_value);
	    my $response2 = $ua->request($referral, $arg, $size, $response);
		return $response2;
	}
}

1;
__END__

=pod

=head1 NAME

LWP::Authen::Ntlm - Library for enabling NTLM authentication (Microsoft) in LWP

=head1 SYNOPSIS

 use LWP::UserAgent;
 use HTTP::Request::Common;
 my $url = 'http://www.company.com/protected_page.html';

 # Set up the ntlm client and then the base64 encoded ntlm handshake message
 my $ua = LWP::UserAgent->new(keep_alive=>1);
 $ua->credentials('www.company.com:80', '', "MyDomain\\MyUserCode", 'MyPassword');

 $request = GET $url;
 print "--Performing request now...-----------\n";
 $response = $ua->request($request);
 print "--Done with request-------------------\n";

 if ($response->is_success) {print "It worked!->" . $response->code . "\n"}
 else {print "It didn't work!->" . $response->code . "\n"}

=head1 DESCRIPTION

L<LWP::Authen::Ntlm> allows LWP to authenticate against servers that are using the
NTLM authentication scheme popularized by Microsoft.  This type of authentication is
common on intranets of Microsoft-centric organizations.

The module takes advantage of the Authen::NTLM module by Mark Bush.  Since there
is also another Authen::NTLM module available from CPAN by Yee Man Chan with an
entirely different interface, it is necessary to ensure that you have the correct
NTLM module.

In addition, there have been problems with incompatibilities between different
versions of L<Mime::Base64>, which Bush's L<Authen::NTLM> makes use of.  Therefore, it is
necessary to ensure that your Mime::Base64 module supports exporting of the
C<encode_base64> and C<decode_base64> functions.

=head1 USAGE

The module is used indirectly through LWP, rather than including it directly in your
code.  The LWP system will invoke the NTLM authentication when it encounters the
authentication scheme while attempting to retrieve a URL from a server.  In order
for the NTLM authentication to work, you must have a few things set up in your
code prior to attempting to retrieve the URL:

=over 4

=item *

Enable persistent HTTP connections

To do this, pass the C<< "keep_alive=>1" >> option to the L<LWP::UserAgent> when creating it, like this:

    my $ua = LWP::UserAgent->new(keep_alive=>1);

=item *

Set the credentials on the UserAgent object

The credentials must be set like this:

   $ua->credentials('www.company.com:80', '', "MyDomain\\MyUserCode", 'MyPassword');

Note that you cannot use the L<HTTP::Request> object's C<authorization_basic()> method to set
the credentials.  Note, too, that the C<'www.company.com:80'> portion only sets credentials
on the specified port AND it is case-sensitive (this is due to the way LWP is coded, and
has nothing to do with LWP::Authen::Ntlm)

=back

=head1 AVAILABILITY

General queries regarding LWP should be made to the LWP Mailing List.

Questions specific to LWP::Authen::Ntlm can be forwarded to jtillman@bigfoot.com

=head1 COPYRIGHT

Copyright (c) 2002 James Tillman. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<LWP>, L<LWP::UserAgent>, L<lwpcook>.

=cut
