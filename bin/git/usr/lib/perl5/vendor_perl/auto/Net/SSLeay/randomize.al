# NOTE: Derived from blib/lib/Net/SSLeay.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Net::SSLeay;

#line 1378 "blib/lib/Net/SSLeay.pm (autosplit into blib/lib/auto/Net/SSLeay/randomize.al)"
### Arrange some randomness for eay PRNG

sub randomize (;$$$) {
    my ($rn_seed_file, $seed, $egd_path) = @_;
    my $rnsf = defined($rn_seed_file) && -r $rn_seed_file;

	$egd_path = '';
    $egd_path = $ENV{'EGD_PATH'} if $ENV{'EGD_PATH'};

    RAND_seed(rand() + $$);  # Stir it with time and pid

    unless ($rnsf || -r $Net::SSLeay::random_device || $seed || -S $egd_path) {
	my $poll_retval = Net::SSLeay::RAND_poll();
	warn "Random number generator not seeded!!!" if $trace && !$poll_retval;
    }

    RAND_load_file($rn_seed_file, -s _) if $rnsf;
    RAND_seed($seed) if $seed;
    RAND_seed($ENV{RND_SEED}) if $ENV{RND_SEED};
    RAND_load_file($Net::SSLeay::random_device, $Net::SSLeay::how_random/8)
	if -r $Net::SSLeay::random_device;
}

# end of Net::SSLeay::randomize
1;
