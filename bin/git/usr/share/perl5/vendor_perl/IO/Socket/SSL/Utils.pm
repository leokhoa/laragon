
package IO::Socket::SSL::Utils;
use strict;
use warnings;
use Carp 'croak';
use Net::SSLeay;

# old versions of Exporter do not export 'import' yet
require Exporter;
*import = \&Exporter::import;

our $VERSION = '2.015';
our @EXPORT = qw(
    PEM_file2cert PEM_file2certs PEM_string2cert PEM_cert2file PEM_certs2file PEM_cert2string
    PEM_file2key PEM_string2key PEM_key2file PEM_key2string
    KEY_free CERT_free
    KEY_create_rsa CERT_asHash CERT_create
);

sub PEM_file2cert {
    my $file = shift;
    my $bio = Net::SSLeay::BIO_new_file($file,'r') or
	croak "cannot read $file: $!";
    my $cert = Net::SSLeay::PEM_read_bio_X509($bio);
    Net::SSLeay::BIO_free($bio);
    $cert or croak "cannot parse $file as PEM X509 cert: ".
	Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error());
    return $cert;
}

sub PEM_cert2file {
    my ($cert,$file) = @_;
    my $string = Net::SSLeay::PEM_get_string_X509($cert)
	or croak("cannot get string from cert");
    open( my $fh,'>',$file ) or croak("cannot write $file: $!");
    print $fh $string;
}

use constant PEM_R_NO_START_LINE => 108;
sub PEM_file2certs {
    my $file = shift;
    my $bio = Net::SSLeay::BIO_new_file($file,'r') or
	croak "cannot read $file: $!";
    my @certs;
    while (1) {
	if (my $cert = Net::SSLeay::PEM_read_bio_X509($bio)) {
	    push @certs, $cert;
	} else {
	    Net::SSLeay::BIO_free($bio);
	    my $error = Net::SSLeay::ERR_get_error();
	    last if ($error & 0xfff) == PEM_R_NO_START_LINE && @certs;
	    croak "cannot parse $file as PEM X509 cert: " .
		Net::SSLeay::ERR_error_string($error);
	}
    }
    return @certs;
}

sub PEM_certs2file {
    my $file = shift;
    open( my $fh,'>',$file ) or croak("cannot write $file: $!");
    for my $cert (@_) {
	my $string = Net::SSLeay::PEM_get_string_X509($cert)
	    or croak("cannot get string from cert");
	print $fh $string;
    }
}


sub PEM_string2cert {
    my $string = shift;
    my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem());
    Net::SSLeay::BIO_write($bio,$string);
    my $cert = Net::SSLeay::PEM_read_bio_X509($bio);
    Net::SSLeay::BIO_free($bio);
    $cert or croak "cannot parse string as PEM X509 cert: ".
	Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error());
    return $cert;
}

sub PEM_cert2string {
    my $cert = shift;
    return Net::SSLeay::PEM_get_string_X509($cert)
	|| croak("cannot get string from cert");
}

sub PEM_file2key {
    my $file = shift;
    my $bio = Net::SSLeay::BIO_new_file($file,'r') or
	croak "cannot read $file: $!";
    my $key = Net::SSLeay::PEM_read_bio_PrivateKey($bio);
    Net::SSLeay::BIO_free($bio);
    $key or croak "cannot parse $file as PEM private key: ".
	Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error());
    return $key;
}

sub PEM_key2file {
    my ($key,$file) = @_;
    my $string = Net::SSLeay::PEM_get_string_PrivateKey($key)
	or croak("cannot get string from key");
    open( my $fh,'>',$file ) or croak("cannot write $file: $!");
    print $fh $string;
}

sub PEM_string2key {
    my $string = shift;
    my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem());
    Net::SSLeay::BIO_write($bio,$string);
    my $key = Net::SSLeay::PEM_read_bio_PrivateKey($bio);
    Net::SSLeay::BIO_free($bio);
    $key or croak "cannot parse string as PEM private key: ".
	Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error());
    return $key;
}

sub PEM_key2string {
    my $key = shift;
    return Net::SSLeay::PEM_get_string_PrivateKey($key)
	|| croak("cannot get string from key");
}

sub CERT_free {
    Net::SSLeay::X509_free($_) for @_;
}

sub KEY_free {
    Net::SSLeay::EVP_PKEY_free($_) for @_;
}

sub KEY_create_rsa {
    my $bits = shift || 2048;
    my $key = Net::SSLeay::EVP_PKEY_new();
    my $rsa = Net::SSLeay::RSA_generate_key($bits, 0x10001); # 0x10001 = RSA_F4
    Net::SSLeay::EVP_PKEY_assign_RSA($key,$rsa);
    return $key;
}

if (defined &Net::SSLeay::EC_KEY_generate_key) {
    push @EXPORT,'KEY_create_ec';
    *KEY_create_ec = sub {
	my $curve = shift || 'prime256v1';
	my $key = Net::SSLeay::EVP_PKEY_new();
	my $ec = Net::SSLeay::EC_KEY_generate_key($curve);
	Net::SSLeay::EVP_PKEY_assign_EC_KEY($key,$ec);
	return $key;
    }
}

# extract information from cert
my %gen2i = qw( OTHERNAME 0 EMAIL 1 DNS 2 X400 3 DIRNAME 4 EDIPARTY 5 URI 6 IP 7 RID 8 );
my %i2gen = reverse %gen2i;
sub CERT_asHash {
    my $cert = shift;
    my $digest_name = shift || 'sha256';

    my %hash = (
	version => Net::SSLeay::X509_get_version($cert),
	not_before => _asn1t2t(Net::SSLeay::X509_get_notBefore($cert)),
	not_after => _asn1t2t(Net::SSLeay::X509_get_notAfter($cert)),
	serial => Net::SSLeay::P_ASN1_INTEGER_get_dec(
	    Net::SSLeay::X509_get_serialNumber($cert)),
	signature_alg => Net::SSLeay::OBJ_obj2txt (
	    Net::SSLeay::P_X509_get_signature_alg($cert)),
	crl_uri  => [ Net::SSLeay::P_X509_get_crl_distribution_points($cert) ],
	keyusage => [ Net::SSLeay::P_X509_get_key_usage($cert) ],
	extkeyusage => {
	    oid => [ Net::SSLeay::P_X509_get_ext_key_usage($cert,0) ],
	    nid => [ Net::SSLeay::P_X509_get_ext_key_usage($cert,1) ],
	    sn  => [ Net::SSLeay::P_X509_get_ext_key_usage($cert,2) ],
	    ln  => [ Net::SSLeay::P_X509_get_ext_key_usage($cert,3) ],
	},
	"pubkey_digest_$digest_name" => Net::SSLeay::X509_pubkey_digest(
	    $cert,_digest($digest_name)),
	"x509_digest_$digest_name" => Net::SSLeay::X509_digest(
	    $cert,_digest($digest_name)),
	"fingerprint_$digest_name" => Net::SSLeay::X509_get_fingerprint(
	    $cert,$digest_name),
    );

    for([ subject => Net::SSLeay::X509_get_subject_name($cert) ],
	[ issuer => Net::SSLeay::X509_get_issuer_name($cert) ]) {
	my ($what,$subj) = @$_;
	my %subj;
	for ( 0..Net::SSLeay::X509_NAME_entry_count($subj)-1 ) {
	    my $e = Net::SSLeay::X509_NAME_get_entry($subj,$_);
	    my $k = Net::SSLeay::OBJ_obj2txt(
		Net::SSLeay::X509_NAME_ENTRY_get_object($e));
	    my $v = Net::SSLeay::P_ASN1_STRING_get(
		    Net::SSLeay::X509_NAME_ENTRY_get_data($e));
	    if (!exists $subj{$k}) {
		$subj{$k} = $v;
	    } elsif (!ref $subj{$k}) {
		$subj{$k} = [ $subj{$k}, $v ];
	    } else {
		push @{$subj{$k}}, $v;
	    }
	}
	$hash{$what} = \%subj;
    }


    if ( my @names = Net::SSLeay::X509_get_subjectAltNames($cert) ) {
	my $alt = $hash{subjectAltNames} = [];
	while (my ($t,$v) = splice(@names,0,2)) {
	    $t = $i2gen{$t} || die "unknown type $t in subjectAltName";
	    if ( $t eq 'IP' ) {
		if (length($v) == 4) {
		    $v = join('.',unpack("CCCC",$v));
		} elsif ( length($v) == 16 ) {
		    my @v = unpack("nnnnnnnn",$v);
		    my ($best0,$last0);
		    for(my $i=0;$i<@v;$i++) {
			if ($v[$i] == 0) {
			    if ($last0) {
				$last0->[1] = $i;
				$last0->[2]++;
				$best0 = $last0 if ++$last0->[2]>$best0->[2];
			    } else {
				$last0 = [ $i,$i,0 ];
				$best0 ||= $last0;
			    }
			} else {
			    $last0 = undef;
			}
		    }
		    if ($best0) {
			$v = '';
			$v .= join(':', map { sprintf( "%x",$_) } @v[0..$best0->[0]-1]) if $best0->[0]>0;
			$v .= '::';
			$v .= join(':', map { sprintf( "%x",$_) } @v[$best0->[1]+1..$#v]) if $best0->[1]<$#v;
		    } else {
			$v = join(':', map { sprintf( "%x",$_) } @v);
		    }
		}
	    }
	    push @$alt,[$t,$v]
	}
    }

    my @ext;
    for( 0..Net::SSLeay::X509_get_ext_count($cert)-1 ) {
	my $e = Net::SSLeay::X509_get_ext($cert,$_);
	my $o = Net::SSLeay::X509_EXTENSION_get_object($e);
	my $nid = Net::SSLeay::OBJ_obj2nid($o);
	push @ext, {
	    oid => Net::SSLeay::OBJ_obj2txt($o),
	    nid => ( $nid > 0 ) ? $nid : undef,
	    sn  => ( $nid > 0 ) ? Net::SSLeay::OBJ_nid2sn($nid) : undef,
	    critical => Net::SSLeay::X509_EXTENSION_get_critical($e),
	    data => Net::SSLeay::X509V3_EXT_print($e),
	}
    }
    $hash{ext} = \@ext;

    if ( defined(&Net::SSLeay::P_X509_get_ocsp_uri)) {
	$hash{ocsp_uri} = [ Net::SSLeay::P_X509_get_ocsp_uri($cert) ];
    } else {
	$hash{ocsp_uri} = [];
	for( @ext ) {
	    $_->{sn} or next;
	    $_->{sn} eq 'authorityInfoAccess' or next;
	    push @{ $hash{ocsp_uri}}, $_->{data} =~m{\bOCSP - URI:(\S+)}g;
	}
    }

    return \%hash;
}

sub CERT_create {
    my %args = @_%2 ? %{ shift() } :  @_;

    my $cert = Net::SSLeay::X509_new();
    my $digest_name = delete $args{digest} || 'sha256';

    Net::SSLeay::ASN1_INTEGER_set(
	Net::SSLeay::X509_get_serialNumber($cert),
	delete $args{serial} || rand(2**32),
    );

    # version default to 2 (V3)
    Net::SSLeay::X509_set_version($cert,
	delete $args{version} || 2 );

    # not_before default to now
    Net::SSLeay::ASN1_TIME_set(
	Net::SSLeay::X509_get_notBefore($cert),
	delete $args{not_before} || time()
    );

    # not_after default to now+365 days
    Net::SSLeay::ASN1_TIME_set(
	Net::SSLeay::X509_get_notAfter($cert),
	delete $args{not_after} || time() + 365*86400
    );

    # set subject
    my $subj_e = Net::SSLeay::X509_get_subject_name($cert);
    my $subj = delete $args{subject} || {
	organizationName => 'IO::Socket::SSL',
	commonName => 'IO::Socket::SSL Test'
    };

    while ( my ($k,$v) = each %$subj ) {
	# Not everything we get is nice - try with MBSTRING_UTF8 first and if it
	# fails try V_ASN1_T61STRING and finally V_ASN1_OCTET_STRING
	for (ref($v) ? @$v : ($v)) {
	    Net::SSLeay::X509_NAME_add_entry_by_txt($subj_e,$k,0x1000,$_,-1,0)
		or Net::SSLeay::X509_NAME_add_entry_by_txt($subj_e,$k,20,$_,-1,0)
		or Net::SSLeay::X509_NAME_add_entry_by_txt($subj_e,$k,4,$_,-1,0)
		or croak("failed to add entry for $k - ".
		Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error()));
	}
    }

    my @ext = (
	&Net::SSLeay::NID_subject_key_identifier => 'hash',
	&Net::SSLeay::NID_authority_key_identifier => 'keyid',
    );
    if ( my $altsubj = delete $args{subjectAltNames} ) {
	push @ext,
	    &Net::SSLeay::NID_subject_alt_name =>
	    join(',', map { "$_->[0]:$_->[1]" } @$altsubj)
    }

    my $key = delete $args{key} || KEY_create_rsa();
    Net::SSLeay::X509_set_pubkey($cert,$key);

    my $is = delete $args{issuer};
    my $issuer_cert = delete $args{issuer_cert} || $is && $is->[0] || $cert;
    my $issuer_key  = delete $args{issuer_key}  || $is && $is->[1] || $key;

    my %purpose;
    if (my $p = delete $args{purpose}) {
	if (!ref($p)) {
	    $purpose{lc($2)} = (!$1 || $1 eq '+') ? 1:0
		while $p =~m{([+-]?)(\w+)}g;
	} elsif (ref($p) eq 'ARRAY') {
	    for(@$p) {
		m{^([+-]?)(\w+)$} or die "invalid entry in purpose: $_";
		$purpose{lc($2)} = (!$1 || $1 eq '+') ? 1:0
	    }
	} else {
	    while( my ($k,$v) = each %$p) {
		$purpose{lc($k)} = ($v && $v ne '-')?1:0;
	    }
	}
    }
    if (delete $args{CA}) {
	# add defaults for CA
	%purpose = (
	    ca => 1, sslca => 1, emailca => 1, objca => 1,
	    %purpose
	);
    }
    if (!%purpose) {
	%purpose = (server => 1, client => 1);
    }

    my (%key_usage,%ext_key_usage,%cert_type,%basic_constraints);

    my %dS = ( digitalSignature => \%key_usage );
    my %kE = ( keyEncipherment => \%key_usage );
    my %CA = ( 'CA:TRUE' => \%basic_constraints, %dS, keyCertSign => \%key_usage );
    my @disable;
    for(
	[ client  => { %dS, %kE, clientAuth => \%ext_key_usage, client  => \%cert_type } ],
	[ server  => { %dS, %kE, serverAuth => \%ext_key_usage, server  => \%cert_type } ],
	[ email   => { %dS, %kE, emailProtection => \%ext_key_usage, email => \%cert_type } ],
	[ objsign => { %dS, %kE, codeSigning => \%ext_key_usage, objsign => \%cert_type } ],

	[ CA      => { %CA }],
	[ sslCA   => { %CA, sslCA => \%cert_type }],
	[ emailCA => { %CA, emailCA => \%cert_type }],
	[ objCA   => { %CA, objCA => \%cert_type }],

	[ emailProtection  => { %dS, %kE, emailProtection => \%ext_key_usage, email => \%cert_type } ],
	[ codeSigning      => { %dS, %kE, codeSigning => \%ext_key_usage, objsign => \%cert_type } ],

	[ timeStamping     => { timeStamping => \%ext_key_usage } ],
	[ digitalSignature => { digitalSignature => \%key_usage } ],
	[ nonRepudiation   => { nonRepudiation => \%key_usage } ],
	[ keyEncipherment  => { keyEncipherment => \%key_usage } ],
	[ dataEncipherment => { dataEncipherment => \%key_usage } ],
	[ keyAgreement     => { keyAgreement => \%key_usage } ],
	[ keyCertSign      => { keyCertSign => \%key_usage } ],
	[ cRLSign          => { cRLSign => \%key_usage } ],
	[ encipherOnly     => { encipherOnly => \%key_usage } ],
	[ decipherOnly     => { decipherOnly => \%key_usage } ],
	[ clientAuth       => { clientAuth   => \%ext_key_usage } ],
	[ serverAuth       => { serverAuth   => \%ext_key_usage } ],
    ) {
	exists $purpose{lc($_->[0])} or next;
	if (delete $purpose{lc($_->[0])}) {
	    while (my($k,$h) = each %{$_->[1]}) {
		$h->{$k} = 1;
	    }
	} else {
	    push @disable, $_->[1];
	}
    }
    die "unknown purpose ".join(",",keys %purpose) if %purpose;
    for(@disable) {
	while (my($k,$h) = each %$_) {
	    delete $h->{$k};
	}
    }

    if (%basic_constraints) {
	push @ext,&Net::SSLeay::NID_basic_constraints,
	    => join(",",'critical', sort keys %basic_constraints);
    } else {
	push @ext, &Net::SSLeay::NID_basic_constraints => 'critical,CA:FALSE';
    }
    push @ext,&Net::SSLeay::NID_key_usage
	=> join(",",'critical', sort keys %key_usage) if %key_usage;
    push @ext,&Net::SSLeay::NID_netscape_cert_type
	=> join(",",sort keys %cert_type) if %cert_type;
    push @ext,&Net::SSLeay::NID_ext_key_usage
	=> join(",",sort keys %ext_key_usage) if %ext_key_usage;
    Net::SSLeay::P_X509_add_extensions($cert, $issuer_cert, @ext);

    my %have_ext;
    for(my $i=0;$i<@ext;$i+=2) {
	$have_ext{ $ext[$i] }++
    }
    for my $ext (@{ delete $args{ext} || [] }) {
	my $nid = $ext->{nid}
	    || $ext->{sn} && Net::SSLeay::OBJ_sn2nid($ext->{sn})
	    || croak "cannot determine NID of extension";
	$have_ext{$nid} and next;
	my $val = $ext->{data};
	if ($nid == 177) {
	    # authorityInfoAccess:
	    # OpenSSL i2v does not output the same way as expected by i2v :(
	    for (split(/\n/,$val)) {
		s{ - }{;}; # "OCSP - URI:..." -> "OCSP;URI:..."
		$_ = "critical,$_" if $ext->{critical};
		Net::SSLeay::P_X509_add_extensions($cert,$issuer_cert,$nid,$_);
	    }
	} else {
	    $val = "critical,$val" if $ext->{critical};
	    Net::SSLeay::P_X509_add_extensions($cert, $issuer_cert, $nid, $val);
	}
    }

    die "unknown arguments: ". join(" ", sort keys %args) 
	if !delete $args{ignore_invalid_args} && %args;

    Net::SSLeay::X509_set_issuer_name($cert,
	Net::SSLeay::X509_get_subject_name($issuer_cert));
    Net::SSLeay::X509_sign($cert,$issuer_key,_digest($digest_name));

    return ($cert,$key);
}



if ( defined &Net::SSLeay::ASN1_TIME_timet ) {
    *_asn1t2t = \&Net::SSLeay::ASN1_TIME_timet
} else {
    require Time::Local;
    my %mon2i = qw(
	Jan 0 Feb 1 Mar 2 Apr 3 May 4 Jun 5
	Jul 6 Aug 7 Sep 8 Oct 9 Nov 10 Dec 11
    );
    *_asn1t2t = sub {
	my $t = Net::SSLeay::P_ASN1_TIME_put2string( shift );
	my ($mon,$d,$h,$m,$s,$y,$tz) = split(/[\s:]+/,$t);
	defined( $mon = $mon2i{$mon} ) or die "invalid month in $t";
	$tz ||= $y =~s{^(\d+)([A-Z]\S*)}{$1} && $2;
	if ( ! $tz ) {
	    return Time::Local::timelocal($s,$m,$h,$d,$mon,$y)
	} elsif ( $tz eq 'GMT' ) {
	    return Time::Local::timegm($s,$m,$h,$d,$mon,$y)
	} else {
	    die "unexpected TZ $tz from ASN1_TIME_print";
	}
    }
}

{
    my %digest;
    sub _digest {
	my $digest_name = shift;
	return $digest{$digest_name} ||= do {
	    Net::SSLeay::SSLeay_add_ssl_algorithms();
	    Net::SSLeay::EVP_get_digestbyname($digest_name)
		or die "Digest algorithm $digest_name is not available";
	};
    }
}


1;

__END__

=head1 NAME

IO::Socket::SSL::Utils -- loading, storing, creating certificates and keys

=head1 SYNOPSIS

    use IO::Socket::SSL::Utils;

    $cert = PEM_file2cert('cert.pem');     # load certificate from file
    my $hash = CERT_asHash($cert);         # get details from certificate
    PEM_cert2file($cert,'cert.pem');       # write certificate to file
    CERT_free($cert);                      # free memory within OpenSSL

    @certs = PEM_file2certs('chain.pem');  # load multiple certificates from file
    PEM_certs2file('chain.pem', @certs);   # write multiple certificates to file
    CERT_free(@certs);                     # free memory for all within OpenSSL

    my $cert = PEM_string2cert($pem);      # load certificate from PEM string
    $pem = PEM_cert2string($cert);         # convert certificate to PEM string

    $key = KEY_create_rsa(2048);           # create new 2048-bit RSA key
    PEM_key2file($key,"key.pem");          # and write it to file
    KEY_free($key);                        # free memory within OpenSSL


=head1 DESCRIPTION

This module provides various utility functions to work with certificates and
private keys, shielding some of the complexity of the underlying Net::SSLeay and
OpenSSL.

=head1 FUNCTIONS

=over 4

=item *

Functions converting between string or file and certificates and keys.
They croak if the operation cannot be completed.

=over 8

=item PEM_file2cert(file) -> cert

=item PEM_cert2file(cert,file)

=item PEM_file2certs(file) -> @certs

=item PEM_certs2file(file,@certs)

=item PEM_string2cert(string) -> cert

=item PEM_cert2string(cert) -> string

=item PEM_file2key(file) -> key

=item PEM_key2file(key,file)

=item PEM_string2key(string) -> key

=item PEM_key2string(key) -> string

=back

=item *

Functions for cleaning up.
Each loaded or created cert and key must be freed to not leak memory.

=over 8

=item CERT_free(@certs)

=item KEY_free(@keys)

=back

=item * KEY_create_rsa(bits) -> key

Creates an RSA key pair, bits defaults to 2048.

=item * KEY_create_ec(curve) -> key

Creates an EC key, curve defaults to C<prime256v1>.

=item * CERT_asHash(cert,[digest_algo]) -> hash

Extracts the information from the certificate into a hash and uses the given
digest_algo (default: SHA-256) to determine digest of pubkey and cert.
The resulting hash contains:

=over 8

=item subject

Hash with the parts of the subject, e.g. commonName, countryName,
organizationName, stateOrProvinceName, localityName. If there are multiple
values for any of these parts the hash value will be an array ref with the
values in order instead of just a scalar.

=item subjectAltNames

Array with list of alternative names. Each entry in the list is of
C<[type,value]>, where C<type> can be OTHERNAME, EMAIL, DNS, X400, DIRNAME,
EDIPARTY, URI, IP or RID.

=item issuer

Hash with the parts of the issuer, e.g. commonName, countryName,
organizationName, stateOrProvinceName, localityName. If there are multiple
values for any of these parts the hash value will be an array ref with the
values in order instead of just a scalar.

=item not_before, not_after

The time frame, where the certificate is valid, as time_t, e.g. can be converted
with localtime or similar functions.

=item serial

The serial number

=item crl_uri

List of URIs for CRL distribution.

=item ocsp_uri

List of URIs for revocation checking using OCSP.

=item keyusage

List of keyUsage information in the certificate.

=item extkeyusage

List of extended key usage information from the certificate. Each entry in
this list consists of a hash with oid, nid, ln and sn.

=item pubkey_digest_xxx

Binary digest of the pubkey using the given digest algorithm, e.g.
pubkey_digest_sha256 if (the default) SHA-256 was used.

=item x509_digest_xxx

Binary digest of the X.509 certificate using the given digest algorithm, e.g.
x509_digest_sha256 if (the default) SHA-256 was used.

=item fingerprint_xxx

Fingerprint of the certificate using the given digest algorithm, e.g.
fingerprint_sha256 if (the default) SHA-256 was used. Contrary to digest_* this
is an ASCII string with a list if hexadecimal numbers, e.g.
"73:59:75:5C:6D...".

=item signature_alg

Algorithm used to sign certificate, e.g. C<sha256WithRSAEncryption>.

=item ext

List of extensions.
Each entry in the list is a hash with oid, nid, sn, critical flag (boolean) and
data (string representation given by X509V3_EXT_print).

=item version

Certificate version, usually 2 (x509v3)

=back

=item * CERT_create(hash) -> (cert,key)

Creates a certificate based on the given hash.
If the issuer is not specified the certificate will be self-signed.
The following keys can be given:

=over 8

=item subject

Hash with the parts of the subject, e.g. commonName, countryName, ... as
described in C<CERT_asHash>.
Default points to IO::Socket::SSL.

=item not_before

A time_t value when the certificate starts to be valid. Defaults to current
time.

=item not_after

A time_t value when the certificate ends to be valid. Defaults to current
time plus one 365 days.

=item serial

The serial number. If not given a random number will be used.

=item version

The version of the certificate, default 2 (x509v3).

=item CA true|false

If true declare certificate as CA, defaults to false.

=item purpose string|array|hash

Set the purpose of the certificate.
The different purposes can be given as a string separated by non-word character,
as array or hash. With string or array each purpose can be prefixed with '+'
(enable) or '-' (disable) and same can be done with the value when given as a
hash. By default enabling the purpose is assumed.

If the CA option is given and true the defaults "ca,sslca,emailca,objca" are
assumed, but can be overridden with explicit purpose.
If the CA option is given and false the defaults "server,client" are assumed.
If no CA option and no purpose is given it defaults to "server,client".

Purpose affects basicConstraints, keyUsage, extKeyUsage and netscapeCertType.
The following purposes are defined (case is not important):

    client
    server
    email
    objsign

    CA
    sslCA
    emailCA
    objCA

    emailProtection
    codeSigning
    timeStamping

    digitalSignature
    nonRepudiation
    keyEncipherment
    dataEncipherment
    keyAgreement
    keyCertSign
    cRLSign
    encipherOnly
    decipherOnly

Examples:

     # root-CA for SSL certificates
     purpose => 'sslCA'   # or CA => 1

     # server certificate and CA (typically self-signed)
     purpose => 'sslCA,server'

     # client certificate
     purpose => 'client',


=item ext [{ sn => .., data => ... }, ... ]

List of extensions. The type of the extension can be specified as name with
C<sn> or as NID with C<nid> and the data with C<data>. These data must be in the
same syntax as expected within openssl.cnf, e.g. something like
C<OCSP;URI=http://...>. Additionally the critical flag can be set with
C<critical => 1>.

=item key key

use given key as key for certificate, otherwise a new one will be generated and
returned

=item issuer_cert cert

set issuer for new certificate

=item issuer_key key

sign new certificate with given key

=item issuer [ cert, key ]

Instead of giving issuer_key and issuer_cert as separate arguments they can be
given both together.

=item digest algorithm

specify the algorithm used to sign the certificate, default SHA-256.

=item ignore_invalid_args

ignore any unknown arguments which might be in the argument list (which might be
in the arguments for example as result from CERT_asHash)

=back

=back

=head1 AUTHOR

Steffen Ullrich
