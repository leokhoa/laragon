# Copyright (c) 2006 Simon Wilkinson
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

package Authen::SASL::Perl::GSSAPI;
$Authen::SASL::Perl::GSSAPI::VERSION = '2.1700';
use strict;
use warnings;

use vars qw(@ISA);
use GSSAPI;

@ISA = qw(Authen::SASL::Perl);

my %secflags = (
  noplaintext => 1,
  noanonymous => 1,
);

sub _order { 4 }
sub _secflags {
  shift;
  scalar grep { $secflags{$_} } @_;
}

sub mechanism { 'GSSAPI' }

sub _init {
  my ($pkg, $self) = @_;
  bless $self, $pkg;

  # set default security properties
  $self->property('minssf',      0);
  $self->property('maxssf',      int 2**31 - 1);    # XXX - arbitrary "high" value
  $self->property('maxbuf',      0xFFFFFF);         # maximum supported by GSSAPI mech
  $self->property('externalssf', 0);
  # the cyrus sasl library allows only one bit to be set in the
  # layer selection mask in the client reply, we default to
  # compatibility with that bug
  $self->property('COMPAT_CYRUSLIB_REPLY_MASK_BUG', 1);
  $self;
}

sub client_start {
  my $self = shift;
  my $status;
  my $principal = $self->service.'@'.$self->host;

  # GSSAPI::Name->import is the *constructor*,
  # storing the new GSSAPI::Name into $target.
  # GSSAPI::Name->import is not the standard
  # import() method as used in Perl normally
  my $target;
  $status = GSSAPI::Name->import($target, $principal, gss_nt_service_name)
    or return $self->set_error("GSSAPI Error : ".$status);
  $self->{gss_name}  = $target;
  $self->{gss_ctx}   = new GSSAPI::Context;
  $self->{gss_state} = 0;
  $self->{gss_layer} = undef;
  my $cred = $self->_call('pass');
  $self->{gss_cred}  = (ref($cred) && $cred->isa('GSSAPI::Cred')) ? $cred : GSS_C_NO_CREDENTIAL;
  $self->{gss_mech}  = $self->_call('gssmech') || gss_mech_krb5;

  # reset properties for new session
  $self->property(maxout => undef);
  $self->property(ssf    => undef);

  return $self->client_step('');
}

sub client_step {
  my ($self, $challenge) = @_;
  my $debug = $self->{debug};

  my $status;

  if ($self->{gss_state} == 0) {
    my $outtok;
    my $inflags = GSS_C_INTEG_FLAG | GSS_C_MUTUAL_FLAG;#todo:set according to ssf props
    my $outflags;
    $status = $self->{gss_ctx}->init($self->{gss_cred}, $self->{gss_name}, 
			     $self->{gss_mech},
			     $inflags, 
			     0, GSS_C_NO_CHANNEL_BINDINGS, $challenge, undef, 
			     $outtok, $outflags, undef);

    print STDERR "state(0): ".
		$status->generic_message.';'.$status->specific_message.
		"; output token sz: ".length($outtok)."\n"
      if ($debug & 1);

    if (GSSAPI::Status::GSS_ERROR($status->major)) {
      return $self->set_error("GSSAPI Error (init): ".$status);
    }
    if ($status->major == GSS_S_COMPLETE) {
      $self->{gss_state} = 1;
    }
    return $outtok;
  }
  elsif ($self->{gss_state} == 1) {
    # If the server has an empty output token when it COMPLETEs, Cyrus SASL
    # kindly sends us that empty token. We need to ignore it, which introduces
    # another round into the process. 
    print STDERR "  state(1): challenge is EMPTY\n"
      if ($debug and $challenge eq '');
    return '' if ($challenge eq '');
 
    my $unwrapped;
    $status = $self->{gss_ctx}->unwrap($challenge, $unwrapped, undef, undef)
      or return $self->set_error("GSSAPI Error (unwrap challenge): ".$status);

    return $self->set_error("GSSAPI Error : invalid security layer token")
      if (length($unwrapped) != 4);

    # the security layers the server supports: bitmask of
    #   1 = no security layer,
    #   2 = integrity protection,
    #   4 = confidentiality protection
    # which is encoded in the first octet of the response;
    # the remote maximum buffer size is encoded in the next three octets
    #
    my $layer = ord(substr($unwrapped, 0, 1, chr(0)));
    my ($rsz) = unpack('N',$unwrapped);

    # get local receive buffer size
    my $lsz = $self->property('maxbuf');

    # choose security layer
    my $choice = $self->_layer($layer,$rsz,$lsz);
    return $self->set_error("GSSAPI Error: security too weak") unless $choice;

    $self->{gss_layer} = $choice;

    if ($choice > 1) {
	# determine maximum plain text message size for peer's cipher buffer
	my $psz;
	$status = $self->{gss_ctx}->wrap_size_limit($choice & 4, 0, $rsz, $psz)
	    or return $self->set_error("GSSAPI Error (wrap size): ".$status);
	return $self->set_error("GSSAPI wrap size = 0") unless ($psz);
	$self->property(maxout => $psz);
	# set SSF property; if we have just integrity protection SSF is set
	# to 1. If we have confidentiality, SSF would be an estimate of the
	# strength of the actual encryption ciphers in use which is not
	# available through the GSSAPI interface; for now just set it to
	# the lowest value that signifies confidentiality.
	$self->property(ssf => (($choice & 4) ? 2 : 1));
    } else {
	# our advertised buffer size should be 0 if no layer selected
	$lsz = 0;
	$self->property(ssf => 0);
    }

    print STDERR "state(1): layermask $layer,rsz $rsz,lsz $lsz,choice $choice\n"
	if ($debug & 1);

    my $message = pack('CCCC', $choice,
			($lsz >> 16)&0xff, ($lsz >> 8)&0xff, $lsz&0xff);

    # append authorization identity if we have one
    my $authz = $self->_call('authname');
    $message .= $authz if ($authz);

    my $outtok;
    $status = $self->{gss_ctx}->wrap(0, 0, $message, undef, $outtok)
      or return $self->set_error("GSSAPI Error (wrap token): ".$status);
    
    $self->{gss_state} = 0;
    return $outtok;
  }
}

# default layer selection
sub _layer {
  my ($self, $theirmask, $rsz, $lsz) = @_;
  my $maxssf = $self->property('maxssf') - $self->property('externalssf');
  $maxssf = 0 if ($maxssf < 0);

  my $minssf = $self->property('minssf') - $self->property('externalssf');
  $minssf = 0 if ($minssf < 0);

  return undef if ($maxssf < $minssf);    # sanity check

  # ssf values > 1 mean integrity and confidentiality
  # ssf == 1 means integrity but no confidentiality
  # ssf < 1 means neither integrity nor confidentiality
  # no security layer can be had if buffer size is 0
  my $ourmask = 0;
  $ourmask |= 1 if ($minssf < 1);
  $ourmask |= 2 if ($minssf <= 1 and $maxssf >= 1);
  $ourmask |= 4 if ($maxssf > 1);
  $ourmask &= 1 unless ($rsz and $lsz);

  # mask the bits they don't have
  $ourmask &= $theirmask;

  return $ourmask unless $self->property('COMPAT_CYRUSLIB_REPLY_MASK_BUG');
	
  # in cyrus sasl bug compat mode, select the highest bit set
  return 4 if ($ourmask & 4);
  return 2 if ($ourmask & 2);
  return 1 if ($ourmask & 1);
  return undef;
}

sub encode {  # input: self, plaintext buffer,length (length not used here)
  my $self = shift;
  my $wrapped;
  my $status = $self->{gss_ctx}->wrap($self->{gss_layer} & 4, 0, $_[0], undef, $wrapped);
  $self->set_error("GSSAPI Error (encode): " . $status), return
    unless ($status);
  return $wrapped;
}

sub decode {  # input: self, cipher buffer,length (length not used here)
  my $self = shift;
  my $unwrapped;
  my $status = $self->{gss_ctx}->unwrap($_[0], $unwrapped, undef, undef);
  $self->set_error("GSSAPI Error (decode): " . $status), return
    unless ($status);
  return $unwrapped;
}

__END__

=head1 NAME

Authen::SASL::Perl::GSSAPI - GSSAPI (Kerberosv5) Authentication class

=head1 VERSION

version 2.1700

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new( mechanism => 'GSSAPI' );

  $sasl = Authen::SASL->new( mechanism => 'GSSAPI',
 			     callback => { pass => $mycred });

  $sasl->client_start( $service, $host );

=head1 DESCRIPTION

This method implements the client part of the GSSAPI SASL algorithm,
as described in RFC 2222 section 7.2.1 resp. draft-ietf-sasl-gssapi-XX.txt.

With a valid Kerberos 5 credentials cache (aka TGT) it allows
to connect to I<service>@I<host> given as the first two parameters
to Authen::SASL's client_start() method.  Alternatively, a GSSAPI::Cred
object can be passed in via the Authen::SASL callback hash using
the `pass' key.

Please note that this module does not currently implement a SASL
security layer following authentication. Unless the connection is
protected by other means, such as TLS, it will be vulnerable to
man-in-the-middle attacks. If security layers are required, then the
L<Authen::SASL::XS> GSSAPI module should be used instead.

=head2 CALLBACK

The callbacks used are:

=over 4

=item authname

The authorization identity to be used in SASL exchange

=item gssmech

The GSS mechanism to be used in the connection

=item pass 

The GSS credentials to be used in the connection (optional)

=back


=head1 EXAMPLE

 #! /usr/bin/perl -w

 use strict;
use warnings;

 use Net::LDAP 0.33;
 use Authen::SASL 2.10;

 # -------- Adjust to your environment --------
 my $adhost      = 'theserver.bla.net';
 my $ldap_base   = 'dc=bla,dc=net';
 my $ldap_filter = '(&(sAMAccountName=BLAAGROL))';

 my $sasl = Authen::SASL->new(mechanism => 'GSSAPI');
 my $ldap;

 eval {
     $ldap = Net::LDAP->new($adhost,
                            onerror => 'die')
       or  die "Cannot connect to LDAP host '$adhost': '$@'";
     $ldap->bind(sasl => $sasl);
 };

 if ($@) {
     chomp $@;
     die   "\nBind error         : $@",
           "\nDetailed SASL error: ", $sasl->error,
           "\nTerminated";
 }

 print "\nLDAP bind() succeeded, working in authenticated state";

 my $mesg = $ldap->search(base   => $ldap_base,
                          filter => $ldap_filter);

 # -------- evaluate $mesg 

=head2 PROPERTIES

The properties used are:

=over 4

=item maxbuf

The maximum buffer size for receiving cipher text

=item minssf

The minimum SSF value that should be provided by the SASL security layer.
The default is 0

=item maxssf

The maximum SSF value that should be provided by the SASL security layer.
The default is 2**31

=item externalssf

The SSF value provided by an underlying external security layer.
The default is 0

=item ssf

The actual SSF value provided by the SASL security layer after the SASL
authentication phase has been completed. This value is read-only and set
by the implementation after the SASL authentication phase has been completed.

=item maxout

The maximum plaintext buffer size for sending data to the peer.
This value is set by the implementation after the SASL authentication
phase has been completed and a SASL security layer is in effect.

=back


=head1 SEE ALSO

L<Authen::SASL>,
L<Authen::SASL::Perl>

=head1 AUTHORS

Written by Simon Wilkinson, with patches and extensions by Achim Grolms
and Peter Marschall.

Please report any bugs, or post any suggestions, to the perl-ldap mailing list
<perl-ldap@perl.org>

=head1 COPYRIGHT 

Copyright (c) 2006 Simon Wilkinson, Achim Grolms and Peter Marschall.
All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut
