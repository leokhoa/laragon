# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 575 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/debug_read.al)"
###
### read and write helpers that block
###

sub debug_read {
    my ($replyr, $gotr) = @_;
    my $vm = $trace>2 && $linux_debug ?
	(split ' ', `cat /proc/$$/stat`)[22] : 'vm_unknown';
    warn "  got " . blength($$gotr) . ':'
	. blength($$replyr) . " bytes (VM=$vm).\n" if $trace == 3;
    warn "  got `$$gotr' (" . blength($$gotr) . ':'
	. blength($$replyr) . " bytes, VM=$vm)\n" if $trace>3;
}

# end of Net::SSLeay::debug_read
1;
