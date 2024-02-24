# Copyright (c) 2003-2009 Graham Barr, Djamel Boudjerda, Paul Connolly, Julian
# Onions, Nexor and Yann Kerherve.
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

# See http://www.ietf.org/rfc/rfc2831.txt for details

package Authen::SASL::Perl::DIGEST_MD5;

use strict;
use vars qw($VERSION @ISA $CNONCE $NONCE);
use Digest::MD5 qw(md5_hex md5);
use Digest::HMAC_MD5 qw(hmac_md5);

# TODO: complete qop support in server, should be configurable

$VERSION = "2.14";
@ISA = qw(Authen::SASL::Perl);

my %secflags = (
  noplaintext => 1,
  noanonymous => 1,
);

# some have to be quoted - some don't - sigh!
my (%cqdval, %sqdval);
@cqdval{qw(
  username authzid realm nonce cnonce digest-uri
)} = ();

## ...and server behaves different than client - double sigh!
@sqdval{keys %cqdval, qw(qop cipher)} = ();
#  username authzid realm nonce cnonce digest-uri qop cipher
#)} = ();

my %multi;
@{$multi{server}}{qw(realm auth-param)} = ();
@{$multi{client}}{qw()} = ();

my @server_required = qw(algorithm nonce);
my @client_required = qw(username nonce cnonce nc qop response);

# available ciphers
my @ourciphers = (
  {
    name  => 'rc4',
    ssf   => 128,
    bs    => 1,
    ks    => 16,
    pkg   => 'Crypt::RC4',
    key   => sub { $_[0] },
    iv    => sub {},
    fixup => sub {
      # retrofit the Crypt::RC4 module with standard subs
      *Crypt::RC4::encrypt   = *Crypt::RC4::decrypt =
        sub { goto &Crypt::RC4::RC4; };
      *Crypt::RC4::keysize   =  sub {128};
      *Crypt::RC4::blocksize =  sub {1};
    }
  },
  {
    name  => '3des',
    ssf   => 112,
    bs    => 8,
    ks    => 16,
    pkg   => 'Crypt::DES3',
    key   => sub {
      pack('B8' x 16,
        map { $_ . '0' }
        map { unpack('a7' x 16, $_); }
        unpack('B*', substr($_[0], 0, 14)) );
    },
    iv => sub { substr($_[0], -8, 8) },
  },
  {
    name  => 'des',
    ssf   => 56,
    bs    => 8,
    ks    => 16,
    pkg   => 'Crypt::DES',
    key   => sub {
      pack('B8' x 8,
        map { $_ . '0' }
        map { unpack('a7' x 8, $_); }
        unpack('B*',substr($_[0], 0, 7)) );
    },
    iv => sub { substr($_[0], -8, 8) },
  },
  {
    name  => 'rc4-56',
    ssf   => 56,
    bs    => 1,
    ks    => 7,
    pkg   => 'Crypt::RC4',
    key   => sub { $_[0] },
    iv    => sub {},
    fixup => sub {
      *Crypt::RC4::encrypt   = *Crypt::RC4::decrypt =
        sub { goto &Crypt::RC4::RC4; };
      *Crypt::RC4::keysize   =  sub {56};
      *Crypt::RC4::blocksize =  sub {1};
    }
  },
  {
    name  => 'rc4-40',
    ssf   => 40,
    bs    => 1,
    ks    => 5,
    pkg   => 'Crypt::RC4',
    key   => sub { $_[0] },
    iv    => sub {},
    fixup => sub {
      *Crypt::RC4::encrypt   = *Crypt::RC4::decrypt =
        sub { goto &Crypt::RC4::RC4; };
      *Crypt::RC4::keysize   =  sub {40};
      *Crypt::RC4::blocksize =  sub {1};
    }
  },
);

## The system we are on, might not be able to crypt the stream
our $NO_CRYPT_AVAILABLE = 1;
for (@ourciphers) {
    eval "require $_->{pkg}";
    unless ($@) {
        $NO_CRYPT_AVAILABLE = 0;
        last;
    }
}

sub _order { 3 }
sub _secflags {
  shift;
  scalar grep { $secflags{$_} } @_;
}

sub mechanism { 'DIGEST-MD5' }

sub _init {
  my ($pkg, $self) = @_;
  bless $self, $pkg;

  # set default security properties
  $self->property('minssf',      0);
  $self->property('maxssf',      int 2**31 - 1);    # XXX - arbitrary "high" value
  $self->property('maxbuf',      0xFFFFFF);         # maximum supported by GSSAPI mech
  $self->property('externalssf', 0);

  $self;
}

sub _init_server {
  my $server  = shift;
  my $options = shift || {};
  if (!ref $options or ref $options ne 'HASH') {
    warn "options for DIGEST_MD5 should be a hashref";
    $options = {};
  }

  ## new server, means new nonce_counts
  $server->{nonce_counts} = {};

  ## determine supported qop
  my   @qop = ('auth');
  push @qop, 'auth-int'  unless $options->{no_integrity};
  push @qop, 'auth-conf' unless $options->{no_integrity}
                             or $options->{no_confidentiality}
                             or $NO_CRYPT_AVAILABLE;

  $server->{supported_qop} = { map { $_ => 1 } @qop };
}

sub init_sec_layer {
  my $self           = shift;
  $self->{cipher}    = undef;
  $self->{khc}       = undef;
  $self->{khs}       = undef;
  $self->{sndseqnum} = 0;
  $self->{rcvseqnum} = 0;

  # reset properties for new session
  $self->property(maxout => undef);
  $self->property(ssf    => undef);
}

# no initial value passed to the server
sub client_start {
  my $self = shift;

  $self->{need_step} = 1;
  $self->{error}     = undef;
  $self->{state}     = 0;
  $self->init_sec_layer;
  '';
}

sub server_start {
  my $self       = shift;
  my $challenge  = shift;
  my $cb         = shift || sub {};

  $self->{need_step} = 1;
  $self->{error}     = undef;
  $self->{nonce}     = md5_hex($NONCE || join (":", $$, time, rand));

  $self->init_sec_layer;

  my $qop = [ sort keys %{$self->{supported_qop}} ];

  ## get the realm using callbacks but default to the host specified
  ## during the instanciation of the SASL object
  my $realm = $self->_call('realm');
  $realm  ||= $self->host;

  my %response = (
    nonce         => $self->{nonce},
    charset       => 'utf-8',
    algorithm     => 'md5-sess',
    realm         => $realm,
    maxbuf        => $self->property('maxbuf'),

## IN DRAFT ONLY:
# If this directive is present multiple times the client MUST treat
# it as if it received a single qop directive containing a comma
# separated value from all instances. I.e.,
# 'qop="auth",qop="auth-int"' is the same as 'qop="auth,auth-int"

    'qop'         => $qop,
    'cipher'      => [ map { $_->{name} } @ourciphers ],
  );
  my $final_response = _response(\%response);
  $cb->($final_response);
  return;
}

sub client_step {   # $self, $server_sasl_credentials
  my ($self, $challenge) = @_;
  $self->{server_params} = \my %sparams;

  # Parse response parameters
  $self->_parse_challenge(\$challenge, server => $self->{server_params})
    or return $self->set_error("Bad challenge: '$challenge'");

  if ($self->{state} == 1) {
    # check server's `rspauth' response
    return $self->set_error("Server did not send rspauth in step 2")
      unless ($sparams{rspauth});
    return $self->set_error("Invalid rspauth in step 2")
      unless ($self->{rspauth} eq $sparams{rspauth});

    # all is well
    $self->set_success;
    return '';
  }

  # check required fields in server challenge
  if (my @missing = grep { !exists $sparams{$_} } @server_required) {
    return $self->set_error("Server did not provide required field(s): @missing")
  }

  my %response = (
    nonce        => $sparams{'nonce'},
    cnonce       => md5_hex($CNONCE || join (":", $$, time, rand)),
    'digest-uri' => $self->service . '/' . $self->host,
    # calc how often the server nonce has been seen; server expects "00000001"
    nc           => sprintf("%08d",     ++$self->{nonce_counts}{$sparams{'nonce'}}),
    charset      => $sparams{'charset'},
  );

  return $self->set_error("Server qop too weak (qop = $sparams{'qop'})")
    unless ($self->_client_layer(\%sparams,\%response));

  # let caller-provided fields override defaults: authorization ID, service name, realm

  my $s_realm = $sparams{realm} || [];
  my $realm = $self->_call('realm', @$s_realm);
  unless (defined $realm) {
    # If the user does not pick a realm, use the first from the server
    $realm = $s_realm->[0];
  }
  if (defined $realm) {
    $response{realm} = $realm;
  }

  my $authzid = $self->_call('authname');
  if (defined $authzid) {
    $response{authzid} = $authzid;
  }

  my $serv_name = $self->_call('serv');
  if (defined $serv_name) {
    $response{'digest-uri'} .= '/' . $serv_name;
  }

  my $user = $self->_call('user');
  return $self->set_error("Username is required")
    unless defined $user;
  $response{username} = $user;

  my $password = $self->_call('pass');
  return $self->set_error("Password is required")
    unless defined $password;

  $self->property('maxout', $sparams{maxbuf} || 65536);

  # Generate the response value
  $self->{state} = 1;

  my ($response, $rspauth)
    = $self->_compute_digests_and_set_keys($password, \%response);

  $response{response} = $response;
  $self->{rspauth}    = $rspauth;

  # finally, return our response token
  return _response(\%response, "is_client");
}

sub _compute_digests_and_set_keys {
  my $self     = shift;
  my $password = shift;
  my $params   = shift;

  if (defined $params->{realm} and ref $params->{realm} eq 'ARRAY') {
    $params->{realm} = $params->{realm}[0];
  }

  my $realm = $params->{realm};
  $realm = "" unless defined $realm;

  my $A1 = join (":",
    md5(join (":", $params->{username}, $realm, $password)),
    @$params{defined($params->{authzid})
      ? qw(nonce cnonce authzid)
      : qw(nonce cnonce)
    }
  );

  # pre-compute MD5(A1) and HEX(MD5(A1)); these are used multiple times below
  my $hdA1 = unpack("H*", (my $dA1 = md5($A1)) );

  # derive keys for layer encryption / integrity
  $self->{kic} = md5($dA1,
    'Digest session key to client-to-server signing key magic constant');

  $self->{kis} = md5($dA1,
    'Digest session key to server-to-client signing key magic constant');

  if (my $cipher = $self->{cipher}) {
    &{ $cipher->{fixup} || sub{} };

    # compute keys for encryption
    my $ks = $cipher->{ks};
    $self->{kcc} = md5(substr($dA1,0,$ks),
      'Digest H(A1) to client-to-server sealing key magic constant');
    $self->{kcs} = md5(substr($dA1,0,$ks),
      'Digest H(A1) to server-to-client sealing key magic constant');

    # get an encryption and decryption handle for the chosen cipher
    $self->{khc} = $cipher->{pkg}->new($cipher->{key}->($self->{kcc}));
    $self->{khs} = $cipher->{pkg}->new($cipher->{key}->($self->{kcs}));

    # initialize IVs
    $self->{ivc} = $cipher->{iv}->($self->{kcc});
    $self->{ivs} = $cipher->{iv}->($self->{kcs});
  }

  my $A2 = "AUTHENTICATE:" . $params->{'digest-uri'};
  $A2 .= ":00000000000000000000000000000000" if ($params->{qop} ne 'auth');

  my $response = md5_hex(
    join (":", $hdA1, @$params{qw(nonce nc cnonce qop)}, md5_hex($A2))
  );

  # calculate server `rspauth' response, so we can check in step 2
  # the only difference here is in the A2 string which from which
  # `AUTHENTICATE' is omitted in the calculation of `rspauth'
  $A2 = ":" . $params->{'digest-uri'};
  $A2 .= ":00000000000000000000000000000000" if ($params->{qop} ne 'auth');

  my $rspauth = md5_hex(
    join (":", $hdA1, @$params{qw(nonce nc cnonce qop)}, md5_hex($A2))
  );

  return ($response, $rspauth);
}

sub server_step {
  my $self      = shift;
  my $challenge = shift;
  my $cb        = shift || sub {};

  $self->{client_params} = \my %cparams;
  unless ( $self->_parse_challenge(\$challenge, client => $self->{client_params}) ) {
   $self->set_error("Bad challenge: '$challenge'");
   return $cb->();
  }

  # check required fields in server challenge
  if (my @missing = grep { !exists $cparams{$_} } @client_required) {
    $self->set_error("Client did not provide required field(s): @missing");
    return $cb->();
  }

  my $count = hex ($cparams{'nc'} || 0);
  unless ($count == ++$self->{nonce_counts}{$cparams{nonce}}) {
    $self->set_error("nonce-count doesn't match: $count");
    return $cb->();
  }

  my $qop = $cparams{'qop'} || "auth";
  unless ($self->is_qop_supported($qop)) {
    $self->set_error("Client qop not supported (qop = '$qop')");
    return $cb->();
  }

  my $username = $cparams{'username'};
  unless ($username) {
    $self->set_error("Client didn't provide a username");
    return $cb->();
  }

  # "The authzid MUST NOT be an empty string."
  if (exists $cparams{authzid} && $cparams{authzid} eq '') {
      $self->set_error("authzid cannot be empty");
      return $cb->();
  }
  my $authzid = $cparams{authzid};

  # digest-uri: "Servers SHOULD check that the supplied value is correct.
  # This will detect accidental connection to the incorrect server, as well as
  # some redirection attacks"
  my $digest_uri = $cparams{'digest-uri'};
  my ($cservice, $chost, $cservname) = split '/', $digest_uri, 3;
  if ($cservice ne $self->service or $chost ne $self->host) {
      # XXX deal with serv_name
      $self->set_error("Incorrect digest-uri");
      return $cb->(); 
  }

  unless (defined $self->callback('getsecret')) {
    $self->set_error("a getsecret callback MUST be defined");
    $cb->();
    return;
  }

  my $realm = $self->{client_params}->{'realm'};
  my $response_check = sub {
    my $password = shift;
    return $self->set_error("Cannot get the passord for $username") 
        unless defined $password;
 
    ## configure the security layer
    $self->_server_layer($qop)
        or return $self->set_error("Cannot negociate the security layer");
 
    my ($expected, $rspauth)
        = $self->_compute_digests_and_set_keys($password, $self->{client_params});
 
    return $self->set_error("Incorrect response $self->{client_params}->{response} <> $expected")
        unless $expected eq $self->{client_params}->{response};
 
    my %response = (
        rspauth => $rspauth,
    );
 
    # I'm not entirely sure of what I am doing
    $self->{answer}{$_} = $self->{client_params}->{$_} for qw/username authzid realm serv/;
 
    $self->set_success;
    return _response(\%response);
  };

  $self->callback('getsecret')->(
    $self,
    { user => $username, realm => $realm, authzid => $authzid },
    sub { $cb->( $response_check->( shift ) ) },
  );
}

sub is_qop_supported {
    my $self = shift;
    my $qop  = shift;
    return $self->{supported_qop}{$qop};
}

sub _response {
  my $response  = shift;
  my $is_client = shift;

  my @out;
  for my $k (sort keys %$response) {
    my $is_array = ref $response->{$k} && ref $response->{$k} eq 'ARRAY';
    my @values = $is_array ? @{$response->{$k}} : ($response->{$k});
    # Per spec, one way of doing it: multiple k=v
    #push @out, [$k, $_] for @values;
    # other way: comma separated list
    push @out, [$k, join (',', @values)];
  }
  return join (",", map { _qdval($_->[0], $_->[1], $is_client) } @out);
}

sub _parse_challenge {
  my $self          = shift;
  my $challenge_ref = shift;
  my $type          = shift;
  my $params        = shift;

  while($$challenge_ref =~
           s/^(?:\s*,)*\s*            # remaining or crap
             ([\w-]+)                 # key, eg: qop
             =
             ("([^\\"]+|\\.)*"|[^,]+) # value, eg: auth-conf or "NoNcE"
             \s*(?:,\s*)*             # remaining
           //x) {

    my ($k, $v) = ($1,$2);
    if ($v =~ /^"(.*)"$/s) {
      ($v = $1) =~ s/\\(.)/$1/g;
    }
    if (exists $multi{$type}{$k}) {
      my $aref = $params->{$k} ||= [];
      push @$aref, $v;
    }
    elsif (defined $params->{$k}) {
      return $self->set_error("Bad challenge: '$$challenge_ref'");
    }
    else {
      $params->{$k} = $v;
    }
  }
  return length $$challenge_ref ? 0 : 1;
}

sub _qdval {
  my ($k, $v, $is_client) = @_;

  my $qdval = $is_client ? \%cqdval : \%sqdval;

  if (!defined $v) {
    return;
  }
  elsif (exists $qdval->{$k}) {
    $v =~ s/([\\"])/\\$1/g;
    return qq{$k="$v"};
  }

  return "$k=$v";
}

sub _server_layer {
  my ($self, $auth) = @_;

  # XXX dupe
  # construct our qop mask
  my $maxssf = $self->property('maxssf') - $self->property('externalssf');
  $maxssf = 0 if ($maxssf < 0);
  my $minssf = $self->property('minssf') - $self->property('externalssf');
  $minssf = 0 if ($minssf < 0);

  return undef if ($maxssf < $minssf); # sanity check

  my $ciphers = [ map { $_->{name} } @ourciphers ];
  if ((     $auth eq 'auth-conf')
        and $self->_select_cipher($minssf, $maxssf, $ciphers )) {
    $self->property('ssf', $self->{cipher}->{ssf});
    return 1;
  }
  if ($auth eq 'auth-int') {
    $self->property('ssf', 1);
    return 1;
  }
  if ($auth eq 'auth') {
    $self->property('ssf', 0);
    return 1;
  }

  return undef;
}

sub _client_layer {
  my ($self, $sparams, $response) = @_;

  # construct server qop mask
  # qop in server challenge is optional: if not there "auth" is assumed
  my $smask = 0;
  map {
    m/^auth$/      and $smask |= 1;
    m/^auth-int$/  and $smask |= 2;
    m/^auth-conf$/ and $smask |= 4;
  } split(/,/, $sparams->{qop}||'auth'); # XXX I think we might have a bug here bc. of LWS

  # construct our qop mask
  my $cmask = 0;
  my $maxssf = $self->property('maxssf') - $self->property('externalssf');
  $maxssf = 0 if ($maxssf < 0);
  my $minssf = $self->property('minssf') - $self->property('externalssf');
  $minssf = 0 if ($minssf < 0);

  return undef if ($maxssf < $minssf); # sanity check

  # ssf values > 1 mean integrity and confidentiality 
  # ssf == 1 means integrity but no confidentiality
  # ssf < 1 means neither integrity nor confidentiality
  # no security layer can be had if buffer size is 0
  $cmask |= 1 if ($minssf < 1);
  $cmask |= 2 if ($minssf <= 1 and $maxssf >= 1);
  $cmask |= 4 if ($maxssf > 1);

  # find common bits
  $cmask &= $smask;

  # parse server cipher options
  my @sciphers = split(/,/, $sparams->{'cipher-opts'}||$sparams->{cipher}||'');

  if (($cmask & 4) and $self->_select_cipher($minssf,$maxssf,\@sciphers)) {
    $response->{qop} = 'auth-conf';
    $response->{cipher} = $self->{cipher}->{name};
    $self->property('ssf', $self->{cipher}->{ssf});
    return 1;
  }
  if ($cmask & 2) {
    $response->{qop} = 'auth-int';
    $self->property('ssf', 1);
    return 1;
  }
  if ($cmask & 1) {
    $response->{qop} = 'auth';
    $self->property('ssf', 0);
    return 1;
  }

  return undef;
}

sub _select_cipher {
  my ($self, $minssf, $maxssf, $ciphers) = @_;

  # compose a subset of candidate ciphers based on ssf and peer list
  my @a = map {
    my $c = $_;
    (grep { $c->{name} eq $_ } @$ciphers and
      $c->{ssf} >= $minssf and $c->{ssf} <= $maxssf) ? $_ : ()
  } @ourciphers;

  # from these, select the first one we can create an instance of
  for (@a) {
    next unless eval "require $_->{pkg}";
    $self->{cipher} = $_;
    return 1;
  }

  return 0;
}

use Digest::HMAC_MD5 qw(hmac_md5);

sub encode {  # input: self, plaintext buffer,length (length not used here)
  my $self   = shift;
  my $seqnum = pack('N', $self->{sndseqnum}++);
  my $mac    = substr(hmac_md5($seqnum . $_[0], $self->{kic}), 0, 10);

  # if integrity only, return concatenation of buffer, MAC, TYPE and SEQNUM
  return $_[0] . $mac.pack('n',1) . $seqnum unless ($self->{khc});

  # must encrypt, block ciphers need padding bytes
  my $pad = '';
  my $bs = $self->{cipher}->{bs};
  if ($bs > 1) {
    # padding is added in between BUF and MAC
    my $n = $bs - ((length($_[0]) + 10) & ($bs - 1));
    $pad = chr($n) x $n;
  }

  # XXX - for future AES cipher support, the currently used common _crypt()
  # function probably wont do; we might to switch to per-cipher routines
  # like so:
  #  return $self->{khc}->encrypt($_[0] . $pad . $mac) . pack('n', 1) . $seqnum;
  return $self->_crypt(0, $_[0] . $pad . $mac) . pack('n', 1) . $seqnum;
}

sub decode {  # input: self, cipher buffer,length
  my ($self, $buf, $len) = @_;

  return if ($len <= 16);

  # extract TYPE/SEQNUM from end of buffer
  my ($type,$seqnum) = unpack('na[4]', substr($buf, -6, 6, ''));

  # decrypt remaining buffer, if necessary
  if ($self->{khs}) {
    # XXX - see remark above in encode() #$buf = $self->{khs}->decrypt($buf);
    $buf = $self->_crypt(1, $buf);
  }
  return unless ($buf);

  # extract 10-byte MAC from the end of (decrypted) buffer
  my ($mac) = unpack('a[10]', substr($buf, -10, 10, ''));

  if ($self->{khs} and $self->{cipher}->{bs} > 1) {
    # remove padding
    my $n = ord(substr($buf, -1, 1));
    substr($buf, -$n, $n, '');
  }

  # check the MAC
  my $check = substr(hmac_md5($seqnum . $buf, $self->{kis}), 0, 10);
  return if ($mac ne $check);
  return if (unpack('N', $seqnum) != $self->{rcvseqnum});
  $self->{rcvseqnum}++;

  return $buf;
}

sub _crypt {  # input: op(decrypting=1/encrypting=0)), buffer
  my ($self,$d) = (shift,shift);
  my $bs = $self->{cipher}->{bs};

  if ($bs <= 1) {
    # stream cipher
    return $d ? $self->{khs}->decrypt($_[0]) : $self->{khc}->encrypt($_[0])
  }

  # the remainder of this sub is for block ciphers

  # get current IV
  my $piv = \$self->{$d ? 'ivs' : 'ivc'};
  my $iv = $$piv;

  my $result = join '', map {
    my $x = $d
      ? $iv ^ $self->{khs}->decrypt($_)
      : $self->{khc}->encrypt($iv ^ $_);
    $iv = $d ? $_ : $x;
    $x;
  } unpack("a$bs "x(int(length($_[0])/$bs)), $_[0]);

  # store current IV
  $$piv = $iv;
  return $result;
}

1;

__END__

=head1 NAME

Authen::SASL::Perl::DIGEST_MD5 - Digest MD5 Authentication class

=head1 SYNOPSIS

  use Authen::SASL qw(Perl);

  $sasl = Authen::SASL->new(
    mechanism => 'DIGEST-MD5',
    callback  => {
      user => $user, 
      pass => $pass,
      serv => $serv
    },
  );

=head1 DESCRIPTION

This method implements the client and server parts of the DIGEST-MD5 SASL
algorithm, as described in RFC 2831.

=head2 CALLBACK

The callbacks used are:

=head3 client

=over 4

=item authname

The authorization id to use after successful authentication

=item user

The username to be used in the response

=item pass

The password to be used to compute the response.

=item serv

The service name when authenticating to a replicated service

=item realm

The authentication realm when overriding the server-provided default.
If not given the server-provided value is used.

The callback will be passed the list of realms that the server provided
in the initial response.

=back

=head3 server

=over4

=item realm

The default realm to provide to the client

=item getsecret(username, realm, authzid)

returns the password associated with C<username> and C<realm>

=back

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

Graham Barr, Djamel Boudjerda (NEXOR), Paul Connolly, Julian Onions (NEXOR),
Yann Kerherve.

Please report any bugs, or post any suggestions, to the perl-ldap mailing list
<perl-ldap@perl.org>

=head1 COPYRIGHT 

Copyright (c) 2003-2009 Graham Barr, Djamel Boudjerda, Paul Connolly,
Julian Onions, Nexor, Peter Marschall and Yann Kerherve.
All rights reserved. This program is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

=cut
