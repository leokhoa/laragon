package URI::file::FAT;

use strict;
use warnings;

use parent 'URI::file::Win32';

our $VERSION = '5.34';

sub fix_path
{
    shift; # class
    for (@_) {
	# turn it into 8.3 names
	my @p = map uc, split(/\./, $_, -1);
	return if @p > 2;     # more than 1 dot is not allowed
	@p = ("") unless @p;  # split bug? (returns nothing when splitting "")
	$_ = substr($p[0], 0, 8);
        if (@p > 1) {
	    my $ext = substr($p[1], 0, 3);
	    $_ .= ".$ext" if length $ext;
	}
    }
    1;  # ok
}

1;
