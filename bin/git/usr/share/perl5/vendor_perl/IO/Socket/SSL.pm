#vim: set sts=4 sw=4 ts=8 ai:
#
# IO::Socket::SSL:
# provide an interface to SSL connections similar to IO::Socket modules
#
# Current Code Shepherd: Steffen Ullrich <sullr at cpan.org>
# Code Shepherd before: Peter Behroozi, <behrooz at fas.harvard.edu>
#
# The original version of this module was written by
# Marko Asplund, <marko.asplund at kronodoc.fi>, who drew from
# Crypt::SSLeay (Net::SSL) by Gisle Aas.
#

package IO::Socket::SSL;

our $VERSION = '2.089';

use IO::Socket;
use Net::SSLeay 1.46;
use IO::Socket::SSL::PublicSuffix;
use Exporter ();
use Errno qw( EWOULDBLOCK EAGAIN ETIMEDOUT EINTR EPIPE );
use Carp;
use strict;

my $use_threads;
BEGIN {
    die "no support for weaken - please install Scalar::Util" if ! do {
	local $SIG{__DIE__};
	eval { require Scalar::Util; Scalar::Util->import("weaken"); 1 }
	    || eval { require WeakRef; WeakRef->import("weaken"); 1 }
    };
    require Config;
    $use_threads = $Config::Config{usethreads};
}


# results from commonly used constant functions from Net::SSLeay for fast access
my $Net_SSLeay_ERROR_WANT_READ   = Net::SSLeay::ERROR_WANT_READ();
my $Net_SSLeay_ERROR_WANT_WRITE  = Net::SSLeay::ERROR_WANT_WRITE();
my $Net_SSLeay_ERROR_SYSCALL     = Net::SSLeay::ERROR_SYSCALL();
my $Net_SSLeay_ERROR_SSL         = Net::SSLeay::ERROR_SSL();
my $Net_SSLeay_VERIFY_NONE       = Net::SSLeay::VERIFY_NONE();
my $Net_SSLeay_VERIFY_PEER       = Net::SSLeay::VERIFY_PEER();


use constant SSL_VERIFY_NONE => &Net::SSLeay::VERIFY_NONE;
use constant SSL_VERIFY_PEER => &Net::SSLeay::VERIFY_PEER;
use constant SSL_VERIFY_FAIL_IF_NO_PEER_CERT => Net::SSLeay::VERIFY_FAIL_IF_NO_PEER_CERT();
use constant SSL_VERIFY_CLIENT_ONCE => Net::SSLeay::VERIFY_CLIENT_ONCE();

# from openssl/ssl.h; should be better in Net::SSLeay
use constant SSL_SENT_SHUTDOWN => 1;
use constant SSL_RECEIVED_SHUTDOWN => 2;

use constant SSL_OCSP_NO_STAPLE   => 0b00001;
use constant SSL_OCSP_MUST_STAPLE => 0b00010;
use constant SSL_OCSP_FAIL_HARD   => 0b00100;
use constant SSL_OCSP_FULL_CHAIN  => 0b01000;
use constant SSL_OCSP_TRY_STAPLE  => 0b10000;

# capabilities of underlying Net::SSLeay/openssl
my $can_client_sni;  # do we support SNI on the client side
my $can_server_sni;  # do we support SNI on the server side
my $can_multi_cert;  # RSA and ECC certificate in same context
my $can_npn;         # do we support NPN (obsolete)
my $can_alpn;        # do we support ALPN
my $can_ecdh;        # do we support ECDH key exchange
my $set_groups_list; # SSL_CTX_set1_groups_list || SSL_CTX_set1_curves_list || undef
my $can_ocsp;        # do we support OCSP
my $can_ocsp_staple; # do we support OCSP stapling
my $can_tckt_keycb;  # TLS ticket key callback
my $can_pha;         # do we support PHA
my $session_upref;   # SSL_SESSION_up_ref is implemented
my %sess_cb;         # SSL_CTX_sess_set_(new|remove)_cb
my $check_partial_chain; # use X509_V_FLAG_PARTIAL_CHAIN if available
my $auto_retry;      # (clear|set)_mode SSL_MODE_AUTO_RETRY with OpenSSL 1.1.1+ with non-blocking
my $ssl_mode_release_buffers = 0; # SSL_MODE_RELEASE_BUFFERS if available
my $can_ciphersuites; # support for SSL_CTX_set_ciphersuites (TLS 1.3)
my $can_client_psk; # work as PSK client
my $can_server_psk; # work as PSK server

my $openssl_version;
my $netssleay_version;

BEGIN {
    $openssl_version = Net::SSLeay::OPENSSL_VERSION_NUMBER();
    $netssleay_version = do { no warnings; $Net::SSLeay::VERSION + 0.0; };
    $can_client_sni = $openssl_version >= 0x10000000;
    $can_server_sni = defined &Net::SSLeay::get_servername;
    $can_npn = defined &Net::SSLeay::P_next_proto_negotiated &&
	! Net::SSLeay::constant("LIBRESSL_VERSION_NUMBER");
	# LibreSSL 2.6.1 disabled NPN by keeping the relevant functions
	# available but removed the actual functionality from these functions.
    $can_alpn = defined &Net::SSLeay::CTX_set_alpn_protos;
    $can_ecdh =
	($openssl_version >= 0x1010000f) ? 'auto' :
	defined(&Net::SSLeay::CTX_set_ecdh_auto) ? 'can_auto' :
	(defined &Net::SSLeay::CTX_set_tmp_ecdh &&
	    # There is a regression with elliptic curves on 1.0.1d with 64bit
	    # http://rt.openssl.org/Ticket/Display.html?id=2975
	    ( $openssl_version != 0x1000104f
	    || length(pack("P",0)) == 4 )) ? 'tmp_ecdh' :
	    '';
    $set_groups_list =
	defined &Net::SSLeay::CTX_set1_groups_list ? \&Net::SSLeay::CTX_set1_groups_list :
	defined &Net::SSLeay::CTX_set1_curves_list ? \&Net::SSLeay::CTX_set1_curves_list :
	undef;
    $can_multi_cert = $can_ecdh
	&& $openssl_version >= 0x10002000;
    $can_ocsp = defined &Net::SSLeay::OCSP_cert2ids
	# OCSP got broken in 1.75..1.77
	&& ($netssleay_version < 1.75 || $netssleay_version > 1.77);
    $can_ocsp_staple = $can_ocsp
	&& defined &Net::SSLeay::set_tlsext_status_type;
    $can_tckt_keycb  = defined &Net::SSLeay::CTX_set_tlsext_ticket_getkey_cb
	&& $netssleay_version >= 1.80;
    $can_pha = defined &Net::SSLeay::CTX_set_post_handshake_auth;
    $can_ciphersuites = defined &Net::SSLeay::CTX_set_ciphersuites;
    $can_client_psk = defined &Net::SSLeay::CTX_set_psk_client_callback;
    $can_server_psk = defined &Net::SSLeay::CTX_set_psk_server_callback;

    if (defined &Net::SSLeay::SESSION_up_ref) {
	$session_upref = 1;
    }

    if ($session_upref
	&& defined &Net::SSLeay::CTX_sess_set_new_cb
	&& defined &Net::SSLeay::CTX_sess_set_remove_cb) {
	%sess_cb = (
	    new => \&Net::SSLeay::CTX_sess_set_new_cb,
	    remove => \&Net::SSLeay::CTX_sess_set_remove_cb,
	);
    }

    if (my $c = defined &Net::SSLeay::CTX_get0_param
	&& eval { Net::SSLeay::X509_V_FLAG_PARTIAL_CHAIN() }) {
	$check_partial_chain = sub {
	    my $ctx = shift;
	    my $param = Net::SSLeay::CTX_get0_param($ctx);
	    Net::SSLeay::X509_VERIFY_PARAM_set_flags($param, $c);
	};
    }

    if (!defined &Net::SSLeay::clear_mode) {
	# assume SSL_CTRL_CLEAR_MODE being 78 since it was always this way
	*Net::SSLeay::clear_mode = sub {
	    my ($ctx,$opt) = @_;
	    Net::SSLeay::ctrl($ctx,78,$opt,0);
	};
    }

    if ($openssl_version >= 0x10101000) {
	# openssl 1.1.1 enabled SSL_MODE_AUTO_RETRY by default, which is bad for
	# non-blocking sockets
	my $mode_auto_retry =
	    # was always 0x00000004
	    eval { Net::SSLeay::MODE_AUTO_RETRY() } || 0x00000004;
	$auto_retry = sub {
	    my ($ssl,$on) = @_;
	    if ($on) {
		Net::SSLeay::set_mode($ssl, $mode_auto_retry);
	    } else {
		Net::SSLeay::clear_mode($ssl, $mode_auto_retry);
	    }
	}
    }
    if ($openssl_version >= 0x10000000) {
	# ssl/ssl.h:#define SSL_MODE_RELEASE_BUFFERS 0x00000010L
	$ssl_mode_release_buffers = 0x00000010;
    }
}

my $algo2digest = do {
    my %digest;
    sub {
	my $digest_name = shift;
	return $digest{$digest_name} ||= do {
	    Net::SSLeay::SSLeay_add_ssl_algorithms();
	    Net::SSLeay::EVP_get_digestbyname($digest_name)
		or die "Digest algorithm $digest_name is not available";
	};
    }
};

my $CTX_tlsv1_3_new;
if ( defined &Net::SSLeay::CTX_set_min_proto_version
    and defined &Net::SSLeay::CTX_set_max_proto_version
    and my $tls13 = eval { Net::SSLeay::TLS1_3_VERSION() }
) {
    $CTX_tlsv1_3_new = sub {
	my $ctx = Net::SSLeay::CTX_new();
	return $ctx if Net::SSLeay::CTX_set_min_proto_version($ctx,$tls13)
	    && Net::SSLeay::CTX_set_max_proto_version($ctx,$tls13);
	Net::SSLeay::CTX_free($ctx);
	return;
    };
}

# global defaults
my %DEFAULT_SSL_ARGS = (
    SSL_check_crl => 0,
    # TLS 1.1 and lower are deprecated with RFC 8996
    SSL_version => 'SSLv23:!TLSv1:!TLSv1_1:!SSLv3:!SSLv2',
    SSL_verify_callback => undef,
    SSL_verifycn_scheme => undef,  # fallback cn verification
    SSL_verifycn_publicsuffix => undef,  # fallback default list verification
    #SSL_verifycn_name => undef,   # use from PeerAddr/PeerHost - do not override in set_args_filter_hack 'use_defaults'
    SSL_npn_protocols => undef,    # meaning depends whether on server or client side
    SSL_alpn_protocols => undef,   # list of protocols we'll accept/send, for example ['http/1.1','spdy/3.1']

    # rely on system default but be sure to disable some definitely bad ones
    SSL_cipher_list => 'DEFAULT !EXP !MEDIUM !LOW !eNULL !aNULL !RC4 !DES !MD5 !PSK !SRP',
);

my %DEFAULT_SSL_CLIENT_ARGS = (
    %DEFAULT_SSL_ARGS,
    SSL_verify_mode => SSL_VERIFY_PEER,

    SSL_ca_file => undef,
    SSL_ca_path => undef,
);

# set values inside _init to work with perlcc, RT#95452
my %DEFAULT_SSL_SERVER_ARGS;

# Initialization of OpenSSL internals
# This will be called once during compilation - perlcc users might need to
# call it again by hand, see RT#95452
{
    sub init {
	# library_init returns false if the library was already initialized.
	# This way we can find out if the library needs to be re-initialized
	# inside code compiled with perlcc
	Net::SSLeay::library_init() or return;

	Net::SSLeay::load_error_strings();
	Net::SSLeay::OpenSSL_add_all_digests();
	Net::SSLeay::randomize();

	%DEFAULT_SSL_SERVER_ARGS = (
	    %DEFAULT_SSL_ARGS,
	    SSL_verify_mode => SSL_VERIFY_NONE,
	    SSL_honor_cipher_order => 1,  # trust server to know the best cipher
	    SSL_dh => do {
		my $bio = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
		# generated with: openssl dhparam 2048
		Net::SSLeay::BIO_write($bio,<<'DH');
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAr8wskArj5+1VCVsnWt/RUR7tXkHJ7mGW7XxrLSPOaFyKyWf8lZht
iSY2Lc4oa4Zw8wibGQ3faeQu/s8fvPq/aqTxYmyHPKCMoze77QJHtrYtJAosB9SY
CN7s5Hexxb5/vQ4qlQuOkVrZDiZO9GC4KaH9mJYnCoAsXDhDft6JT0oRVSgtZQnU
gWFKShIm+JVjN94kGs0TcBEesPTK2g8XVHK9H8AtSUb9BwW2qD/T5RmgNABysApO
Ps2vlkxjAHjJcqc3O+OiImKik/X2rtBTZjpKmzN3WWTB0RJZCOWaLlDO81D01o1E
aZecz3Np9KIYey900f+X7zC2bJxEHp95ywIBAg==
-----END DH PARAMETERS-----
DH
		my $dh = Net::SSLeay::PEM_read_bio_DHparams($bio);
		Net::SSLeay::BIO_free($bio);
		$dh or die "no DH";
		$dh;
	    },
	    (
		$can_ecdh eq 'auto' ? () : # automatically enabled by openssl
		$can_ecdh eq 'can_auto' ? (SSL_ecdh_curve => 'auto') :
		$can_ecdh eq 'tmp_ecdh' ? ( SSL_ecdh_curve => 'prime256v1' ) :
		(),
	    )
	);
    }
    # Call it once at compile time and try it at INIT.
    # This should catch all cases of including the module, e.g. 'use' (INIT) or
    # 'require' (compile time) and works also with perlcc
    {
	no warnings;
	INIT { init() }
	init();
    }
}

# global defaults which can be changed using set_defaults
# either key/value can be set or it can just be set to an external hash
my $GLOBAL_SSL_ARGS = {};
my $GLOBAL_SSL_CLIENT_ARGS = {};
my $GLOBAL_SSL_SERVER_ARGS = {};

# hack which is used to filter bad settings from used modules
my $FILTER_SSL_ARGS = undef;

# non-XS Versions of Scalar::Util will fail
BEGIN{
    die "You need the XS Version of Scalar::Util for dualvar() support" if !do {
	local $SIG{__DIE__}; local $SIG{__WARN__}; # be silent
	eval { use Scalar::Util 'dualvar'; dualvar(0,''); 1 };
    };
}

# get constants for SSL_OP_NO_* now, instead calling the related functions
# every time we setup a connection
my %SSL_OP_NO;
for(qw( SSLv2 SSLv3 TLSv1 TLSv1_1 TLSv11:TLSv1_1 TLSv1_2 TLSv12:TLSv1_2
	TLSv1_3 TLSv13:TLSv1_3 )) {
    my ($k,$op) = m{:} ? split(m{:},$_,2) : ($_,$_);
    my $sub = "Net::SSLeay::OP_NO_$op";
    local $SIG{__DIE__};
    $SSL_OP_NO{$k} = eval { no strict 'refs'; &$sub } || 0;
}

# Make SSL_CTX_clear_options accessible through SSL_CTX_ctrl unless it is
# already implemented in Net::SSLeay
if (!defined &Net::SSLeay::CTX_clear_options) {
    *Net::SSLeay::CTX_clear_options = sub {
	my ($ctx,$opt) = @_;
	# 77 = SSL_CTRL_CLEAR_OPTIONS
	Net::SSLeay::CTX_ctrl($ctx,77,$opt,0);
    };
}

# Try to work around problems with alternative trust path by default, RT#104759
my $DEFAULT_X509_STORE_flags = 0;
{
    local $SIG{__DIE__};
    eval { $DEFAULT_X509_STORE_flags |= Net::SSLeay::X509_V_FLAG_TRUSTED_FIRST() };
}

our $DEBUG;
use vars qw(@ISA $SSL_ERROR @EXPORT);

{
    # These constants will be used in $! at return from SSL_connect,
    # SSL_accept, _generic_(read|write), thus notifying the caller
    # the usual way of problems. Like with EWOULDBLOCK, EINPROGRESS..
    # these are especially important for non-blocking sockets

    my $x = $Net_SSLeay_ERROR_WANT_READ;
    use constant SSL_WANT_READ  => dualvar( \$x, 'SSL wants a read first' );
    my $y = $Net_SSLeay_ERROR_WANT_WRITE;
    use constant SSL_WANT_WRITE => dualvar( \$y, 'SSL wants a write first' );

    @EXPORT = qw(
	SSL_WANT_READ SSL_WANT_WRITE SSL_VERIFY_NONE SSL_VERIFY_PEER
	SSL_VERIFY_FAIL_IF_NO_PEER_CERT SSL_VERIFY_CLIENT_ONCE
	SSL_OCSP_NO_STAPLE SSL_OCSP_TRY_STAPLE SSL_OCSP_MUST_STAPLE
	SSL_OCSP_FAIL_HARD SSL_OCSP_FULL_CHAIN
	$SSL_ERROR GEN_DNS GEN_IPADD
    );
}

my @caller_force_inet4; # in case inet4 gets forced we store here who forced it

my $IOCLASS;
my $family_key; # 'Domain'||'Family'
BEGIN {
    # declare @ISA depending of the installed socket class

    # try to load inet_pton from Socket or Socket6 and make sure it is usable
    local $SIG{__DIE__}; local $SIG{__WARN__}; # be silent
    my $ip6 = eval {
	require Socket;
	Socket->VERSION(1.95);
	Socket::inet_pton( AF_INET6(),'::1') && AF_INET6() or die;
	Socket->import( qw/inet_pton NI_NUMERICHOST NI_NUMERICSERV/ );
	# behavior different to Socket6::getnameinfo - wrap
	*_getnameinfo = sub {
	    my ($err,$host,$port) = Socket::getnameinfo(@_) or return;
	    return if $err;
	    return ($host,$port);
	};
	'Socket';
    } || eval {
	require Socket6;
	Socket6::inet_pton( AF_INET6(),'::1') && AF_INET6() or die;
	Socket6->import( qw/inet_pton NI_NUMERICHOST NI_NUMERICSERV/ );
	# behavior different to Socket::getnameinfo - wrap
	*_getnameinfo = sub { return Socket6::getnameinfo(@_); };
	'Socket6';
    } || undef;

    # try IO::Socket::IP or IO::Socket::INET6 for IPv6 support
    $family_key = 'Domain'; # traditional
    if ($ip6) {
	# if we have IO::Socket::IP >= 0.31 we will use this in preference
	# because it can handle both IPv4 and IPv6
	if ( eval {
	    require IO::Socket::IP;
	    IO::Socket::IP->VERSION(0.31)
	}) {
	    @ISA = qw(IO::Socket::IP);
	    constant->import( CAN_IPV6 => "IO::Socket::IP" );
	    $family_key = 'Family';
	    $IOCLASS = "IO::Socket::IP";

	# if we have IO::Socket::INET6 we will use this not IO::Socket::INET
	# because it can handle both IPv4 and IPv6
	# require at least 2.62 because of several problems before that version
	} elsif( eval { require IO::Socket::INET6; IO::Socket::INET6->VERSION(2.62) } ) {
	    @ISA = qw(IO::Socket::INET6);
	    constant->import( CAN_IPV6 => "IO::Socket::INET6" );
	    $IOCLASS = "IO::Socket::INET6";
	} else {
	    $ip6 = ''
	}
    }

    # fall back to IO::Socket::INET for IPv4 only
    if (!$ip6) {
	@ISA = qw(IO::Socket::INET);
	$IOCLASS = "IO::Socket::INET";
	constant->import(CAN_IPV6 => '');
	if (!defined $ip6) {
	    constant->import(NI_NUMERICHOST => 1);
	    constant->import(NI_NUMERICSERV => 2);
	}
    }

    #Make $DEBUG another name for $Net::SSLeay::trace
    *DEBUG = \$Net::SSLeay::trace;

    #Compatibility
    *ERROR = \$SSL_ERROR;
}


sub DEBUG {
    $DEBUG or return;
    my (undef,$file,$line,$sub) = caller(1);
    if ($sub =~m{^IO::Socket::SSL::(?:error|(_internal_error))$}) {
	(undef,$file,$line) = caller(2) if $1;
    } else {
	(undef,$file,$line) = caller;
    }
    my $msg = shift;
    $file = '...'.substr( $file,-17 ) if length($file)>20;
    $msg = sprintf $msg,@_ if @_;
    print STDERR "DEBUG: $file:$line: $msg\n";
}

BEGIN {
    # import some constants from Net::SSLeay or use hard-coded defaults
    # if Net::SSLeay isn't recent enough to provide the constants
    my %const = (
	NID_CommonName => 13,
	GEN_DNS => 2,
	GEN_IPADD => 7,
    );
    while ( my ($name,$value) = each %const ) {
	no strict 'refs';
	*{$name} = UNIVERSAL::can( 'Net::SSLeay', $name ) || sub { $value };
    }

    *idn_to_ascii = \&IO::Socket::SSL::PublicSuffix::idn_to_ascii;
    *idn_to_unicode = \&IO::Socket::SSL::PublicSuffix::idn_to_unicode;
}

my $OPENSSL_LIST_SEPARATOR = $^O =~m{^(?:(dos|os2|mswin32|netware)|vms)$}i
    ? $1 ? ';' : ',' : ':';
my $CHECK_SSL_PATH = sub {
    my %args = (@_ == 1) ? ('',@_) : @_;
    for my $type (keys %args) {
	my $path = $args{$type};
	if (!$type) {
	    delete $args{$type};
	    $type = (ref($path) || -d $path) ? 'SSL_ca_path' : 'SSL_ca_file';
	    $args{$type} = $path;
	}

	next if ref($path) eq 'SCALAR' && ! $$path;
	if ($type eq 'SSL_ca_file') {
	    die "SSL_ca_file $path can't be used: $!"
		if ! open(my $fh,'<',$path);
	} elsif ($type eq 'SSL_ca_path') {
	    $path = [ split($OPENSSL_LIST_SEPARATOR,$path) ] if !ref($path);
	    my @err;
	    for my $d (ref($path) ? @$path : $path) {
		if (! -d $d) {
		    push @err, "SSL_ca_path $d does not exist";
		} elsif (! opendir(my $dh,$d)) {
		    push @err, "SSL_ca_path $d is not accessible: $!"
		} else {
		    @err = ();
		    last
		}
	    }
	    die "@err" if @err;
	}
    }
    return %args;
};


{
    my %default_ca;
    my $ca_detected; # 0: never detect, undef: need to (re)detect
    my $openssldir;

    sub default_ca {
	if (@_) {
	    # user defined default CA or reset
	    if ( @_ > 1 ) {
		%default_ca = @_;
		$ca_detected  = 0;
	    } elsif ( my $path = shift ) {
		%default_ca = $CHECK_SSL_PATH->($path);
		$ca_detected  = 0;
	    } else {
		$ca_detected = undef;
	    }
	}
	return %default_ca if defined $ca_detected;

	# SSLEAY_DIR was 5 up to OpenSSL 1.1, then switched to 4 and got
	# renamed to OPENSSL_DIR. Unfortunately it is not exported as constant
	# by Net::SSLeay so we use the fixed number.
	$openssldir ||=
	    Net::SSLeay::SSLeay_version(5) =~m{^OPENSSLDIR: "(.+)"$} ? $1 :
	    Net::SSLeay::SSLeay_version(4) =~m{^OPENSSLDIR: "(.+)"$} ? $1 :
	    'cannot-determine-openssldir-from-ssleay-version';

	# (re)detect according to openssl crypto/cryptlib.h
	my $dir = $ENV{SSL_CERT_DIR}
	    || ( $^O =~m{vms}i ? "SSLCERTS:":"$openssldir/certs" );
	if ( opendir(my $dh,$dir)) {
	    FILES: for my $f (  grep { m{^[a-f\d]{8}(\.\d+)?$} } readdir($dh) ) {
		open( my $fh,'<',"$dir/$f") or next;
		while (my $line = <$fh>) {
		    $line =~m{^-+BEGIN (X509 |TRUSTED |)CERTIFICATE-} or next;
		    $default_ca{SSL_ca_path} = $dir;
		    last FILES;
		}
	    }
	}
	my $file = $ENV{SSL_CERT_FILE}
	    || ( $^O =~m{vms}i ? "SSLCERTS:cert.pem":"$openssldir/cert.pem" );
	if ( open(my $fh,'<',$file)) {
	    while (my $line = <$fh>) {
		$line =~m{^-+BEGIN (X509 |TRUSTED |)CERTIFICATE-} or next;
		$default_ca{SSL_ca_file} = $file;
		last;
	    }
	}

	$default_ca{SSL_ca_file} = Mozilla::CA::SSL_ca_file() if ! %default_ca && do {
		local $SIG{__DIE__};
		eval { require Mozilla::CA; 1 };
	    };

	$ca_detected = 1;
	return %default_ca;
    }
}


# Export some stuff
# inet4|inet6|debug will be handled by myself, everything
# else will be handled the Exporter way
sub import {
    my $class = shift;

    my @export;
    foreach (@_) {
	if ( /^inet4$/i ) {
	    # explicitly fall back to inet4
	    @ISA = 'IO::Socket::INET';
	    @caller_force_inet4 = caller(); # save for warnings for 'inet6' case
	} elsif ( /^inet6$/i ) {
	    # check if we have already ipv6 as base
	    if ( ! UNIVERSAL::isa( $class, 'IO::Socket::INET6')
		and ! UNIVERSAL::isa( $class, 'IO::Socket::IP' )) {
		# either we don't support it or we disabled it by explicitly
		# loading it with 'inet4'. In this case re-enable but warn
		# because this is probably an error
		if ( CAN_IPV6 ) {
		    @ISA = ( CAN_IPV6 );
		    warn "IPv6 support re-enabled in __PACKAGE__, got disabled in file $caller_force_inet4[1] line $caller_force_inet4[2]";
		} else {
		    die "INET6 is not supported, install IO::Socket::IP";
		}
	    }
	} elsif ( /^:?debug(\d+)/ ) {
	    $DEBUG=$1;
	} else {
	    push @export,$_
	}
    }

    @_ = ( $class,@export );
    goto &Exporter::import;
}

my %SSL_OBJECT;
my %CREATED_IN_THIS_THREAD;
sub CLONE { %CREATED_IN_THIS_THREAD = (); }

# all keys used internally, these should be cleaned up at end
my @all_my_keys = qw(
    _SSL_arguments
    _SSL_certificate
    _SSL_ctx
    _SSL_fileno
    _SSL_in_DESTROY
    _SSL_ioclass_downgrade
    _SSL_ioclass_upgraded
    _SSL_last_err
    _SSL_object
    _SSL_ocsp_verify
    _SSL_opened
    _SSL_opening
    _SSL_servername
    _SSL_msg_callback
);


# we have callbacks associated with contexts, but have no way to access the
# current SSL object from these callbacks. To work around this
# CURRENT_SSL_OBJECT will be set before calling Net::SSLeay::{connect,accept}
# and reset afterwards, so we have access to it inside _internal_error.
my $CURRENT_SSL_OBJECT;

# You might be expecting to find a new() subroutine here, but that is
# not how IO::Socket::INET works.  All configuration gets performed in
# the calls to configure() and either connect() or accept().

#Call to configure occurs when a new socket is made using
#IO::Socket::INET.  Returns false (empty list) on failure.
sub configure {
    my ($self, $arg_hash) = @_;
    return _invalid_object() unless($self);

    # force initial blocking
    # otherwise IO::Socket::SSL->new might return undef if the
    # socket is nonblocking and it fails to connect immediately
    # for real nonblocking behavior one should create a nonblocking
    # socket and later call connect explicitly
    my $blocking = delete $arg_hash->{Blocking};

    # because Net::HTTPS simple redefines blocking() to {} (e.g.
    # return undef) and IO::Socket::INET does not like this we
    # set Blocking only explicitly if it was set
    $arg_hash->{Blocking} = 1 if defined ($blocking);

    $self->configure_SSL($arg_hash) || return;

    if ($arg_hash->{$family_key} ||= $arg_hash->{Domain} || $arg_hash->{Family}) {
	# Hack to work around the problem that IO::Socket::IP defaults to
	# AI_ADDRCONFIG which creates problems if we have only the loopback
	# interface. If we already know the family this flag is more harmful
	# then useful.
	$arg_hash->{GetAddrInfoFlags} = 0 if $IOCLASS eq 'IO::Socket::IP'
		&& ! defined $arg_hash->{GetAddrInfoFlags};
    }
    return $self->_internal_error("@ISA configuration failed",0)
	if ! $self->SUPER::configure($arg_hash);

    $self->blocking(0) if defined $blocking && !$blocking;
    return $self;
}

sub configure_SSL {
    my ($self, $arg_hash) = @_;

    $arg_hash->{Proto} ||= 'tcp';
    my $is_server = $arg_hash->{SSL_server};
    if ( ! defined $is_server ) {
	$is_server = $arg_hash->{SSL_server} = $arg_hash->{Listen} || 0;
    }

    # add user defined defaults, maybe after filtering
    $FILTER_SSL_ARGS->($is_server,$arg_hash) if $FILTER_SSL_ARGS;

    delete @{*$self}{@all_my_keys};
    ${*$self}{_SSL_opened} = $is_server;
    ${*$self}{_SSL_arguments} = $arg_hash;

    # this adds defaults to $arg_hash as a side effect!
    ${*$self}{'_SSL_ctx'} = IO::Socket::SSL::SSL_Context->new($arg_hash)
	or return;

    return $self;
}


sub _skip_rw_error {
    my ($self,$ssl,$rv) = @_;
    my $err = Net::SSLeay::get_error($ssl,$rv);
    if ( $err == $Net_SSLeay_ERROR_WANT_READ) {
	$SSL_ERROR = SSL_WANT_READ;
    } elsif ( $err == $Net_SSLeay_ERROR_WANT_WRITE) {
	$SSL_ERROR = SSL_WANT_WRITE;
    } else {
	return $err;
    }
    $! ||= EWOULDBLOCK;
    ${*$self}{_SSL_last_err} = [$SSL_ERROR,4] if ref($self);
    Net::SSLeay::ERR_clear_error();
    return 0;
}


# Call to connect occurs when a new client socket is made using IO::Socket::*
sub connect {
    my $self = shift || return _invalid_object();
    return $self if ${*$self}{'_SSL_opened'};  # already connected

    if ( ! ${*$self}{'_SSL_opening'} ) {
	# call SUPER::connect if the underlying socket is not connected
	# if this fails this might not be an error (e.g. if $! = EINPROGRESS
	# and socket is nonblocking this is normal), so keep any error
	# handling to the client
	$DEBUG>=2 && DEBUG('socket not yet connected' );
	$self->SUPER::connect(@_) || return;
	$DEBUG>=2 && DEBUG('socket connected' );

	# IO::Socket works around systems, which return EISCONN or similar
	# on non-blocking re-connect by returning true, even if $! is set
	# but it does not clear $!, so do it here
	$! = undef;

	# don't continue with connect_SSL if SSL_startHandshake is set to 0
	my $sh = ${*$self}{_SSL_arguments}{SSL_startHandshake};
	return $self if defined $sh && ! $sh;
    }
    return $self->connect_SSL;
}


sub connect_SSL {
    my $self = shift;
    my $args = @_>1 ? {@_}: $_[0]||{};
    return $self if ${*$self}{'_SSL_opened'};  # already connected

    my ($ssl,$ctx);
    if ( ! ${*$self}{'_SSL_opening'} ) {
	# start ssl connection
	$DEBUG>=2 && DEBUG('ssl handshake not started' );
	${*$self}{'_SSL_opening'} = 1;
	my $arg_hash = ${*$self}{'_SSL_arguments'};

	my $fileno = ${*$self}{'_SSL_fileno'} = fileno($self);
	return $self->_internal_error("Socket has no fileno",9)
	    if ! defined $fileno;

	$ctx = ${*$self}{'_SSL_ctx'};  # Reference to real context
	$ssl = ${*$self}{'_SSL_object'} = Net::SSLeay::new($ctx->{context})
	    || return $self->error("SSL structure creation failed");
	$CREATED_IN_THIS_THREAD{$ssl} = 1 if $use_threads;
	$SSL_OBJECT{$ssl} = [$self,0];
	weaken($SSL_OBJECT{$ssl}[0]);

	if ($ctx->{session_cache}) {
	    $arg_hash->{SSL_session_key} ||= do {
		my $host = $arg_hash->{PeerAddr} || $arg_hash->{PeerHost}
		    || $self->_update_peer;
		my $port = $arg_hash->{PeerPort} || $arg_hash->{PeerService};
		$port ? "$host:$port" : $host;
	    }
	}

	Net::SSLeay::set_fd($ssl, $fileno)
	    || return $self->error("SSL filehandle association failed");

	set_msg_callback($self) if $DEBUG>=2 || ${*$self}{_SSL_msg_callback};

	if ( $can_client_sni ) {
	    my $host;
	    if ( exists $arg_hash->{SSL_hostname} ) {
		# explicitly given
		# can be set to undef/'' to not use extension
		$host = $arg_hash->{SSL_hostname}
	    } elsif ( $host = $arg_hash->{PeerAddr} || $arg_hash->{PeerHost} ) {
		# implicitly given
		$host =~s{:[a-zA-Z0-9_\-]+$}{};
		# should be hostname, not IPv4/6
		$host = undef if $host !~m{[a-z_]}i or $host =~m{:};
	    }
	    # define SSL_CTRL_SET_TLSEXT_HOSTNAME 55
	    # define TLSEXT_NAMETYPE_host_name 0
	    if ($host) {
		$DEBUG>=2 && DEBUG("using SNI with hostname $host");
		Net::SSLeay::ctrl($ssl,55,0,$host);
	    } else {
		$DEBUG>=2 && DEBUG("not using SNI because hostname is unknown");
	    }
	} elsif ( $arg_hash->{SSL_hostname} ) {
	    return $self->_internal_error(
		"Client side SNI not supported for this openssl",9);
	} else {
	    $DEBUG>=2 && DEBUG("not using SNI because openssl is too old");
	}

	$arg_hash->{PeerAddr} || $arg_hash->{PeerHost} || $self->_update_peer;
	if ( $ctx->{verify_name_ref} ) {
	    # need target name for update
	    my $host = $arg_hash->{SSL_verifycn_name}
		|| $arg_hash->{SSL_hostname};
	    if ( ! defined $host ) {
		if ( $host = $arg_hash->{PeerAddr} || $arg_hash->{PeerHost} ) {
		    $host =~s{^
			(
			    (?:[^:\[]+) |    # ipv4|host
			    (?:\[(?:.*)\])   # [ipv6|host]
			)
			(:[\w\-]+)?          # optional :port
		    $}{$1}x;                 # ipv4|host|ipv6
		}
	    }
	    ${$ctx->{verify_name_ref}} = $host;
	}

	my $ocsp = $ctx->{ocsp_mode};
	if ( $ocsp & SSL_OCSP_NO_STAPLE ) {
	    # don't try stapling
	} elsif ( ! $can_ocsp_staple ) {
	    croak("OCSP stapling not support") if $ocsp & SSL_OCSP_MUST_STAPLE;
	} elsif ( $ocsp & (SSL_OCSP_TRY_STAPLE|SSL_OCSP_MUST_STAPLE)) {
	    # staple by default if verification enabled
	    ${*$self}{_SSL_ocsp_verify} = undef;
	    Net::SSLeay::set_tlsext_status_type($ssl,
		Net::SSLeay::TLSEXT_STATUSTYPE_ocsp());
	    $DEBUG>=2 && DEBUG("request OCSP stapling");
	}

	if ($ctx->{session_cache} and my $session =
	    $ctx->{session_cache}->get_session($arg_hash->{SSL_session_key})
	) {
	    Net::SSLeay::set_session($ssl, $session);
	}
    }

    $ssl ||= ${*$self}{'_SSL_object'};

    $SSL_ERROR = $! = undef;
    my $timeout = exists $args->{Timeout}
	? $args->{Timeout}
	: ${*$self}{io_socket_timeout}; # from IO::Socket
    if ( defined($timeout) && $timeout>0 && $self->blocking(0) ) {
	$DEBUG>=2 && DEBUG( "set socket to non-blocking to enforce timeout=$timeout" );
	# timeout was given and socket was blocking
	# enforce timeout with now non-blocking socket
    } else {
	# timeout does not apply because invalid or socket non-blocking
	$timeout = undef;
	$auto_retry && $auto_retry->($ssl,$self->blocking);
    }

    my $start = defined($timeout) && time();
    {
	$SSL_ERROR = undef;
	$CURRENT_SSL_OBJECT = $self;
	$DEBUG>=3 && DEBUG("call Net::SSLeay::connect" );
	my $rv = Net::SSLeay::connect($ssl);
	$CURRENT_SSL_OBJECT = undef;
	$DEBUG>=3 && DEBUG("done Net::SSLeay::connect -> $rv" );
	if ( $rv < 0 ) {
	    if ( my $err = $self->_skip_rw_error( $ssl,$rv )) {
		$self->error("SSL connect attempt failed");
		delete ${*$self}{'_SSL_opening'};
		${*$self}{'_SSL_opened'} = -1;
		$DEBUG>=1 && DEBUG( "fatal SSL error: $SSL_ERROR" );
		return $self->fatal_ssl_error();
	    }

	    $DEBUG>=2 && DEBUG('ssl handshake in progress' );
	    # connect failed because handshake needs to be completed
	    # if socket was non-blocking or no timeout was given return with this error
	    return if ! defined($timeout);

	    # wait until socket is readable or writable
	    my $rv;
	    if ( $timeout>0 ) {
		my $vec = '';
		vec($vec,$self->fileno,1) = 1;
		$DEBUG>=2 && DEBUG( "waiting for fd to become ready: $SSL_ERROR" );
		$rv =
		    $SSL_ERROR == SSL_WANT_READ ? select( $vec,undef,undef,$timeout) :
		    $SSL_ERROR == SSL_WANT_WRITE ? select( undef,$vec,undef,$timeout) :
		    undef;
	    } else {
		$DEBUG>=2 && DEBUG("handshake failed because no more time" );
		$! = ETIMEDOUT
	    }
	    if ( ! $rv ) {
		$DEBUG>=2 && DEBUG("handshake failed because socket did not became ready" );
		# failed because of timeout, return
		$! ||= ETIMEDOUT;
		delete ${*$self}{'_SSL_opening'};
		${*$self}{'_SSL_opened'} = -1;
		$self->blocking(1); # was blocking before
		return
	    }

	    # socket is ready, try non-blocking connect again after recomputing timeout
	    $DEBUG>=2 && DEBUG("socket ready, retrying connect" );
	    my $now = time();
	    $timeout -= $now - $start;
	    $start = $now;
	    redo;

	} elsif ( $rv == 0 ) {
	    delete ${*$self}{'_SSL_opening'};
	    $DEBUG>=2 && DEBUG("connection failed - connect returned 0" );
	    $self->error("SSL connect attempt failed because of handshake problems" );
	    ${*$self}{'_SSL_opened'} = -1;
	    return $self->fatal_ssl_error();
	}
    }

    $DEBUG>=2 && DEBUG('ssl handshake done' );
    # ssl connect successful
    delete ${*$self}{'_SSL_opening'};
    ${*$self}{'_SSL_opened'}=1;
    if (defined($timeout)) {
	$self->blocking(1); # reset back to blocking
	$! = undef; # reset errors from non-blocking
    }

    $ctx ||= ${*$self}{'_SSL_ctx'};

    if ( my $ocsp_result = ${*$self}{_SSL_ocsp_verify} ) {
	# got result from OCSP stapling
	if ( $ocsp_result->[0] > 0 ) {
	    $DEBUG>=3 && DEBUG("got OCSP success with stapling");
	    # successful validated
	} elsif ( $ocsp_result->[0] < 0 ) {
	    # Permanent problem with validation because certificate
	    # is either self-signed or the issuer cannot be found.
	    # Ignore here, because this will cause other errors too.
	    $DEBUG>=3 && DEBUG("got OCSP failure with stapling: %s",
		$ocsp_result->[1]);
	} else {
	    # definitely revoked
	    $DEBUG>=3 && DEBUG("got OCSP revocation with stapling: %s",
		$ocsp_result->[1]);
	    $self->_internal_error($ocsp_result->[1],5);
	    return $self->fatal_ssl_error();
	}
    } elsif ( $ctx->{ocsp_mode} & SSL_OCSP_MUST_STAPLE ) {
	$self->_internal_error("did not receive the required stapled OCSP response",5);
	return $self->fatal_ssl_error();
    }

    if (!%sess_cb and $ctx->{session_cache}
	and my $session = Net::SSLeay::get1_session($ssl)) {
	$ctx->{session_cache}->add_session(
	    ${*$self}{_SSL_arguments}{SSL_session_key},
	    $session
	);
    }

    tie *{$self}, "IO::Socket::SSL::SSL_HANDLE", $self;

    return $self;
}

# called if PeerAddr is not set in ${*$self}{'_SSL_arguments'}
# this can be the case if start_SSL is called with a normal IO::Socket::INET
# so that PeerAddr|PeerPort are not set from args
# returns PeerAddr
sub _update_peer {
    my $self = shift;
    my $arg_hash = ${*$self}{'_SSL_arguments'};
    eval {
	my $sockaddr = getpeername( $self );
	my $af = sockaddr_family($sockaddr);
	if( CAN_IPV6 && $af == AF_INET6 ) {
	    my (undef, $host, $port) = _getnameinfo($sockaddr,
		NI_NUMERICHOST | NI_NUMERICSERV);
	    $arg_hash->{PeerPort} = $port;
	    $arg_hash->{PeerAddr} = $host;
	} else {
	    my ($port,$addr) = sockaddr_in( $sockaddr);
	    $arg_hash->{PeerPort} = $port;
	    $arg_hash->{PeerAddr} = inet_ntoa( $addr );
	}
    }
}

#Call to accept occurs when a new client connects to a server using
#IO::Socket::SSL
sub accept {
    my $self = shift || return _invalid_object();
    my $class = shift || 'IO::Socket::SSL';

    my $socket = ${*$self}{'_SSL_opening'};
    if ( ! $socket ) {
	# underlying socket not done
	$DEBUG>=2 && DEBUG('no socket yet' );
	$socket = $self->SUPER::accept($class) || return;
	$DEBUG>=2 && DEBUG('accept created normal socket '.$socket );

	# don't continue with accept_SSL if SSL_startHandshake is set to 0
	my $sh = ${*$self}{_SSL_arguments}{SSL_startHandshake};
	if (defined $sh && ! $sh) {
	    ${*$socket}{_SSL_ctx} = ${*$self}{_SSL_ctx};
	    ${*$socket}{_SSL_arguments} = {
		%{${*$self}{_SSL_arguments}},
		SSL_server => 0,
	    };
	    $DEBUG>=2 && DEBUG('will not start SSL handshake yet');
	    return wantarray ? ($socket, getpeername($socket) ) : $socket
	}
    }

    $self->accept_SSL($socket) || return;
    $DEBUG>=2 && DEBUG('accept_SSL ok' );

    return wantarray ? ($socket, getpeername($socket) ) : $socket;
}

sub accept_SSL {
    my $self = shift;
    my $socket = ( @_ && UNIVERSAL::isa( $_[0], 'IO::Handle' )) ? shift : $self;
    my $args = @_>1 ? {@_}: $_[0]||{};

    my $ssl;
    if ( ! ${*$self}{'_SSL_opening'} ) {
	$DEBUG>=2 && DEBUG('starting sslifying' );
	${*$self}{'_SSL_opening'} = $socket;
	if ($socket != $self) {
	    ${*$socket}{_SSL_ctx} = ${*$self}{_SSL_ctx};
	    ${*$socket}{_SSL_arguments} = {
		%{${*$self}{_SSL_arguments}},
		SSL_server => 0
	    };
	}

	my $fileno = ${*$socket}{'_SSL_fileno'} = fileno($socket);
	return $socket->_internal_error("Socket has no fileno",9)
	    if ! defined $fileno;

	$ssl = ${*$socket}{_SSL_object} =
	    Net::SSLeay::new(${*$socket}{_SSL_ctx}{context})
	    || return $socket->error("SSL structure creation failed");
	$CREATED_IN_THIS_THREAD{$ssl} = 1 if $use_threads;
	$SSL_OBJECT{$ssl} = [$socket,1];
	weaken($SSL_OBJECT{$ssl}[0]);

	Net::SSLeay::set_fd($ssl, $fileno)
	    || return $socket->error("SSL filehandle association failed");

	set_msg_callback($self) if $DEBUG>=2 || ${*$self}{_SSL_msg_callback};
    }

    $ssl ||= ${*$socket}{'_SSL_object'};

    $SSL_ERROR = $! = undef;
    #$DEBUG>=2 && DEBUG('calling ssleay::accept' );

    my $timeout = exists $args->{Timeout}
	? $args->{Timeout}
	: ${*$self}{io_socket_timeout}; # from IO::Socket
    if ( defined($timeout) && $timeout>0 && $socket->blocking(0) ) {
	# timeout was given and socket was blocking
	# enforce timeout with now non-blocking socket
    } else {
	# timeout does not apply because invalid or socket non-blocking
	$timeout = undef;
	$auto_retry && $auto_retry->($ssl,$socket->blocking);
    }

    my $start = defined($timeout) && time();
    {
	$SSL_ERROR = undef;
	$CURRENT_SSL_OBJECT = $self;
	my $rv = Net::SSLeay::accept($ssl);
	$CURRENT_SSL_OBJECT = undef;
	$DEBUG>=3 && DEBUG( "Net::SSLeay::accept -> $rv" );
	if ( $rv < 0 ) {
	    if ( my $err = $socket->_skip_rw_error( $ssl,$rv )) {
		$socket->error("SSL accept attempt failed");
		delete ${*$self}{'_SSL_opening'};
		${*$socket}{'_SSL_opened'} = -1;
		return $socket->fatal_ssl_error();
	    }

	    # accept failed because handshake needs to be completed
	    # if socket was non-blocking or no timeout was given return with this error
	    return if ! defined($timeout);

	    # wait until socket is readable or writable
	    my $rv;
	    if ( $timeout>0 ) {
		my $vec = '';
		vec($vec,$socket->fileno,1) = 1;
		$rv =
		    $SSL_ERROR == SSL_WANT_READ  ? select( $vec,undef,undef,$timeout) :
		    $SSL_ERROR == SSL_WANT_WRITE ? select( undef,$vec,undef,$timeout) :
		    undef;
	    } else {
		$! = ETIMEDOUT
	    }
	    if ( ! $rv ) {
		# failed because of timeout, return
		$! ||= ETIMEDOUT;
		delete ${*$self}{'_SSL_opening'};
		${*$socket}{'_SSL_opened'} = -1;
		$socket->blocking(1); # was blocking before
		return
	    }

	    # socket is ready, try non-blocking accept again after recomputing timeout
	    my $now = time();
	    $timeout -= $now - $start;
	    $start = $now;
	    redo;

	} elsif ( $rv == 0 ) {
	    $socket->error("SSL accept attempt failed because of handshake problems" );
	    delete ${*$self}{'_SSL_opening'};
	    ${*$socket}{'_SSL_opened'} = -1;
	    return $socket->fatal_ssl_error();
	}
    }

    $DEBUG>=2 && DEBUG('handshake done, socket ready' );
    # socket opened
    delete ${*$self}{'_SSL_opening'};
    ${*$socket}{'_SSL_opened'} = 1;
    if (defined($timeout)) {
	$socket->blocking(1); # reset back to blocking
	$! = undef; # reset errors from non-blocking
    }

    tie *{$socket}, "IO::Socket::SSL::SSL_HANDLE", $socket;

    return $socket;
}


# support user defined message callback but also internal debugging
sub _msg_callback {
    ##  my ($direction, $ssl_ver, $content_type, $buf, $len, $ssl, $userp) = @_;
    IO::Socket::SSL::Trace::ossl_trace(@_) if $DEBUG>=2;
    my $self = ($SSL_OBJECT{$_[5]} || return)->[0] || return;
    if (my $cb = ${*$self}{_SSL_msg_callback}) {
	my ($sub,@arg) = @$cb;
	$sub->($self, @_[0..5], @arg);
    }
}

my $ssleay_set_msg_callback = defined &Net::SSLeay::set_msg_callback
    && \&Net::SSLeay::set_msg_callback;

sub set_msg_callback {
    my $self = shift;
    if (@_) {
	if ($_[0]) {
	    # enable user defined callback: ($cb,@arg)
	    die "no support for msg callback with this version of Net::SSLeay/OpenSSL"
		if !$ssleay_set_msg_callback;
	    ${*$self}{_SSL_msg_callback} = [@_];
	} else {
	    # disable user defined callback
	    delete ${*$self}{_SSL_msg_callback};
	}
    }

    # activate user set callback and/or internal for debugging
    if ($ssleay_set_msg_callback and my $ssl = ${*$self}{_SSL_object}) {
	$ssleay_set_msg_callback->($ssl,
	    ($DEBUG>=2 || ${*$self}{_SSL_msg_callback})? \&_msg_callback : undef)
    }
}


####### I/O subroutines ########################

if ($auto_retry) {
    *blocking = sub {
	my $self = shift;
	{ @_ && $auto_retry->(${*$self}{_SSL_object} || last, @_); }
	return $self->SUPER::blocking(@_);
    };
}

sub _generic_read {
    my ($self, $read_func, undef, $length, $offset) = @_;
    my $ssl =  ${*$self}{_SSL_object} || return;
    my $buffer=\$_[2];

    $SSL_ERROR = $! = undef;
    my ($data,$rwerr) = $read_func->($ssl, $length);
    while ( ! defined($data)) {
	if ( my $err = $self->_skip_rw_error( $ssl, defined($rwerr) ? $rwerr:-1 )) {
	    # OpenSSL 1.1.0c+ : EOF can now result in SSL_read returning -1 and SSL_ERROR_SYSCALL
	    # OpenSSL 3.0 : EOF can now result in SSL_read returning -1 and SSL_ERROR_SSL
	    if (not $! and $err == $Net_SSLeay_ERROR_SSL || $err == $Net_SSLeay_ERROR_SYSCALL) {
		# treat as EOF
		$data = '';
		# clear the "unexpected eof while reading" error (OpenSSL 3.0+)
		Net::SSLeay::ERR_clear_error();
		last;
	    }
	    $self->error("SSL read error");
	}
	return;
    }

    $length = length($data);
    $$buffer = '' if !defined $$buffer;
    $offset ||= 0;
    if ($offset>length($$buffer)) {
	$$buffer.="\0" x ($offset-length($$buffer));  #mimic behavior of read
    }

    substr($$buffer, $offset, length($$buffer), $data);
    return $length;
}

sub read {
    my $self = shift;
    ${*$self}{_SSL_object} && return _generic_read($self,
	$self->blocking ? \&Net::SSLeay::ssl_read_all : \&Net::SSLeay::read,
	@_
    );

    # fall back to plain read if we are not required to use SSL yet
    return $self->SUPER::read(@_);
}

# contrary to the behavior of read sysread can read partial data
sub sysread {
    my $self = shift;
    ${*$self}{_SSL_object} && return _generic_read( $self,
	\&Net::SSLeay::read, @_ );

    # fall back to plain sysread if we are not required to use SSL yet
    my $rv = $self->SUPER::sysread(@_);
    return $rv;
}

sub peek {
    my $self = shift;
    ${*$self}{_SSL_object} && return _generic_read( $self,
	\&Net::SSLeay::peek, @_ );

    # fall back to plain peek if we are not required to use SSL yet
    # emulate peek with recv(...,MS_PEEK) - peek(buf,len,offset)
    return if ! defined recv($self,my $buf,$_[1],MSG_PEEK);
    $_[0] = $_[2] ? substr($_[0],0,$_[2]).$buf : $buf;
    return length($buf);
}


sub _generic_write {
    my ($self, $write_all, undef, $length, $offset) = @_;

    my $ssl =  ${*$self}{_SSL_object} || return;
    my $buffer = \$_[2];

    my $buf_len = length($$buffer);
    $length ||= $buf_len;
    $offset ||= 0;
    return $self->_internal_error("Invalid offset for SSL write",9)
	if $offset>$buf_len;
    return 0 if ($offset == $buf_len);

    $SSL_ERROR = $! = undef;
    my $written;
    if ( $write_all ) {
	my $data = $length < $buf_len-$offset ? substr($$buffer, $offset, $length) : $$buffer;
	($written, my $errs) = Net::SSLeay::ssl_write_all($ssl, $data);
	# ssl_write_all returns number of bytes written
	$written = undef if ! $written && $errs;
    } else {
	$written = Net::SSLeay::write_partial( $ssl,$offset,$length,$$buffer );
	# write_partial does SSL_write which returns -1 on error
	$written = undef if $written <= 0;
    }
    if ( !defined($written) ) {
	if ( my $err = $self->_skip_rw_error( $ssl,-1 )) {
	    # if $! is not set with ERROR_SYSCALL then report as EPIPE
	    $! ||= EPIPE if $err == $Net_SSLeay_ERROR_SYSCALL;
	    $self->error("SSL write error ($err)");
	}
	return;
    }

    return $written;
}

# if socket is blocking write() should return only on error or
# if all data are written
sub write {
    my $self = shift;
    ${*$self}{_SSL_object} && return _generic_write( $self,
	scalar($self->blocking),@_ );

    # fall back to plain write if we are not required to use SSL yet
    return $self->SUPER::write(@_);
}

# contrary to write syswrite() returns already if only
# a part of the data is written
sub syswrite {
    my $self = shift;
    ${*$self}{_SSL_object} && return _generic_write($self,0,@_);

    # fall back to plain syswrite if we are not required to use SSL yet
    return $self->SUPER::syswrite(@_);
}

sub print {
    my $self = shift;
    my $string = join(($, or ''), @_, ($\ or ''));
    return $self->write( $string );
}

sub printf {
    my ($self,$format) = (shift,shift);
    return $self->write(sprintf($format, @_));
}

sub getc {
    my ($self, $buffer) = (shift, undef);
    return $buffer if $self->read($buffer, 1, 0);
}

sub readline {
    my $self = shift;
    ${*$self}{_SSL_object} or return $self->SUPER::getline;

    if ( not defined $/ or wantarray) {
	# read all and split

	my $buf = '';
	while (1) {
	    my $rv = $self->sysread($buf,2**16,length($buf));
	    if ( ! defined $rv ) {
		next if $! == EINTR;       # retry
		last if $! == EWOULDBLOCK || $! == EAGAIN; # use everything so far
		return;                    # return error
	    } elsif ( ! $rv ) {
		last
	    }
	}

	if ( ! defined $/ ) {
	    return $buf
	} elsif ( ref($/)) {
	    my $size = ${$/};
	    die "bad value in ref \$/: $size" unless $size>0;
	    return $buf=~m{\G(.{1,$size})}g;
	} elsif ( $/ eq '' ) {
	    return $buf =~m{\G(.*\n\n+|.+)}g;
	} else {
	    return $buf =~m{\G(.*$/|.+)}g;
	}
    }

    # read only one line
    if ( ref($/) ) {
	my $size = ${$/};
	# read record of $size bytes
	die "bad value in ref \$/: $size" unless $size>0;
	my $buf = '';
	while ( $size>length($buf)) {
	    my $rv = $self->sysread($buf,$size-length($buf),length($buf));
	    if ( ! defined $rv ) {
		next if $! == EINTR;       # retry
		last if $! == EWOULDBLOCK || $! == EAGAIN; # use everything so far
		return;                    # return error
	    } elsif ( ! $rv ) {
		last
	    }
	}
	return $buf;
    }

    my ($delim0,$delim1) = $/ eq '' ? ("\n\n","\n"):($/,'');

    # find first occurrence of $delim0 followed by as much as possible $delim1
    my $buf = '';
    my $eod = 0;  # pointer into $buf after $delim0 $delim1*
    my $ssl = $self->_get_ssl_object or return;
    while (1) {

	# wait until we have more data or eof
	my $poke = Net::SSLeay::peek($ssl,1);
	if ( ! defined $poke or $poke eq '' ) {
	    next if $! == EINTR;
	}

	my $skip = 0;

	# peek into available data w/o reading
	my $pending = Net::SSLeay::pending($ssl);
	if ( $pending and
	    ( my $pb = Net::SSLeay::peek( $ssl,$pending )) ne '' ) {
	    $buf .= $pb
	} else {
	    return $buf eq '' ? ():$buf;
	}
	if ( !$eod ) {
	    my $pos = index( $buf,$delim0 );
	    if ( $pos<0 ) {
		$skip = $pending
	    } else {
		$eod = $pos + length($delim0); # pos after delim0
	    }
	}

	if ( $eod ) {
	    if ( $delim1 ne '' ) {
		# delim0 found, check for as much delim1 as possible
		while ( index( $buf,$delim1,$eod ) == $eod ) {
		    $eod+= length($delim1);
		}
	    }
	    $skip = $pending - ( length($buf) - $eod );
	}

	# remove data from $self which I already have in buf
	while ( $skip>0 ) {
	    if ($self->sysread(my $p,$skip,0)) {
		$skip -= length($p);
		next;
	    }
	    $! == EINTR or last;
	}

	if ( $eod and ( $delim1 eq '' or $eod < length($buf))) {
	    # delim0 found and there can be no more delim1 pending
	    last
	}
    }
    return substr($buf,0,$eod);
}

sub close {
    my $self = shift || return _invalid_object();
    my $close_args = (ref($_[0]) eq 'HASH') ? $_[0] : {@_};

    return if ! $self->stop_SSL(
	SSL_fast_shutdown => 1,
	%$close_args,
	_SSL_ioclass_downgrade => 0,
    );

    if ( ! $close_args->{_SSL_in_DESTROY} ) {
	untie( *$self );
	undef ${*$self}{_SSL_fileno};
	return $self->SUPER::close;
    }
    return 1;
}

sub is_SSL {
    my $self = pop;
    return ${*$self}{_SSL_object} && 1
}

sub stop_SSL {
    my $self = shift || return _invalid_object();
    my $stop_args = (ref($_[0]) eq 'HASH') ? $_[0] : {@_};
    $stop_args->{SSL_no_shutdown} = 1 if ! ${*$self}{_SSL_opened};

    if (my $ssl = ${*$self}{'_SSL_object'}) {
	if (delete ${*$self}{'_SSL_opening'}) {
	    # just destroy the object further below
	} elsif ( ! $stop_args->{SSL_no_shutdown} ) {
	    my $status = Net::SSLeay::get_shutdown($ssl);

	    my $timeout =
		not($self->blocking) ? undef :
		exists $stop_args->{Timeout} ? $stop_args->{Timeout} :
		${*$self}{io_socket_timeout}; # from IO::Socket
	    if ($timeout) {
		$self->blocking(0);
		$timeout += time();
	    }

	    while (1) {
		if ( $status & SSL_SENT_SHUTDOWN and
		    # don't care for received if fast shutdown
		    $status & SSL_RECEIVED_SHUTDOWN
			|| $stop_args->{SSL_fast_shutdown}) {
		    # shutdown complete
		    last;
		}
		if ((${*$self}{'_SSL_opened'}||0) <= 0) {
		    # not really open, thus don't expect shutdown to return
		    # something meaningful
		    last;
		}

		# initiate or complete shutdown
		local $SIG{PIPE} = 'IGNORE';
		$SSL_ERROR = $! = undef;
		my $rv = Net::SSLeay::shutdown($ssl);
		if ( $rv < 0 ) {
		    # non-blocking socket?
		    if ( ! $timeout ) {
			if ( my $err = $self->_skip_rw_error( $ssl, $rv )) {
				# if $! is not set with ERROR_SYSCALL then report as EPIPE
				$! ||= EPIPE if $err == $Net_SSLeay_ERROR_SYSCALL;
				$self->error("SSL shutdown error ($err)");
			}
			# need to try again
			return;
		    }

		    # don't use _skip_rw_error so that existing error does
		    # not get cleared
		    my $wait = $timeout - time();
		    last if $wait<=0;
		    vec(my $vec = '',fileno($self),1) = 1;
		    my $err = Net::SSLeay::get_error($ssl,$rv);
		    if ( $err == $Net_SSLeay_ERROR_WANT_READ) {
			select($vec,undef,undef,$wait)
		    } elsif ( $err == $Net_SSLeay_ERROR_WANT_WRITE) {
			select(undef,$vec,undef,$wait)
		    } else {
			if ($err) {
			    # if $! is not set with ERROR_SYSCALL then report as EPIPE
			    $! ||= EPIPE if $err == $Net_SSLeay_ERROR_SYSCALL;
			    $self->error("SSL shutdown error ($err)");
			}
			last;
		    }
		}

		$status |= SSL_SENT_SHUTDOWN;
		$status |= SSL_RECEIVED_SHUTDOWN if $rv>0;
	    }
	    $self->blocking(1) if $timeout;
	}

	# destroy allocated objects for SSL and untie
	# do not destroy CTX unless explicitly specified
	Net::SSLeay::free($ssl);
	if (my $cert = delete ${*$self}{'_SSL_certificate'}) {
	    Net::SSLeay::X509_free($cert);
	}
	delete ${*$self}{_SSL_object};
	${*$self}{'_SSL_opened'} = 0;
	delete $SSL_OBJECT{$ssl};
	delete $CREATED_IN_THIS_THREAD{$ssl};
	untie(*$self);
    }

    if ($stop_args->{'SSL_ctx_free'}) {
	my $ctx = delete ${*$self}{'_SSL_ctx'};
	$ctx && $ctx->DESTROY();
    }


    if ( ! $stop_args->{_SSL_in_DESTROY} ) {

	my $downgrade = $stop_args->{_SSL_ioclass_downgrade};
	if ( $downgrade || ! defined $downgrade ) {
	    # rebless to original class from start_SSL
	    if ( my $orig_class = delete ${*$self}{'_SSL_ioclass_upgraded'} ) {
		bless $self,$orig_class;
		# FIXME: if original class was tied too we need to restore the tie
		# remove all _SSL related from *$self
		my @sslkeys = grep { m{^_?SSL_} } keys %{*$self};
		delete @{*$self}{@sslkeys} if @sslkeys;
	    }
	}
    }
    return 1;
}


sub fileno {
    my $self = shift;
    my $fn = ${*$self}{'_SSL_fileno'};
	return defined($fn) ? $fn : $self->SUPER::fileno();
}


####### IO::Socket::SSL specific functions #######
# get access to SSL handle for use with Net::SSLeay. Use with caution!
sub _get_ssl_object {
    my $self = shift;
    return ${*$self}{'_SSL_object'} ||
	IO::Socket::SSL->_internal_error("Undefined SSL object",9);
}

# get access to SSL handle for use with Net::SSLeay. Use with caution!
sub _get_ctx_object {
    my $self = shift;
    my $ctx_object = ${*$self}{_SSL_ctx};
    return $ctx_object && $ctx_object->{context};
}

# default error for undefined arguments
sub _invalid_object {
    return IO::Socket::SSL->_internal_error("Undefined IO::Socket::SSL object",9);
}


sub pending {
    my $ssl = shift()->_get_ssl_object || return;
    return Net::SSLeay::pending($ssl);
}

sub start_SSL {
    my ($class,$socket) = (shift,shift);
    return $class->_internal_error("Not a socket",9) if ! ref($socket);
    my $arg_hash = @_ == 1 ? $_[0] : {@_};
    my %to = exists $arg_hash->{Timeout} ? ( Timeout => delete $arg_hash->{Timeout} ) :();
    my $original_class = ref($socket);
    if ( ! $original_class ) {
	$socket = ($original_class = $ISA[0])->new_from_fd($socket,'<+')
	    or return $class->_internal_error(
	    "creating $original_class from file handle failed",9);
    }
    my $original_fileno = (UNIVERSAL::can($socket, "fileno"))
	? $socket->fileno : CORE::fileno($socket);
    return $class->_internal_error("Socket has no fileno",9)
	if ! defined $original_fileno;

    bless $socket, $class;
    $socket->configure_SSL($arg_hash) or bless($socket, $original_class) && return;

    ${*$socket}{'_SSL_fileno'} = $original_fileno;
    ${*$socket}{'_SSL_ioclass_upgraded'} = $original_class
	if $class ne $original_class;

    my $start_handshake = $arg_hash->{SSL_startHandshake};
    if ( ! defined($start_handshake) || $start_handshake ) {
	# if we have no callback force blocking mode
	$DEBUG>=2 && DEBUG( "start handshake" );
	my $was_blocking = $socket->blocking(1);
	my $result = ${*$socket}{'_SSL_arguments'}{SSL_server}
	    ? $socket->accept_SSL(%to)
	    : $socket->connect_SSL(%to);
	if ( $result ) {
	    $socket->blocking(0) if ! $was_blocking;
	    return $socket;
	} else {
	    # upgrade to SSL failed, downgrade socket to original class
	    if ( $original_class ) {
		bless($socket,$original_class);
		$socket->blocking(0) if ! $was_blocking
		    && $socket->can('blocking');
	    }
	    return;
	}
    } else {
	$DEBUG>=2 && DEBUG( "don't start handshake: $socket" );
	return $socket; # just return upgraded socket
    }

}

sub new_from_fd {
    my ($class, $fd) = (shift,shift);
    # Check for accidental inclusion of MODE in the argument list
    if (length($_[0]) < 4) {
	(my $mode = $_[0]) =~ tr/+<>//d;
	shift unless length($mode);
    }
    my $handle = $ISA[0]->new_from_fd($fd, '+<')
	|| return($class->error("Could not create socket from file descriptor."));

    # Annoying workaround for Perl 5.6.1 and below:
    $handle = $ISA[0]->new_from_fd($handle, '+<');

    return $class->start_SSL($handle, @_);
}


sub dump_peer_certificate {
    my $ssl = shift()->_get_ssl_object || return;
    return Net::SSLeay::dump_peer_certificate($ssl);
}

if ( defined &Net::SSLeay::get_peer_cert_chain
    && $netssleay_version >= 1.58 ) {
    *peer_certificates = sub {
	my $self = shift;
	my $ssl = $self->_get_ssl_object || return;
	my @chain = Net::SSLeay::get_peer_cert_chain($ssl);
	@chain = () if @chain && !$self->peer_certificate; # work around #96013
	if ( ${*$self}{_SSL_arguments}{SSL_server} ) {
	    # in the client case the chain contains the peer certificate,
	    # in the server case not
	    # this one has an increased reference counter, the other not
	    if ( my $peer = Net::SSLeay::get_peer_certificate($ssl)) {
		Net::SSLeay::X509_free($peer);
		unshift @chain, $peer;
	    }
	}
	return @chain;

    }
} else {
    *peer_certificates = sub {
	die "peer_certificates needs Net::SSLeay>=1.58";
    }
}

{
    my %dispatcher = (
	issuer =>  sub { Net::SSLeay::X509_NAME_oneline( Net::SSLeay::X509_get_issuer_name( shift )) },
	subject => sub { Net::SSLeay::X509_NAME_oneline( Net::SSLeay::X509_get_subject_name( shift )) },
	commonName => sub {
	    my $cn = Net::SSLeay::X509_NAME_get_text_by_NID(
		Net::SSLeay::X509_get_subject_name( shift ), NID_CommonName);
	    $cn;
	},
	subjectAltNames => sub { Net::SSLeay::X509_get_subjectAltNames( shift ) },
    );

    # alternative names
    $dispatcher{authority} = $dispatcher{issuer};
    $dispatcher{owner}     = $dispatcher{subject};
    $dispatcher{cn}        = $dispatcher{commonName};

    sub peer_certificate {
	my ($self,$field,$reload) = @_;
	my $ssl = $self->_get_ssl_object or return;

	Net::SSLeay::X509_free(delete ${*$self}{_SSL_certificate})
	    if $reload && ${*$self}{_SSL_certificate};
	my $cert = ${*$self}{_SSL_certificate}
	    ||= Net::SSLeay::get_peer_certificate($ssl)
	    or return $self->error("Could not retrieve peer certificate");

	if ($field) {
	    my $sub = $dispatcher{$field} or croak
		"invalid argument for peer_certificate, valid are: ".join( " ",keys %dispatcher ).
		"\nMaybe you need to upgrade your Net::SSLeay";
	    return $sub->($cert);
	} else {
	    return $cert
	}
    }

    sub sock_certificate {
	my ($self,$field) = @_;
	my $ssl = $self->_get_ssl_object || return;
	my $cert = Net::SSLeay::get_certificate( $ssl ) || return;
	if ($field) {
	    my $sub = $dispatcher{$field} or croak
		"invalid argument for sock_certificate, valid are: ".join( " ",keys %dispatcher ).
		"\nMaybe you need to upgrade your Net::SSLeay";
	    return $sub->($cert);
	} else {
	    return $cert
	}
    }


    # known schemes, possible attributes are:
    #  - wildcards_in_alt (0, 'full_label', 'anywhere')
    #  - wildcards_in_cn (0, 'full_label', 'anywhere')
    #  - check_cn (0, 'always', 'when_only')
    # unfortunately there are a lot of different schemes used, see RFC 6125 for a
    # summary, which references all of the following except RFC4217/ftp

    my %scheme = (
	none => {}, # do not check
	# default set is a superset of all the others and thus worse than a more
	# specific set, but much better than not verifying name at all
	default => {
	    wildcards_in_cn  => 'anywhere',
	    wildcards_in_alt => 'anywhere',
	    check_cn         => 'always',
	    ip_in_cn         => 1,
	},
    );

    for(qw(
	rfc2818
	rfc3920 xmpp
	rfc4217 ftp
    )) {
	$scheme{$_} = {
	    wildcards_in_cn  => 'anywhere',
	    wildcards_in_alt => 'anywhere',
	    check_cn         => 'when_only',
	}
    }

    for(qw(www http)) {
	$scheme{$_} = {
	    wildcards_in_cn  => 'anywhere',
	    wildcards_in_alt => 'anywhere',
	    check_cn         => 'when_only',
	    ip_in_cn         => 4,
	}
    }

    for(qw(
	rfc4513 ldap
    )) {
	$scheme{$_} = {
	    wildcards_in_cn  => 0,
	    wildcards_in_alt => 'full_label',
	    check_cn         => 'always',
	};
    }

    for(qw(
	rfc2595 smtp
	rfc4642 imap pop3 acap
	rfc5539 nntp
	rfc5538 netconf
	rfc5425 syslog
	rfc5953 snmp
    )) {
	$scheme{$_} = {
	    wildcards_in_cn  => 'full_label',
	    wildcards_in_alt => 'full_label',
	    check_cn         => 'always'
	};
    }
    for(qw(
	rfc5971 gist
    )) {
	$scheme{$_} = {
	    wildcards_in_cn  => 'full_label',
	    wildcards_in_alt => 'full_label',
	    check_cn         => 'when_only',
	};
    }

    for(qw(
	rfc5922 sip
    )) {
	$scheme{$_} = {
	    wildcards_in_cn  => 0,
	    wildcards_in_alt => 0,
	    check_cn         => 'always',
	};
    }


    # function to verify the hostname
    #
    # as every application protocol has its own rules to do this
    # we provide some default rules as well as a user-defined
    # callback

    sub verify_hostname_of_cert {
	my $identity = shift;
	my $cert = shift;
	my $scheme = shift || 'default';
	my $publicsuffix = shift;
	if ( ! ref($scheme) ) {
	    $DEBUG>=3 && DEBUG( "scheme=$scheme cert=$cert" );
	    $scheme = $scheme{$scheme} || croak("scheme $scheme not defined");
	}

	return 1 if ! %$scheme; # 'none'
	$identity =~s{\.+$}{}; # ignore absolutism

	# get data from certificate
	my $commonName = $dispatcher{cn}->($cert);
	my @altNames = $dispatcher{subjectAltNames}->($cert);
	$DEBUG>=3 && DEBUG("identity=$identity cn=$commonName alt=@altNames" );

	if ( my $sub = $scheme->{callback} ) {
	    # use custom callback
	    return $sub->($identity,$commonName,@altNames);
	}

	# is the given hostname an IP address? Then we have to convert to network byte order [RFC791][RFC2460]

	my $ipn;
	if ( CAN_IPV6 and $identity =~m{:} ) {
	    # no IPv4 or hostname have ':'  in it, try IPv6.
	    $identity =~m{[^\da-fA-F:\.]} and return; # invalid characters in name
	    $ipn = inet_pton(AF_INET6,$identity) or return; # invalid name
	} elsif ( my @ip = $identity =~m{^(\d+)(?:\.(\d+)\.(\d+)\.(\d+)|[\d\.]*)$} ) {
	    # check for invalid IP/hostname
	    return if 4 != @ip or 4 != grep { defined($_) && $_<256 } @ip;
	    $ipn = pack("CCCC",@ip);
	} else {
	    # assume hostname, check for umlauts etc
	    if ( $identity =~m{[^a-zA-Z0-9_.\-]} ) {
		$identity =~m{\0} and return; # $identity has \\0 byte
		$identity = idn_to_ascii($identity)
		    or return; # conversation to IDNA failed
		$identity =~m{[^a-zA-Z0-9_.\-]}
		    and return; # still junk inside
	    }
	}

	# do the actual verification
	my $check_name = sub {
	    my ($name,$identity,$wtyp,$publicsuffix) = @_;
	    $name =~s{\.+$}{}; # ignore absolutism
	    $name eq '' and return;
	    $wtyp ||= '';
	    my $pattern;
	    ### IMPORTANT!
	    # We accept only a single wildcard and only for a single part of the FQDN
	    # e.g. *.example.org does match www.example.org but not bla.www.example.org
	    # The RFCs are in this regard unspecific but we don't want to have to
	    # deal with certificates like *.com, *.co.uk or even *
	    # see also http://nils.toedtmann.net/pub/subjectAltName.txt .
	    # Also, we fall back to full_label matches if the identity is an IDNA
	    # name, see RFC6125 and the discussion at
	    # http://bugs.python.org/issue17997#msg194950
	    if ( $wtyp eq 'anywhere' and $name =~m{^([a-zA-Z0-9_\-]*)\*(.+)} ) {
		return if $1 ne '' and substr($identity,0,4) eq 'xn--'; # IDNA
		$pattern = qr{^\Q$1\E[a-zA-Z0-9_\-]+\Q$2\E$}i;
	    } elsif ( $wtyp =~ m{^(?:full_label|leftmost)$}
		and $name =~m{^\*(\..+)$} ) {
		$pattern = qr{^[a-zA-Z0-9_\-]+\Q$1\E$}i;
	    } else {
		return lc($identity) eq lc($name);
	    }
	    if ( $identity =~ $pattern ) {
		$publicsuffix = IO::Socket::SSL::PublicSuffix->default
		    if ! defined $publicsuffix;
		return 1 if $publicsuffix eq '';
		my @labels = split( m{\.+}, $identity );
		my $tld = $publicsuffix->public_suffix(\@labels,+1);
		return 1 if @labels > ( $tld ? 0+@$tld : 1 );
	    }
	    return;
	};


	my $alt_dnsNames = 0;
	while (@altNames) {
	    my ($type, $name) = splice (@altNames, 0, 2);
	    if ( $ipn and $type == GEN_IPADD ) {
		# exact match needed for IP
		# $name is already packed format (inet_xton)
		return 1 if $ipn eq $name;

	    } elsif ( ! $ipn and $type == GEN_DNS ) {
		$name =~s/\s+$//; $name =~s/^\s+//;
		$alt_dnsNames++;
		$check_name->($name,$identity,$scheme->{wildcards_in_alt},$publicsuffix)
		    and return 1;
	    }
	}

	if ( $scheme->{check_cn} eq 'always' or
	    $scheme->{check_cn} eq 'when_only' and !$alt_dnsNames ) {
	    if ( ! $ipn ) {
		$check_name->($commonName,$identity,$scheme->{wildcards_in_cn},$publicsuffix)
		    and return 1;
	    } elsif ( $scheme->{ip_in_cn} ) {
		if ( $identity eq $commonName ) {
		    return 1 if
			$scheme->{ip_in_cn} == 4 ? length($ipn) == 4 :
			$scheme->{ip_in_cn} == 6 ? length($ipn) == 16 :
			1;
		}
	    }
	}

	return 0; # no match
    }
}

sub verify_hostname {
    my $self = shift;
    my $host = shift;
    my $cert = $self->peer_certificate;
    return verify_hostname_of_cert( $host,$cert,@_ );
}


sub get_servername {
    my $self = shift;
    return ${*$self}{_SSL_servername} ||= do {
	my $ssl = $self->_get_ssl_object or return;
	Net::SSLeay::get_servername($ssl);
    };
}

sub get_fingerprint_bin {
    my ($self,$algo,$cert,$key_only) = @_;
    $cert ||= $self->peer_certificate or return;
    return $key_only
	? Net::SSLeay::X509_pubkey_digest($cert, $algo2digest->($algo || 'sha256'))
	: Net::SSLeay::X509_digest($cert, $algo2digest->($algo || 'sha256'));
}

sub get_fingerprint {
    my ($self,$algo,$cert,$key_only) = @_;
    $algo ||= 'sha256';
    my $fp = get_fingerprint_bin($self,$algo,$cert,$key_only) or return;
    return $algo.'$'.($key_only ? 'pub$':'').unpack('H*',$fp);
}

sub get_cipher {
    my $ssl = shift()->_get_ssl_object || return;
    return Net::SSLeay::get_cipher($ssl);
}

sub get_sslversion {
    my $ssl = shift()->_get_ssl_object || return;
    my $version = Net::SSLeay::version($ssl) or return;
    return
	$version == 0x0304 ? 'TLSv1_3' :
	$version == 0x0303 ? 'TLSv1_2' :
	$version == 0x0302 ? 'TLSv1_1' :
	$version == 0x0301 ? 'TLSv1'   :
	$version == 0x0300 ? 'SSLv3'   :
	$version == 0x0002 ? 'SSLv2'   :
	$version == 0xfeff ? 'DTLS1'   :
	undef;
}

sub get_sslversion_int {
    my $ssl = shift()->_get_ssl_object || return;
    return Net::SSLeay::version($ssl);
}

sub get_session_reused {
    return Net::SSLeay::session_reused(
	shift()->_get_ssl_object || return);
}

if ($can_ocsp) {
    no warnings 'once';
    *ocsp_resolver = sub {
	my $self = shift;
	my $ssl = $self->_get_ssl_object || return;
	my $ctx = ${*$self}{_SSL_ctx};
	return IO::Socket::SSL::OCSP_Resolver->new(
	    $ssl,
	    $ctx->{ocsp_cache} ||= IO::Socket::SSL::OCSP_Cache->new,
	    $ctx->{ocsp_mode} & SSL_OCSP_FAIL_HARD,
	    @_ ? \@_ :
		$ctx->{ocsp_mode} & SSL_OCSP_FULL_CHAIN ? [ $self->peer_certificates ]:
		[ $self->peer_certificate ]
	);
    };
}

sub errstr {
    my $self = shift;
    my $oe = ref($self) && ${*$self}{_SSL_last_err};
    return $oe ? $oe->[0] : $SSL_ERROR || '';
}

sub fatal_ssl_error {
    my $self = shift;
    my $error_trap = ${*$self}{'_SSL_arguments'}->{'SSL_error_trap'};
    $@ = $self->errstr;
    my $saved_error = $SSL_ERROR;
    if (defined $error_trap and ref($error_trap) eq 'CODE') {
	$error_trap->($self, $self->errstr()."\n".$self->get_ssleay_error());
    } elsif ( ${*$self}{'_SSL_ioclass_upgraded'}
	|| ${*$self}{_SSL_arguments}{SSL_keepSocketOnError}) {
	# downgrade only
	$DEBUG>=3 && DEBUG('downgrading SSL only, not closing socket' );
	$self->stop_SSL;
    } else {
	# kill socket
	$self->close
    }
    $SSL_ERROR = $saved_error if $saved_error;
    return;
}

sub get_ssleay_error {
    #Net::SSLeay will print out the errors itself unless we explicitly
    #undefine $Net::SSLeay::trace while running print_errs()
    local $Net::SSLeay::trace;
    return Net::SSLeay::print_errs('SSL error: ') || '';
}

# internal errors, e.g. unsupported features, hostname check failed etc
# _SSL_last_err contains severity so that on error chains we can decide if one
# error should replace the previous one or if this is just a less specific
# follow-up error, e.g. configuration failed because certificate failed because
# hostname check went wrong:
# 0 - fallback errors
# 4 - errors bubbled up from OpenSSL (sub error, r/w error)
# 5 - hostname or OCSP verification failed
# 9 - fatal problems, e.g. missing feature, no fileno...
# _SSL_last_err and SSL_ERROR are only replaced if the error has a higher
# severity than the previous one

sub _internal_error {
    my ($self, $error, $severity) = @_;
    $error = dualvar( -1, $error );
    $self = $CURRENT_SSL_OBJECT if !ref($self) && $CURRENT_SSL_OBJECT;
    if (ref($self)) {
	my $oe = ${*$self}{_SSL_last_err};
	if (!$oe || $oe->[1] <= $severity) {
	    ${*$self}{_SSL_last_err} = [$error,$severity];
	    $SSL_ERROR = $error;
	    $DEBUG && DEBUG("local error: $error");
	} else {
	    $DEBUG && DEBUG("ignoring less severe local error '$error', keep '$oe->[0]'");
	}
    } else {
	$SSL_ERROR = $error;
	$DEBUG && DEBUG("global error: $error");
    }
    return;
}

# OpenSSL errors
sub error {
    my ($self, $error) = @_;
    my @err;
    while ( my $err = Net::SSLeay::ERR_get_error()) {
	push @err, Net::SSLeay::ERR_error_string($err);
	$DEBUG>=2 && DEBUG( $error."\n".$self->get_ssleay_error());
    }
    $error .= ' '.join(' ',@err) if @err;
    return $self->_internal_error($error,4) if $error;
    return;
}

sub _errstack {
    my @err;
    while (my $err = Net::SSLeay::ERR_get_error()) {
	push @err, Net::SSLeay::ERR_error_string($err);
    }
    return @err;
}

sub can_client_sni { return $can_client_sni }
sub can_server_sni { return $can_server_sni }
sub can_multi_cert { return $can_multi_cert }
sub can_npn        { return $can_npn }
sub can_alpn       { return $can_alpn }
sub can_ecdh       { return $can_ecdh }
sub can_ipv6       { return CAN_IPV6 }
sub can_ocsp       { return $can_ocsp }
sub can_ticket_keycb { return $can_tckt_keycb }
sub can_pha        { return $can_pha }
sub can_partial_chain { return $check_partial_chain && 1 }
sub can_ciphersuites { return $can_ciphersuites }
sub can_psk {
    my %can;
    $can{client}=1 if $can_client_psk;
    $can{server}=1 if $can_server_psk;
    return %can ? \%can : undef
}

sub DESTROY {
    my $self = shift or return;
    if (my $ssl = ${*$self}{_SSL_object}) {
	delete $SSL_OBJECT{$ssl};
	if (!$use_threads or delete $CREATED_IN_THIS_THREAD{$ssl}) {
	    $self->close(_SSL_in_DESTROY => 1, SSL_no_shutdown => 1);
	}
    }
    delete @{*$self}{@all_my_keys};
}


#######Extra Backwards Compatibility Functionality#######
sub socket_to_SSL { IO::Socket::SSL->start_SSL(@_); }
sub socketToSSL { IO::Socket::SSL->start_SSL(@_); }
sub kill_socket { shift->close }

sub issuer_name { return(shift()->peer_certificate("issuer")) }
sub subject_name { return(shift()->peer_certificate("subject")) }
sub get_peer_certificate { return shift() }

sub context_init {
    return($GLOBAL_SSL_ARGS = (ref($_[0]) eq 'HASH') ? $_[0] : {@_});
}

sub set_default_context {
    $GLOBAL_SSL_ARGS->{'SSL_reuse_ctx'} = shift;
}

sub set_default_session_cache {
    $GLOBAL_SSL_ARGS->{SSL_session_cache} = shift;
}


{
    my $set_defaults = sub {
	my $args = shift;
	for(my $i=0;$i<@$args;$i+=2 ) {
	    my ($k,$v) = @{$args}[$i,$i+1];
	    if ( $k =~m{^SSL_} ) {
		$_->{$k} = $v for(@_);
	    } elsif ( $k =~m{^(name|scheme)$} ) {
		$_->{"SSL_verifycn_$k"} = $v for (@_);
	    } elsif ( $k =~m{^(callback|mode)$} ) {
		$_->{"SSL_verify_$k"} = $v for(@_);
	    } else {
		$_->{"SSL_$k"} = $v for(@_);
	    }
	}
    };
    sub set_defaults {
	my %args = @_;
	$set_defaults->(\@_,
	    $GLOBAL_SSL_ARGS,
	    $GLOBAL_SSL_CLIENT_ARGS,
	    $GLOBAL_SSL_SERVER_ARGS
	);
    }
    { # deprecated API
	no warnings;
	*set_ctx_defaults = \&set_defaults;
    }
    sub set_client_defaults {
	my %args = @_;
	$set_defaults->(\@_, $GLOBAL_SSL_CLIENT_ARGS );
    }
    sub set_server_defaults {
	my %args = @_;
	$set_defaults->(\@_, $GLOBAL_SSL_SERVER_ARGS );
    }
}

sub set_args_filter_hack {
    my $sub = shift;
    if ( ref $sub ) {
	$FILTER_SSL_ARGS = $sub;
    } elsif ( $sub eq 'use_defaults' ) {
	# override args with defaults
	$FILTER_SSL_ARGS = sub {
	    my ($is_server,$args) = @_;
	    %$args = ( %$args, $is_server
		? ( %DEFAULT_SSL_SERVER_ARGS, %$GLOBAL_SSL_SERVER_ARGS )
		: ( %DEFAULT_SSL_CLIENT_ARGS, %$GLOBAL_SSL_CLIENT_ARGS )
	    );
	}
    }
}

sub next_proto_negotiated {
    my $self = shift;
    return $self->_internal_error("NPN not supported in Net::SSLeay",9) if ! $can_npn;
    my $ssl = $self->_get_ssl_object || return;
    return Net::SSLeay::P_next_proto_negotiated($ssl);
}

sub alpn_selected {
    my $self = shift;
    return $self->_internal_error("ALPN not supported in Net::SSLeay",9) if ! $can_alpn;
    my $ssl = $self->_get_ssl_object || return;
    return Net::SSLeay::P_alpn_selected($ssl);
}

sub opened {
    my $self = shift;
    return IO::Handle::opened($self) && ${*$self}{'_SSL_opened'};
}

sub opening {
    my $self = shift;
    return ${*$self}{'_SSL_opening'};
}

sub want_read  { shift->errstr == SSL_WANT_READ }
sub want_write { shift->errstr == SSL_WANT_WRITE }


#Redundant IO::Handle functionality
sub getline { return(scalar shift->readline()) }
sub getlines {
    return(shift->readline()) if wantarray();
    croak("Use of getlines() not allowed in scalar context");
}

#Useless IO::Handle functionality
sub truncate { croak("Use of truncate() not allowed with SSL") }
sub stat     { croak("Use of stat() not allowed with SSL" ) }
sub setbuf   { croak("Use of setbuf() not allowed with SSL" ) }
sub setvbuf  { croak("Use of setvbuf() not allowed with SSL" ) }
sub fdopen   { croak("Use of fdopen() not allowed with SSL" ) }

#Unsupported socket functionality
sub ungetc { croak("Use of ungetc() not implemented in IO::Socket::SSL") }
sub send   { croak("Use of send() not implemented in IO::Socket::SSL; use print/printf/syswrite instead") }
sub recv   { croak("Use of recv() not implemented in IO::Socket::SSL; use read/sysread instead") }

package IO::Socket::SSL::SSL_HANDLE;
use strict;
use Errno 'EBADF';
*weaken = *IO::Socket::SSL::weaken;

sub TIEHANDLE {
    my ($class, $handle) = @_;
    weaken($handle);
    bless \$handle, $class;
}

sub READ     { ${shift()}->sysread(@_) }
sub READLINE { ${shift()}->readline(@_) }
sub GETC     { ${shift()}->getc(@_) }

sub PRINT    { ${shift()}->print(@_) }
sub PRINTF   { ${shift()}->printf(@_) }
sub WRITE    { ${shift()}->syswrite(@_) }

sub FILENO   { ${shift()}->fileno(@_) }

sub TELL     { $! = EBADF; return -1 }
sub BINMODE  { return 0 }  # not perfect, but better than not implementing the method

sub CLOSE {                          #<---- Do not change this function!
    my $ssl = ${$_[0]};
    local @_;
    $ssl->close();
}


package IO::Socket::SSL::SSL_Context;
use Carp;
use strict;

my %CTX_CREATED_IN_THIS_THREAD;
*DEBUG = *IO::Socket::SSL::DEBUG;
*_errstack = \&IO::Socket::SSL::_errstack;

use constant SSL_MODE_ENABLE_PARTIAL_WRITE => 1;
use constant SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER => 2;

use constant FILETYPE_PEM => Net::SSLeay::FILETYPE_PEM();
use constant FILETYPE_ASN1 => Net::SSLeay::FILETYPE_ASN1();

my $DEFAULT_SSL_OP = &Net::SSLeay::OP_ALL
    | &Net::SSLeay::OP_SINGLE_DH_USE
    | ($can_ecdh ? &Net::SSLeay::OP_SINGLE_ECDH_USE : 0);


# get access to SSL handle for use with Net::SSLeay. Use with caution!
sub _get_ctx_object { shift->{context} }

# Note that the final object will actually be a reference to the scalar
# (C-style pointer) returned by Net::SSLeay::CTX_*_new() so that
# it can be blessed.
sub new {
    my $class = shift;
    #DEBUG( "$class @_" );
    my $arg_hash = (ref($_[0]) eq 'HASH') ? $_[0] : {@_};

    my $is_server = $arg_hash->{SSL_server};
    my %defaults = $is_server
	? (%DEFAULT_SSL_SERVER_ARGS, %$GLOBAL_SSL_ARGS, %$GLOBAL_SSL_SERVER_ARGS)
	: (%DEFAULT_SSL_CLIENT_ARGS, %$GLOBAL_SSL_ARGS, %$GLOBAL_SSL_CLIENT_ARGS);
    if ( $defaults{SSL_reuse_ctx} ) {
	# ignore default context if there are args to override it
	delete $defaults{SSL_reuse_ctx}
	    if grep { m{^SSL_(?!verifycn_name|hostname)$} } keys %$arg_hash;
    }
    %$arg_hash = ( %defaults, %$arg_hash ) if %defaults;

    if (my $ctx = $arg_hash->{'SSL_reuse_ctx'}) {
	if ($ctx->isa('IO::Socket::SSL::SSL_Context') and
	    $ctx->{context}) {
	    # valid context
	} elsif ( $ctx = ${*$ctx}{_SSL_ctx} ) {
	    # reuse context from existing SSL object
	}
	return $ctx
    }

    # common problem forgetting to set SSL_use_cert
    # if client cert is given by user but SSL_use_cert is undef, assume that it
    # should be set
    if ( ! $is_server && ! defined $arg_hash->{SSL_use_cert}
	&& ( grep { $arg_hash->{$_} } qw(SSL_cert SSL_cert_file))
	&& ( grep { $arg_hash->{$_} } qw(SSL_key SSL_key_file)) ) {
	$arg_hash->{SSL_use_cert} = 1
    }

    # if any of SSL_ca* is set don't set the other SSL_ca*
    # from defaults
    if ( $arg_hash->{SSL_ca} ) {
	$arg_hash->{SSL_ca_file} ||= undef
	$arg_hash->{SSL_ca_path} ||= undef
    } elsif ( $arg_hash->{SSL_ca_path} ) {
	$arg_hash->{SSL_ca_file} ||= undef
    } elsif ( $arg_hash->{SSL_ca_file} ) {
	$arg_hash->{SSL_ca_path} ||= undef;
    }

    # add library defaults
    $arg_hash->{SSL_use_cert} = $is_server if ! defined $arg_hash->{SSL_use_cert};


    # Avoid passing undef arguments to Net::SSLeay
    defined($arg_hash->{$_}) or delete($arg_hash->{$_}) for(keys %$arg_hash);

    # check SSL CA, cert etc arguments
    # some apps set keys '' to signal that it is not set, replace with undef
    for (qw( SSL_cert SSL_cert_file SSL_key SSL_key_file
	SSL_ca SSL_ca_file SSL_ca_path
	SSL_fingerprint )) {
	$arg_hash->{$_} = undef if defined $arg_hash->{$_}
	    and $arg_hash->{$_} eq '';
    }
    for(qw(SSL_cert_file SSL_key_file)) {
	 defined( my $file = $arg_hash->{$_} ) or next;
	for my $f (ref($file) eq 'HASH' ? values(%$file):$file ) {
	    die "$_ $f can't be used: $!" if ! open(my $fh,'<',$f)
	}
    }

    my $verify_mode = $arg_hash->{SSL_verify_mode} || 0;
    if ( $verify_mode != $Net_SSLeay_VERIFY_NONE) {
	for (qw(SSL_ca_file SSL_ca_path)) {
	    $CHECK_SSL_PATH->($_ => $arg_hash->{$_} || next);
	}
    } elsif ( $verify_mode ne '0' ) {
	# some users use the string 'SSL_VERIFY_PEER' instead of the constant
	die "SSL_verify_mode must be a number and not a string";
    }

    my $self = bless {},$class;

    my $vcn_scheme = delete $arg_hash->{SSL_verifycn_scheme};
    my $vcn_publicsuffix = delete $arg_hash->{SSL_verifycn_publicsuffix};
    if ( ! $is_server and $verify_mode & 0x01 and
	! $vcn_scheme || $vcn_scheme ne 'none' ) {

	# gets updated during configure_SSL
	my $verify_name;
	$self->{verify_name_ref} = \$verify_name;

	my $vcb = $arg_hash->{SSL_verify_callback};
	$arg_hash->{SSL_verify_callback} = sub {
	    my ($ok,$ctx_store,$certname,$error,$cert,$depth) = @_;
	    $ok = $vcb->($ok,$ctx_store,$certname,$error,$cert,$depth) if $vcb;
	    $ok or return 0;

	    return $ok if $depth != 0;

	    my $host = $verify_name || ref($vcn_scheme) && $vcn_scheme->{callback} && 'unknown';
	    if ( ! $host ) {
		if ( $vcn_scheme ) {
		    IO::Socket::SSL->_internal_error(
			"Cannot determine peer hostname for verification",8);
		    return 0;
		}
		warn "Cannot determine hostname of peer for verification. ".
		    "Disabling default hostname verification for now. ".
		    "Please specify hostname with SSL_verifycn_name and better set SSL_verifycn_scheme too.\n";
		return $ok;
	    }


	    # verify name
	    my $rv = IO::Socket::SSL::verify_hostname_of_cert(
		$host,$cert,$vcn_scheme,$vcn_publicsuffix );
	    if ( ! $rv ) {
		IO::Socket::SSL->_internal_error(
		    "hostname verification failed",5);
	    }
	    return $rv;
	};
    }

    if ($is_server) {
	if ($arg_hash->{SSL_ticket_keycb} && !$can_tckt_keycb) {
	    warn "Ticket Key Callback is not supported - ignoring option SSL_ticket_keycb\n";
	    delete $arg_hash->{SSL_ticket_keycb};
	}
    }


    my $ssl_op = $DEFAULT_SSL_OP;

    my $ver;
    for (split(/\s*:\s*/,$arg_hash->{SSL_version})) {
	m{^(!?)(?:(SSL(?:v2|v3|v23|v2/3))|(TLSv1(?:_?[123])?))$}i
	or croak("invalid SSL_version specified");
	my $not = $1;
	( my $v = lc($2||$3) ) =~s{^(...)}{\U$1};
	if ( $not ) {
	    $ssl_op |= $SSL_OP_NO{$v};
	} else {
	    croak("cannot set multiple SSL protocols in SSL_version")
		if $ver && $v ne $ver;
	    $ver = $v;
	    $ver =~s{/}{}; # interpret SSLv2/3 as SSLv23
	    $ver =~s{(TLSv1)(\d)}{$1\_$2}; # TLSv1_1
	}
    }

    my $ctx_new_sub =
	$ver eq 'TLSv1_3' ? $CTX_tlsv1_3_new :
	UNIVERSAL::can( 'Net::SSLeay',
	    $ver eq 'SSLv2'   ? 'CTX_v2_new' :
	    $ver eq 'SSLv3'   ? 'CTX_v3_new' :
	    $ver eq 'TLSv1'   ? 'CTX_tlsv1_new' :
	    $ver eq 'TLSv1_1' ? 'CTX_tlsv1_1_new' :
	    $ver eq 'TLSv1_2' ? 'CTX_tlsv1_2_new' :
	    'CTX_new'
	)
	or return IO::Socket::SSL->_internal_error("SSL Version $ver not supported",9);

    # For SNI in server mode we need a separate context for each certificate.
    my %ctx;
    if ($is_server) {
	my %sni;
	for my $opt (qw(SSL_key SSL_key_file SSL_cert SSL_cert_file)) {
	    my $val  = $arg_hash->{$opt} or next;
	    if ( ref($val) eq 'HASH' ) {
		while ( my ($host,$v) = each %$val ) {
		    $sni{lc($host)}{$opt} = $v;
		}
	    }
	}
	while (my ($host,$v) = each %sni) {
	    $ctx{$host} = $host =~m{%} ? $v : { %$arg_hash, %$v };
	}
    }
    $ctx{''} = $arg_hash if ! %ctx;

    for my $host (sort keys %ctx) {
	my $arg_hash = delete $ctx{$host};
	my $ctx;
	if ($host =~m{^([^%]*)%}) {
	    $ctx = $ctx{$1} or return IO::Socket::SSL->error(
		"SSL Context init for $host failed - no config for $1");
	    if (my @k = grep { !m{^SSL_(?:cert|key)(?:_file)?$} }
		keys %$arg_hash) {
		return IO::Socket::SSL->error(
		    "invalid keys @k in configuration '$host' of additional certs");
	    }
	    $can_multi_cert or return IO::Socket::SSL->error(
		"no support for both RSA and ECC certificate in same context");
	    $host = $1;
	    goto just_configure_certs;
	}

	$ctx = $ctx_new_sub->() or return
	    IO::Socket::SSL->error("SSL Context init failed");
	$CTX_CREATED_IN_THIS_THREAD{$ctx} = 1 if $use_threads;
	$ctx{$host} = $ctx; # replace value in %ctx with real context

	# SSL_OP_CIPHER_SERVER_PREFERENCE
	$ssl_op |= 0x00400000 if $arg_hash->{SSL_honor_cipher_order};

	if ($ver eq 'SSLv23' && !($ssl_op & $SSL_OP_NO{SSLv3})) {
	    # At least LibreSSL disables SSLv3 by default in SSL_CTX_new.
	    # If we really want SSL3.0 we need to explicitly allow it with
	    # SSL_CTX_clear_options.
	    Net::SSLeay::CTX_clear_options($ctx,$SSL_OP_NO{SSLv3});
	}

	Net::SSLeay::CTX_set_options($ctx,$ssl_op);

	# enable X509_V_FLAG_PARTIAL_CHAIN if possible (OpenSSL 1.1.0+)
	$check_partial_chain && $check_partial_chain->($ctx);

	# if we don't set session_id_context if client certificate is expected
	# client session caching will fail
	# if user does not provide explicit id just use the stringification
	# of the context
	if($arg_hash->{SSL_server} and my $id =
	    $arg_hash->{SSL_session_id_context} ||
	    ( $arg_hash->{SSL_verify_mode} & 0x01 ) && "$ctx" ) {
	    Net::SSLeay::CTX_set_session_id_context($ctx,$id,length($id));
	}

	# SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER makes syswrite return if at least one
	# buffer was written and not block for the rest
	# SSL_MODE_ENABLE_PARTIAL_WRITE can be necessary for non-blocking because we
	# cannot guarantee, that the location of the buffer stays constant
	Net::SSLeay::CTX_set_mode( $ctx,
	    SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER |
	    SSL_MODE_ENABLE_PARTIAL_WRITE |
	    ($arg_hash->{SSL_mode_release_buffers} ? $ssl_mode_release_buffers : 0)
	);

	if ( my $proto_list = $arg_hash->{SSL_npn_protocols} ) {
	    return IO::Socket::SSL->_internal_error("NPN not supported in Net::SSLeay",9)
		if ! $can_npn;
	    if($arg_hash->{SSL_server}) {
		# on server side SSL_npn_protocols means a list of advertised protocols
		Net::SSLeay::CTX_set_next_protos_advertised_cb($ctx, $proto_list);
	    } else {
		# on client side SSL_npn_protocols means a list of preferred protocols
		# negotiation algorithm used is "as-openssl-implements-it"
		Net::SSLeay::CTX_set_next_proto_select_cb($ctx, $proto_list);
	    }
	}

	if ( my $proto_list = $arg_hash->{SSL_alpn_protocols} ) {
	    return IO::Socket::SSL->_internal_error("ALPN not supported in Net::SSLeay",9)
		if ! $can_alpn;
	    if($arg_hash->{SSL_server}) {
		Net::SSLeay::CTX_set_alpn_select_cb($ctx, $proto_list);
	    } else {
		Net::SSLeay::CTX_set_alpn_protos($ctx, $proto_list);
	    }
	}

	if ($arg_hash->{SSL_ticket_keycb}) {
	    my $cb = $arg_hash->{SSL_ticket_keycb};
	    ($cb,my $arg) = ref($cb) eq 'CODE' ? ($cb):@$cb;
	    Net::SSLeay::CTX_set_tlsext_ticket_getkey_cb($ctx,$cb,$arg);
	}

	if ($arg_hash->{SSL_psk}) {
	    my $psk = $arg_hash->{SSL_psk};
	    if ($arg_hash->{SSL_server}) {
		$can_server_psk or return IO::Socket::SSL->_internal_error(
		    "no support for server side PSK");
		Net::SSLeay::CTX_set_psk_server_callback($ctx, sub {
		    my ($ssl,$identity,$psklen) = @_;
		    if (ref($psk) eq 'HASH') {
			return $psk->{$identity} || $psk->{''} ||
			    IO::Socket::SSL->_internal_error(
			    "no PSK for given identity '$identity' and no default");
		    } else {
			return $psk;
		    }
		});
	    } else {
		$can_client_psk or return IO::Socket::SSL->_internal_error(
		    "no support for client side PSK");
		Net::SSLeay::CTX_set_psk_client_callback($ctx, sub {
		    my $hint = shift;
		    my ($i,$p);
		    if (ref($psk) eq 'HASH') {
			$hint = '' if ! defined $hint;
			$p = $psk->{$hint} or return IO::Socket::SSL->_internal_error(
			    "no PSK for given hint '$hint'");
			$i = $hint;
		    } elsif (ref($psk)) { # [identity,psk]
			($i,$p) = @$psk;
		    } else {
			($i,$p) = ('io_socket_ssl', $psk)
		    }
		    # for some reason this expects the PSK in hex whereas the server
		    # side function expects the PSK in binary
		    return ($i, unpack("H*",$p));
		});
	    }
	}

	# Try to apply SSL_ca even if SSL_verify_mode is 0, so that they can be
	# used to verify OCSP responses.
	# If applying fails complain only if verify_mode != VERIFY_NONE.
	if ( $arg_hash->{SSL_ca}
	    || defined $arg_hash->{SSL_ca_file}
	    || defined $arg_hash->{SSL_ca_path} ) {
	    my $file = $arg_hash->{SSL_ca_file};
	    $file = undef if ref($file) eq 'SCALAR' && ! $$file;
	    my $dir = $arg_hash->{SSL_ca_path};
	    $dir = undef if ref($dir) eq 'SCALAR' && ! $$dir;
	    if ( $arg_hash->{SSL_ca} ) {
		my $store = Net::SSLeay::CTX_get_cert_store($ctx);
		for (@{$arg_hash->{SSL_ca}}) {
		    Net::SSLeay::X509_STORE_add_cert($store,$_) or
			return IO::Socket::SSL->error(
			    "Failed to add certificate to CA store");
		}
	    }
	    $dir = join($OPENSSL_LIST_SEPARATOR,@$dir) if ref($dir);
	    if ( $file || $dir and ! Net::SSLeay::CTX_load_verify_locations(
		$ctx, $file || '', $dir || '')) {
		return IO::Socket::SSL->error(
		    "Invalid certificate authority locations")
		    if $verify_mode != $Net_SSLeay_VERIFY_NONE;
	    }
	} elsif ( my %ca = IO::Socket::SSL::default_ca()) {
	    # no CA path given, continue with system defaults
	    my $dir = $ca{SSL_ca_path};
	    $dir = join($OPENSSL_LIST_SEPARATOR,@$dir) if ref($dir);
	    if (! Net::SSLeay::CTX_load_verify_locations( $ctx,
		$ca{SSL_ca_file} || '',$dir || '')
		&& $verify_mode != $Net_SSLeay_VERIFY_NONE) {
		return IO::Socket::SSL->error(
		    "Invalid default certificate authority locations")
	    }
	}

	if ($is_server && ($verify_mode & $Net_SSLeay_VERIFY_PEER)) {
	    if ($arg_hash->{SSL_client_ca}) {
		for (@{$arg_hash->{SSL_client_ca}}) {
		    return IO::Socket::SSL->error(
			"Failed to add certificate to client CA list") if
			! Net::SSLeay::CTX_add_client_CA($ctx,$_);
		}
	    }
	    if ($arg_hash->{SSL_client_ca_file}) {
		my $list = Net::SSLeay::load_client_CA_file(
		    $arg_hash->{SSL_client_ca_file}) or
		    return IO::Socket::SSL->error(
		    "Failed to load certificate to client CA list");
		Net::SSLeay::CTX_set_client_CA_list($ctx,$list);
	    }
	}

	my $X509_STORE_flags = $DEFAULT_X509_STORE_flags;
	if ($arg_hash->{'SSL_check_crl'}) {
	    $X509_STORE_flags |= Net::SSLeay::X509_V_FLAG_CRL_CHECK();
	    if ($arg_hash->{'SSL_crl_file'}) {
		my $bio = Net::SSLeay::BIO_new_file($arg_hash->{'SSL_crl_file'}, 'r');
		my $crl = Net::SSLeay::PEM_read_bio_X509_CRL($bio);
		Net::SSLeay::BIO_free($bio);
		if ( $crl ) {
		    Net::SSLeay::X509_STORE_add_crl(Net::SSLeay::CTX_get_cert_store($ctx), $crl);
		    Net::SSLeay::X509_CRL_free($crl);
		} else {
		    return IO::Socket::SSL->error("Invalid certificate revocation list");
		}
	    }
	}

	Net::SSLeay::X509_STORE_set_flags(
	    Net::SSLeay::CTX_get_cert_store($ctx),
	    $X509_STORE_flags
	) if $X509_STORE_flags;

	Net::SSLeay::CTX_set_default_passwd_cb($ctx,$arg_hash->{SSL_passwd_cb})
	    if $arg_hash->{SSL_passwd_cb};

	just_configure_certs:
	my ($havekey,$havecert);
	if ( my $x509 = $arg_hash->{SSL_cert} ) {
	    # binary, e.g. X509*
	    # we have either a single certificate or a list with
	    # a chain of certificates
	    my @x509 = ref($x509) eq 'ARRAY' ? @$x509: ($x509);
	    my $cert = shift @x509;
	    Net::SSLeay::CTX_use_certificate( $ctx,$cert )
		|| return IO::Socket::SSL->error("Failed to use Certificate");
	    foreach my $ca (@x509) {
		Net::SSLeay::CTX_add_extra_chain_cert( $ctx,$ca )
		    || return IO::Socket::SSL->error("Failed to use Certificate");
	    }
	    $havecert = 'OBJ';
	} elsif ( my $f = $arg_hash->{SSL_cert_file} ) {
	    # try to load chain from PEM or certificate from ASN1
	    my @err;
	    if (Net::SSLeay::CTX_use_certificate_chain_file($ctx,$f)) {
		$havecert = 'PEM';
	    } elsif (do {
		push @err, [ PEM => _errstack() ];
		Net::SSLeay::CTX_use_certificate_file($ctx,$f,FILETYPE_ASN1)
	    }) {
		$havecert = 'DER';
	    } else {
		push @err, [ DER => _errstack() ];
		# try to load certificate, key and chain from PKCS12 file
		my ($key,$cert,@chain) = Net::SSLeay::P_PKCS12_load_file($f,1);
		if (!$cert and $arg_hash->{SSL_passwd_cb}
		    and defined( my $pw = $arg_hash->{SSL_passwd_cb}->(0))) {
		    ($key,$cert,@chain) = Net::SSLeay::P_PKCS12_load_file($f,1,$pw);
		}
		PKCS12: while ($cert) {
		    Net::SSLeay::CTX_use_certificate($ctx,$cert) or last;
		    # Net::SSLeay::P_PKCS12_load_file is implemented using
		    # OpenSSL PKCS12_parse which according to the source code
		    # returns the chain with the last CA certificate first (i.e.
		    # reverse order as in the PKCS12 file). This is not
		    # documented but given the age of this function we'll assume
		    # that this will stay this way in the future.
		    while (my $ca = pop @chain) {
			Net::SSLeay::CTX_add_extra_chain_cert($ctx,$ca)
			    or last PKCS12;
		    }
		    last if $key && ! Net::SSLeay::CTX_use_PrivateKey($ctx,$key);
		    $havecert = 'PKCS12';
		    last;
		}
		$havekey = 'PKCS12' if $key;
		Net::SSLeay::X509_free($cert) if $cert;
		Net::SSLeay::EVP_PKEY_free($key) if $key;
		# don't free @chain, because CTX_add_extra_chain_cert
		# did not duplicate the certificates
	    }
	    if (!$havecert) {
		push @err, [ PKCS12 => _errstack() ];
		my $err = "Failed to load certificate from file $f:";
		for(@err) {
		    my ($type,@e) = @$_;
		    $err .= " [format:$type] @e **" if @e;
		}
		return IO::Socket::SSL->error($err);
	    }
	}

	if (!$havecert || $havekey) {
	    # skip SSL_key_*
	} elsif ( my $pkey = $arg_hash->{SSL_key} ) {
	    # binary, e.g. EVP_PKEY*
	    Net::SSLeay::CTX_use_PrivateKey($ctx, $pkey)
		|| return IO::Socket::SSL->error("Failed to use Private Key");
	    $havekey = 'MEM';
	} elsif ( my $f = $arg_hash->{SSL_key_file}
	    || (($havecert eq 'PEM') ? $arg_hash->{SSL_cert_file}:undef) ) {
	    for my $ft ( FILETYPE_PEM, FILETYPE_ASN1 ) {
		if (Net::SSLeay::CTX_use_PrivateKey_file($ctx,$f,$ft)) {
		    $havekey = ($ft == FILETYPE_PEM) ? 'PEM':'DER';
		    last;
		}
	    }
	    $havekey or return IO::Socket::SSL->error(
		"Failed to load key from file (no PEM or DER)");
	}

	Net::SSLeay::CTX_set_post_handshake_auth($ctx,1)
	    if (!$is_server && $can_pha && $havecert && $havekey);
    }

    if ($arg_hash->{SSL_server}) {

	if ( my $f = $arg_hash->{SSL_dh_file} ) {
	    my $bio = Net::SSLeay::BIO_new_file( $f,'r' )
		|| return IO::Socket::SSL->error( "Failed to open DH file $f" );
	    my $dh = Net::SSLeay::PEM_read_bio_DHparams($bio);
	    Net::SSLeay::BIO_free($bio);
	    $dh || return IO::Socket::SSL->error( "Failed to read PEM for DH from $f - wrong format?" );
	    my $rv;
	    for (values (%ctx)) {
		$rv = Net::SSLeay::CTX_set_tmp_dh( $_,$dh ) or last;
	    }
	    Net::SSLeay::DH_free( $dh );
	    $rv || return IO::Socket::SSL->error( "Failed to set DH from $f" );
	} elsif ( my $dh = $arg_hash->{SSL_dh} ) {
	    # binary, e.g. DH*

	    for( values %ctx ) {
		Net::SSLeay::CTX_set_tmp_dh( $_,$dh ) || return
		    IO::Socket::SSL->error( "Failed to set DH from SSL_dh" );
	    }
	}
    }

    if ( my $curve = $arg_hash->{SSL_ecdh_curve} ) {
	return IO::Socket::SSL->_internal_error(
	    "ECDH curve needs Net::SSLeay>=1.56 and OpenSSL>=1.0",9)
	    if ! $can_ecdh;

	for(values %ctx) {
	    if ($arg_hash->{SSL_server} and $curve eq 'auto') {
		if ($can_ecdh eq 'can_auto') {
			Net::SSLeay::CTX_set_ecdh_auto($_,1) or
			    return IO::Socket::SSL->error(
			    "failed to set ECDH curve context");
		} elsif ($can_ecdh eq 'auto') {
		    # automatically enabled anyway
		} else {
		    return IO::Socket::SSL->error(
			"SSL_CTX_set_ecdh_auto not implemented");
		}

	    } elsif ($set_groups_list) {
		$set_groups_list->($_,$curve) or return IO::Socket::SSL->error(
		    "failed to set ECDH groups/curves on context");
		# needed for OpenSSL 1.0.2 if ($can_ecdh eq 'can_auto') {
		Net::SSLeay::CTX_set_ecdh_auto($_,1) if $can_ecdh eq 'can_auto';
	    } elsif ($curve =~m{:}) {
		return IO::Socket::SSL->error(
		    "SSL_CTX_groups_list or SSL_CTX_curves_list not implemented");

	    } elsif ($arg_hash->{SSL_server}) {
		if ( $curve !~ /^\d+$/ ) {
		    # name of curve, find NID
		    $curve = Net::SSLeay::OBJ_txt2nid($curve)
			|| return IO::Socket::SSL->error(
			"cannot find NID for curve name '$curve'");
		}
		my $ecdh = Net::SSLeay::EC_KEY_new_by_curve_name($curve) or
		    return IO::Socket::SSL->error(
		    "cannot create curve for NID $curve");
		for( values %ctx ) {
		    Net::SSLeay::CTX_set_tmp_ecdh($_,$ecdh) or
			return IO::Socket::SSL->error(
			"failed to set ECDH curve context");
		}
		Net::SSLeay::EC_KEY_free($ecdh);
	    }
	}
    }

    my $verify_cb = $arg_hash->{SSL_verify_callback};
    my @accept_fp;
    if ( my $fp = $arg_hash->{SSL_fingerprint} ) {
	for( ref($fp) ? @$fp : $fp) {
	    my ($algo,$pubkey,$digest) = m{^(?:([\w-]+)\$)?(pub\$)?([a-f\d:]+)$}i
		or return IO::Socket::SSL->_internal_error("invalid fingerprint '$_'",9);
	    ( $digest = lc($digest) ) =~s{:}{}g;
	    $algo ||=
		length($digest) == 32 ? 'md5' :
		length($digest) == 40 ? 'sha1' :
		length($digest) == 64 ? 'sha256' :
		return IO::Socket::SSL->_internal_error(
		    "cannot detect hash algorithm from fingerprint '$_'",9);
	    $algo = lc($algo);
	    push @accept_fp,[ $algo, $pubkey || '', pack('H*',$digest) ]
	}
    }
    my $verify_fingerprint = @accept_fp && do {
	my $fail;
	my $force = $arg_hash->{SSL_force_fingerprint};
	sub {
	    my ($ok,$cert,$depth) = @_;
	    $fail = 1 if ! $ok;
	    return 1 if $depth>0; # to let us continue with verification
	    # Check fingerprint only from top certificate.
	    my %fp;
	    for(@accept_fp) {
		my $fp = $fp{$_->[0],$_->[1]} ||= $_->[1]
		    ? Net::SSLeay::X509_pubkey_digest($cert,$algo2digest->($_->[0]))
		    : Net::SSLeay::X509_digest($cert,$algo2digest->($_->[0]));
		next if $fp ne $_->[2];
		return 1;
	    }
	    return $force ? 0 : ! $fail;
	}
    };
    my $verify_callback = ( $verify_cb || @accept_fp ) && sub {
	my ($ok, $ctx_store) = @_;
	my ($certname,$cert,$error,$depth);
	if ($ctx_store) {
	    $cert  = Net::SSLeay::X509_STORE_CTX_get_current_cert($ctx_store);
	    $error = Net::SSLeay::X509_STORE_CTX_get_error($ctx_store);
	    $depth = Net::SSLeay::X509_STORE_CTX_get_error_depth($ctx_store);
	    $certname =
		Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_issuer_name($cert)).
		Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($cert));
	    $error &&= Net::SSLeay::ERR_error_string($error);
	}
	$DEBUG>=3 && DEBUG( "ok=$ok [$depth] $certname" );
	$ok = $verify_cb->($ok,$ctx_store,$certname,$error,$cert,$depth) if $verify_cb;
	$ok = $verify_fingerprint->($ok,$cert,$depth) if $verify_fingerprint && $cert;
	return $ok;
    };

    if ( $^O eq 'darwin' ) {
	# explicitly set error code to disable use of apples TEA patch
	# https://hynek.me/articles/apple-openssl-verification-surprises/
	my $vcb = $verify_callback;
	$verify_callback = sub {
	    my $rv = $vcb ? &$vcb : $_[0];
	    if ( $rv != 1 ) {
		# 50 - X509_V_ERR_APPLICATION_VERIFICATION: application verification failure
		Net::SSLeay::X509_STORE_CTX_set_error($_[1], 50);
	    }
	    return $rv;
	};
    }
    Net::SSLeay::CTX_set_verify($_, $verify_mode, $verify_callback)
	for (values %ctx);

    my $staple_callback = $arg_hash->{SSL_ocsp_staple_callback};
    if ( !$is_server && $can_ocsp_staple && ! $verify_fingerprint) {
	$self->{ocsp_cache} = $arg_hash->{SSL_ocsp_cache};
	my $status_cb = sub {
	    my ($ssl,$resp) = @_;
	    my $iossl = $SSL_OBJECT{$ssl} or
		die "no IO::Socket::SSL object found for SSL $ssl";
	    $iossl->[1] and do {
		# we must return with 1 or it will be called again
		# and because we have no SSL object we must make the error global
		Carp::cluck($IO::Socket::SSL::SSL_ERROR
		    = "OCSP callback on server side");
		return 1;
	    };
	    $iossl = $iossl->[0];

	    # if we have a callback use this
	    # callback must not free or copy $resp !!
	    if ( $staple_callback ) {
		$staple_callback->($iossl,$resp);
		return 1;
	    }

	    # default callback does verification
	    if ( ! $resp ) {
		$DEBUG>=3 && DEBUG("did not get stapled OCSP response");
		return 1;
	    }
	    $DEBUG>=3 && DEBUG("got stapled OCSP response");
	    my $status = Net::SSLeay::OCSP_response_status($resp);
	    if ($status != Net::SSLeay::OCSP_RESPONSE_STATUS_SUCCESSFUL()) {
		$DEBUG>=3 && DEBUG("bad status of stapled OCSP response: ".
		    Net::SSLeay::OCSP_response_status_str($status));
		return 1;
	    }
	    if (!eval { Net::SSLeay::OCSP_response_verify($ssl,$resp) }) {
		$DEBUG>=3 && DEBUG("verify of stapled OCSP response failed");
		return 1;
	    }
	    my (@results,$hard_error);
	    my @chain = $iossl->peer_certificates;
	    for my $cert (@chain) {
		my $certid = eval { Net::SSLeay::OCSP_cert2ids($ssl,$cert) };
		if (!$certid) {
		    $DEBUG>=3 && DEBUG("cannot create OCSP_CERTID: $@");
		    push @results,[-1,$@];
		    last;
		}
		($status) = Net::SSLeay::OCSP_response_results($resp,$certid);
		if ($status && $status->[2]) {
		    my $cache = ${*$iossl}{_SSL_ctx}{ocsp_cache};
		    if (!$status->[1]) {
			push @results,[1,$status->[2]{nextUpdate}];
			$cache && $cache->put($certid,$status->[2]);
		    } elsif ( $status->[2]{statusType} ==
			Net::SSLeay::V_OCSP_CERTSTATUS_GOOD()) {
			push @results,[1,$status->[2]{nextUpdate}];
			$cache && $cache->put($certid,{
			    %{$status->[2]},
			    expire => time()+120,
			    soft_error => $status->[1],
			});
		    } else {
			push @results,($hard_error = [0,$status->[1]]);
			$cache && $cache->put($certid,{
			    %{$status->[2]},
			    hard_error => $status->[1],
			});
		    }
		}
	    }
	    # return result of lead certificate, this should be in chain[0] and
	    # thus result[0], but we better check. But if we had any hard_error
	    # return this instead
	    if ($hard_error) {
		${*$iossl}{_SSL_ocsp_verify} = $hard_error;
	    } elsif (@results and $chain[0] == $iossl->peer_certificate) {
		${*$iossl}{_SSL_ocsp_verify} = $results[0];
	    }
	    return 1;
	};
	Net::SSLeay::CTX_set_tlsext_status_cb($_,$status_cb) for (values %ctx);
    }

    if ( my $cl = $arg_hash->{SSL_cipher_list} ) {
	for (keys %ctx) {
	    Net::SSLeay::CTX_set_cipher_list($ctx{$_}, ref($cl)
		? $cl->{$_} || $cl->{''} || $DEFAULT_SSL_ARGS{SSL_cipher_list} || next
		: $cl
	    ) || return IO::Socket::SSL->error("Failed to set SSL cipher list");
	}
    }
    if ( my $cl = $arg_hash->{SSL_ciphersuites} ) {
	return IO::Socket::SSL->error("no support for SSL_ciphersuites in Net::SSLeay")
	    if ! $can_ciphersuites;
	for (keys %ctx) {
	    Net::SSLeay::CTX_set_ciphersuites($ctx{$_}, ref($cl)
		? $cl->{$_} || $cl->{''} || $DEFAULT_SSL_ARGS{SSL_cipher_list} || next
		: $cl
	    ) || return IO::Socket::SSL->error("Failed to set SSL cipher list");
	}
    }

    # Main context is default context or any other if no default context.
    my $ctx = $ctx{''} || (values %ctx)[0];
    if (keys(%ctx) > 1 || ! exists $ctx{''}) {
	$can_server_sni or return IO::Socket::SSL->_internal_error(
	    "Server side SNI not supported for this openssl/Net::SSLeay",9);

	Net::SSLeay::CTX_set_tlsext_servername_callback($ctx, sub {
	    my $ssl = shift;
	    my $host = Net::SSLeay::get_servername($ssl);
	    $host = '' if ! defined $host;
	    my $snictx = $ctx{lc($host)} || $ctx{''} or do {
		$DEBUG>1 and DEBUG(
		    "cannot get context from servername '$host'");
		return 2; # SSL_TLSEXT_ERR_ALERT_FATAL
	    };
	    $DEBUG>1 and DEBUG("set context from servername $host");
	    Net::SSLeay::set_SSL_CTX($ssl,$snictx) if $snictx != $ctx;
	    return 0; # SSL_TLSEXT_ERR_OK
	});
    }

    if ( my $cb = $arg_hash->{SSL_create_ctx_callback} ) {
	$cb->($_) for values (%ctx);
    }

    $self->{context} = $ctx;
    $self->{verify_mode} = $arg_hash->{SSL_verify_mode};
    $self->{ocsp_mode} =
	defined($arg_hash->{SSL_ocsp_mode}) ? $arg_hash->{SSL_ocsp_mode} :
	$self->{verify_mode} ? IO::Socket::SSL::SSL_OCSP_TRY_STAPLE() :
	0;
    $DEBUG>=3 && DEBUG( "new ctx $ctx" );

    if ( my $cache = $arg_hash->{SSL_session_cache} ) {
	# use predefined cache
	$self->{session_cache} = $cache
    } elsif ( my $size = $arg_hash->{SSL_session_cache_size}) {
	$self->{session_cache} = IO::Socket::SSL::Session_Cache->new( $size );
    }


    if ($self->{session_cache} and %sess_cb) {
	Net::SSLeay::CTX_set_session_cache_mode($ctx,
	    Net::SSLeay::SESS_CACHE_CLIENT());
	my $cache = $self->{session_cache};
	$sess_cb{new}($ctx, sub {
	    my ($ssl,$session) = @_;
	    my $self = ($SSL_OBJECT{$ssl} || do {
		warn "callback session new: no known SSL object for $ssl";
		return;
	    })->[0];
	    my $args = ${*$self}{_SSL_arguments};
	    my $key = $args->{SSL_session_key} or do {
		warn "callback session new: no known SSL_session_key for $ssl";
		return;
	    };
	    $DEBUG>=3 && DEBUG("callback session new <$key> $session");
	    Net::SSLeay::SESSION_up_ref($session);
	    $cache->add_session($key,$session);
	});
	$sess_cb{remove}($ctx, sub {
	    my ($ctx,$session) = @_;
	    $DEBUG>=3 && DEBUG("callback session remove $session");
	    $cache->del_session(undef,$session);
	});
    }

    return $self;
}


sub has_session_cache {
    return defined shift->{session_cache};
}


sub CLONE { %CTX_CREATED_IN_THIS_THREAD = (); }
sub DESTROY {
    my $self = shift;
    if ( my $ctx = $self->{context} ) {
	$DEBUG>=3 && DEBUG("free ctx $ctx open=".join( " ",keys %CTX_CREATED_IN_THIS_THREAD ));
	if (!$use_threads or delete $CTX_CREATED_IN_THIS_THREAD{$ctx} ) {
	    # remove any verify callback for this context
	    if ( $self->{verify_mode}) {
		$DEBUG>=3 && DEBUG("free ctx $ctx callback" );
		Net::SSLeay::CTX_set_verify($ctx, 0,undef);
	    }
	    if ( $self->{ocsp_error_ref}) {
		$DEBUG>=3 && DEBUG("free ctx $ctx tlsext_status_cb" );
		Net::SSLeay::CTX_set_tlsext_status_cb($ctx,undef);
	    }
	    $DEBUG>=3 && DEBUG("OK free ctx $ctx" );
	    Net::SSLeay::CTX_free($ctx);
	}
    }
    delete(@{$self}{'context','session_cache'});
}

package IO::Socket::SSL::Session_Cache;
*DEBUG = *IO::Socket::SSL::DEBUG;

# The cache is consisting of one list which contains all sessions and then
# for each session key another list containing all sessions for same key.
# The order of the list is by use, i.e. last used are put on top.
# self.ghead points to the top of the global list while
# self.shead{key} to the top of the session key specific list
# All lists are cyclic
# Each element in the list consists of an array with slots for ...
use constant {
    SESSION => 0,  # session object
    KEY     => 1,  # key for object
    GNEXT   => 2,  # next element in global list
    GPREV   => 3,  # previous element in global list
    SNEXT   => 4,  # next element for same session key
    SPREV   => 5,  # previous element for same session key
};

sub new {
    my ($class, $size) = @_;
    $size>0 or return;
    return bless {
	room  => $size,  # free space regarding to max size
	ghead => undef,  # top of global list
	shead => {},     # top of key specific list
    }, $class;
}

sub add_session {
    my ($self, $key, $session) = @_;

    # create new
    my $v = [];
    $v->[SESSION] = $session;
    $v->[KEY] = $key;
    $DEBUG>=3 && DEBUG("add_session($key,$session)");
    _add_entry($self,$v);
}

sub replace_session {
    my ($self, $key, $session) = @_;
    $self->del_session($key);
    $self->add_session($key, $session);
}

sub del_session {
    my ($self, $key, $session) = @_;

    # find all sessions which match given key and session and add to @del
    # if key is given scan only sessions for the key, else all sessions
    my ($head,$inext) = $key
	? ($self->{shead}{$key},SNEXT) : ($self->{ghead},GNEXT);
    my $v = $head;
    my @del;
    while ($v) {
	if (!$session) {
	    push @del,$v
	} elsif ($v->[SESSION] == $session) {
	    push @del, $v;
	    last;
	}
	$v = $v->[$inext];
	last if $v == $head;
    }
    $DEBUG>=3 && DEBUG("del_session("
	. ($key ? $key : "undef")
	. ($session ? ",$session) -> " : ") -> ")
	.  (~~@del || 'none'));
    for (@del) {
	_del_entry($self,$_);
	Net::SSLeay::SESSION_free($_->[SESSION]) if $_->[SESSION];
	@$_ = ();
    }
    return ~~@del;
}

sub get_session {
    my ($self, $key, $session) = @_;

    # find first session for key
    # if $session is given further look for this specific one
    my $v = $self->{shead}{$key};
    if ($session) {
	my $shead = $v;
	while ($v) {
	    $DEBUG>=3 && DEBUG("check $session - $v->[SESSION]");
	    last if $v->[SESSION] == $session;
	    $v = $v->[SNEXT];
	    $v = undef if $v == $shead; # session not found
	}
    }

    # mark as recent by moving to top so that it gets expired last
    _touch_entry($self,$v) if $v;

    $DEBUG>=3 && DEBUG("get_session($key"
	. ( $session ? ",$session) -> " : ") -> ")
	. ($v? $v->[SESSION]:"none"));
    return $v && $v->[SESSION];
}

sub _add_entry {
    my ($self,$v) = @_;

    # If there are already sessions for same key add to this list else create
    # a new sublist for this key. Similar for global list.
    for(
	[ SNEXT, SPREV, \$self->{shead}{$v->[KEY]} ],
	[ GNEXT, GPREV, \$self->{ghead} ],
    ) {
	my ($inext,$iprev,$rhead) = @$_;
	if ($$rhead) {
	    # add on top of list
	    $v->[$inext] = $$rhead;
	    $v->[$iprev] = ${$rhead}->[$iprev];
	    ${$rhead}->[$iprev][$inext] = $v;
	    ${$rhead}->[$iprev] = $v;
	    $$rhead = $v;
	} else {
	    # create a new list
	    $$rhead = $v->[$inext] = $v->[$iprev] = $v;
	}
    }

    $self->{room}--;

    # drop old entries if necessary
    if ($self->{room}<0) {
	my $l = $self->{ghead}[GPREV];
	_del_entry($self,$l);
	Net::SSLeay::SESSION_free($l->[SESSION]) if $l->[SESSION];
	@$l = ();
    }
}

sub _del_entry {
    my ($self,$v) = @_;
    # Remove element from both key specific list and global list
    # If key specific list is then empty drop it from self.shead
    for(
	[ SNEXT, SPREV, \$self->{shead}{$v->[KEY]} ],
	[ GNEXT, GPREV, \$self->{ghead} ],
    ) {
	my ($inext,$iprev,$rhead) = @$_;
	$$rhead or return;
	$v->[$inext][$iprev] = $v->[$iprev];
	$v->[$iprev][$inext] = $v->[$inext];
	if ($v != $$rhead) {
	    # not removed from top of list
	} elsif ($v->[$inext] == $v) {
	    # was only element on list, drop list
	    if ($inext == SNEXT) {
		delete $self->{shead}{$v->[KEY]};
	    } else {
		$$rhead = undef;
	    }
	} else {
	    # was top element, keep others
	    $$rhead = $v->[$inext];
	}
    }
    $self->{room}++;
}

sub _touch_entry {
    my ($self,$v) = @_;

    # Put element on top of both global list and key specific list
    # so that it gets expired last when making space in the cache
    for(
	[ SNEXT, SPREV, \$self->{shead}{$v->[KEY]} ],
	[ GNEXT, GPREV, \$self->{ghead} ],
    ) {
	my ($inext,$iprev,$rhead) = @$_;
	$$rhead or die "entry not in list ($inext)"; # should not happen
	next if $$rhead == $v; # already at top

	# remove from current position - like _del_entry
	$v->[$inext][$iprev] = $v->[$iprev];
	$v->[$iprev][$inext] = $v->[$inext];

	# add on top - like _add_entry
	$v->[$inext] = $$rhead;
	$v->[$iprev] = ${$rhead}->[$iprev];
	${$rhead}->[$iprev][$inext] = $v;
	${$rhead}->[$iprev] = $v;
	$$rhead = $v;
    }
}

sub _dump {
    my $self = shift;

    my %v2i;
    my $v = $self->{ghead};
    while ($v) {
	exists $v2i{$v} and die;
	$v2i{$v} = int(keys %v2i);
	$v = $v->[GNEXT];
	last if $v == $self->{ghead};
    }

    my $out = "room: $self->{room}\nghead:\n";
    $v = $self->{ghead};
    while ($v) {
	$out .= sprintf(" - [%d] <%d,%d> '%s' <%s>\n",
	    $v2i{$v}, $v2i{$v->[GPREV]}, $v2i{$v->[GNEXT]},
	    $v->[KEY], $v->[SESSION]);
	$v = $v->[GNEXT];
	last if $v == $self->{ghead};
    }
    $out .= "shead:\n";
    for my $key (sort keys %{$self->{shead}}) {
	$out .= " - '$key'\n";
	my $shead = $self->{shead}{$key};
	my $v = $shead;
	while ($v) {
	    $out .= sprintf("   - [%d] <%d,%d> '%s' <%s>\n",
		$v2i{$v}, $v2i{$v->[SPREV]}, $v2i{$v->[SNEXT]},
		$v->[KEY], $v->[SESSION]);
	    $v = $v->[SNEXT];
	    last if $v == $shead;
	}
    }
    return $out;
}

sub DESTROY {
    my $self = shift;
    delete $self->{shead};
    my $v = delete $self->{ghead};
    while ($v) {
	Net::SSLeay::SESSION_free($v->[SESSION]) if $v->[SESSION];
	my $next = $v->[GNEXT];
	@$v = ();
	$v = $next;
    }
}



package IO::Socket::SSL::OCSP_Cache;

sub new {
    my ($class,$size) = @_;
    return bless {
	'' => { _lru => 0, size => $size || 100 }
    },$class;
}
sub get {
    my ($self,$id) = @_;
    my $e = $self->{$id} or return;
    $e->{_lru} = $self->{''}{_lru}++;
    if ( $e->{expire} && time()<$e->{expire}) {
	delete $self->{$id};
	return;
    }
    if ( $e->{nextUpdate} && time()<$e->{nextUpdate} ) {
	delete $self->{$id};
	return;
    }
    return $e;
}

sub put {
    my ($self,$id,$e) = @_;
    $self->{$id} = $e;
    $e->{_lru} = $self->{''}{_lru}++;
    my $del = keys(%$self) - $self->{''}{size};
    if ($del>0) {
	my @k = sort { $self->{$a}{_lru} <=> $self->{$b}{_lru} } keys %$self;
	delete @{$self}{ splice(@k,0,$del) };
    }
    return $e;
}

package IO::Socket::SSL::OCSP_Resolver;
*DEBUG = *IO::Socket::SSL::DEBUG;

# create a new resolver
# $ssl - the ssl object
# $cache - OCSP_Cache object (put,get)
# $failhard - flag if we should fail hard on OCSP problems
# $certs - list of certs to verify
sub new {
    my ($class,$ssl,$cache,$failhard,$certs) = @_;
    my (%todo,$done,$hard_error,@soft_error);
    for my $cert (@$certs) {
	# skip entries which have no OCSP uri or where we cannot get a certid
	# (e.g. self-signed or where we don't have the issuer)
	my $subj = Net::SSLeay::X509_NAME_oneline(Net::SSLeay::X509_get_subject_name($cert));
	my $uri = Net::SSLeay::P_X509_get_ocsp_uri($cert) or do {
	    $DEBUG>2 && DEBUG("no URI for certificate $subj");
	    push @soft_error,"no ocsp_uri for $subj";
	    next;
	};
	my $certid = eval { Net::SSLeay::OCSP_cert2ids($ssl,$cert) } or do {
	    $DEBUG>2 && DEBUG("no OCSP_CERTID for certificate $subj: $@");
	    push @soft_error,"no certid for $subj: $@";
	    next;
	};
	if (!($done = $cache->get($certid))) {
	    push @{ $todo{$uri}{ids} }, $certid;
	    push @{ $todo{$uri}{subj} }, $subj;
	} elsif ( $done->{hard_error} ) {
	    # one error is enough to fail validation
	    $hard_error = $done->{hard_error};
	    %todo = ();
	    last;
	} elsif ( $done->{soft_error} ) {
	    push @soft_error,$done->{soft_error};
	}
    }
    while ( my($uri,$v) = each %todo) {
	my $ids = $v->{ids};
	$v->{req} = Net::SSLeay::i2d_OCSP_REQUEST(
	    Net::SSLeay::OCSP_ids2req(@$ids));
    }
    $hard_error ||= '' if ! %todo;
    return bless {
	ssl => $ssl,
	cache => $cache,
	failhard => $failhard,
	hard_error => $hard_error,
	soft_error => @soft_error ? join("; ",@soft_error) : undef,
	todo => \%todo,
    },$class;
}

# return current result, e.g. '' for no error, else error
# if undef we have no final result yet
sub hard_error { return shift->{hard_error} }
sub soft_error { return shift->{soft_error} }

# return hash with uri => ocsp_request_data for open requests
sub requests {
    my $todo = shift()->{todo};
    return map { ($_,$todo->{$_}{req}) } keys %$todo;
}

# add new response
sub add_response {
    my ($self,$uri,$resp) = @_;
    my $todo = delete $self->{todo}{$uri};
    return $self->{error} if ! $todo || $self->{error};

    my ($req,@soft_error,@hard_error);

    # do we have a response
    if (!$resp) {
	@soft_error = "http request for OCSP failed; subject: ".
	    join("; ",@{$todo->{subj}});

    # is it a valid OCSP_RESPONSE
    } elsif ( ! eval { $resp = Net::SSLeay::d2i_OCSP_RESPONSE($resp) }) {
	@soft_error = "invalid response (no OCSP_RESPONSE); subject: ".
	    join("; ",@{$todo->{subj}});
	# hopefully short-time error
	$self->{cache}->put($_,{
	    soft_error => "@soft_error",
	    expire => time()+10,
	}) for (@{$todo->{ids}});
    # is the OCSP response status success
    } elsif (
	( my $status = Net::SSLeay::OCSP_response_status($resp))
	    != Net::SSLeay::OCSP_RESPONSE_STATUS_SUCCESSFUL()
    ){
	@soft_error = "OCSP response failed: ".
	    Net::SSLeay::OCSP_response_status_str($status).
	    "; subject: ".join("; ",@{$todo->{subj}});
	# hopefully short-time error
	$self->{cache}->put($_,{
	    soft_error => "@soft_error",
	    expire => time()+10,
	}) for (@{$todo->{ids}});

    # does nonce match the request and can the signature be verified
    } elsif ( ! eval {
	$req = Net::SSLeay::d2i_OCSP_REQUEST($todo->{req});
	Net::SSLeay::OCSP_response_verify($self->{ssl},$resp,$req);
    }) {
	if ($@) {
	    @soft_error = $@
	} else {
	    my @err;
	    while ( my $err = Net::SSLeay::ERR_get_error()) {
		push @soft_error, Net::SSLeay::ERR_error_string($err);
	    }
	    @soft_error = 'failed to verify OCSP response; subject: '.
		join("; ",@{$todo->{subj}}) if ! @soft_error;
	}
	# configuration problem or we don't know the signer
	$self->{cache}->put($_,{
	    soft_error => "@soft_error",
	    expire => time()+120,
	}) for (@{$todo->{ids}});

    # extract results from response
    } elsif ( my @result =
	Net::SSLeay::OCSP_response_results($resp,@{$todo->{ids}})) {
	my (@found,@miss);
	for my $rv (@result) {
	    if ($rv->[2]) {
		push @found,$rv->[0];
		if (!$rv->[1]) {
		    # no error
		    $self->{cache}->put($rv->[0],$rv->[2]);
		} elsif ( $rv->[2]{statusType} ==
		    Net::SSLeay::V_OCSP_CERTSTATUS_GOOD()) {
		    # soft error, like response after nextUpdate
		    push @soft_error,$rv->[1]."; subject: ".
			join("; ",@{$todo->{subj}});
		    $self->{cache}->put($rv->[0],{
			%{$rv->[2]},
			soft_error => "@soft_error",
			expire => time()+120,
		    });
		} else {
		    # hard error
		    $self->{cache}->put($rv->[0],$rv->[2]);
		    push @hard_error, $rv->[1]."; subject: ".
			join("; ",@{$todo->{subj}});
		}
	    } else {
		push @miss,$rv->[0];
	    }
	}
	if (@miss && @found) {
	    # we sent multiple responses, but server answered only to one
	    # try again
	    $self->{todo}{$uri} = $todo;
	    $todo->{ids} = \@miss;
	    $todo->{req} = Net::SSLeay::i2d_OCSP_REQUEST(
		Net::SSLeay::OCSP_ids2req(@miss));
	    $DEBUG>=2 && DEBUG("$uri just answered ".@found." of ".(@found+@miss)." requests");
	}
    } else {
	@soft_error = "no data in response; subject: ".
	    join("; ",@{$todo->{subj}});
	# probably configuration problem
	$self->{cache}->put($_,{
	    soft_error => "@soft_error",
	    expire => time()+120,
	}) for (@{$todo->{ids}});
    }

    Net::SSLeay::OCSP_REQUEST_free($req) if $req;
    if ($self->{failhard}) {
	push @hard_error,@soft_error;
	@soft_error = ();
    }
    if (@soft_error) {
	$self->{soft_error} .= "; " if $self->{soft_error};
	$self->{soft_error} .= "$uri: ".join('; ',@soft_error);
    }
    if (@hard_error) {
	$self->{hard_error} = "$uri: ".join('; ',@hard_error);
	%{$self->{todo}} = ();
    } elsif ( ! %{$self->{todo}} ) {
	$self->{hard_error} = ''
    }
    return $self->{hard_error};
}

# make all necessary requests to get OCSP responses blocking
sub resolve_blocking {
    my ($self,%args) = @_;
    while ( my %todo = $self->requests ) {
	eval { require HTTP::Tiny } or die "need HTTP::Tiny installed";
	# OCSP responses have their own signature, so we don't need SSL verification
	my $ua = HTTP::Tiny->new(verify_SSL => 0,%args);
	while (my ($uri,$reqdata) = each %todo) {
	    $DEBUG && DEBUG("sending OCSP request to $uri");
	    my $resp = $ua->request('POST',$uri, {
		headers => { 'Content-type' => 'application/ocsp-request' },
		content => $reqdata
	    });
	    $DEBUG && DEBUG("got  OCSP response from $uri code=$resp->{status}");
	    defined ($self->add_response($uri,
		$resp->{success} && $resp->{content}))
		&& last;
	}
    }
    $DEBUG>=2 && DEBUG("no more open OCSP requests");
    return $self->{hard_error};
}

package IO::Socket::SSL::Trace;
*DEBUG = *IO::Socket::SSL::DEBUG;

# Exhaustive list of constants we need for tracing
my %trace_constants = map { $_ => eval { Net::SSLeay->$_ } || -1 } qw(
    SSL2_VERSION
    SSL3_VERSION
    TLS1_VERSION
    TLS1_1_VERSION
    TLS1_2_VERSION
    TLS1_3_VERSION
    DTLS1_VERSION
    DTLS1_2_VERSION
    DTLS1_BAD_VER
    SSL3_RT_INNER_CONTENT_TYPE
    SSL3_RT_CHANGE_CIPHER_SPEC
    SSL3_RT_ALERT
    SSL3_RT_HEADER
    SSL3_RT_HANDSHAKE
    SSL3_RT_APPLICATION_DATA
    SSL2_MT_ERROR
    SSL2_MT_CLIENT_HELLO
    SSL2_MT_CLIENT_MASTER_KEY
    SSL2_MT_CLIENT_FINISHED
    SSL2_MT_SERVER_HELLO
    SSL2_MT_SERVER_VERIFY
    SSL2_MT_SERVER_FINISHED
    SSL2_MT_REQUEST_CERTIFICATE
    SSL2_MT_CLIENT_CERTIFICATE
    SSL3_MT_HELLO_REQUEST
    SSL3_MT_CLIENT_HELLO
    SSL3_MT_SERVER_HELLO
    SSL3_MT_NEWSESSION_TICKET
    SSL3_MT_CERTIFICATE
    SSL3_MT_SERVER_KEY_EXCHANGE
    SSL3_MT_CLIENT_KEY_EXCHANGE
    SSL3_MT_CERTIFICATE_REQUEST
    SSL3_MT_SERVER_DONE
    SSL3_MT_CERTIFICATE_VERIFY
    SSL3_MT_FINISHED
    SSL3_MT_CERTIFICATE_STATUS
    SSL3_MT_ENCRYPTED_EXTENSIONS
    SSL3_MT_SUPPLEMENTAL_DATA
    SSL3_MT_END_OF_EARLY_DATA
    SSL3_MT_KEY_UPDATE
    SSL3_MT_NEXT_PROTO
    SSL3_MT_MESSAGE_HASH
);

#
# Major versions
#
$trace_constants{SSL2_VERSION_MAJOR} = $trace_constants{SSL2_VERSION} >> 8;
$trace_constants{SSL3_VERSION_MAJOR} = $trace_constants{SSL3_VERSION} >> 8;

#
# Mapping between trace constant and version string
#
my %tc_ver2s;
for (
    [ SSL2_VERSION    => "SSLv2" ],
    [ SSL2_VERSION    => "SSLv2" ],
    [ SSL3_VERSION    => "SSLv3" ],
    [ TLS1_VERSION    => "TLSv1.0" ],
    [ TLS1_1_VERSION  => "TLSv1.1" ],
    [ TLS1_2_VERSION  => "TLSv1.2" ],
    [ TLS1_3_VERSION  => "TLSv1.3" ],
    [ DTLS1_VERSION   => "DTLSv1.0" ],
    [ DTLS1_2_VERSION => "DTLSv1.2" ],
    [ DTLS1_BAD_VER   => "DTLSv1.0 (bad)" ]
) {
    next if $trace_constants{$_->[0]} == -1;
    $tc_ver2s{$trace_constants{$_->[0]}} = $_->[1];
}

my %tc_type2s;
for (
    [ SSL3_RT_HEADER             => "TLS header" ],
    [ SSL3_RT_CHANGE_CIPHER_SPEC => "TLS change cipher" ],
    [ SSL3_RT_ALERT              => "TLS alert" ],
    [ SSL3_RT_HANDSHAKE          => "TLS handshake" ],
    [ SSL3_RT_APPLICATION_DATA   => "TLS app data" ]
) {
    next if $trace_constants{$_->[0]} == -1;
    $tc_type2s{$trace_constants{$_->[0]}} = $_->[1];
}

my %tc_msgtype2s;
for(
    [ SSL2_MT_ERROR               => "Error" ],
    [ SSL2_MT_CLIENT_HELLO        => "Client hello" ],
    [ SSL2_MT_CLIENT_MASTER_KEY   => "Client key" ],
    [ SSL2_MT_CLIENT_FINISHED     => "Client finished" ],
    [ SSL2_MT_SERVER_HELLO        => "Server hello" ],
    [ SSL2_MT_SERVER_VERIFY       => "Server verify" ],
    [ SSL2_MT_SERVER_FINISHED     => "Server finished" ],
    [ SSL2_MT_REQUEST_CERTIFICATE => "Request CERT" ],
    [ SSL2_MT_REQUEST_CERTIFICATE => "Client CERT" ]
) {
    next if $trace_constants{$_->[0]} == -1;
    $tc_msgtype2s{$trace_constants{SSL2_VERSION_MAJOR}, $trace_constants{$_->[0]}} = $_->[1];
}
for(
    [ SSL3_MT_HELLO_REQUEST        => "Hello request" ],
    [ SSL3_MT_CLIENT_HELLO         => "Client hello" ],
    [ SSL3_MT_SERVER_HELLO         => "Server hello" ],
    [ SSL3_MT_NEWSESSION_TICKET    => "Newsession Ticket" ],
    [ SSL3_MT_CERTIFICATE          => "Certificate" ],
    [ SSL3_MT_SERVER_KEY_EXCHANGE  => "Server key exchange" ],
    [ SSL3_MT_CLIENT_KEY_EXCHANGE  => "Client key exchange" ],
    [ SSL3_MT_CERTIFICATE_REQUEST  => "Request CERT" ],
    [ SSL3_MT_SERVER_DONE          => "Server finished" ],
    [ SSL3_MT_CERTIFICATE_VERIFY   => "CERT verify" ],
    [ SSL3_MT_FINISHED             => "Finished" ],
    [ SSL3_MT_CERTIFICATE_STATUS   => "Certificate Status" ],
    [ SSL3_MT_ENCRYPTED_EXTENSIONS => "Encrypted Extensions" ],
    [ SSL3_MT_SUPPLEMENTAL_DATA    => "Supplemental data" ],
    [ SSL3_MT_END_OF_EARLY_DATA    => "End of early data" ],
    [ SSL3_MT_KEY_UPDATE           => "Key update" ],
    [ SSL3_MT_NEXT_PROTO           => "Next protocol" ],
    [ SSL3_MT_MESSAGE_HASH         => "Message hash" ]
) {
    next if $trace_constants{$_->[0]} == -1;
    $tc_msgtype2s{$trace_constants{SSL3_VERSION_MAJOR}, $trace_constants{$_->[0]}} = $_->[1];
}

#
# Translation of curl ossl_trace
#

sub ossl_trace {
    $DEBUG>=2 or return;
    my ($direction, $ssl_ver, $content_type, $buf, $len, $ssl) = @_;

    # Restore original $! value on return
    local $!;

    my $verstr = $tc_ver2s{$ssl_ver} || "(version=$ssl_ver)";

    # Log progress for interesting records only (like Handshake or Alert), skip
    # all raw record headers (content_type == SSL3_RT_HEADER or ssl_ver == 0).
    # For TLS 1.3, skip notification of the decrypted inner Content-Type.

    if ($ssl_ver
	&& ($content_type != $trace_constants{SSL3_RT_HEADER})
	&& ($content_type != $trace_constants{SSL3_RT_INNER_CONTENT_TYPE})
    ) {

        # the info given when the version is zero is not that useful for us
        $ssl_ver >>= 8;  # check the upper 8 bits only below */

        # SSLv2 doesn't seem to have TLS record-type headers, so OpenSSL
        # always pass-up content-type as 0. But the interesting message-type
        # is at 'buf[0]'.

	my $tls_rt_name = ($ssl_ver == $trace_constants{SSL3_VERSION_MAJOR} && $content_type)
	    ? $tc_type2s{$content_type} || "TLS Unknown (type=$content_type)"
	    : "";

        my $msg_type;
        my $msg_name;
        if ($content_type == $trace_constants{SSL3_RT_CHANGE_CIPHER_SPEC}) {
            $msg_type = unpack('c1', $buf);
            $msg_name = "Change cipher spec";
        } elsif ($content_type == $trace_constants{SSL3_RT_ALERT}) {
            my @c = unpack('c2', $buf);
            $msg_type = ($c[0] << 8) + $c[1];
            $msg_name = eval { Net::SSLeay::alert_desc_string_long($msg_type) } || "Unknown alert";
        } else {
            $msg_type = unpack('c1', $buf);
	    $msg_name = $tc_msgtype2s{$ssl_ver, $msg_type} || "Unknown (ssl_ver=$ssl_ver, msg=$msg_type)";
        }
	DEBUG(sprintf("* %s (%s), %s, %s (%d)",
	    $verstr, $direction ? "OUT" : "IN", $tls_rt_name, $msg_name, $msg_type));
    }

    #
    # Here one might want to hexdump $buf (?)
    #
    # $DEBUG>=4 && printf STDERR "%s", hexdump($buf);
}


1;

__END__
