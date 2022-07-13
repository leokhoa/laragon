# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 635 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/ssl_write_all.al)"
sub ssl_write_all {
    my $ssl = $_[0];
    my ($data_ref, $errs);
    if (ref $_[1]) {
	$data_ref = $_[1];
    } else {
	$data_ref = \$_[1];
    }
    my ($wrote, $written, $to_write) = (0,0, blength($$data_ref));
    my $vm = $trace>2 && $linux_debug ?
	(split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
    warn "  write_all VM at entry=$vm\n" if $trace>2;
    while ($to_write) {
	#sleep 1; # *** DEBUG
	warn "partial `$$data_ref'\n" if $trace>3;
	$wrote = write_partial($ssl, $written, $to_write, $$data_ref);
	if (defined $wrote && ($wrote > 0)) {  # write_partial can return -1
	    $written += $wrote;
	    $to_write -= $wrote;
	} else {
	  if (defined $wrote) {
	    # check error conditions via SSL_get_error per man page
	    if ( my $sslerr = get_error($ssl, $wrote) ) {
	      my $errstr = ERR_error_string($sslerr);
	      my $errname = '';
	      SWITCH: {
		$sslerr == constant("ERROR_NONE") && do {
		  # according to map page SSL_get_error(3ssl):
		  #  The TLS/SSL I/O operation completed.
		  #  This result code is returned if and only if ret > 0
                  # so if we received it here complain...
		  warn "ERROR_NONE unexpected with invalid return value!"
		    if $trace;
		  $errname = "SSL_ERROR_NONE";
		};
		$sslerr == constant("ERROR_WANT_READ") && do {
		  # operation did not complete, call again later, so do not
		  # set errname and empty err_que since this is a known
		  # error that is expected but, we should continue to try
		  # writing the rest of our data with same io call and params.
		  warn "ERROR_WANT_READ (TLS/SSL Handshake, will continue)\n"
		    if $trace;
		  print_errs('SSL_write(want read)');
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_WRITE") && do {
		  # operation did not complete, call again later, so do not
		  # set errname and empty err_que since this is a known
		  # error that is expected but, we should continue to try
		  # writing the rest of our data with same io call and params.
		  warn "ERROR_WANT_WRITE (TLS/SSL Handshake, will continue)\n"
		    if $trace;
		  print_errs('SSL_write(want write)');
		  last SWITCH;
		};
		$sslerr == constant("ERROR_ZERO_RETURN") && do {
		  # valid protocol closure from other side, no longer able to
		  # write, since there is no longer a session...
		  warn "ERROR_ZERO_RETURN($wrote): TLS/SSLv3 Closure alert\n"
		    if $trace;
		  $errname = "SSL_ERROR_ZERO_RETURN";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_SSL") && do {
		  # library/protocol error
		  warn "ERROR_SSL($wrote): Library/Protocol error occured\n"
		    if $trace;
		  $errname = "SSL_ERROR_SSL";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_CONNECT") && do {
		  # according to man page, should never happen on call to
		  # SSL_write, so complain, but handle as known error type
		  warn "ERROR_WANT_CONNECT: Unexpected error for SSL_write\n"
		    if $trace;
		  $errname = "SSL_ERROR_WANT_CONNECT";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_ACCEPT") && do {
		  # according to man page, should never happen on call to
		  # SSL_write, so complain, but handle as known error type
		  warn "ERROR_WANT_ACCEPT: Unexpected error for SSL_write\n"
		    if $trace;
		  $errname = "SSL_ERROR_WANT_ACCEPT";
		  last SWITCH;
		};
		$sslerr == constant("ERROR_WANT_X509_LOOKUP") && do {
		  # operation did not complete: waiting on call back,
		  # call again later, so do not set errname and empty err_que
		  # since this is a known error that is expected but, we should
		  # continue to try writing the rest of our data with same io
		  # call parameter.
		  warn "ERROR_WANT_X509_LOOKUP: (Cert Callback asked for in ".
		    "SSL_write will contine)\n" if $trace;
		  print_errs('SSL_write(want x509');
		  last SWITCH;
		};
		$sslerr == constant("ERROR_SYSCALL") && do {
		  # some IO error occured. According to man page:
		  # Check retval, ERR, fallback to errno
		  if ($wrote==0) { # EOF
		    warn "ERROR_SYSCALL($wrote): EOF violates protocol.\n"
		      if $trace;
		    $errname = "SSL_ERROR_SYSCALL(EOF)";
		  } else { # -1 underlying BIO error reported.
		    # check error que for details, don't set errname since we
		    # are directly appending to errs
		    my $chkerrs = print_errs('SSL_write (syscall)');
		    if ($chkerrs) {
		      warn "ERROR_SYSCALL($wrote): Have errors\n" if $trace;
		      $errs .= "ssl_write_all $$: 1 - ERROR_SYSCALL($wrote,".
			"$sslerr,$errstr,$!)\n$chkerrs";
		    } else { # que was empty, use errno
		      warn "ERROR_SYSCALL($wrote): errno($!)\n" if $trace;
		      $errs .= "ssl_write_all $$: 1 - ERROR_SYSCALL($wrote,".
			"$sslerr) : $!\n";
		    }
		  }
		  last SWITCH;
		};
		warn "Unhandled val $sslerr from SSL_get_error(SSL,$wrote)\n"
		  if $trace;
		$errname = "SSL_ERROR_?($sslerr)";
	      } # end of SWITCH block
	      if ($errname) { # if we had an errname set add the error
		$errs .= "ssl_write_all $$: 1 - $errname($wrote,$sslerr,".
		  "$errstr,$!)\n";
	      }
	    } # endif on have SSL_get_error val
	  } # endif on $wrote defined
	} # endelse on $wrote > 0
	$vm = $trace>2 && $linux_debug ?
	    (split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
	warn "  written so far $wrote:$written bytes (VM=$vm)\n" if $trace>2;
	# append remaining errors in que and report if errs exist
	$errs .= print_errs('SSL_write');
	return (wantarray ? (undef, $errs) : undef) if $errs;
    }
    return wantarray ? ($written, $errs) : $written;
}

# end of Net::SSLeay::ssl_write_all
1;
