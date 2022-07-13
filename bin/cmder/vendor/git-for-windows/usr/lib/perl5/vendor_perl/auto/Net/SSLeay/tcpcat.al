# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1146 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/tcpcat.al)"
sub tcpcat { # address, port, message, $crt, $key --> reply / (reply,errs,cert)
    my ($dest_serv, $port, $out_message) = @_;
    my ($got, $errs, $written);

    ($got, $errs) = open_proxy_tcp_connection($dest_serv, $port);
    return (wantarray ? (undef, $errs) : undef) unless $got;

    ### Connected. Exchange some data (doing repeated tries if necessary).

    warn "tcpcat $$: sending " . blength($out_message) . " bytes...\n"
	if $trace==3;
    warn "tcpcat $$: sending `$out_message' (" . blength($out_message)
	. " bytes)...\n" if $trace>3;
    ($written, $errs) = tcp_write_all($out_message);
    goto cleanup unless $written;

    sleep $slowly if $slowly;  # Closing too soon can abort broken servers
    CORE::shutdown SSLCAT_S, 1;  # Half close --> No more output, send EOF to server

    warn "waiting for reply...\n" if $trace>2;
    ($got, $errs) = tcp_read_all();
    warn "Got " . blength($got) . " bytes.\n" if $trace==3;
    warn "Got `$got' (" . blength($got) . " bytes)\n" if $trace>3;

cleanup:
    close SSLCAT_S;
    return wantarray ? ($got, $errs) : $got;
}

# end of Net::SSLeay::tcpcat
1;
